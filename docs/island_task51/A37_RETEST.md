# Samsung A37 / 8 GB — Task 5.1 controlled retest

**Scope: performance only.** Map scale, river exits, enemy placement, collisions and control redesign are queued for later review. No physical phone was available to the agent, so Samsung root cause and stable 30 FPS are not yet proven.

## Two matched APKs

| APK | Purpose |
|---|---|
| `Veil_of_Vera_Task51_Native_Baseline.apk` | A: native 3D resolution, improved recorder |
| `Veil_of_Vera_Task51_720p_Trial.apk` | B: 3D-only height cap of 720 pixels when native height is larger; same recorder |

Both use the same `com.hirukshanan.veilofveyra.islandtest` package and verified same signing identity as the previous test APK. Install/update one at a time. **Keep the app installed and use an in-place update**; no uninstall or data clearing is required. Existing test saves/layout/progress stay in that package's sandbox. Production app/data are separate. Both start with 30 FPS cap and shadows off; all original controls/mechanics and visuals are unchanged except B's lower 3D sampling resolution. 2D HUD/input rectangles remain native and unchanged. This does not fix the small-button feedback yet.

B is an experimental candidate, not an approved default. It may help fill-bound regions, have little effect in CPU-bound regions, or regress due to scaling/driver overhead. Only keep it after A37 evidence and image-quality review. On a 1920×1080 window it samples 1280×720 3D; on 2400×1080 it samples 1600×720. These are calculated examples, not measured Samsung dimensions. At 720p-or-lower height it leaves scale 1.0. Resize/orientation recalculates the cap without changing HUD geometry.

## Quick owner check

Update to B, continue the same save, then walk the same forest approach and look around. Note whether sustained lag changes and whether distant foliage becomes unacceptably soft/shimmery. Keep settings at 30 FPS/shadows off. This is useful feedback, but a subjective impression alone is not an FPS benchmark.

For controlled measurements, compare **A → B → B → A**, allowing the phone to return to a similar temperature between runs. Use the same save/location, camera direction, display refresh/brightness, power mode, charging state and foreground apps. Warm up actual gameplay for five minutes, then repeat the same 3–5 minute forest/hill/mountain route per short run. Perform a longer 30-minute run only after identifying the better configuration. Record actual Android version and physical render/window dimensions; do not assume the 1280×720 design viewport is the rendered resolution.

## Local profiling (reuse the existing kit)

From the repository root, using Python 3 and Android platform-tools:

```powershell
$adb = "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
& $python tools/profile_island_android.py check --adb $adb --output .validation/a37_task51
& $adb install -r builds/android/task51/Veil_of_Vera_Task51_Native_Baseline.apk
& $python tools/profile_island_android.py collect --adb $adb --minutes 10 --interval 30 --output .validation/a37_task51/native_run1
```

Play while the collector runs. Pause/background the app to flush its last local CSV buffer, then:

```powershell
& $python tools/profile_island_android.py pull --adb $adb --output .validation/a37_task51/native_run1
& $python tools/profile_island_android.py analyze --session .validation/a37_task51/native_run1/mobile_profile_TIMESTAMP --warmup 300 --output .validation/a37_task51/native_run1/analysis
```

Update to B using `install -r` and its filename, and use a different output folder. Each APK session records its experiment name. Select the matching timestamp; `pull` can return multiple previous sessions. Share only the selected profiling CSV/JSON and in-game screenshots after checking for private information. No cloud upload or global phone log capture is built in.

Schema 2 adds actual physical window pixels, root viewport pixels, calculated 3D pixels/scale, engine startup-to-placement interval, backend render CPU/GPU times, engine process/physics monitors, active physics objects, collision pairs and memory/call/primitive counters. GPU/CPU fields that stay zero are **unavailable**, not zero-cost. Backend timing rows average five seconds and cannot supply GPU p95/p99; frame CSV provides callback p95/p99/max and spikes over 50/100 ms. Engine process duration is not isolated CPU work and must not be added to GPU time. Counter changes can reveal movement between regions; keep a separate route/time note.

The test recorder itself has overhead (GPU timer queries, string buffering and periodic five-second file flush). A/B use identical instrumentation. If spikes align with flushing, or query overhead seems material, flag that before changing game assets. Later release/non-instrumented confirmation is still required.

Collect available app PSS, battery temperature/charge fields and thermal status with the same helper. Battery drain needs an unplugged controlled run; a charging USB run does not establish drain. A single authorized local wireless-ADB connection can support an unplugged run. Missing thermal/sensor fields remain unknown. Record ambient conditions and OS/game power settings. Never reset phone battery statistics for this test.

## Interpret the result before another correction

- If B improves measured GPU time and forest frame spikes while CPU/physics cost stays comparable, retain the resolution option only after visual acceptance.
- If B hardly changes GPU/frame times, or frame time worsens, revert to A and investigate render submission/physics/AI/startup timing using the recorded counters. Do not reduce geometry blindly.
- If initial play is slow but settles after warm-up, distinguish shader compilation/loading from sustained workload. Existing normal/LOD generation runs once during candidate construction, not every frame.
- If early performance is good and degrades as thermal status rises, investigate sustained heat/power before changing world scale or controls.
- If neither variant approaches stable 30 FPS, return the selected session metadata, CSVs, per-region screenshots, Android version and a short description of the worst location/action. Actual SurfaceView presentation and GPU/CPU traces may need local Android Studio/Perfetto tooling, as described in the original Task 5 protocol.

Capture screenshots or a short Samsung gameplay recording **separately from timing runs**, because screen recording adds workload. No Android screenshot, video, thermal, memory or FPS result is claimed by this delivery. The included gallery is clearly desktop-only evidence.

Stop after this Task 5.1 review. Task 5.2 world/river work and Task 5.4 controls/settings are not part of either APK.
