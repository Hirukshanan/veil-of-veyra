# Veil of Veyra prototype

This is a Godot 4.7 GDScript prototype for an original third-person island-fantasy action RPG.

## Open the project

1. Download the standard Godot 4.7.2 editor from the [official Godot download page](https://godotengine.org/download/windows/).
2. Extract the download and open `project.godot` with Godot.
3. Press **F5** to run the project.

## Controls

- Move: **WASD** or arrow keys; on touchscreens, use the lower-left joystick.
- Attack: **J** or the on-screen **ATTACK** button. Press near the end of a swing to queue the next combo hit; dodge or taking damage cancels it.
- Dodge: **K** / **Space** or the on-screen **DODGE** button.
- Camera: hold the right mouse button and drag, or drag on an open area of the screen.
- Target lock: **Tab** or **LOCK**.
- Spirit Burst: **L** or **BURST** when fully charged.
- Lantern: **E** or **LIGHT** when nearby and unlocked.
- Pause/resume: **Escape**; after defeat use **Retry hunt**.

See [Android setup](ANDROID_SETUP.md) for build prerequisites and device acceptance checks.

The hero now uses a Quaternius rigged base with idle, walk, sprint, sword attack, roll, hit, death, and Spirit Burst animations. The base body is temporary; Aru's costume and hair are not final. Enemies and environments still use generated shapes. See [asset credits](assets/characters/quaternius/README.md) for sources and licenses. Story, sound, visual polish, and Android export remain prototype work.
