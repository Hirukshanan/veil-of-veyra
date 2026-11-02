# Gameplay validation — 2026-11-02

Environment: Godot 4.7.2 on Windows. Headless physics checks and OpenGL rendering on Intel Iris Xe. Test saves isolated under `.validation`; player saves were not used.

## Passed

- Settings sliders, camera scaling, save/reload, discard, mute/unmute, sound stream creation, and invalid setting fallback/clamping.
- Enemy attack warnings, escaping attack range, delayed damage, and sword-hit interruption.
- Three-hit sword combo with double-damage finisher and timeout reset.
- Camp startup, resume, pause, healing limits, purchase cost, upgrade application, save reload.
- All three chapters: enemy count, safe spawn distance, actual sword Area3D overlap damage.
- Dodge invulnerability and camera orientation independent of player rotation.
- Actual wave defeat signals spawn the dragon with chapter-scaled health.
- Dragon windup/breath transition and damage to a player in its attack cone.
- Boss defeat signals advance chapters, grant rewards, and reach the final ending.
- Player death and actual scene reload restore health and potions.
- Rendered 1280×720 camp and gameplay screenshots inspected for readable text and visible controls.

The rendered gameplay inspection showed enemies starting too close to the player in later chapters. Spawns now use a wider ring, with a regression assertion requiring at least five units of separation.

## Limits

These checks do not establish Android device performance, multitouch reliability, all display aspect ratios, long-session stability, or enjoyable difficulty. Combat checks use scripted positioning and damage to exercise transitions; they are not a complete human playthrough. Art and animations remain placeholders.

## Reproduce

Set `APPDATA` to an isolated temporary directory and `VEYRA_TEST=1`. Run Godot from the project root:

```text
godot --headless --path . --script res://tests/gameplay_check.gd
godot --headless --path . --script res://tests/campaign_smoke.gd
godot --headless --path . --script res://tests/combat_check.gd
godot --headless --path . --script res://tests/settings_check.gd
```

The tests replace campaign saves in that isolated directory. Never point test APPDATA at your regular user profile.

Audio checks validate stream creation and volume routing, not perceived sound quality. Cues are synthesized placeholders. Combat checks allow audio playback to finish before exiting so the audio server can release its playback resources.
