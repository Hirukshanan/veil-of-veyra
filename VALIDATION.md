# Gameplay validation — 2026-11-03

Latest HUD cleanup verification is recorded separately in `docs/CH1_HUD_CLEANUP_REPORT.md`. It covers the gameplay-only button allowlist, tap/hold target lock, hold/release/drag/menu cancellation, legacy-profile migration and the retained editor. Earlier runs below retain their original scope.

## Phase 2 HUD redesign — 2026-11-14

19/19 targeted checks pass without diagnostics in this selected run. Native Windows Godot 4.7.2 GL Compatibility editor regression and eight-screenshot capture pass with empty stderr. Coverage includes separate layers, Settings > Controls navigation, touch drag/corner resize, scale/opacity/presets, save/cancel/reset, corrupt/failed-write recovery, safe layouts, guard/parry and retained combat/quest/camera/saves. Both cached 3D HUD viewports are asserted disabled after startup. Unique isolated APPDATA protects personal progress. Details/screenshots/metrics: `docs/CH1_HUD_REDESIGN_REPORT.md`. Phone acceptance and a new APK remain pending; Phase 3 awaits screenshot approval.

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

## Island objective guidance — 2026-11-05

HUD now shows camera-relative direction and horizontal distance to the nearest
living wolf, then the lantern, then the dragon. It does not change target lock.
The journal explains these directions and names the bound water-rescue waystone.
Compact status text uses a 20px font. Camp return now faces home and preserves
vertical gravity instead of overwriting velocity each frame.

navigation_check, exploration_check, journal_check and safe_area_check passed.
Checks cover rotated-camera bearings, vertical distance exclusion, objective
progression, bound waypoint text and compact cutout layouts. The existing two
ObjectDB shutdown warning in exploration_check remains unresolved. Device
navigation readability/traversal still needs playtesting. Debug 0.2.1-dev (code 9).

## Island map screen — 2026-11-05

Pause menu now opens an Island Map: a north-up schematic with a player/facing
arrow, three camp statuses, numbered waystones and the current bound point.
Lantern/dragon status and explicit cleared/remaining text appear in the legend.
Camp state uses living enemies' home locations, so chasing wolves do not move
camp markers. This is a paused snapshot, not fast travel or a live minimap.
Return to hunt stays above the map; legend/pause navigation remains scrollable.
Height adapts so the full diagram fits the tested compact menu.

island_map_check, pause_check and layout_check passed. Native minimized OpenGL
preview at 800x450 with simulated cutouts was inspected; reduced diagram height
and adjusted label spacing. Actual phone readability/touch testing is pending.
Debug APK: 0.2.2-dev (code 10).

## Sprint and stamina — 2026-11-05

Shift or the SPRINT touch button toggles sprint (8.3 m/s versus 5.2 m/s).
Stamina is session-only, capped at 100, drains 25/s while moving in sprint and
recovers 18/s otherwise; starting requires 20. Exhaustion disables sprint.
Accepted sword attacks, dodge, hit cancellation, Spirit Burst and menus stop
sprint. Paused gameplay does not regenerate stamina. The button shows remaining
percentage and can stop active sprint even below the start threshold. Existing
analog movement and dodge speed remain unchanged. Boss HUD width is reduced to
reserve space above the joystick for the new 140x48 control.

sprint_check, safe_area_check and combat_check passed. Native OpenGL compact
HUD preview inspected. Phone multitouch and movement/balance acceptance remain
pending. Debug APK: 0.2.3-dev (code 11).

## Wolf patrols and alerts — 2026-11-05

Unalerted wolves follow four short patrol points 2.5 m from home, at 55% of
pursuit speed, with staggered starts and 1.5-second pauses. Detection shows a
one-second yellow exclamation mark. Existing detection/attack values remain.
A leashed wolf returns home before it can reacquire the player, preventing
repeated alert/return switching at the boundary. Patrols are direct movement,
not pathfinding; existing scenery remains camera-only collision.

patrol_check, enemy_check, exploration_check and gameplay_check passed. Covered
bounded goals, slower movement, alert expiry, return-state hysteresis, home reset
and pause. Exploration's existing two-object shutdown warning remains. A staged
native OpenGL alert/walking preview was inspected in `.validation/patrol_alert.png`.
Long-session patrol behavior and phone performance remain unverified.
Debug APK: 0.2.4-dev (code 12).

## Environment realism and faster pursuit — 2026-11-05

Added CC0 Poly Haven 1K sand, grass, forest-floor and rock texture sets, world
triplanar normal/roughness materials, scanned island trees and ferns, textured
ruins and procedural shoreline boulders. Ground imports enable mipmaps, VRAM
compression and anisotropic filtering. Original coastal shader adds subtle moving
water detail and shallow/deep colors. Reduced ambient fill for more directional
lighting. Terrain remains the circular layout with flat inland geometry; roads
and foliage silhouettes still need art refinement.

Reduced tree scene: 16,794 triangles; fern cluster: 6,232. Additional trail trees
reduced from 28 to 20. Tree/fern visibility distances are 55/28 m. Source glTF and
BIN files are excluded from export; dependency inspection confirmed generated
SCNs reference only texture files. Provenance and regeneration instructions are
in assets/environment/README.md. These assets may be committed under CC0.

Pursuit: Ember Wolf 4.4, Ash Stalker 5.8, Dire Warg 3.8 m/s. Patrol rates remain
1.18/1.7/0.8 m/s. Attack windups/damage unchanged. enemy_check validates the new
speeds and existing warning/escape behavior. environment_check, patrol_check,
exploration_check and gameplay_check also passed. Native minimized OpenGL trail
and overview renders inspected; iterated texture filtering, foliage reduction
and water glare. This larger visual workload still needs Samsung A37 frame-rate,
heat and battery acceptance; earlier smoothness reports do not cover this build.
Debug version: 0.3.0-dev (code 13).

## Curved island terrain pass
- Replaced circular cylinder ground with an irregular 128-segment coastline and matching sloped-beach collision. Combat plateau remains level.
- Replaced rectangular paths with sampled curves; the pause map uses the same paths and coastline.
- Passed exploration (including rays around 32 shoreline points and every trail sample), environment, island map, and gameplay checks.
- Inspected native OpenGL overview and ground-level captures. Ground still has sharp material boundaries; this is not a finished photorealistic terrain pass.
- Samsung A37 performance and playtesting remain pending.
- Exploration assertions passed; the previously observed two ObjectDB instances warning recurred at process shutdown. Its cause remains unresolved.

## Android terrain build: 0.3.1-dev (code 14)
- Exported ARM64 Android Debug APK successfully; signature verified with apksigner.
- Manifest confirms com.hirukshanan.veilofveyra.dev, version 0.3.1-dev, code 14.
- APK size: 82,170,475 bytes. New island terrain script is packaged; original heavy tree/fern glTF and BIN files remain excluded.
- Physical device installation, performance, and gameplay acceptance remain pending. This export does not resolve the previously documented test shutdown warning.

## Blended terrain and shoreline (2026-11-06)
- terrain_material_check passed: continuous path coverage, feathered borders, no beach spill, cached mask reuse, and textures for all chapter palettes. Desktop mask/material check took 36 ms (not a phone performance measurement).
- environment_check, exploration_check, island_map_check, and gameplay_check passed.
- Native OpenGL captures inspected at overview, hero-height trail, and beach views. Material boundaries blend without overlapping path meshes; wet sand and coastal foam follow the irregular shore.
- Exploration still reports the previously documented two ObjectDB instances at shutdown; assertions pass, cause unresolved.
- Terrain is still a flat combat plateau with sloped beaches. This pass does not add elevation, swimming, or new chapters.
- Shader rendering verified on desktop Intel Iris Xe; Samsung A37 visual/performance acceptance pending.
- Android 0.4.0-dev (code 15) export and signature verification passed; ARM64 APK size 82174665 bytes. New terrain shader packaged; heavy source models excluded.

## Keeper quest (2026-11-06)
- keeper_check passed in all three chapters: proximity, touch dialogue, paused combat/input reset, acceptance, home-camp tracking, blocked premature/double reports, once-only victory payment, saved shards and fresh-hunt reset.
- gameplay_check, relic_check, journal_check, layout_check, safe_area_check and island_map_check passed.
- Captured and inspected Keeper world view, dialogue and HUD at 800x450 with simulated safe-area insets. Fixed a controls-hint overlap by putting those instructions in the journal. Accept is visible; further dialogue choices remain scrollable.
- Keeper uses the existing hero rig and idle clip with a blue spirit material. No new external art dependency.
- Physical-device interaction, visual quality and performance remain pending.
- Android 0.5.0-dev (code 16), ARM64 debug APK exported and signature verified. Size: 82178920 bytes.

## Heavy attack (2026-11-07)
- heavy_attack_check passed: touch activation, cost/low-stamina/repeat/death guards, delayed 4x damage, front-only range/height filtering, enemy stagger, spirit gain, no recovery while committed, dodge/hit/menu cancellation, and pause-aware damage timing.
- combat_check, sprint_check, attack_buffer_check, spirit_check, enemy_check, gameplay_check, layout_check and safe_area_check passed.
- Inspected staged native OpenGL charge-arc and 800x450 safe-area HUD captures; new heavy button fits above existing combat controls.
- Sprint check reported four ObjectDB instances at shutdown. Assertions passed; shutdown resource warnings remain unresolved and are not presented as a clean leak check.
- Physical-device touch combat, balance, thermal behavior and performance are pending.
- Android 0.6.0-dev (code 17), ARM64 debug APK export and signature verification passed. Size: 82183016 bytes.

## Mountains and demon presence (2026-11-07)
- mountain_demons_check passed: seven physical peaks plus six ridges, camera collision, every trail sample stays level/unobstructed, enlarged wolf scales/capsules, snarl-to-idle transitions, and growl resource/distance bounds.
- environment_check and exploration_check passed after refining mountain geometry. Objectives/relics and camp/waystone ground remain accessible. The base beach slope is tested separately beneath mountain feet; exposed southern beach remains checked.
- enemy_check, combat_pose_check, wolf_feedback_check, heavy_attack_check and gameplay_check passed with enlarged demons.
- Native OpenGL island overview/trail views and staged three-demon comparison inspected. Initial conical silhouettes were revised into multi-peak rock formations and connected by lower ridges.
- Growl is an original synthesized cue; auditory quality and device volume balance have not been listening-tested.
- Intermittent ObjectDB shutdown warnings (2-4 instances) remain unresolved. Assertions passed.
- Samsung A37 performance, combat feel and navigation around cliff feet remain pending.
- Android 0.7.0-dev (code 18), ARM64 debug APK export and signature verification passed. Size: 82191461 bytes.

## Waystone fast travel (2026-11-08)
- fast_travel_check passed: discovery, invalid/locked destinations, current location, nearby enemies at both ends, combat cooldown, active boss, touch button travel, rescue binding, no resource refill and fresh-hunt reset.
- island_map_check, exploration_check and gameplay_check passed.
- Native OpenGL map/scroll captures at 800x450 with safe-area insets inspected; destination buttons are reachable by scrolling and include blocked reasons.
- Existing exploration shutdown warning recurred (four ObjectDB instances); assertions passed, cause unresolved.
- Physical-device travel controls and performance remain pending.
- Android 0.8.0-dev (code 19), ARM64 debug export and APK signature verification passed; size 82191461 bytes.

## Quest scroll and round HUD (2026-11-08)
- Updated keeper_check passed: accept and complete remotely through the scroll, blocked premature/double completion, chapter victory payment, persistence and hunt reset.
- journal_check, layout_check, safe_area_check, sprint_check and gameplay_check passed.
- quest_hud_check passed at 800x450, 1280x720 and 1920x864: equal width/height, circular hit testing, non-overlapping controls, sprint on right, scroll access and blocked incomplete quest.
- Native OpenGL HUD and quest menu inspected at 800x450 with simulated display insets. Long menus scroll; accept/complete appears ahead of objective details.
- Increased campaign demon health still needs player balance feedback. Physical-device touch comfort remains pending.
- Larger world, continuous progression, herbs and new water boundaries are deferred to separate stages.
- Android 0.9.0-dev (code 20), ARM64 export and APK signature verification passed; size 82195925 bytes. Device testing remains pending.

## NPC removal and demon health (2026-11-08)
- keeper_check verifies a non-spatial quest with no visual children and passing accept/complete/reward/reset behavior.
- gameplay_check verifies every campaign enemy's health and initial visible health label in all three hunts. enemy_check, island_map_check and quest_hud_check passed.
- Native spawn/HUD capture inspected: NPC, ring and label removed; quest scroll retained.
- Stronger demon health needs device combat-balance feedback.
- Android 0.9.1-dev (code 21) ARM64 export and signature verification passed. Physical-device acceptance pending.


## Charcoal dragon integration (2026-11-08)

- Original 2K GLB inspected: 1,000,038 triangles, no skeleton or animation.
- Offline Blender preparation: welded primitive seams, baked orientation, consolidated identical UV maps, reduced to 34,999 triangles (about 5.9 MiB), added 21 bones and eight motion clips. Original texture colors and ivory horns retained.
- Native Godot renders reviewed for idle, breath and death; full island encounter captured with the normal player camera and side camera. No UV compatibility warning after preparation.
- Passed dragon_check, boss_phase_check, combat_pose_check, gameplay_check and target_lock_check. Coverage includes mesh budget, skinning, finite poses, head motion, warning synchronization, pause, death cleanup, existing damage/rewards and target lock.
- Animations use small anatomical-envelope motions for the source flying pose; this is a hovering boss, not a ground-walking dragon. No free-flight navigation or new bite damage attack was added.
- Physical Android performance, thermal behavior and touch combat playtesting remain pending.

- Follow-up motion audit: five samples per clip revealed restrained wing travel; this remains a prototype hover animation rather than a polished flight cycle. Added a 100 ms bone-pose transition blend to avoid abrupt clip changes. Do not treat the current APK as final animation-quality approval.

## Dragon motion and fire correction

- Added visible shoulder-axis wingbeats, delayed wing-tip follow-through and hover bob, retaining the 100 ms pose transition blend.
- Replaced the static cone with a bounded 48-instance additive flame stream following the animated head muzzle. Existing damage range/timing remains unchanged.
- Reviewed runtime motion phase captures and the island breath render. Regression checks cover wing rotation amplitude, muzzle attachment, fire clock, pause and existing combat. Physical phone feel/performance remain unverified.

## Procedural pose drift fix

- Reproduced right-foot translation drift after 12 frames of grounded movement. Constant channels omitted from GLB retained procedural offsets from the previous frame.
- Reset skeleton bone poses before every animation sample, then apply current-frame offsets.
- 1,200-frame walking regression now passes with bounded per-bone translations; no APK generated for this change.

## Island expansion first pass

- Ground radius 38 to 76, outer beach 48 to 96; shoreline shading and map scale updated. Existing landmarks/objectives remain in the original central area.
- Added chunked, distance-culled grass; trees/columns now block player layer 8 and camera layer 4. Rocks have convex colliders matching their transforms. Enemy collision masks are unchanged.
- prop_collision_check and gameplay_check passed. Expanded outer-area content and single-world save/progression migration are still pending. No APK exported.


## Persistent island conversion (2026-11-09)

- Removed runtime chapter advancement and three-hunt reload loop. Added six fixed-ID demons across existing camps; one lantern/dragon quest with continued exploration after victory.
- Save version 2 stores cleared IDs, herb/relic IDs, bounty state, reward claims, discovered waystones, bound checkpoint, position, health and potion stock, plus economy/completion. Legacy chapter saves migrate currency/upgrades/final victory; old in-hunt state was never present and cannot be recovered.
- Save boundaries: quest actions, menus, five-second exploration interval and normal exit/focus pause. Forced termination can lose recent movement. Living enemy/boss health and session spirit/stamina are not persisted. Death restores health at the bound waystone without resetting objectives or potion stock.
- Save format validates bounded unique IDs, types, finite map positions, resource ranges, discovery/checkpoint consistency and completion/reward prerequisites. Existing temporary/backup promotion retained. Reset is committed before replacing in-memory state.
- End-to-end persistent_world_check covers autosave, scene reopen, item/camp persistence, death, lantern/boss restoration, post-victory exploration and one-time optional rewards. save_check covers legacy migration, malformed state, backups, failed/interrupted writes, unreadable-save protection, victory retry and failed reset.
- Existing gameplay/optional-quest tests migrated to the single-world behavior. No APK exported for this update.

- Final targeted checks passed: persistent_world_check, save_check, gameplay_check, campaign_smoke, keeper_check, relic_check, environment_check, journal_check, herbal_check, fast_travel_check, quest_hud_check, navigation_check, pause_check, settings_check, prop_collision_check and island_map_check. Each used isolated APPDATA. Native 960x540 camp, quest scroll and victory captures reviewed; Continue exploring is available after victory. APK remains the earlier build.

## Dire Warg encounter adjustment (2026-11-09)

- Removed the second Dire Warg (CampDemon5) from the ruins. One Dire Warg remains, alongside two Ember Wolves and two Ash Stalkers.
- Retired ID 5 is marked cleared on world load, keeping existing version-2 saves and the lantern unlock condition compatible. Persistent-world regression verifies five active demons, one brute, reopen persistence and lantern/dragon progression. No APK exported.

## Moonleaf Grove (2026-11-09)

- Added a south-east grove at (44, 0, 28), with a clear western entrance, trees/ferns, colliding rocks, five new stable-ID herbs and a map leaf marker. A branching trail from Beach waystone stays clear of existing props and mountains.
- Gathering three grove herbs automatically awards 25 shards once. Ordinary herbs do not count; all flowers add one potion each. Grove progress and reward state persist through reload.
- Save format version 3 migrates existing v1/v2 records without changing old pickup IDs; potion limit accommodates all 13 finite pickups. Future formats and malformed current records remain protected.
- grove_check covers v2 migration, route/plant physics accessibility, partial progress across reopen, exact third-flower payout, no repeat payout, reward-flag consistency and potion capacity. Native grove arrival/overview renders reviewed. No APK exported. Physical device performance is pending.

## Camp redesign and launcher icon (2026-11-09)

- Approved generated dragon/lantern artwork saved in assets/ui/brand; prepared 512px main and 432px adaptive foreground/background PNGs, configured in project.godot and Android export preset. No APK exported. Actual Android launcher mask/caching behavior requires installation of the next APK.
- Camp scroll list replaced with an adaptive two-column composition: title, equipment/currency cards, primary Continue action, two upgrades and quest/guide/settings/reset/quit navigation. Detailed guides remain accessible through Field guide; New journey retains confirmation. Quest parchment and other menu flows remain functional.
- Native renders reviewed at 800x450, 1280x720 and 1920x864. Initial stat-card overlap corrected before final capture.
- camp_menu_check covers safe-area bounds, nonoverlapping touch targets, disabled/working upgrade actions, menu navigation, reset confirmation, play/pause and configured image dimensions. Existing layout_check understands the dedicated camp view.

- Final checks passed: camp_menu_check, layout_check, settings_check, pause_check, campaign_smoke, save_check, persistent_world_check, journal_check and safe_area_check. Native captures at all three landscape sizes reviewed after spacing correction. Existing Android APK was left unchanged; launcher appearance on the phone awaits the next build/install.

## Android debug build 0.11.0-dev (2026-11-10)

- Exported code 25 as builds/android/veyra-0.11.0-dev.apk and updated the usual builds/android/veyra-debug.apk copy. Size: 95,466,418 bytes (about 91.0 MiB).
- apksigner verification passed; signer matches the prior debug APK, allowing an in-place update without changing the application ID.
- Manifest checked: version 0.11.0-dev/code 25, ARM64 only, minimum SDK 24, target SDK 36.
- Approved dragon launcher image extracted from packaged mipmap resources and visually confirmed; adaptive icon XML and foreground/background resources are present.
- Includes current persistent island, Moonleaf Grove, grass/collision improvements and redesigned camp. Physical-device install/performance testing remains pending.

## Collection input and icon-only controls (2026-11-10)

- Reproduced a quick E press/release not reaching frame-polled collection in the event test. Collection now routes from the key event and ignores repeat; touch interaction fires on press so movement out of range before release cannot lose the pickup. Existing range/pause/death guards remain in the shared action.
- Removed separate target-lock and heavy-attack touch buttons. Sword tap releases a normal attack; 0.4-second hold emits one heavy attack. Outside release/drag, menu, dodge and taking damage cancel pending holds. A release after a heavy never emits a light attack. H and Tab keyboard shortcuts remain.
- Gameplay buttons now use original centered SVG icons with screen-reader names and visual meter rings, without visible action text. Native 800x450 captures checked near a herb and during a hold.
- interaction_controls_check covers quick E, touch-down pickup while moving away, range/pause guards, real pointer short tap/hold, no repeated heavy, outside/menu cancellation, stamina gating, icon-only controls and absence of removed buttons. Existing harvesting, grove and heavy combat tests updated to the new controls.

- Final checks passed: interaction_controls_check, herbal_check, grove_check, heavy_attack_check, target_lock_check, quest_hud_check, safe_area_check, gameplay_check, pause_check, sprint_check and spirit_check.
- Android 0.11.1-dev/code 26 exported as builds/android/veyra-0.11.1-dev.apk (95,484,605 bytes); usual veyra-debug.apk updated. Signature verifies and matches 0.11.0; manifest confirms code 26/0.11.1-dev and ARM64. Physical-device test pending.

## Beach seal fragments and lantern prerequisite (2026-11-10)

- Added Tideseal Ruins at (-44, 0, 54), standing/broken colliding pillars, three fragment pickups and a cyan map marker. The new Beach waystone trail routes around existing shoreline boulders. Expanded the trail mask to a 208 m span/512px so beach paths outside the old 104 m range appear and grass stays clear.
- The northern lantern requires all three seal fragments and cleared camps. Either collection/clear order works. Fragment collection uses the existing hand icon/E event path and immediately saves without modifying health, potions or shards. HUD, journal, camp summary, map legend and lantern label describe the same gate.
- Save version 4 requires bounded unique fragment IDs; lit lanterns require a full seal. Old v1/v2/v3 lit or completed saves automatically receive full fragment progress, avoiding a reset. Earlier unlit saves retain other progress and receive the new quest.
- beach_seals_check verifies beach trail and pickup accessibility, input/duplicate/pause/range guards, partial reopen persistence, both prerequisite gates, single boss spawn and legacy lit/completed migration. Native arrival/overview renders reviewed. Fixed an orphaned pillar node discovered via exit warnings. No APK exported; device testing remains pending.

- Passed beach_seals_check plus persistent_world_check, save_check, gameplay_check, grove_check, terrain_material_check, campaign_smoke, keeper_check, relic_check, navigation_check, journal_check, interaction_controls_check, mountain_demons_check and island_map_check. Dedicated migration rerun after freeing the skipped pillar exits without resource-leak warnings.

## Shallow-water movement boundary (2026-11-10)

- Continued the partial boundary implementation. Replaced misaligned box segments with one continuous static collision mesh using the terrain's 128-segment irregular coastline. The base radius is 93 m, just beyond the waterline at base 90.5 m. Collision layer 8 blocks Aru while leaving the camera and enemy collision masks unchanged. No per-frame boundary geometry or movement clamp is needed.
- Ordinary shallow-water entry no longer triggers the old y < -1.2 rescue/damage rule. Emergency recovery remains below y = -4 with the existing 20-health fall penalty; death, waystone binding and travel remain unchanged.
- Save validation accepts the newly reachable coastline area while retaining the previous 92 m area for legacy relocation. Outside saved positions relocate just inside the boundary; resting contact positions survive reload without shifting. No save version/schema change is needed. Health, potion stock, currency and fragment progress are preserved.
- shallow_water_check passed: collision rays at all 128 joins and midpoints; real walk/sprint/dodge at eight coastline angles with 60 and 15 physics ticks per second; outward stability, diagonal sliding across joins, return to land, unchanged ordinary health, emergency rescue, beach trail and all three fragment interactions, wading-position save round trips and legacy outside-position reopen/re-save.
- Native OpenGL Compatibility capture followed 260 continuous physics frames through beach approach, wading, blocked movement, sliding and return. Health stayed at 100; the stationary blocked segment had no measured drift or teleport. Reviewed wading/sliding/return renders from a minimized window. Captures and synthetic save storage are local ignored validation artifacts.
- exploration_check, save_check, persistent_world_check, fast_travel_check, beach_seals_check, navigation_check, camera_check, prop_collision_check, terrain_material_check and gameplay_check passed. The prop collision check distinguishes the player-only sea boundary from trees/rocks that also block the camera. exploration_check still reports four shutdown ObjectDB instances; sustained device performance and shutdown cleanup remain separate pending work.
- No APK exported; no changes were staged, committed or pushed. Phone testing of this update remains pending.

## Intermittent walking stutter: background autosave (2026-11-10)

- The owner reports occasional walking stalls rather than constant low frame rate or attack-specific lag. The periodic five-second save previously performed temporary-file serialization, validation, primary-save reading and backup/rename operations synchronously inside the gameplay frame. This is a concrete source of storage-induced stalls; direct Android timing was unavailable because no phone was connected over ADB. It is not yet established that this explains every reported hitch.
- Periodic saves now copy only plain campaign data on the main thread and write it on one low-priority worker. Completion/error UI is handled on the main thread. Quest/menu/exit writes, reads, reset and scene teardown join any pending writer before touching the same files, preventing overlap and old snapshots overwriting newer progress. The existing transactional temporary/backup validation is unchanged. Rendering quality and combat timing are unchanged.
- autosave_check passed with injected 180 ms storage latency: initial background dispatch took 0.26 ms while movement continued. It also verifies independent snapshot arrays, one writer at a time, newer synchronous saves winning, failed writes/retry, corrupt-save protection, reset ordering and pending-save completion on scene exit.
- A minimized native OpenGL walking comparison used the same injected 180 ms write latency for both paths. Synchronous save calls occupied 195.89-207.89 ms of the gameplay frame; background dispatch occupied 0.54-1.16 ms. Maximum observed frame interval fell from 229.20 ms to 30.03 ms across the two controlled 200-frame samples. These desktop/synthetic results are not handset FPS measurements; phone acceptance remains pending. Captures/timing data and synthetic saves remain local ignored validation artifacts.
- Passed autosave_check, persistent_world_check, save_check, beach_seals_check, grove_check, fast_travel_check, campaign_smoke, pause_check, interaction_controls_check and shallow_water_check. The existing periodic-save regression now explicitly joins its asynchronous write before reading the result.
- Thread usage follows the [Godot thread-safety guidance](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html): no active scene tree or rendering API is touched by the worker.
- No APK exported; no changes staged, committed or pushed. Retest the fix in a newly built APK on the reported phone.

## Expanded island, separated hills and tall forests (2026-11-11)

- Increased the land-mesh base radius from 96 to 120 m (approximately 56% larger footprint), with level inland radius 100 m, visible waterline base 114.5 m and movement boundary base 117 m. Updated ground/sand blending, grass coverage, 256 m trail-mask mapping, sea foam, map scale and save bounds together. The sea's appearance/height and original quest coordinates remain unchanged.
- Replaced the linked ring of seven steep peaks/six ridges with six broad, separated cosine-profile hills in the ground mesh. Their 18-24 m footprints and 6-10 m summits keep slopes below the player limit. Visible and physical terrain share one mesh. Existing camp, lantern, grove and beach-ruin paths remain clear.
- Added 54 deterministic forest trees in two woodland patches, with approximately 12-16 m trunks/branches and fuller textured canopies. Central and grove trees also have taller proportions. New forest placement protects clearings, paths/pickups and the tree-free sandy coast. Shared reduced wood geometry (1,835 triangles) plus leaf-atlas cards (1,000 triangles/canopy) replace the old 16,794-triangle tree in gameplay. Forest visuals use spatial MultiMesh batches and distance culling; colliders still match trunks. The derivative has no dependency on the original high-resolution glTF scene.
- Restore now lifts an old saved position that is below expanded land or a new hill, preserving health, potion stock and currency. Saves on the expanded coast validate without changing the save schema. Emergency fall recovery and the background-autosave fix remain covered.
- island_regions_check passed: expanded terrain/bounds, forest height/count/mesh-material budget, batched instance totals, every forest trunk collider, 64 clear coastal directions, separated hill height/slope samples, actual movement climbing two open hills at 30 physics ticks per second, new-position persistence and safe old-position height restoration.
- Passed exploration_check, mountain_demons_check, terrain_material_check, island_regions_check, beach_seals_check, grove_check, shallow_water_check, island_map_check, prop_collision_check, camera_check, persistent_world_check, save_check, autosave_check, gameplay_check and fast_travel_check. The nine-world beach migration run needs more than the initial 20-second runner limit under concurrent rendering; it passed separately in about 18 seconds. Final tree-material changes were followed by regions/grove/prop/camera reruns.
- Reviewed native OpenGL offscreen captures of the complete island, woodland at ground level, open hillside and clear sandy beach. These ignored local artifacts were rendered through a minimized window; no gameplay window was brought to the foreground. Placeholder solid canopy shapes were replaced with the final photographed leaf-atlas cards before acceptance.
- Desktop starting-view sampling recorded 532 draw calls / 684,031 primitives, versus the earlier baseline of 674 / 1,857,425. These counters show the reduced geometry/draw submission; measured frame intervals were comparable rather than demonstrating a guaranteed FPS increase. No handset benchmark is available.
- No APK exported; no changes staged, committed or pushed. Physical-phone acceptance, sustained frame rate and thermal behavior remain pending.

## Jump control and character motion (2026-11-11)

- Added an 80 px icon-only round jump button above Sprint, using the established SVG style and circular hit area. Its touch-down action calls the same grounded jump method as keyboard Space; K remains dodge. The button is disabled in the air and while takeoff is blocked by combat/reaction state. Input is event-driven, so a quick Space press/release does not depend on physics-frame polling.
- Jump uses an upward impulse and the existing gravity/collision controller. A takeoff flag preserves the impulse on the first grounded frame and prevents repeated launches until landing. Horizontal movement continues normally. No additional stamina cost or double jump is introduced. Menus, death, active attacks/dodges and hit reactions guard takeoff.
- Retargeted the existing Quaternius Jump_Start, imported Jump loop and Jump_Land clips to the hero. Air/landing motion follows the actual grounded state and preserves combat/death action priority. Godot strips the source Jump_Loop suffix during import; the runtime uses the imported Jump name.
- jump_check passed using real viewport key/touch events: icon/accessibility/circular hit area, no action overlap, quick Space without dodge, bounded height, movement in the air, takeoff/air/landing animation, repeat and double-jump guards, paused/dead/combat restrictions, and sea-wall collision at 15 physics ticks per second. Input events use the same unscaled viewport setup as the existing interaction checks.
- Passed jump_check, layout_check, safe_area_check, hero_animation_check, heavy_attack_check, interaction_controls_check, pause_check and gameplay_check. interaction_controls_check reported two existing shutdown ObjectDB instances; its behavioral assertions passed.
- Native 800x450 offscreen captures reviewed with the button grounded/enabled and airborne/disabled. The airborne capture records height 1.08 m and the Jump clip. No foreground game window was opened. PNGs and synthetic saves remain ignored local validation artifacts.
- No APK exported and no changes staged, committed or pushed. Physical-phone verification remains pending.


## Android debug 0.12.0-dev (2026-11-11)

- Exported current project using Godot 4.7.2 Android Debug preset: `builds/android/veyra-0.12.0-dev.apk`; `veyra-debug.apk` contains the same build.
- Version code 27; package `com.hirukshanan.veilofveyra.dev`; ARM64; minimum API 24; target API 36.
- APK signature verification passed. Signing certificate matches 0.11.1-dev, allowing an in-place update.
- ZIP integrity passed. Jump icon, player script, reduced forest tree, foliage shader, island forest and beach seal scripts are included; development tests/tools are excluded.
- File size: 95,784,476 bytes. SHA-256: `55231FC649A2241E6C8F460CBF8B5C0715D1BD26DF71B4979A2B5850ABE795C5`.
- Export stderr was empty. This is packaging verification; installation, jump touch controls, expanded-island performance, save continuity and sustained gameplay still require phone testing.

## Chapter I route and reserved grove pass — Phase 1 (2026-11-13)

- Added three connecting woodland/grove trails, a central trunk/pillar detour, four solid waymarks, readable map landmarks, a separate Ancient Grove floor and reserved Dragon camera/perch markers. Terrain heights, sea, quest locations/IDs, save version and rewards are retained.
- Passed 20 targeted checks: chapter_route_check, island_regions_check, mountain_demons_check, terrain_material_check, prop_collision_check, camera_check, navigation_check, beach_seals_check, grove_check, herbal_check, persistent_world_check, save_check, autosave_check, gameplay_check, island_map_check, layout_check, safe_area_check, fast_travel_check, environment_check and shallow_water_check. No shutdown warnings in this selected suite. Coast check passed in 117.33 seconds.
- The new actual-controller test sweeps a larger-than-player capsule, samples the clear grove floor, checks waymark collision/vista orientation, walks 711 waypoints around shore/foothills/forest/ruins/grove and back, visits/returns from optional Moonleaf Grove, and reopens a partial seal save at the new clearing. Enemies are frozen and simulation accelerated 4x solely for controlled navigation testing.
- Native rendered rerun also passes; a 20.4-second route movie, before/after overview/woodland screenshots, grove/vista and 1280x720/800x450 map captures were reviewed. Dragon framing preview is local validation only, not a story scene. Capture data and synthetic saves remain ignored under .validation/ch1_phase1_2026-11-13.
- Forest count 54 -> 38 after intentional route/grove/vista exclusions. Both patches retain at least 12 tall trees; individual trunk collision, shared mesh budgets and distance culling remain. No existing rock or central trunk/pillar collision was disabled.
- Controlled arrival counters: 534 -> 533 draw calls and 646,633 -> 591,428 primitives; median/p95 intervals 40.369/46.388 -> 34.567/39.700 ms. Both minimized-window methods include a roughly 17-second first interval, so this is not a clean sustained/phone FPS benchmark. See docs/CH1_PHASE1_REPORT.md for the dual-viewport sample and limitations.
- No phone connected; physical touch, sustained performance and thermal acceptance remain pending. No APK exported: Phase 0's restricted-runner editor-config/SDK-resolution blocker remains. No new branch, commit or push was created. Phase 2 awaits owner review.

## Chapter I Phase 2 controls (2026-11-14)

- Isolated tests and native GL Compatibility captures live in .validation/ch1_phase2_2026-11-14. New mobile_controls_check verifies three-pointer movement/look/attack, touch target cycling, visibility/boss priority, camera and held-action cancellation across menus, mirrored camera zone, control-size/handedness/inset layouts and settings persistence.
- Existing keyboard/interaction checks were updated to require the touch lock affordance. The old combat fixture now updates its teleported enemy home to avoid an unrelated return-home leash; enemy AI remains unchanged.
- Original/CC0 starter outfit retains the existing skeletal controller and action timing. Fitted trouser geometry uses the source body's skin weights to avoid the leg clipping seen in early cylinder prototypes. Native idle/walk/attack/roll views were reviewed; final art approval remains pending.
- See docs/CH1_PHASE2_REPORT.md for the final 19-check list, shutdown warnings, native run evidence, changed-file boundary and rollback. No connected phone, sustained mobile benchmark or new APK. Existing packaging configuration-access issue remains documented.
