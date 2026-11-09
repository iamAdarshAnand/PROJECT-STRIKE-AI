# PROJECT STRIKE AI 🎯

**A prototype 3D first-person Android arena shooter featuring adaptive enemy tactics and lightweight on-device machine learning.**

**Developer / project credit:** [Adarsh Anand](https://github.com/iamAdarshAnand)  
**AI-assisted development:** OpenAI ChatGPT  
**Engine:** Godot 4.2+ (GDScript) · **Rendering:** GL Compatibility · **Platform:** Android (landscape), desktop for testing

> **Status:** Source-code prototype. Not yet verified by a Godot editor run or Android APK build. No precompiled APK is included.

## Gameplay

Fight successive waves of procedurally generated enemies in a compact 3D arena. Move, aim, shoot, reload, survive, and earn points. Enemies can rush, strafe, or retreat and adjust their choices from in-game feedback.

## AI and machine learning

The `scripts/adaptive_ai.gd` module implements a **contextual multi-armed bandit**, not a pretrained neural network. Four contexts combine player skill (low/high) with distance (near/far). For each context, the algorithm tracks reward estimates for **rush**, **strafe**, and **retreat**. It selects actions using epsilon-greedy exploration with a confidence bonus and updates estimates based on damage inflicted, with a penalty when an enemy dies.

- Player skill is estimated from accuracy and movement.
- Obstacle avoidance uses local raycasts; it is **not** navigation-mesh pathfinding.
- Learning happens entirely on device, in memory; values reset on game restart.
- No cloud AI, internet, external ML runtime, telemetry, or downloaded assets.

## Controls

| Action | Android touchscreen | Desktop |
|---|---|---|
| Move | Drag lower-left virtual joystick | WASD |
| Look / aim | Drag middle/right view | Hold right mouse button and drag |
| Shoot | FIRE button | Space |
| Reload | RELOAD button | R |
| Restart | RESTART after defeat | On-screen restart |

## Run in Godot

1. Download/clone this repository.
2. Install [Godot 4.2 or later](https://godotengine.org/download/).
3. Import `project.godot` using Godot Project Manager.
4. Open the project and press **F5** to launch.
5. Test controls and enemy behavior; address any Godot parser or device-specific errors before release.

## Export Android APK

1. Install Android Studio's **Android SDK** (platform, build tools, platform-tools, command-line tools) and **JDK 17**.
2. In Godot: **Editor → Manage Export Templates**; install templates matching the exact editor version.
3. In **Editor → Editor Settings → Export → Android**, set the Java SDK and Android SDK paths.
4. Choose **Project → Export → Add… → Android**.
5. Set a unique Android package name, e.g. `dev.adarshanand.projectstrikeai`. Select `arm64-v8a` for modern Android devices.
6. Export with **Export With Debug** enabled to `ProjectStrikeAI.apk`.
7. Transfer the APK to your phone and install it. For public distribution, configure a private signing keystore and produce a release AAB.

## Project structure

```text
project.godot
main.tscn
scripts/
  game.gd          # Procedural arena, FPS controls, combat, enemies, HUD
  adaptive_ai.gd   # Online contextual bandit learning
```

## Credits

**Adarsh Anand** — project owner and developer.  
**OpenAI ChatGPT** — AI-assisted prototyping, code generation and documentation.  
**Godot Engine** — open-source game engine (see [Godot license](https://godotengine.org/license/)).

All prototype geometry is generated in code. No third-party art, music, or sound assets are included.

## License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE). Copyright (c) 2026 Adarsh Anand.
