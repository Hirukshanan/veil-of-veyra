# Veil of Vera — Island Task 5: Android readiness

**Result: test build and local profiling kit prepared. Actual Android performance/readiness remains unverified. Production candidate activation was not performed.**

## Hardware and measured-result status

| Item | Result |
|---|---|
| Agreed baseline device | Samsung A37, 8 GB RAM, supplied by the owner |
| Physical phone connected | No authorized physical device during this task |
| Actual model code / Android version | Pending on-device check |
| Android gameplay/touch controls | Not executed; joystick/sword/dodge/other touch behavior on A37 pending |
| Actual Android FPS / spikes | Not measured |
| Android CPU / GPU timing / PSS | Not measured |
| Android thermal / battery behavior | Not measured |
| Android screenshots / visual comparison | Pending; no Android screenshots are fabricated |
| Stable sustained 30 FPS verdict | Not established |

`device_check.json` contains explicit null measurements. The device is an agreed test target, not a verified connected model. No desktop figure, emulator or offline video is treated as Android performance. Existing Task 4 desktop render counters remain a risk reference only.

## Build delivered and configuration inspection

- APK: `Veil_of_Vera_Island_Task5_Android_Test.apk`, **143.98 MiB** (150,975,539 bytes), SHA-256 `9671e5736136eb1bd5501f0947868c956c60580007825e74bc254d9f01f4f164`.
- Distinct debug test app: `com.hirukshanan.veilofveyra.islandtest`, launcher **Veil of Vera Island Test**. ARM64 only, minimum API 24, target API 36; signature and debug flag verified with Android SDK tools. Internet permission absent. No network telemetry.
- Installed Java 21, Android SDK and Godot 4.7.2 templates exported successfully using the existing non-Gradle workflow. No external SDK/asset download or release-key use. Android SDK build-tools 35.0.0 verification tools were used; final manifest records target/compile platform metadata. SDK minimum/target values describe compatibility metadata, not phone execution.
- Source export preset originally used `all_resources`, development package `com.hirukshanan.veilofveyra.dev`, 60 FPS/shadows-on game defaults and GL Compatibility/ETC2 imports. Its exclusion rules did not explicitly cover the newer authoring/evidence directories, so this test's staging preset explicitly excludes source/docs/tests/tools and includes dynamic metadata JSON. The original preset remains unchanged.
- Only the copied staging project launches `res://mobile_test/main.tscn`, which loads the approved `res://scenes/island_candidate.tscn`. Original project still opens `res://scenes/main.tscn`. Separate Android package means a separate save/settings sandbox.
- Test-only initial quality: 30 FPS cap, shadows off, existing rendering/art/HUD unchanged. Existing Settings still offer shadow/60 FPS comparisons. The project has a 1280×720 design viewport with `canvas_items`; actual phone 3D pixel resolution may be native window size and must be recorded.

## What was actually verified

1. APK export/import zero exits, cryptographic signature verification, APK ZIP CRC, ARM64/package/debug/SDK/no-internet manifest checks and correct binary main-scene entry point.
2. Required candidate scripts, Task 4 shaders/mask remaps, vegetation metadata and imported runtime assets included. No authoring blends, private signing files, docs, test scripts or tools are in the APK.
3. The **final APK resource payload** was extracted and loaded using the native desktop GL Compatibility engine. The exact approved candidate, 72-tree vegetation, Task 3/4 modules, original gameplay and test quality defaults load; local per-frame/five-second CSV writer works. This is a Windows functional packaging test, **not Android execution or speed evidence**. The desktop driver warned that ETC2 formats were expanded to RGBA; that fallback makes its memory/performance unsuitable for phone inference.
4. Profiling parser self-test verifies pause/resume boundaries, genuine long-hitch retention, quantiles and rejection of desktop/synthetic data as Android results. The collector correctly reports pending when no phone is connected. Device-specific ADB collection remains unexercised on hardware.
5. **21/21 final existing regressions pass cleanly**, including island geometry/collision, forest, actual regional traversal, cave quest/reload, campaign progression, combat/enemies/boar, travel, autosave/persistence and HUD. Nine target candidate fixtures; twelve retain their original system fixtures. Raw final logs/exit codes are in `logs/` and scopes in `test_results.json`.

Initial boar/combat fixtures passed assertions but reported audio playback resources still alive during process shutdown. Verbose diagnostics identified WAV/playback objects rather than changed enemy logic. Only fixture teardown was corrected: free the scene and allow stopped audio mixing to release before terminating. The affected tests were rerun cleanly; original/diagnostic logs remain under `logs/diagnostics/`. No combat, boar, audio runtime or assertion behavior was changed. These fixture diagnostics alone do not establish or rule out Android runtime leaks.

One initial payload-identity check also detected regenerated Godot binary scene/sparse-pack metadata after rebuilding the helper. Instead of assuming identity, the final APK payload was extracted and functionally rechecked; `apk_verification.json` matches the final hash. Rebuilds are not claimed byte-identical.

## Gameplay screenshot evidence

- `DESKTOP_ONLY_exported_bundle.png`: actual current exported-bundle smoke screenshot on Windows, original hero/HUD/gameplay. It is labeled desktop-only and is not an Android graphics pass.
- `APPROVED_DESKTOP_Task4_map_reference.png` and `APPROVED_DESKTOP_Task4_gameplay_reference.png`: original approved desktop images copied byte-for-byte for later phone matching.
- Android forest, hills, mountains, river, cave, coastline, combat and touch screenshots remain pending. `ANDROID_TEST_PROTOCOL.md` specifies those captures and the sustained route.

## Performance observations and smallest next optimizations

There is no phone bottleneck attribution yet. The following are static/package observations and hypotheses to verify, not measured A37 conclusions. Approved art is preserved; no speculative quality reduction was applied.

| Priority | Observation / risk | Smallest action only if phone evidence warrants it |
|---|---|---|
| Baseline | Existing 60 FPS/shadows-on defaults can raise cost; test wrapper now starts at 30 FPS/off. | Measure this existing-quality baseline first, then optional shadows separately. Retain 26 m single-split Task 4 shadows for capable devices. |
| Fill/foliage | Dense cutout forest and close grass can be overdraw-heavy even with instancing/LOD. Native display resolution may exceed the desktop design viewport. | Inspect phone GPU/frame-time evidence and actual render pixels; tune existing culling/density thresholds gradually before changing approved meshes/atlases. No threshold change applied. |
| Rock/water shaders | Task 3 triplanar diffuse/normal samples, moving waterfall noise, water and Task 4 fog/mask sampling add shader work. | Compare controlled views with local device GPU tools. Simplify only the proven expensive distant material path; preserve close-range normals and approved river geometry. |
| Loading/CPU | Five rock/grotto meshes rebuild normals/ImporterMesh LODs on candidate initialization; large trimesh collision construction is retained. | Measure cold/warm start CPU and transient memory. If significant, pre-bake the exact existing visual LOD resources offline; retain collision/vertex fingerprints. Not implemented here. |
| Textures/memory | APK contains 74 imported texture files, totaling 104.46 MiB of packaged ctex data. This is not resident VRAM or Android PSS. | Measure app PSS/engine estimates after warm-up and repeat travel/reloads. Audit live vs unused assets before reducing texture quality. |
| Export/storage | Conservative all-resource APK is 143.98 MiB and includes legacy runtime dependencies. | A validated candidate-specific dependency export may reduce install/storage; preserve explicit JSON/binary metadata. Smaller APK does not automatically prove smaller runtime memory. |
| Stability / energy | No sustained hardware run, charging control, thermal trace or battery observation exists. | Perform 5-minute warm-up + 30-minute A37 route, repeat unplugged for drain/thermal conclusions. Debug/profiling overhead needs later release-build comparison. |

No Android FPS, memory, thermal, battery life or graphics-quality target is marked passed. SurfaceView presentation and CPU/GPU time need local on-device tools in addition to engine callback intervals. The recorder's five-second flushing may contribute occasional small spikes and must be considered when interpreting data.

## Preservation and changed files

Approved candidate art/runtime, terrain/river/sea, 47 static collisions, forest/grass, mountains/cave/waterfall, hero/HUD, enemies/combat, quests/saves and dragon remain unchanged. Production `project.godot` and `export_presets.cfg` retain their baseline bytes. `preservation.json` and baseline hashes document this.

Added build/profile helper scripts and two build-only templates under `tools/`; updated only two test teardown blocks. Added this report/protocol/evidence. No new runtime art assets or licenses; existing game asset licenses/credits remain. No private source/assets or traces were uploaded to a service, and no signing key/password is packaged. `CHANGED_FILES.json` lists exact files/hashes.

`REBUILD.md` contains a reproducible isolated build command. `ANDROID_TEST_PROTOCOL.md` contains install, sustained region/combat/control checks, sanitized device collection, CSV extraction/analysis, battery conditions, graphics comparison and readiness gate. Final build logs, APK checks, parser tests, source hashes and regression logs are included.

Stop after Task 5. Await approval and actual Samsung A37 test evidence; do not activate the candidate or begin another chapter/task.
