# Gameplay validation — 2026-11-03

Environment: Godot 4.7.2 on Windows. Headless physics checks and OpenGL rendering on Intel Iris Xe. Test saves isolated under `.validation`; player saves were not used.

## Passed

- Spirit Burst: misses grant no charge; crowd hits grant once per swing; charge caps at 100; pause cancels pending requests; keyboard/button activation, actual area damage, normal-enemy interruption, no self-hit, out-of-range/resource/death guards, empty-cast cost, and restart reset.
- Chapter environments: correct theme/palette on load, all scenery mesh bounds inside the island, clear inner arena, camera-only trunk/pillar collision via physics raycasts, and grounded lantern/relic positions.
- Target lock: keyboard/button activation, nearest living enemy selection, facing/camera movement, actual locked sword overlap damage, explicit/manual camera/range/freed-target/menu/death release, empty selection, and boss selection.
- Dragon phase thresholds across chapter-scaled health, one-time transition, no phase announcement on lethal damage, preserved active windup/recovery, faster future charge/recovery, attack labels, single-hit damage, and Enraged HUD wiring.
- Enemy types: chapter composition, health modifiers, pursuit speed, warning radius/timing, damage, escape, interruptibility, health labels, hit-flash recovery, and single defeat signal across Shore/Scout/Brute.
- Campaign save promotion, previous snapshot rotation, invalid/missing primary recovery, simulated interruption between renames, blocked temporary-file write, invalid type/range rejection, and protection against overwriting two unreadable snapshots.
- Logical landscape layouts at 800×450, 1280×720, and 1920×864: joystick/action controls remain inside the viewport, action buttons do not overlap the joystick, and the last camp/request/settings button remains reachable by scrolling.
- Camera: owner excluded from collision, wall retraction, unobstructed extension, distance adjustment, terrain collision, saved distance reload and invalid-distance clamping.
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

Spirit Burst is tested through physics overlap queries and input events. Its pulse visual, touch-button readability and combat balance are not visually verified. It uses a spherical 3-metre physics query against enemy colliders and does not test line of sight through future walls; the current arena has no gameplay-blocking walls.

Chapter scenery is a procedural placeholder environment pass on the same circular arena, not three distinct exploration maps. Appearance/composition and frame rate have not been visually or physically tested. Trunks/pillars block cameras only; characters can pass through perimeter scenery until navigation-aware physical obstacles are implemented.

Target lock is nearest-by-distance, including targets behind the player; it does not filter by screen visibility or line of sight. Rotation/framing feel and the new touch button/3D marker require visual and phone testing. Menus deliberately clear the lock.

The Enraged phase uses 0.65-second windups and 0.6-second recovery for attacks started after the transition (normal: 0.85 and 0.8). Charge speed increases from 9 to 11; damage is unchanged. Headless state tests pass, but visual legibility, warning coverage, and player difficulty remain unverified.

Enemy variants use placeholder capsule silhouettes. Automated checks verify their combat rules, not enjoyable difficulty, readable labels during crowds, or visual quality. Scout base damage is 5 with a 0.4-second warning; Brute damage is 16 with a 0.95-second warning. Actual balance playtesting remains pending.

Save recovery tests simulate filesystem states and write failure; they do not prove power-loss durability or Android storage behavior. Backup recovery may lose the latest checkpoint. Settings still use their separate simple save file.

Layout checks use headless Control rectangles with window content scaling disabled to exercise different logical viewport sizes. They are not screenshot inspection or physical-device verification. Portrait, display cutouts/safe areas, readable physical touch sizes, text overlap, and simultaneous touch input remain unverified.

The lantern objective update was checked headlessly only, without opening or focusing a game window. Its visual layout and on-device touch interaction remain pending.

The Keeper relic update was also checked headlessly only. Pickup visuals, the additional camp button, and the relic HUD still require visual/device review. Relics are optional and reset with each hunt; only victory rewards are persisted.

Camera collision and distance settings were verified with headless physics, not visual rendering. Camera framing, rapid movement near corners, and the expanded settings layout still need visual/device review. Tree trunks use camera-only blockers; foliage and other decorative meshes without collision shapes do not block the camera. The implementation uses Godot's native [SpringArm3D](https://docs.godotengine.org/en/4.0/classes/class_springarm3d.html).

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
godot --headless --path . --script res://tests/camera_check.gd
godot --headless --path . --script res://tests/layout_check.gd
godot --headless --path . --script res://tests/save_check.gd
godot --headless --path . --script res://tests/enemy_check.gd
godot --headless --path . --script res://tests/boss_phase_check.gd
godot --headless --path . --script res://tests/target_lock_check.gd
godot --headless --path . --script res://tests/environment_check.gd
godot --headless --path . --script res://tests/spirit_check.gd
```

The tests replace campaign saves in that isolated directory. Never point test APPDATA at your regular user profile.

Audio checks validate stream creation and volume routing, not perceived sound quality. Cues are synthesized placeholders. Combat checks allow audio playback to finish before exiting so the audio server can release its playback resources.

## Live desktop inspection — 2026-11-03

Used the native Windows game window with a separate `.validation/manual` save directory. Directly observed camp/start, enemy approach and warning discs, player damage flashes, death, Escape pause/resume, and retry returning to camp with restored health. Updated the camera hint to specify right-mouse drag on desktop.

The game previously continued combat after losing application focus. Focus loss and application suspension now open the pause menu, and focus return does not automatically resume. Pausing also clears joystick finger ownership and movement to avoid stale touch input after returning. These cases have automated regression coverage; Android lifecycle behavior still needs a device test.

Live input/capture latency prevented a reliable continuous combat playthrough. Full dragon-fight difficulty, sustained movement/camera feel, healing during real-time combat, and touch multitasking remain unverified manually. The limited desktop inspection must not be treated as completed gameplay acceptance testing.

## Latest desktop render review — 2026-11-03

Rendered and inspected six 1280×720 screenshots on Windows / Intel Iris Xe OpenGL: camp, settings, all three chapter environments, and a staged Enraged dragon with Spirit Burst. This review supersedes earlier blanket statements that these features had no visual inspection, but only for these desktop views.

Fixed a relic label becoming oversized near the camera, moved the final lantern away from the initial player view, and made menu backgrounds opaque. Re-rendered and inspected the corrected views. Gameplay, relic, environment, and layout regression checks passed after the edits. Screenshots are in ignored `.validation/review_*.png`.

Remaining: distant 3D labels are small, art is primitive, camp requires scrolling, full combat readability/motion and continuous manual playthrough remain unverified. The capture script stages positions and effects; it is not a completed hunt. Android adb was absent from PATH and the default SDK location, and no export preset was found. No physical-device or emulator test was performed.
