# Gameplay validation — 2026-11-03

Environment: Godot 4.7.2 on Windows. Headless physics checks and OpenGL rendering on Intel Iris Xe. Test saves isolated under `.validation`; player saves were not used.

## Passed

- Keeper relics: reachable placement in all chapters, proximity collection, camp/pause guards, single pickup counting, partial versus full victory rewards, no duplicate reward, persisted currency, and collection reset on reload.
- Escape pause/resume through viewport input, focus/background auto-pause, frozen player state during pause, joystick reset, and settings/camp menu guards.
- Settings sliders, camera scaling, save/reload, discard, mute/unmute, sound stream creation, and invalid setting fallback/clamping.
- Enemy attack warnings, escaping attack range, delayed damage, and sword-hit interruption.
- Three-hit sword combo with double-damage finisher and timeout reset.
- Camp startup, resume, pause, healing limits, purchase cost, upgrade application, save reload.
- All three chapters: enemy count, safe spawn distance, actual sword Area3D overlap damage.
- Dodge invulnerability and camera orientation independent of player rotation.
- Wave defeat unlocks the chapter lantern. Nearby E/button interaction lights it and spawns one dragon with chapter-scaled health.
- Lantern interaction rejects uncleared enemies, distant players, paused gameplay, and repeated activation; retry resets the objective.
- Dragon windup/breath transition and damage to a player in its attack cone.
- Boss defeat signals advance chapters, grant rewards, and reach the final ending.
- Player death and actual scene reload restore health and potions.
- Rendered 1280×720 camp and gameplay screenshots inspected for readable text and visible controls.

The rendered gameplay inspection showed enemies starting too close to the player in later chapters. Spawns now use a wider ring, with a regression assertion requiring at least five units of separation.

## Limits

The lantern objective update was checked headlessly only, without opening or focusing a game window. Its visual layout and on-device touch interaction remain pending.

The Keeper relic update was also checked headlessly only. Pickup visuals, the additional camp button, and the relic HUD still require visual/device review. Relics are optional and reset with each hunt; only victory rewards are persisted.

These checks do not establish Android device performance, multitouch reliability, all display aspect ratios, long-session stability, or enjoyable difficulty. Combat checks use scripted positioning and damage to exercise transitions; they are not a complete human playthrough. Art and animations remain placeholders.

## Reproduce

Set `APPDATA` to an isolated temporary directory and `VEYRA_TEST=1`. Run Godot from the project root:

```text
godot --headless --path . --script res://tests/gameplay_check.gd
godot --headless --path . --script res://tests/campaign_smoke.gd
godot --headless --path . --script res://tests/combat_check.gd
godot --headless --path . --script res://tests/settings_check.gd
godot --headless --path . --script res://tests/pause_check.gd
godot --headless --path . --script res://tests/relic_check.gd
```

The tests replace campaign saves in that isolated directory. Never point test APPDATA at your regular user profile.

Audio checks validate stream creation and volume routing, not perceived sound quality. Cues are synthesized placeholders. Combat checks allow audio playback to finish before exiting so the audio server can release its playback resources.

## Live desktop inspection — 2026-11-03

Used the native Windows game window with a separate `.validation/manual` save directory. Directly observed camp/start, enemy approach and warning discs, player damage flashes, death, Escape pause/resume, and retry returning to camp with restored health. Updated the camera hint to specify right-mouse drag on desktop.

The game previously continued combat after losing application focus. Focus loss and application suspension now open the pause menu, and focus return does not automatically resume. Pausing also clears joystick finger ownership and movement to avoid stale touch input after returning. These cases have automated regression coverage; Android lifecycle behavior still needs a device test.

Live input/capture latency prevented a reliable continuous combat playthrough. Full dragon-fight difficulty, sustained movement/camera feel, healing during real-time combat, and touch multitasking remain unverified manually. The limited desktop inspection must not be treated as completed gameplay acceptance testing.
