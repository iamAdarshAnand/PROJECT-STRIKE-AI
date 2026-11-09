extends Node
## Contextual multi-armed bandit: on-device online learning, no cloud dependency.
const ACTIONS := ["rush", "strafe", "retreat"]
const CONTEXTS := 4
var estimates: Array = []
var counts: Array = []
var exploration := 0.18
var rng := RandomNumberGenerator.new()
var player_shots := 0
var player_hits := 0
var player_distance := 0.0
var player_time := 0.0
var difficulty := 0.0

func _ready() -> void:
 rng.randomize()
 for context in range(CONTEXTS):
  estimates.append([0.0, 0.0, 0.0])
  counts.append([0, 0, 0])

func observe_player(shots: int, hits: int, distance: float, elapsed: float) -> void:
 player_shots = shots
 player_hits = hits
 player_distance = distance
 player_time = elapsed
 var accuracy := float(hits) / maxf(1.0, float(shots))
 var mobility := distance / maxf(1.0, elapsed)
 difficulty = clampf(accuracy * 0.65 + clampf(mobility / 6.0, 0.0, 1.0) * 0.35, 0.0, 1.0)

func context_for(distance: float) -> int:
 var close := distance < 9.0
 var skilled := difficulty >= 0.45
 return int(close) + 2 * int(skilled)

func choose_action(context: int) -> int:
 if rng.randf() < exploration:
  return rng.randi_range(0, ACTIONS.size() - 1)
 var best := 0
 var best_value := -100000.0
 for i in range(ACTIONS.size()):
  var bonus := 0.35 * sqrt(log(float(2 + counts[context][0] + counts[context][1] + counts[context][2])) / float(1 + counts[context][i]))
  var value: float = estimates[context][i] + bonus
  if value > best_value:
   best_value = value
   best = i
 return best

func learn(context: int, action: int, reward: float) -> void:
 counts[context][action] += 1
 var n: int = counts[context][action]
 estimates[context][action] += (clampf(reward, -1.0, 1.0) - estimates[context][action]) / float(n)
