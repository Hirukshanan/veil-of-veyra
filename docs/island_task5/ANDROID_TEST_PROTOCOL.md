# Samsung A37 / 8 GB — Android test protocol

Status: **not yet executed on a phone**. Samsung A37 and 8 GB RAM are owner-provided; actual model identifier and Android version remain pending. Target is sustained 30 FPS. This test app uses the approved candidate and original touch controls/combat. Production app, quests and save data use a separate Android package.

## Install and verify

1. Install `Veil_of_Vera_Island_Task5_Android_Test.apk` on the Samsung A37. App name: **Veil of Vera Island Test**. It is a debug-signed ARM64 APK; minimum Android API 24, target API 36. A successful build/signature check does not establish phone compatibility or speed.
2. Start the app, enter the game and confirm the connected candidate map, original joystick and sword icon/HUD. Each launch starts with 30 FPS cap and shadows off. Use existing Settings for optional shadows/60 FPS comparisons later.
3. For measurements, connect exactly one authorized physical phone using Android platform-tools. USB is suitable for frame/memory tests. Battery drain needs an unplugged run: use already-authorized local wireless ADB if available, or capture battery levels locally on the phone. A charging USB run cannot establish battery drain. Keep captures local.
4. On the computer, use Python 3 and the bundled platform-tools `adb`. Enable USB debugging and approve the computer on the phone when needed. No internet connection or account is required by the game.

From the repository root in PowerShell (set `$python` to your Python 3 executable):

```powershell
$adb = "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
& $python tools/profile_island_android.py check --adb $adb --output .validation/phone_run
& $adb install -r builds/android/Veil_of_Vera_Island_Task5_Android_Test.apk
```

The helper records model/Android version without retaining serial numbers. If more than one ADB target is connected, leave only the intended physical phone connected. Repeat installs with the same private test-signing profile. A different debug key can prevent an update; do not remove any production app to resolve a test-app signing issue.

## Controlled baseline

- Record actual Android version, model code, RAM as reported by owner/system, display resolution/refresh, brightness, battery state, charging state, power-saving/game-boost mode, ambient room temperature and case use. Keep these constant across comparisons. Proposed baseline: normal power mode, fixed comfortable brightness, 60 Hz display if available, no screen recorder or other heavy app.
- Allow initial import/shader activity to settle with **5 minutes of actual play**, then perform **30 minutes sustained gameplay**, ideally two comparable runs after cooling. Do not count menus/loading/background periods as gameplay.
- The 1280×720 setting is a design viewport. `canvas_items` stretching can render 3D at the phone window resolution; it is not a guaranteed fixed 720p GPU workload. Record screenshot/window resolution before comparing desktop images or phone performance.
- Keep the first baseline at the supplied 30 FPS / shadows-off setting. Test optional 30 FPS / shadows-on separately after cooling; a 60 FPS run is optional and is not the readiness target. Each launch restores the test defaults.

Suggested 30-minute route (use the included approved desktop top-down reference for orientation):

| Section | Minutes | Actions |
|---|---:|---|
| Western forest interior and approach | 6 | Walk/run among tall trees, turn camera through canopy, approach and retreat across LOD bands. |
| Open hills and grassland | 4 | Move across grass density changes, rotate view toward multiple regions, inspect both ground inlays. |
| Mountains and river/waterfall | 6 | Approach the northern mountain area, inspect rock normals and waterfall from near/far, follow accessible banks. |
| Eastern cave | 4 | Follow existing accessible route; enter/explore/exit, collect the existing relic when available, save and reload inside. |
| Coastline | 3 | Walk on clean sand and look across the sea/outlet. |
| Combat and controls | 7 | Fight existing camps/boar where available; test simultaneous movement, camera, sword attack, kick, dodge, jump, guard, sprint, potion and skill. |

Check multi-touch overlaps, missed/repeated taps, hold/release behavior, camera drag with joystick held, thumb reach, HUD safe areas, settings transitions, pause/resume, background/foreground and one clean save/relaunch. Existing combat/cooldowns apply; there is no target-lock control. Record each action as pass/fail and note exact reproduction steps. No Android touch action was verified in this task.

## Record device observations

Run this while playing the warm-up + route (35 minutes):

```powershell
& $python tools/profile_island_android.py collect --adb $adb --minutes 35 --interval 30 --output .validation/phone_run
```

It records app PSS where Android exposes it, battery fields, charging state and available thermal status/temperatures every 30 seconds. Sensor names, serials, full system dumps, unrelated app logs and accounts are not saved. Battery temperature is not CPU/GPU temperature. Missing fields mean unavailable, not zero.

The test APK automatically writes a local `mobile_profile_<timestamp>` folder containing per-frame engine callback intervals, active-gameplay flags, and five-second whole-scene draw/primitive/memory/settings/position counters. Five-second CSV flushing can add small observer overhead; record this limitation. No automatic camera rail, invulnerability, rewards, movement or enemies are changed in the APK.

After the run, pause/background the app to flush its final buffer, then:

```powershell
& $python tools/profile_island_android.py pull --adb $adb --output .validation/phone_run
& $python tools/profile_island_android.py analyze --session .validation/phone_run/mobile_profile_TIMESTAMP --warmup 300 --output .validation/phone_run/analysis
```

`pull` copies only the three profiling files from this debug test package. It does not collect campaign saves, settings, production data or global phone logs. Select the correct timestamp folder. `analyze` rejects Windows/synthetic sessions, excludes paused/resume boundary samples, and reports mean callback FPS, p50/p95/p99/max intervals and counts above 50/100 ms. Review each region and final minutes, rather than relying only on an overall average. The CSV does not directly measure SurfaceView presentation, CPU work per frame or GPU duration.

For actual display pacing/CPU/GPU diagnosis, use **on-device/local Android Studio System Trace/CPU Profiler**, or a local Perfetto workflow focused on this package/SurfaceView. GPU inspection availability varies by device/backend. `dumpsys gfxinfo` alone can miss a native Godot SurfaceView and must not be presented as game FPS. Keep raw traces locally and review for private data before sharing selected results. No cloud trace upload is part of this workflow.

## Screenshots and quality comparison

Capture phone screenshots at forest interior/approach, hills, mountain close-up/overview, river/waterfall, cave exterior/interior, beach and combat. Use native-resolution PNGs. Record matching location, camera direction and quality settings. Compare textures/normals, foliage cutout/mip behavior, LOD transitions, haze/shadows, water, UI safe areas and touch sizes with `docs/island_polish_task4/gallery.html`. Included PNGs are explicitly desktop references, **not Android proof**.

For automated screenshots, first ensure only this test app is visible; use the phone's screenshot gesture or platform-tools `exec-out screencap -p` with binary-safe output handling. Do not capture another app, notifications containing private information or account screens. The provided collector does not automatically take screenshots or global logcat dumps.

## Battery / thermal interpretation and review gate

- For drain estimates, use an unplugged, fixed-brightness controlled interval after warm-up. Report elapsed time, start/end battery percentage and charge-counter fields when supported. Percentage is coarse; repeat runs. Do not infer watts, total energy or remaining battery life from APK size or desktop FPS.
- Compare early and late frame intervals/PSS/thermal status. Note throttling, sustained heat, charging, ambient changes and OS power settings. If sensor access is denied, report it as unavailable.
- Aim for sustained 30 FPS throughout the route and combat; report p95/p99/max spikes and their locations. Agree numeric acceptance thresholds from the measured baseline rather than declaring success from an average alone. Compare optional quality only after the baseline meets the target.
- Return the device/version metadata, sanitized profile results, original gameplay screenshots and touch checklist. A stable 30 FPS, memory/thermal/battery verdict requires those actual A37 measurements. Until then, Android readiness remains **unverified**.
