# Phase 6.2.1 — transition and import investigation

## Status: partial fix; performance approval remains blocked

The final runtime keeps safe rendering/input-independent optimizations and the editor import workaround. **Cold Windows shader-linking stalls remain.** Automatic shader preparation is not enabled: although its measured cinematic playback reached 32–38 ms maximum in two uncapped runs, it increased cold loading and did not meet the owner's startup constraint. This report does not declare the cinematic fully fixed or mobile-ready.

The approved cinematic sequence, hero, single crimson eye, wall motion, audio sources, timing, Skip, quest gating, permanent passage and version-4 persistence remain intact. No production activation, boss work, Chapter II or APK build was performed. The preceding Phase 6.2 work was committed by the owner as `72b39e1`.

## Confirmed cause and ruled-out work

Instrumented live process-frame intervals place the multi-second delays inside the rendering span between Godot's pre-draw and post-draw signals. The original uncapped baseline reproduced a 4,048 ms placement frame; an on-screen matched mobile-quality baseline is tabulated below. GDScript sampling stayed below about 1 ms in the diagnostic run; start-save took 10.3 ms and finish-save 5.9 ms. Cue work, including console output and audio play calls, was single-digit milliseconds. Geometry is created during scene initialization, not at transition cues. Wall collision disabling was not a multi-second bottleneck.

A local graphics-call capture/replay found synchronous `glLinkProgram` calls up to 1,133 ms, with about 51.4 s aggregate linking across the whole captured startup/playback. Texture uploads were much smaller. Replay timing is diagnostic evidence, not gameplay FPS. The full GPU trace stayed local and is excluded from this package. The same-process second playback dropped to a 22.6 ms maximum, while rendering-disabled execution had no multi-second transition stalls. Together these identify first-use graphics program linking/specialization as the dominant cause on the installed Intel native OpenGL driver.

Placement reveals newly lit geometry/material combinations. Descent first displays the dust renderer; cracks first display their material. Camera travel changes visible render states; darkness first displays the eye shader. The historical “music cut” spike occurred around 17.3 s, when the hero camera returned, not at the 15.7 s `music.stop()` call. The final code turns off the already-hidden lantern light before returning to gameplay and limits cinematic lights to the cave, event props and hero.

Godot documents the Compatibility renderer's first-use compilation limitation and rendering resources during loading as its workaround. [Official stutter documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html). Our exact-view preparation experiment worked during playback but introduced unacceptable loading costs; it is retained as rejected evidence, not silently enabled.

## Final safe changes

- `scripts/lantern_awakening.gd`: a bounded cinematic camera view containing the existing cave, hero and event props; 50 m cinematic far distance; isolated event light masks; redundant light disabled before camera return; preloaded fracture sound; opt-in operation timing; unlit dust material and redundant unshaded flame-emission flag removed. Particle count, color, motion, timing and geometry remain unchanged.
- `project.godot`: `editor/import/use_multiple_threads=false`, an editor-only workaround validated with independent fresh extractions.
- `tests/cinematic_transition_profile.gd`: portable, isolated-save live profiler with pre-load mobile settings, uncapped and 30 FPS modes, every frame, rendering spans, audio playback positions and transition data.
- This evidence directory: raw logs, diagnostics, screenshots, movie and reproducibility material.

The island candidate script itself is unchanged from Phase 6.2. No automatic preparation screen or hidden warmup is shipped. No new model, texture or sound asset was introduced; existing licenses remain unchanged. The temporary compact rock shader and ANGLE/default-driver changes were rejected and removed.

## Live Windows measurements

1280×720 landscape, existing 720-high 3D/native HUD approach, shadows off **before scene creation**, V-Sync disabled. The first two final runs are uncapped; the last is capped at 30 FPS. Actors are held for controlled framing, as in the baseline. Every run uses an isolated synthetic save and fresh Godot user shader cache. The OS/driver cache was not manually cleared. Measurements describe Windows Intel Iris Xe, native OpenGL 3.3, driver 30.0.101.1404, Godot 4.7.2. They do not establish Samsung performance.

All triplets below are **p95 / p99 / maximum milliseconds**; quantiles use nearest rank. Rare severe stalls can coexist with a low p99, so maxima and raw intervals must also be reviewed.

| Run | Cinematic p95 / p99 / max ms | Frames >100 ms | Setup + common settle s | Largest setup frame ms |
| --- | ---: | ---: | ---: | ---: |
| visible_mobile_before_retry | 5.01 / 5.99 / 3413.42 | 5 | 32.11 | 22941.10 |
| default_safe_1 | 5.04 / 5.99 / 2634.30 | 4 | 47.01 | 36731.71 |
| default_safe_2 | 7.79 / 10.29 / 4864.73 | 4 | 52.36 | 39116.86 |
| default_safe_cap30 | 33.60 / 34.30 / 5355.31 | 4 | 55.57 | 39926.96 |

The setup interval includes scene creation and the same fixed-frame/two-second settling protocol. It is not an Android launch-time estimate. See `live_performance.json` and `live/` for every interval, CPU/GPU counters, memory counters and audio-clock samples.

| Transition window | Matched before | Final uncapped 1 | Final uncapped 2 | Final 30 FPS |
| --- | ---: | ---: | ---: | ---: |
| Placement | 5.79 / 6.71 / 3413.42 | 5.54 / 6.31 / 2634.30 | 6.39 / 13.08 / 4864.73 | 34.17 / 5355.31 / 5355.31 |
| Descent / dust | 5.87 / 6.97 / 1176.83 | 5.66 / 6.68 / 538.14 | 7.70 / 11.22 / 514.07 | 33.57 / 542.83 / 542.83 |
| Spreading cracks | 4.31 / 5.11 / 418.47 | 4.47 / 5.35 / 8.43 | 8.51 / 10.60 / 14.06 | 33.46 / 33.58 / 33.58 |
| Wall break | 4.44 / 5.43 / 9.44 | 5.36 / 5.99 / 27.25 | 7.16 / 10.86 / 11.87 | 33.44 / 33.46 / 33.46 |
| Roar | 4.58 / 5.63 / 9.30 | 4.97 / 5.31 / 8.26 | 8.78 / 10.72 / 10.81 | 33.54 / 34.21 / 34.21 |
| Passage camera | 4.89 / 5.46 / 593.46 | 4.92 / 5.55 / 8.79 | 8.65 / 10.29 / 12.62 | 33.55 / 34.22 / 34.30 |
| Darkness | 2.46 / 2.91 / 427.61 | 3.89 / 4.75 / 636.44 | 4.80 / 5.66 / 631.96 | 33.50 / 633.84 / 633.84 |
| Eye opening | 2.53 / 2.89 / 7.81 | 2.87 / 3.30 / 5.30 | 5.41 / 6.30 / 9.68 | 33.52 / 34.25 / 34.25 |
| Music cut | 2.56 / 3.13 / 7.05 | 2.77 / 3.13 / 8.47 | 5.02 / 6.06 / 10.31 | 33.88 / 33.89 / 33.89 |
| Hero camera return | 5.34 / 6.39 / 6.92 | 6.92 / 7.50 / 156.87 | 9.99 / 725.91 / 725.91 | 570.58 / 570.58 / 570.58 |
| Completion / save | 24.60 / 24.60 / 24.60 | 40.04 / 40.04 / 40.04 | 73.85 / 73.85 / 73.85 | 65.90 / 65.90 / 65.90 |

## Rejected alternatives and remaining limitations

An ANGLE driver trial increased the placement stall to about 10.4 s; the project remains on its original renderer/driver setting. Disabling shader caching or lowering light-loop limits did not solve cold linking. Generic small-viewport warming missed actual render states. Exact main-view preparation removed playback freezes, but added roughly 5–10 s to setup in recorded runs and still had cold steps around 0.6 s. A broader staged initial-view trial was worse and was also removed. These failures are included under `diagnostics/`.

**The current cold transition target is not met.** Driver/compiler behavior needs an external change or an owner-approved loading tradeoff before full approval. No driver update or engine replacement was performed. Audio cue order and actual engine audio are retained, but cold rendering stalls can still let audio advance ahead of the animation clock. Playback-position offsets are reported honestly rather than declaring perfect live synchronization. Startup costs and occasional native shutdown failures also remain documented. There is no measured Android FPS, memory, thermal or battery result.

The movie was recorded during this task from the preparation-enabled diagnostic build, before its startup preparation was rejected and removed. The cinematic body is unchanged in the final safe runtime; the recording is labelled with this provenance. It is a Godot movie-writer capture at fixed 20 FPS with actual engine audio. It proves the in-engine sequence and appearance; it intentionally is **not** live-performance evidence. Live timing comes from the independent uncapped/capped runs. Original PNGs are preserved.

## Import reliability

Three controlled fully fresh threaded imports produced two successful exits and one `0xC0000005` native crash. The earlier review package also recorded a fresh-import crash at the font stage. Windows application-error records locate those import faults in the Godot executable. One later runtime profiling attempt faulted during native shutdown; it is separately retained and must not be confused with the importer failure.

Two controlled full fresh serial imports passed before final packaging; final ZIP validation adds independently extracted serial-import results. Twelve font-only diagnostic fixtures (six threaded and six serial) all passed, so a particular font alone was not shown to be corrupt. A related upstream native importer race exists, but the exact C++ fault is not established without symbols; different recorded fault offsets are preserved. [Related Godot import issue](https://github.com/godotengine/godot/issues/111039). The safe workaround is serial import, not retrying a partially populated cache and calling it a fresh pass.

## Functional verification and reproduction

All 14 regression programs passed during this investigation with exit 0 and no final script/shader/engine errors: complete event and Skip, prerequisites, cave traversal/collision, camera clearance, immunity, quest progression, old saves, atomic saving, world/campaign state, river escape, repeated Boar attacks, heavy combat, gestures, HUD customization and Settings. The pre-existing filled `draw_rect` width warning remains; HUD source was preserved. The current safe rollback reran the focused event/Skip/save test. Remaining records are from the earlier Phase 6.2.1 build; its headless preparation path is a no-op and was removed without changing the tested gameplay logic. The full suite was not repeated again after that removal, to avoid redundant time and token use. Build provenance is explicit in `test_results.json` and raw `logs/`.

Extract this archive, open `gallery.html`, and read this status before approving. The supplied `project/` is the current safe candidate. Its main production scene remains `scenes/main.tscn`; run `scenes/island_candidate.tscn` explicitly for candidate review. `REPRODUCE.md` supplies isolated-profile commands. No commit, push or production activation was performed for Phase 6.2.1. Stop for the owner's review.

## Final ZIP validation

The extracted gallery loaded all 24 original PNGs. All supplied manifest hashes matched. Fresh serial imports passed 1/1 with no partial-cache retry. The already supplied current focused regression was not repeated. Exact exits and logs are in package_validation.json and package_checks/. Cold-transition performance remains unapproved.
