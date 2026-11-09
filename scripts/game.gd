extends Node3D

const SPEED := 7.0
const MAX_AMMO := 18
var player: CharacterBody3D
var camera: Camera3D
var health := 100
var ammo := MAX_AMMO
var score := 0
var wave := 0
var enemies: Array[CharacterBody3D] = []
var dead := false
var shoot_cooldown := 0.0
var enemy_timer := 0.0
var joy_id := -1
var look_id := -1
var joy_origin := Vector2.ZERO
var joy_delta := Vector2.ZERO
var look_last := Vector2.ZERO
var hud: Label
var message: Label
var crosshair: Label
var fire_button: Button
var reload_button: Button
var restart_button: Button
var stick_base: ColorRect
var stick_knob: ColorRect
var rng := RandomNumberGenerator.new()
var ai: Node
var shots_fired := 0
var shots_hit := 0
var distance_walked := 0.0
var play_time := 0.0
var ai_label: Label
var enemy_states := {}
var ai_tick := 0.0

func _ready() -> void:
 rng.randomize()
 ai = preload("res://scripts/adaptive_ai.gd").new()
 add_child(ai)
 _make_world()
 _make_player()
 _make_ui()
 _next_wave()
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _material(color: Color) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = 0.85
 return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, solid := true) -> Node3D:
 var body := StaticBody3D.new() if solid else Node3D.new()
 parent.add_child(body)
 body.position = pos
 var mesh := MeshInstance3D.new()
 var cube := BoxMesh.new()
 cube.size = size
 mesh.mesh = cube
 mesh.material_override = _material(color)
 body.add_child(mesh)
 if solid:
  var collision := CollisionShape3D.new()
  var shape := BoxShape3D.new()
  shape.size = size
  collision.shape = shape
  body.add_child(collision)
 return body

func _make_world() -> void:
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_COLOR
 e.background_color = Color("101d31")
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("8096ba")
 e.ambient_light_energy = 0.65
 env.environment = e
 add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55, -35, 0)
 sun.light_energy = 1.3
 add_child(sun)
 _box(self, Vector3(52, 1, 52), Vector3(0, -0.5, 0), Color("273b4b"))
 for i in range(-5, 6):
  _box(self, Vector3(0.08, 0.02, 52), Vector3(i * 4, 0.02, 0), Color("304c59"), false)
 _box(self, Vector3(52, 7, 1), Vector3(0, 3.5, -26), Color("142536"))
 _box(self, Vector3(52, 7, 1), Vector3(0, 3.5, 26), Color("142536"))
 _box(self, Vector3(1, 7, 52), Vector3(-26, 3.5, 0), Color("142536"))
 _box(self, Vector3(1, 7, 52), Vector3(26, 3.5, 0), Color("142536"))
 for p in [Vector3(-10, 1, -8), Vector3(9, 1, -10), Vector3(-12, 1, 9), Vector3(12, 1, 11), Vector3(0, 1, -17)]:
  _box(self, Vector3(4, 2, 3), p, Color("586e78"))

func _make_player() -> void:
 player = CharacterBody3D.new()
 player.position = Vector3(0, 1.1, 12)
 add_child(player)
 var collision := CollisionShape3D.new()
 var shape := CapsuleShape3D.new()
 shape.radius = 0.45
 shape.height = 1.8
 collision.shape = shape
 player.add_child(collision)
 camera = Camera3D.new()
 camera.current = true
 camera.position.y = 0.5
 camera.fov = 75
 player.add_child(camera)
 _box(camera, Vector3(0.22, 0.22, 0.85), Vector3(0.48, -0.38, -0.8), Color("1a232b"), false)
 _box(camera, Vector3(0.12, 0.13, 0.5), Vector3(0.48, -0.32, -1.35), Color("52d8c2"), false)

func _label(parent: Control, txt: String, pos: Vector2, size: Vector2, font_size: int) -> Label:
 var l := Label.new()
 l.text = txt
 l.position = pos
 l.size = size
 l.add_theme_font_size_override("font_size", font_size)
 l.add_theme_color_override("font_color", Color("e6f9ff"))
 parent.add_child(l)
 return l

func _make_ui() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_PASS
 layer.add_child(root)
 hud = _label(root, "", Vector2(25, 15), Vector2(700, 45), 26)
 message = _label(root, "", Vector2(400, 80), Vector2(600, 70), 36)
 crosshair = _label(root, "+", Vector2(625, 330), Vector2(60, 60), 38)
 stick_base = ColorRect.new()
 stick_base.color = Color(0.3, 0.8, 0.9, 0.2)
 stick_base.position = Vector2(90, 515)
 stick_base.size = Vector2(150, 150)
 stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(stick_base)
 stick_knob = ColorRect.new()
 stick_knob.color = Color(0.35, 0.95, 0.85, 0.7)
 stick_knob.position = Vector2(140, 565)
 stick_knob.size = Vector2(50, 50)
 stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(stick_knob)
 fire_button = Button.new()
 fire_button.text = "FIRE"
 fire_button.position = Vector2(1070, 520)
 fire_button.size = Vector2(155, 145)
 fire_button.add_theme_font_size_override("font_size", 30)
 fire_button.pressed.connect(_shoot)
 root.add_child(fire_button)
 reload_button = Button.new()
 reload_button.text = "RELOAD"
 reload_button.position = Vector2(1090, 420)
 reload_button.size = Vector2(130, 65)
 reload_button.pressed.connect(_reload)
 root.add_child(reload_button)
 restart_button = Button.new()
 restart_button.text = "RESTART"
 restart_button.position = Vector2(535, 400)
 restart_button.size = Vector2(210, 75)
 restart_button.visible = false
 restart_button.pressed.connect(func(): get_tree().reload_current_scene())
 root.add_child(restart_button)
 ai_label = _label(root, "", Vector2(25, 58), Vector2(900, 35), 18)
 _update_hud()

func _update_hud() -> void:
 hud.text = "HP %d   |   AMMO %d/%d   |   SCORE %d   |   WAVE %d" % [health, ammo, MAX_AMMO, score, wave]
 if ai_label != null and ai != null:
  ai_label.text = "ADAPTIVE AI  |  Skill estimate %d%%  |  Accuracy %d%%" % [int(ai.difficulty * 100), int(100.0 * float(shots_hit) / maxf(1.0, float(shots_fired)))]

func _next_wave() -> void:
 wave += 1
 message.text = "WAVE %d" % wave
 for i in range(min(3 + wave, 12)):
  _spawn_enemy()
 _update_hud()

func _spawn_enemy() -> void:
 var enemy := CharacterBody3D.new()
 enemy.position = Vector3(rng.randf_range(-20, 20), 1.0, rng.randf_range(-20, -6))
 if enemy.position.distance_to(player.position) < 7:
  enemy.position.z = -20
 enemy.set_meta("hp", 2 + int(wave / 3))
 add_child(enemy)
 var coll := CollisionShape3D.new()
 var shape := CapsuleShape3D.new()
 shape.radius = 0.55
 shape.height = 2
 coll.shape = shape
 enemy.add_child(coll)
 var visual := MeshInstance3D.new()
 var mesh := CapsuleMesh.new()
 mesh.radius = 0.55
 mesh.height = 2
 visual.mesh = mesh
 visual.material_override = _material(Color("fa5b66"))
 enemy.add_child(visual)
 var eye := MeshInstance3D.new()
 var eye_mesh := BoxMesh.new()
 eye_mesh.size = Vector3(0.6, 0.17, 0.14)
 eye.mesh = eye_mesh
 eye.position = Vector3(0, 0.3, -0.52)
 eye.material_override = _material(Color("ffed9e"))
 enemy.add_child(eye)
 enemies.append(enemy)
 enemy_states[enemy.get_instance_id()] = {"action": 0, "context": 0, "age": 0.0, "damage": 0.0, "strafe": -1.0 if rng.randf() < 0.5 else 1.0, "last_hp": health}

func _physics_process(delta: float) -> void:
 if dead:
  return
 shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
 enemy_timer += delta
 play_time += delta
 ai_tick += delta
 if ai_tick >= 1.0:
  ai.observe_player(shots_fired, shots_hit, distance_walked, play_time)
  ai_tick = 0.0
 var previous_position := player.global_position
 var move := Vector2(float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)), float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))) + joy_delta
 move = move.limit_length(1)
 var direction := player.global_transform.basis * Vector3(move.x, 0, move.y)
 player.velocity.x = direction.x * SPEED
 player.velocity.z = direction.z * SPEED
 player.velocity.y = -0.1
 player.move_and_slide()
 distance_walked += player.global_position.distance_to(previous_position)
 for item in enemies.duplicate():
  var enemy: CharacterBody3D = item
  if not is_instance_valid(enemy):
   enemies.erase(enemy)
   continue
  var toward: Vector3 = player.global_position - enemy.global_position
  toward.y = 0
  var dist: float = toward.length()
  var id: int = enemy.get_instance_id()
  var state: Dictionary = enemy_states[id]
  state["age"] += delta
  if state["age"] > 2.5:
   var reward := clampf(float(state["damage"]) / 15.0, -1.0, 1.0)
   ai.learn(state["context"], state["action"], reward)
   state["context"] = ai.context_for(dist)
   state["action"] = ai.choose_action(state["context"])
   state["age"] = 0.0
   state["damage"] = 0.0
  var forward: Vector3 = toward.normalized() if dist > 0.01 else Vector3.ZERO
  var side: Vector3 = Vector3(-forward.z, 0, forward.x) * float(state["strafe"])
  var enemy_direction: Vector3 = forward
  if state["action"] == 1:
   enemy_direction = (forward * 0.35 + side * 0.9).normalized()
  elif state["action"] == 2:
   enemy_direction = (-forward * 0.8 + side * 0.35).normalized() if dist < 14.0 else forward
  var ray_start: Vector3 = enemy.global_position + Vector3.UP * 0.3
  var query := PhysicsRayQueryParameters3D.create(ray_start, ray_start + enemy_direction * 2.8)
  query.exclude = [enemy.get_rid(), player.get_rid()]
  var obstacle := get_world_3d().direct_space_state.intersect_ray(query)
  if not obstacle.is_empty():
   enemy_direction = (side * 0.85 + forward * 0.15).normalized()
  if dist > 1.6 or state["action"] == 2:
   enemy.velocity = enemy_direction * (2.0 + wave * 0.12 + ai.difficulty * 1.1)
   enemy.move_and_slide()
  else:
   enemy.velocity = Vector3.ZERO
  if dist < 1.8 and enemy_timer > 0.75:
   var damage := 5
   health = maxi(0, health - damage)
   state["damage"] += damage
   _update_hud()
   if health == 0:
    _game_over()
  enemy_states[id] = state
 if enemy_timer > 0.75:
  enemy_timer = 0
 if enemies.is_empty():
  _next_wave()

func _shoot() -> void:
 if dead or shoot_cooldown > 0:
  return
 if ammo <= 0:
  _reload()
  return
 ammo -= 1
 shots_fired += 1
 shoot_cooldown = 0.18
 var origin := camera.global_position
 var end := origin - camera.global_transform.basis.z * 80.0
 var query := PhysicsRayQueryParameters3D.create(origin, end)
 query.exclude = [player.get_rid()]
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():
  var target = hit["collider"]
  if target in enemies:
   shots_hit += 1
   var hp: int = target.get_meta("hp") - 1
   target.set_meta("hp", hp)
   if hp <= 0:
    var id: int = target.get_instance_id()
    if enemy_states.has(id):
     var state: Dictionary = enemy_states[id]
     ai.learn(state["context"], state["action"], clampf(float(state["damage"]) / 15.0 - 0.5, -1.0, 1.0))
     enemy_states.erase(id)
    enemies.erase(target)
    target.queue_free()
    score += 100
 _update_hud()

func _reload() -> void:
 if dead:
  return
 ammo = MAX_AMMO
 _update_hud()

func _game_over() -> void:
 dead = true
 message.text = "GAME OVER — SCORE %d" % score
 restart_button.visible = true

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  _look(event.relative)
 if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
  _shoot()
 if event is InputEventScreenTouch:
  if event.pressed:
   if event.position.x < 380 and event.position.y > 350 and joy_id == -1:
    joy_id = event.index
    joy_origin = event.position
   elif event.position.x > 380 and event.position.x < 1040 and look_id == -1:
    look_id = event.index
    look_last = event.position
  else:
   if event.index == joy_id:
    joy_id = -1
    joy_delta = Vector2.ZERO
    stick_knob.position = Vector2(140, 565)
   if event.index == look_id:
    look_id = -1
 if event is InputEventScreenDrag:
  if event.index == joy_id:
   joy_delta = ((event.position - joy_origin) / 85.0).limit_length(1)
   stick_knob.position = Vector2(140, 565) + joy_delta * 48
  elif event.index == look_id:
   _look(event.position - look_last)
   look_last = event.position

func _look(relative: Vector2) -> void:
 if dead:
  return
 player.rotate_y(-relative.x * 0.003)
 camera.rotation.x = clampf(camera.rotation.x - relative.y * 0.003, -1.3, 1.3)
