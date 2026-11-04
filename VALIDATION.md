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
godot --headless --path . --script res://tests/hero_animation_check.gd
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

## Animated hero pass — 2026-11-03

Replaced the capsule hero with the CC0 Quaternius base and seven selected skeletal
clips. All 15 headless suites passed, including the new rig/track validity,
right-hand weapon attachment, locomotion/action priority, death state, and
visual-only movement check. Existing combat damage and movement checks still pass.

Rendered via a minimized native Windows OpenGL window and inspected static idle,
attack, sprint, and roll poses plus the chapter-zero gameplay view. Screenshots
are in ignored `.validation/hero_*.png` and `.validation/review_*.png`. These are
staged poses, not a continuous animation-quality or complete-hunt acceptance test.
The base is visibly unfinished (bare torso/shorts); final costume, transitions,
combo variety, weapon contact timing, and real Android performance remain pending.
No APK or physical-device test was performed in this pass.

## Sword windup and interruption — 2026-11-03

Sword damage now resolves after a 0.12-second light or 0.20-second heavy windup,
using overlap at contact time. Dodge, taking damage, death, and opening a menu
invalidate pending contact. Paused attack/dodge calls are ignored. The third hit
still deals double damage and successful contact still charges Spirit Burst.

All 15 headless suites passed. Combat coverage now verifies no early damage and
cancellation by dodge, damage, and menu transitions. Precise blade/contact-frame
alignment and continuous animation feel still require visual playtesting; these
initial windup values are gameplay tuning, not mesh-based sword collision.

## Analog locomotion and action transitions — 2026-11-03

The hero now walks below 3 m/s and sprints above that speed, with playback scaled
to horizontal movement. Idle starts at or below 0.2 m/s. Actions restore normal
playback speed before applying their duration, and preserve outgoing poses for
blending instead of stopping the animator. Repeated actions restart their clip.
Death also clears any lingering damage overlay.

The hero animation, combat, and three-chapter gameplay suites passed headlessly.
Coverage includes slow-walk playback and restoring normal action speed. Continuous
visual smoothness and physical-device behavior remain unverified for this pass.

## Combo input buffer — 2026-11-04

Attack presses during the final 0.18 seconds of recovery queue one next swing.
Earlier presses are ignored; repeated presses do not stack attacks. Dodge, damage,
death, and menus clear queued input. Paused input does not create a queue.

The new attack_buffer_check plus combat_check, gameplay_check, and pause_check
passed headlessly. Continuous touch feel and device behavior still require manual
playtesting. Run the new suite with the same isolated APPDATA and VEYRA_TEST=1
setup used above:

```powershell
godot --headless --path . --script res://tests/attack_buffer_check.gd
```

## Floating damage feedback — 2026-11-04

Enemy and boss damage now spawns a gold floating number for actual health lost,
including finishing hits. Numbers belong to the world rather than the victim,
pause with gameplay, fade over 0.65 seconds, and are limited to 24 active labels.
Zero/negative damage does not produce feedback or heal enemies.

The damage_feedback_check, combat_check, boss_phase_check, and spirit_check suites
passed headlessly. The new check covers values, victim removal, pause, expiry,
boss damage, scene cleanup, and the population limit. Desktop/phone readability
and overlapping-number appearance still require visual review.

```powershell
godot --headless --path . --script res://tests/damage_feedback_check.gd
```

## Damage feedback visual review — 2026-11-04

Rendered normal, lethal, boss, and eight simultaneous same-target hits at 1280x720
using a minimized native Windows OpenGL window (Intel Iris Xe), with isolated saves.
Initial numbers were too small and same-target labels overlapped. Increased their
world-space display size and spread simultaneous labels horizontally, then into
lower rows. Re-rendered and inspected the corrected normal and boss/crowd views;
the eight-hit view is readable and avoids the boss HUD at the staged camera angle.
The feedback lifecycle regression check passed after the size/spacing change.

Captures: ignored `.validation/feedback_normal.png`, `feedback_finisher.png`,
`feedback_boss.png`, and `feedback_crowd.png`. These staged screenshots do not
validate a full fight, all camera distances, phone aspect ratios, or device performance.

## Quest Journal — 2026-11-04

Q opens the active hunt journal; touch players can use Pause > Quest Journal.
It shows chapter instructions, remaining demons, lantern readiness/completion,
dragon activation and optional relic progress. Q/Escape returns to gameplay.
Opening it uses the existing menu pause/input cleanup; camp and ended hunts do
not open an active journal. No additional save state is introduced.

journal_check, pause_check and layout_check passed headlessly. The new check covers
keyboard and pause-menu access, objective states, queued-input cleanup and menu
exit guards. Journal text/layout has not yet had a native screenshot review.
Run with the isolated test profile described above:

```powershell
godot --headless --path . --script res://tests/journal_check.gd
```

## Quest Journal visual review — 2026-11-04

Rendered the initial chapter at 1280x720 and a staged final-chapter boss objective
at an 800x450 logical viewport in a minimized native OpenGL window. Inspected the
compact journal at both scroll ends: text wraps and lower content is reachable.
The original return button required scrolling on the smaller viewport, so moved
it immediately below the title. Re-rendered the compact view and verified the
return control is visible at the initial scroll position. journal_check passed
with an additional assertion for return-button order.

Screenshots live in ignored `.validation/journal_desktop.png`,
`journal_small_top.png`, and `journal_small_bottom.png`. This desktop simulation
does not replace touch scrolling or safe-area acceptance on a physical phone.

## Chapter skies and sunlight — 2026-11-04

Added procedural skies with coastal, cool grove, and sunset ruin palettes. Sunlight
colors vary by chapter and directional shadows are enabled within 45 metres.
The sea is now a 2000-metre plane to avoid the nearby square edge. HUD text has dark
outlines for contrast against bright skies. Removed the obsolete flat-background
campaign override.

Rendered and inspected all three chapters at 1280x720 with native OpenGL on Intel
Iris Xe, then re-rendered and inspected the shore HUD contrast correction.
Environment, camera and layout suites passed. Screenshots are ignored
`.validation/sky_chapter_0.png` through `sky_chapter_2.png`. Native desktop rendering
worked without reported errors; frame-rate and shadow cost on Android have not
been measured. This remains primitive prototype geometry with a static sea.

## Saved shadow setting — 2026-11-04

Settings now includes a Shadows toggle (default on). It updates directional lights
immediately, persists with Save and back, and reverts with Back without saving.
Missing or non-boolean saved values use the default. This gives players a manual
option to reduce shadow rendering cost; no automatic quality selection is used.

settings_check and layout_check passed, including shadow state on the actual
light, reload, discard, and invalid-value fallback. Rendered the settings menu
at an 800x450 logical viewport with native OpenGL and inspected the toggle.
Capture: ignored `.validation/shadows_settings.png`. Android performance gains
remain unmeasured; a toggle is not a substitute for physical-device profiling.

## Frame-rate limit — 2026-11-04

Settings offers 30 or 60 FPS (default 60), applied immediately through Engine.max_fps
and persisted with the existing settings. Back without saving restores the saved
limit. Missing, zero, non-integer, or unsupported limits use 60. Physics tick rate
is unchanged; the selected value is a cap, not a guaranteed measured frame rate.

settings_check and layout_check passed, including 30 FPS selection, save/reload,
discard to the saved cap, and invalid-limit fallback. The new dropdown has not
had native visual or physical-phone performance acceptance yet.

## Android debug export — 2026-11-04

Added the Android Debug preset with development package identity, ARM64-only
libraries, explicit landscape orientation, and ETC2/ASTC texture imports.
Installed the official Godot 4.7.2 Android APK templates after verifying the
complete downloaded archive against the release SHA512 checksum.

Godot headless import and debug export succeeded using Java 21 and Android SDK
build tools 36.0.0. `builds/android/veyra-debug.apk` is 49,496,107 bytes.
Android apksigner verification passed (v2 and v3). aapt confirmed package
`com.hirukshanan.veilofveyra.dev`, version `0.1.0-dev` / code 1, minimum SDK 24,
target SDK 36, and arm64-v8a only. Archive inspection found no bundled tests,
tools, or Markdown documents. Android prerequisite presence checks passed.
The landscape layout check passed at 800x450, 1280x720, and 1920x864.

`adb devices -l` reported no connected devices. Installation, startup, multitouch,
background/resume, saves, safe areas, and sustained performance on Android remain
unverified. This APK uses debug signing and the default icon, not release/store
configuration. Local build/import logs are in ignored `.validation/android/`.

## Device feedback and demon creatures — 2026-11-04

Owner-reported testing of the first Android debug APK on Samsung A37: gameplay
was smooth without noticeable lag, three levels were available, and progress
persisted after closing and reopening the app. Android version, measured frame
rate/temperature, and background/resume behavior were not supplied or verified.

Replaced capsule enemy visuals with original procedural animal meshes: Ember
Fox (ears, muzzle, bushy tail), Dusk Serpent (continuous coiled body, hood, fangs),
and Iron Tusk (quadruped boar, curved tusks). Dark fitted carapace, horns, spikes
and glowing eyes provide the demon theme. The existing SHORE/SCOUT/BRUTE enum
values remain internal behavior IDs, preserving chapter composition and stats.

Creature visuals animate diagonal quadruped gait, serpent neck sway, windup,
bite/lunge, recoil and tail movement. Dragon wings pivot at their shoulders and
body poses follow breath/charge/recovery states. Collision shapes, warning
geometry, damage and timing remain unchanged. The new visuals are procedural
stylized models, not externally sourced or skeletal-animation assets.

combat_pose_check, enemy_check, boss_phase_check, target_lock_check and
gameplay_check passed. Coverage includes species names and limb counts,
diagonal gait, serpent sway, interrupted strikes, pose reset, pause, collider
isolation, actual sword hits, all three chapter objectives and retry.
A close-up native OpenGL preview was inspected using a minimized window:
`.validation/combat_poses.png`. A tube-mesh winding issue was corrected during
inspection. Continuous motion quality and added mesh cost need phone testing.

Latest debug APK: 0.1.3-dev (code 4). Earlier phone acceptance does not cover
these new models/animations. No staging or commits were performed.
## Licensed skeletal wolf integration — 2026-11-05

Beast Quest mobile wolf screenshots informed the natural anatomy/textured-art
direction only. Selected Dire Wolf Lite 1.0.0 from Literock Studios:
https://literock-studios.itch.io/direwolf-lite
Creator documentation and bundled license permit commercial packaged game use
but prohibit standalone redistribution. The GLB is gitignored, installed locally,
and included only in the packaged game. Setup and AI-assisted provenance are in
assets/characters/literock/README.md. No Beast Quest assets were extracted.

All three enemy roles now use size/tint variants of this ONE textured model;
they are not three independently modeled species. Previous animal geometry is
only a warned fallback for source checkouts without the licensed dependency.
Idle/walk/run use the imported skeleton; bite pose sampling follows the existing
windup/contact/recovery clock. Imported +Z facing is rotated to gameplay -Z.
The 0.65-second bite contact sample is an initial mapping needing playtest tuning.

combat_pose_check, enemy_check, target_lock_check and gameplay_check passed,
including required imported asset presence, animation transitions/sampling,
interruption, pause, sword contact, chapter progression and retry. Staged native
OpenGL model preview inspected. This is approximately 10k triangles per enemy
with 2K textures; phone performance and continuous-motion acceptance are pending.
Latest debug build: 0.1.4-dev (code 5). Earlier phone feedback does not cover it.

## Wolf impact and defeat feedback — 2026-11-05

Imported wolf materials now receive a short warm emission flash from the existing
hurt timer. Normal texturing returns when it expires. Defeat detaches only the
visual, pauses its skeleton, rolls it onto its side over 0.24 seconds, holds for
0.15 seconds, then fades over 0.45 seconds. This is procedural fall/fade feedback,
not a new skeletal death clip. Alpha depth prepass fixes overlapping transparent
surfaces seen during native preview. Enemy defeat signals/collider removal remain
immediate; visuals cannot take hits or be locked. At most eight remains persist,
respect pause, and are freed with the world or on effect expiry.

wolf_feedback_check, enemy_check, target_lock_check and gameplay_check passed.
The dedicated test covers flash reset, single defeat, immediate enemy removal,
non-colliding remains, pause, expiry, the limit and world cleanup. Native OpenGL
hit/fall poses were inspected in `.validation/wolf_feedback.png`; phone visual
quality/performance is pending. Debug APK version: 0.1.5-dev (code 6).

## Mobile safe-area layout — 2026-11-05

HUD, campaign actions and menu contents now share a safe-area Control script.
On mobile it converts DisplayServer.get_display_safe_area() through the inverse
viewport screen transform into logical canvas coordinates, intersects the viewport,
and falls back to full bounds for missing/outside rectangles. Desktop keeps the
full viewport. Resize and a paused-safe 0.5-second timer refresh the layout;
background shade and 3D rendering still cover the entire display. Compact hints
reserve the HEAL column and mobile shows a touch-camera instruction.
API reference: https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area

layout_check, safe_area_check, pause_check and settings_check passed. Tests cover
800x450, 1280x720, 1920x864, asymmetric simulated cutout/gesture margins, scaled
and translated pixel conversion, invalid-rectangle fallback, action separation,
scroll reachability, pause and settings. settings_check emitted a two-object
shutdown leak warning; it did not fail assertions, and the cause is not established.
Native minimized OpenGL HUD/settings previews at 800x450 were inspected:
`.validation/safe_area_hud.png` and `.validation/safe_area_menu.png`. Fixed a hint
text overlap found during that pass. These simulated margins do not establish
real Android cutout, gesture navigation or multitouch acceptance.
Debug APK: 0.1.6-dev (code 7).

## First explorable island layout — 2026-11-05

Expanded the terrain from a 16 m radius arena to a 38 m radius flat interior
with a sloped sandy perimeter reaching 48 m below water. The native mesh collider
matches the slope; this remains a circular first-layout terrain, not a finished
organic coastline. Added a beach arrival, branching trail, forest scenery and
northern ruins, using existing lightweight procedural scenery. All chapters
share this layout with their existing palettes and progression.

Existing enemy totals are distributed among three camps. Detection starts within
11 m; wolves disengage beyond 24 m from the target or 20 m from their camp and
return home. Relics are spread across the route. The northern lantern still
requires all enemies defeated; its dragon spawns at the ruins. Three waystones
bind a rescue position for the current hunt. Entering deep water returns the
player there with a 20-vitality damage attempt under existing invulnerability
rules. Waystones do not persist across app restart or defeat/retry, and do not
save partially cleared camps. Swimming and persistent checkpoints remain future work.

Passed exploration_check, gameplay_check, environment_check, enemy_check,
relic_check, target_lock_check and campaign_smoke. Updated the old relic radius
assertion and explicitly reset boss state in the isolated breath test, since the
new nearby spawn can already have entered windup. Exploration checks raycast
camp/waystone ground and the beach slope, validate rescue/penalty and local aggro.
Two shutdown ObjectDB instances were reported by exploration_check; assertions
passed, but leak origin remains unconfirmed.

Native minimized OpenGL overview and trail previews were inspected:
`.validation/island_overview.png`, `.validation/island_trail.png` (paused staging).
This is an initial playable map layout: terrain art, navigation balance, long
manual traversal and phone performance still need review. Debug version 0.2.0-dev
(code 8). Earlier Samsung A37 feedback does not validate the larger map.
