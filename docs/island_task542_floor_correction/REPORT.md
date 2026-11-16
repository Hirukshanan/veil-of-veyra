# Task 5.4.2 — Cave floor visual regression correction

Dark rocky material ownership is restored throughout the cave entrance floor, curved passage, inner chamber, reserved hall and interior walls. The approved cave geometry, exterior ridge, waterfall, lighting and all gameplay systems retain their baseline data. The correction changes the interior vertex mask and fixes its source generator.

## Root cause and investigation

Physics face probes at five floor locations identified **PlayableGrotto** as the rendered floor. It uses `assets/environment/new_island/task542/rock_transition.gdshader`, with `interior=true` and the exterior ridge blend enabled. The shader first applies dark interior limestone, then its exterior branch blends toward grass/sand using vertex `COLOR.r`.

Blender's new FLOAT_COLOR attribute initialized the chamber's 1,848 vertices to white. The Task 5.4.2 generator marked outer vertices white, but never explicitly initialized the interior to black. Every probed floor triangle therefore had an exterior blend weight of **1**, overriding its earlier dark treatment. This explains why preserving positions alone missed the rendered regression.

The underlying ConnectedTerrain was also inspected. It sits at y=1.32 beneath the sampled cave floor heights of approximately 1.46–3.05 m. It was not the surface covering the tested floor points. Terrain ownership, overlapping support, material assignment, exterior masks and lighting were checked. The existing environment and cave fill-light sources are hash-identical and were not responsible for this change. [Before diagnosis](diagnosis_before.json) and [after diagnosis](diagnosis_after.json) record hit faces, corner colors and underlying support.

## Correction

- Set all 1,848 interior shell vertices to `(0,0,0,1)`, giving floors, walls and ceilings zero exterior grass/sand weight. Retain every other vertex color, including the approved outer slopes and graded entrance band.
- Update the editable `.blend` and both preview/runtime GLB copies. Explicitly initialize the generator's vertex-color layer to black before assigning exterior masks, preventing the same default-value error during future exports.
- Run the corrected generator from the accepted Task 5.4.1 source. Its exported GLB is **byte-identical** to the repaired asset.
- Keep all existing shaders, material assignments, lights, world positions, mesh normals, indices and ordered triangle faces unchanged. Godot verified exact geometry and collision-face equality. The model remains **8,624 triangles**. No additional geometry, light or texture was introduced.

The material shader has zero grass/sand interpolation on interior faces because their three corner weights are zero. A new targeted regression checks the actual supported surfaces in six floor locations plus an interior wall, including the reserved hall's material. Exterior white masks remain present. The reserved hall has visual/material verification only, and its gameplay traversal remains untested.

## Visual and gameplay evidence

Five matched actual Godot before/after pairs include the original 09_passage_preserved, 10_inner_chamber and 11_reserved_hall camera angles, plus exterior and waterfall preservation views. Full camera positions, targets and quality are recorded in each metrics.json. The new walkthrough shows dark rock flooring while the unmodified hero controller enters, collects existing relic 1, traverses the curved passage, accesses the inner chamber and safely returns outside. Health is preserved and there are no teleports after initial fixture placement. Enemy physics is held for recording only.

The walkthrough is 253 actual captured frames at 15 fps playback, approximately 16.9 seconds. It is an offline fixed-step recording and does not establish Android FPS. Original PNG bytes and the encoded H.264 video are included in the review ZIP. [Gallery](gallery.html) and [walkthrough](cave_walkthrough.mp4).

## Final regression results

**28/28 regression programs pass**, including the new material-ownership check, cave collision/camera, river entry/escape, enemy navigation and repeated boar charges, ordinary/heavy combat, quest/relic and campaign progression, autosave/persistent saves, HUD, customization, Settings, sprint and pinch zoom. River entry/escape is **26/26**, with exit code 0 and raw stdout/stderr. Heavy-attack and campaign teardown retain the accepted audio cleanup waits and finish without resource-release errors. [Full results](test_results.json), [river stdout](logs/island_river_escape_check.stdout.log) and [river stderr](logs/island_river_escape_check.stderr.log).

Final recorded runs contain no script, shader or engine errors. Some pre-existing HUD tests emit the filled draw_rect width warning from premium_hud.gd. This warning is documented and unchanged.

## Desktop rendering comparison

Windows / Godot 4.7.2 Compatibility / Intel Iris Xe, 1600×720 native canvas and 720-high 3D, shadows off, 30 FPS cap, held actors. Each view uses 40 warmup and 90 measured frames. Captures ran sequentially after tests and recording completed. Values below show before / after. Frame intervals include pacing. Android performance and physical-phone visibility were not measured.

| View | Draw calls | Submitted primitives | Median frame ms | p95 frame ms | Render CPU ms | GPU ms | Static MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 09_passage_preserved | 125 / 125 | 343823 / 343823 | 33.34 / 33.34 | 33.47 / 33.46 | 2.19 / 1.83 | 5.71 / 5.40 | 135.9 / 135.9 |
| 10_inner_chamber | 71 / 71 | 168556 / 168556 | 33.34 / 33.33 | 33.57 / 33.57 | 1.49 / 1.25 | 3.79 / 3.70 | 135.9 / 135.9 |
| 11_reserved_hall | 10 / 10 | 123241 / 123241 | 33.33 / 33.33 | 33.54 / 33.50 | 0.87 / 0.75 | 3.56 / 3.38 | 135.9 / 135.9 |
| 01_exterior_preservation | 183 / 183 | 190589 / 190589 | 33.33 / 33.33 | 33.45 / 33.44 | 1.87 / 2.05 | 4.28 / 4.22 | 135.9 / 135.9 |
| 05_waterfall_preservation | 130 / 130 | 166096 / 166096 | 33.34 / 33.34 | 33.52 / 33.48 | 1.58 / 1.50 | 5.58 / 5.67 | 135.9 / 135.9 |

Draw calls and submitted primitives are identical in every matched view. Per-view driver video/texture counters are included in [rendering_cost.json](rendering_cost.json). Static allocator counters and driver memory do not represent total Android process memory.

## Changed files

- `assets/environment/new_island/task542/cave_exterior.glb` — interior mask only.
- `art_source/island/task542/Cave_Exterior.blend` — matching editable colors.
- `art_source/island/task542/cave_exterior.glb` — matching preview export.
- `art_source/island/task542/refine_exterior.py` — explicit interior mask initialization.
- `tests/cave_floor_material_check.gd` — actual visible floor/wall ownership regression.
- `art_source/island/task542/floor_correction/` — preserved pre-fix source, patch/reproduction scripts and verification data.
- `docs/island_task542_floor_correction/` — this report, matched captures, video, raw logs and preservation/cost evidence.

The ZIP contains the complete runtime project and required assets for independent candidate-scene review, plus editable sources, the preserved pre-fix model and reproduction scripts. It excludes generated caches and signing credentials. The production main scene setting is preserved. No commit, staging or push was performed for this correction.

## Limits

The current interior uses the existing ambient/fill lighting. Future lantern illumination and Dragon events remain reserved for their quest phase. The prior stylized rock silhouette, texture repetition and some small existing wall seams are outside this floor-material correction. Physical Samsung A37 contrast, visibility and performance still require owner testing. The approved exterior, waterfall, river routes, hero, HUD, combat, quest/save progression and 720p bootstrap have preservation hashes in [preservation.json](preservation.json).

Stop here for owner visual approval.
