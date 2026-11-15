# Task 5.1 — Android performance investigation and correction trial

**Status: investigation and two controlled test APKs delivered. Samsung A37 lag is not yet claimed fixed.** No physical phone was connected to the agent. Owner-reported severe lag is accepted as the problem; desktop tests cannot overrule it. Task 5.2 and later changes are only recorded in `FOLLOW_UP_TASKS.md`.

## Confirmed facts and changes

- Existing `canvas_items` stretch with a 1280×720 design viewport does not enforce a 720p 3D GPU workload. The previous logger recorded a logical viewport but did not establish the Samsung's physical render size. Actual phone dimensions are still unknown.
- Added a **test-build-only, resize-aware 720-pixel 3D height cap** using bilinear 3D scaling; HUD, touch rectangles, camera, art/LOD distances and world geometry remain unchanged. At native heights <=720, it leaves 1.0 scale. The comparison baseline retains native 3D resolution. No resolution option is activated in the production map or normal candidate source.
- Added schema-2 observation of physical window/viewport, requested 3D scale/calculated buffer dimensions, render CPU/GPU backend timing where supported, process/physics monitors, collision activity, memory and initialization time. Extended the existing analyzer; zero timing values become unavailable, not fabricated zero cost. Old frame CSV schema remains supported.
- Fixed reuse of the private Android export profile directory (`exist_ok=True`) so repeat scripted builds can use the same test-signing identity. No key/password is included in source or evidence.

## Desktop controlled evidence — not Android benchmarks

Intel Iris Xe, Godot 4.7.2 GL Compatibility, **measured 1920×1080 physical window and PNG output**, shadows off. Renderer-isolation trials hold player/enemy physics, retain animated visuals and the gameplay HUD, and use native → cap → cap → native order per view. Each trial has 60 warm-up and 120 sampled frames. Numbers below are means of the two per-trial medians, not pooled frame statistics. A separate AI-active diagnostic and vegetation-hidden diagnostic are never retained/shipped.

| Desktop view | Native frame median ms | 720p frame median ms | Native GPU ms | 720p GPU ms | Native render CPU ms | 720p render CPU ms |
|---|---:|---:|---:|---:|---:|---:|
| forest | 16.971 | 14.320 | 14.282 | 11.091 | 4.227 | 6.112 |
| hills | 8.663 | 8.952 | 5.861 | 5.943 | 4.606 | 5.448 |
| mountain | 7.310 | 8.000 | 4.243 | 4.636 | 4.339 | 4.954 |


Raw `desktop_controlled_measurements.json` includes p95 callback intervals, backend GPU/render CPU timing, process/physics samples, draw calls, submitted primitives and engine memory estimates for all cases. Native vs cap retains identical submitted geometry/calls in the render-only pairs, so a pixel-workload effect can be observed without assuming triangles caused the lag. Hiding vegetation in diagnostics changes vertices, overdraw and draw calls together; it does **not** prove which of those dominates. Some views regress when scaling; no universal gain or A37 30 FPS verdict is claimed. GPU clocks/compositor/driver behavior and short sample lengths limit extrapolation.

Two earlier exploratory captures are retained separately under `logs/diagnostics/`: one had DPI/window-clamping ambiguity, and another left AI active during comparisons. They are excluded from the headline table. Final renderer isolation records physical window, viewport and actual PNG dimensions consistently.

## Investigation coverage and unresolved causes

| Area | Evidence / limitation |
|---|---|
| Rendering resolution | Native default and 3D-only cap are implemented and measured separately; 1080p desktop output verified. Actual A37 pixels require new session data. |
| GPU and CPU | Backend render timers enabled where supported; CPU render submission and engine physics/process monitors recorded. Desktop timing is real but not a phone result; engine process monitor is not isolated CPU work. |
| Vegetation / overdraw / LOD | Existing instancing, three tree forms, dither crossfades and distances inspected. Whole-vegetation hidden diagnostic shows a substantial forest rendering contribution, without separating alpha overdraw from vertex/draw cost. No thinning or LOD-distance change retained. |
| Terrain/materials | Draw/primitive costs recorded; existing triplanar normal mapping, waterfall/noise, ground sampling and fog inspected. No approved material/geometry changed. No per-material Samsung GPU attribution yet. |
| Texture/RAM | Engine static/video estimates captured; app PSS collection reused. Estimates are not Android RSS/VRAM. No phone resident-memory/leak conclusion. |
| Collision/AI | Physics timing and activity counters added; separate AI diagnostic retained for analysis. Existing 47 collision shapes and AI/gameplay source are exact. No evidence authorizes a collision/navigation/AI rewrite in this task. |
| Runtime generation | Normal/LOD work is startup-only. A separate desktop microprofile measured **118.317 ms total** across five existing calls; no geometry changed. The complete candidate startup in the rendering fixture includes additional preload/construction/shader activity and must not be attributed wholly to these calls. Android cold/warm startup remains pending. |
| Thermal/power | Device collector records available battery/thermal fields locally. No connected phone means throttling, battery drain and sustained behavior remain unknown. |

## APKs, preservation and verification

`Veil_of_Vera_Task51_Native_Baseline.apk` (A) and `Veil_of_Vera_Task51_720p_Trial.apk` (B) both use the existing `com.hirukshanan.veilofveyra.islandtest` package, ARM64, 30 FPS/off shadows and the same original game/art. Both signatures match each other **and the previous test APK**, allowing in-place updates without clearing the test sandbox. This is a verified package/signature compatibility property; Android save/relaunch behavior still needs the owner retest. Full APK hashes are in `apk_verification.json`.

The two APKs have identical bootstrap/probe bytecode; their experiment JSON differs by native vs 720p request, plus generated export scene/sparse-pack metadata. Internet permission is absent. Existing production package/main scene/preset are unchanged. Final exported payloads were actually loaded in desktop functional tests, checked at 1920×1080, 1280×720 and 1600×900, and their schema-2 CSV writers verified. HUD input/layout rectangles were asserted identical while changing 3D scale. Desktop ETC2-to-RGBA driver fallback warnings occurred and are documented; those runs are packaging checks, not mobile memory/performance evidence.

**21/21 final existing regressions pass.** One initial candidate-campaign fixture completed its assertions but reported a shutdown resource diagnostic; the original logs are retained and an isolated verbose rerun passed cleanly without changing tests/gameplay. This does not establish Android runtime stability. Existing campaign, quest/save/reload, collision/traversal, vegetation, HUD and combat coverage remains intact.

Only the four existing build/profile tooling files changed. `preservation.json` verifies all approved runtime scripts, scenes, assets, tests, production project and export settings retain baseline hashes. No world-scale, river exits, enemy placement, collision fixes, larger buttons, sprint/pinch/settings changes or Dragon changes were made. New analysis fixtures and documentation are original local project work; no new art asset/license dependency or private upload.

## Owner review gate

Follow `A37_RETEST.md`: matched A/B runs, same save/location/settings/temperature, actual window dimensions, CPU/GPU/frame spikes, PSS and available thermal/battery observations. Record separately from timed runs if providing a video. Lower-resolution foliage is softer and can change cutout aliasing; visual quality needs review. Scaling may regress CPU-bound views, so B remains a **reversible experiment**, not an accepted default or proven Samsung fix. Both variants share observer overhead; later non-instrumented/release validation remains necessary.

Actual Android FPS/GPU/CPU/thermal/memory results, screenshots and recordings remain pending. No commercial-completion or stable 30 FPS claim. Stop for Task 5.1 review before world scale or control work.

## Commands and sources

Rebuild using existing `tools/build_island_android.py` with the documented Task 5 tool paths and a fresh external staging directory. Use `--render-height 0` for A or `--render-height 720` for B, and separate output folders. The helper still uses the existing private export profile and preserves source config. Exact import/export/check commands and exits are in the included logs.

Public references: [Godot resolution scaling](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html), [RenderingServer CPU/GPU timers](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html), [Performance monitor semantics](https://docs.godotengine.org/en/stable/classes/class_performance.html). Generic documentation queries only; private code/assets/screenshots were not uploaded. Timing/render trials and existing asset work remain local.
