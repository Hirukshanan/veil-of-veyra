# Veil of Vera — Task 5.4 review

Task 5.4 implementation and desktop functional verification are complete. Visual and physical-phone approval remain pending. The production map is not activated. No Chapter II or unrelated content changes were made.

## Controls

The default movement joystick and sword attack both increase from 144 to **176 logical pixels** at the 1280×720 reference viewport: +22.2% diameter. Their centers are deliberately mirrored at **(100,604)** and **(1180,604)**. These are logical layout units, not a claim about millimeters on the Samsung screen. The HUD continues to render at native canvas resolution over the preserved 720p 3D render.

| Control | Default diameter | Center at 1280×720 |
| --- | ---: | --- |
| Movement joystick | 176 | 100,604 |
| Sword | 176 | 1180,604 |
| Kick / Boot (existing Dodge action) | 76 | 1050,636 |
| Special / Star | 72 | 1050,436 |
| Shield | 84 | 1044,524 |
| Jump | 76 | 1180,466 |
| Interact | 64 | 1180,384 |
| Potion | 64 | 574,672 |

Kick and Special centers are exactly preserved against the archived pre-task layout, including all tested scales/presets. Secondary buttons remain smaller than the primaries. The other combat controls were spaced to fit the enlarged primaries without overlap. Portrait, quests, map and upper utility HUD were not globally scaled. User-saved customization remains supported and can override defaults; existing layouts are not erased on update.

**Sprint:** normal joystick travel remains unchanged. Drag upward beyond 1.35× the movement radius, within a narrow horizontal cone, and hold 0.25 s. A gold stamina arc and SPRINT label confirm activation. Drag beyond 1.95× and hold an additional 0.45 s for AUTO, then release to continue. Touch the stick again, drag it normally, enter a menu, lose app focus, interrupt sprint through combat, die or deplete stamina to cancel. A neutral re-arm prevents repeated accidental activation. The gameplay sprint button is removed. Original speed (5.2/8.3), start threshold and 25 stamina/s consumption are unchanged.

**Pinch:** use two fingers on free gameplay space, excluding UI-owned touches. Spread to move closer, pinch together to move farther. Camera distance is smoothed and bounded to 4–9 m; the original SpringArm collision remains enabled. Remaining fingers must release before one-finger look re-arms, avoiding a camera jump. Distance is saved after the gesture, including menu/focus cancellation. The existing distance slider still works.

HUD editing remains only under **Settings → Controls → Customize HUD**. No target lock, layout editing, swap or resize button was restored to gameplay.

## Settings

The narrow settings column is replaced with full-safe-area tabs: Controls, Camera, Graphics & Sound. Wide layouts use two columns, narrower logical layouts use one. Normal finger swipes over labels/empty card space scroll the content; the thin scrollbar is optional. Only actual slider tracks claim slider gestures. Save, Back without saving and Reset defaults remain fixed outside the scroller. Existing values and configuration keys remain compatible.

The separate Task 5.4 APK also expands the canvas to the actual landscape aspect ratio instead of retaining a 16:9 letterboxed render area on wider windows. This is confined to the test bootstrap; production project settings remain unchanged. The accepted 3D height-cap function and bilinear mode remain identical. Final packaged checks compare the native window size with the actual viewport image size, including 1600×720. Before/after comparison captures deliberately use the same expanded-aspect preview configuration on both revisions to isolate the HUD change; they are not screenshots of the original letterboxed startup configuration.

Back restores the entry snapshot. Reset previews defaults until saved. Failed saves leave the previous settings intact and show an error. Settings writes use a temporary file and backup fallback; campaign/world save storage is unchanged. The existing Android bootstrap previously overwrote saved FPS/shadows at each launch: it now applies 30 FPS/shadows-off defaults only when no settings or backup exists. Existing test saves and selected preferences survive an update. The 720p scale function is identical to the accepted version.

## Verification and evidence

- **34/34 final regression programs passed**, with no final script/shader/engine errors. [Full results](test_results.json) and [raw logs](logs/final_mobile_gestures_check.stdout.log) are included.
- [54 HUD layout combinations](control_layout_results.json): six landscape logical sizes × three control scales × three presets. Matched mirrored primaries, preserved Boot/Star centers, no touch-rectangle overlap and safe bounds.
- [Sprint/pinch tests](gesture_results.json): normal walk versus deliberate sprint, release cancellation, AUTO continuation/new-touch cancellation, stamina/combat restrictions, focus loss, bounds/smoothing/persistence, simultaneous joystick+attack+two-finger pinch, stale-touch cancellation. Actual Godot `Viewport.push_input` dispatch was used; this is automated input, not a physical phone playtest.
- [Settings touch tests](settings_touch_results.json): 100 px finger swipe without slider changes, slider-track input without scroll, 12 tab/safe-area combinations including simulated cutouts, settings save/reload, reset/discard, failed-write preservation.
- Existing combat, heavy attack, campaign, quests, autosave, persistent world, fast travel, HUD editor, island geometry/collision/traversal, enemy navigation and repeated boar attack checks passed. Boar state logs and navigation/collision/river results are included.
- [Packaged-build functional check](packaged_settings_check.json): exported APK resources run through native Godot; resize-aware 720p scaling at 1080/900/720 physical heights; HUD rectangles unaffected by 3D scale; schema-2 local profiler output; camera/HUD/volume/frame settings retained across restart. This was **Windows execution of exported resources**, not Android execution.
- [Preservation](preservation.json): all **298 existing assets**, both scene files, production project settings/export presets and protected world/AI/dragon/geometry scripts remain hash-identical. No island collision shape was changed. Original player movement/combat methods verified unchanged.
- Screenshots are original PNG captures from Godot. The before/after pairs use the same camera and held actor physics for comparison. Sprint/pinch feedback shots also hold actors; they prove UI output, not sustained gameplay. The packaged screenshot is clearly labeled DESKTOP_ONLY.

## Rendering and input cost

Windows / Intel Iris Xe / OpenGL Compatibility. Same actor-held camera, 720p cap and shadows-off configuration; native canvas. 40 warmup frames +90 observations/view. Desktop cap 60. These intervals include pacing and are **not Android FPS or a sustained-gameplay benchmark**.

| View | Draw calls before → after | Submitted primitives before → after | Median frame ms before → after | p95 frame ms before → after |
| --- | ---: | ---: | ---: | ---: |
| gameplay_1280x720 | 204 → 199 | 451485 → 450821 | 16.67 → 16.67 | 17.31 → 16.75 |
| settings_1280x720 | 230 → 231 | 453095 → 455629 | 16.67 → 16.67 | 16.82 → 16.73 |
| gameplay_1600x720 | 223 → 218 | 475823 → 475159 | 16.66 → 16.66 | 17.22 → 17.41 |
| settings_1600x720 | 249 → 250 | 477433 → 479967 | 16.66 → 16.67 | 16.76 → 16.90 |
| gameplay_960x540 | 204 → 199 | 451485 → 450821 | 16.67 → 16.67 | 16.79 → 16.75 |
| settings_960x540 | 230 → 231 | 453095 → 455629 | 16.66 → 16.67 | 16.90 → 16.86 |

The raw GPU-timer/static-allocation samples are in [rendering_input_cost.json](rendering_input_cost.json). Static allocator bytes are not Android PSS or total GPU memory. No world geometry, texture, shadow or shader was added. Changes are UI/input work; active sprint redraw adds a stamina arc and pinch may change what the camera sees.

Synthetic input dispatch, five trials ×5000 drag events after100 warmup events, CPU microseconds/event. This measures the local engine input path, not physical touch latency:

| Input path | Median CPU µs/event |
| --- | ---: |
| camera_drag | 3.238 |
| joystick_drag | 4.871 |
| camera_drag (after) | 3.780 |
| joystick_drag (after) | 4.223 |
| pinch_drag (after) | 3.942 |

The camera path adds small local dispatch overhead; these samples do not establish Android cost. No visual degradation or unrelated graphics optimization was made.

## APK and Samsung A37 test

The ZIP includes exactly one updated APK: `APK/Veil_of_Vera_Task54_720p_Candidate.apk` (151,000,889 bytes, SHA256 `50e5760bfb682de56c7111aea782c0f04c451a9a9d212a89b2bd1b1cbc7df7da`). ARM64 debug candidate. Package `com.hirukshanan.veilofveyra.islandtest`; signature verified against the accepted 720p test build. Update the existing test app in place; **do not uninstall or clear its data**. This keeps the separate package's test saves. No Internet permission is requested. Production main remains `res://scenes/main.tscn`; the isolated APK staging copy launches `res://mobile_test/main.tscn` only.

No physical Android device was connected. Device model/Android version, actual FPS, frame-time spikes, CPU/GPU, memory, battery and thermal results are **unverified**. Owner target: Samsung A37, 8 GB RAM; Android version not yet recorded. No stable 60 FPS or physical usability claim is made. Fresh installs use 30 FPS/shadows off; saved preferences survive updates.

See [SAMSUNG_TEST.md](SAMSUNG_TEST.md) for the combined 5.1–5.4 test steps after approval.

## Files, sources and limitations

Changed runtime files: `scripts/main.gd`, `mobile_hud.gd`, `player.gd`, `campaign.gd`; new `mobile_joystick.gd`, `mobile_settings.gd`. Build helper/bootstrap updated for Task 5.4 labeling and retained settings. Existing test fixtures were updated to address the new tabs/removed sprint control/enlarged bounds; a teardown wait in the sprint fixture allows existing audio to release cleanly. New real-touch/layout test programs are included. [Exact changed files](changed_files.json), [commands](COMMANDS.md), baseline hashes and review source copies are provided. No Git stage/commit/push was performed for this task.

No new external assets, fonts, shaders, textures or proprietary graphics were downloaded. Existing project sword/boot/star/shield artwork, gold/dark styling and Cinzel font are reused under their existing project licenses. The joystick feedback and Settings layout are original code.

Remaining limitations: hardware touch reach and accidental-trigger tolerance require the A37 owner test; platform-specific touch/cutout behavior is not proven by simulated input; no sustained Android thermal/battery/memory evidence; existing island cave/waterfall visual limits and prior traversal/frame-spike risks remain outside Task 5.4. A pre-existing filled-rectangle width warning remains in `premium_hud.gd`; it is unrelated to these changes. Desktop exported ETC2 textures use the driver fallback and are not evidence of Android texture-memory usage. Existing customized HUD profiles retain their choices rather than being silently replaced by new defaults.

**Stop here for visual approval. Do not activate the production candidate or begin another task.**
