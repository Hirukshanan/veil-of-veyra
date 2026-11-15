# Veil of Vera — Task 3: mountains, cave and waterfall

Status: candidate refinement submitted for visual approval. **Production is unchanged. No next task, commit or push was performed. This is not a declaration of commercial finish.**

## Changes

- Mountain and eastern-cliff rock materials now use world-space triplanar original 1K albedo/normal maps, removing stretched imported UV patterns. Slope/height-controlled toes blend into the existing ground. Five visual meshes receive averaged shared-position normals and regenerated visual LODs once during candidate initialization (startup CPU cost is not profiled on Android); every base triangle position/index remains exact. Sharp large-scale outlines are retained for route/collision compatibility.
- A fitted 96-triangle rock mantle connects the existing cave arch to adjacent eastern rock rather than leaving an exposed thin tunnel. The existing connected grotto is retained; a rock floor finish follows the greater of its original floor or approved terrain height with a 14 mm visual offset. A fitted visual end cap closes the rough-vault slit. The existing unshadowed cave fill is tuned, with no new lights. No cave physics shape is changed or added.
- A crest-to-river nonplanar waterfall uses three slightly separating filaments, irregular edges, inexpensive moving texture noise and small alpha-scissor impact flecks copied from existing river-top faces. It ends at the existing upper river. The painted source waterfall is replaced visually by rock beneath the new effect. No riverbed, banks, sea outlet, sea shader or water simulation is changed.
- Added visual geometry: **1,875 triangles**, four small visual meshes, distance-culled at 165 m, no new colliders or shadow casting. Two compressed/mipmapped 1K maps are shared across the scoped rock surfaces.

## Evidence

`gallery.html` contains all seven matched before/after pairs as unedited 1280×720 native Godot PNGs. Camera poses and low-quality settings are identical. Inspection cameras hide HUD for surface readability; they are actual candidate renders. Five extra third-person stills and `cave_gameplay.mp4` show the unmodified hero/controller/HUD inside this candidate.

The 12-second H.264 clip contains 360 captured viewport frames, native spring-arm follow, real walking input from (76,1.58,-10) into the same cave, and collection of existing relic ID 1. Health remains unchanged, with hero height 1.406–1.734 m. Initial scene placement is a review fixture; no recorded traversal teleports are used. Fixed-step 30 FPS encoding is **not live or Android FPS**. No audio or frame interpolation is included.

## Final regressions and preservation

**20/20 checks passed. Failed checks: none.** `test_results.json` and raw stdout/stderr/run records are included. Eight candidate checks cover this task's visual/collision budget, forest GPU forms, vegetation, terrain, island construction, real cave movement/relic/save reload/campaign progression, collision/camera behavior and all five regional connections walked outward and back. Twelve existing gameplay fixtures cover combat, boar, enemies, campaign, saves, travel and quest/HUD behavior in their original fixture contexts.

All **47 original collision shapes**, approved terrain/river/sea/grotto vertex/index fingerprints, regional GLBs and the terrain support resource remain identical. No new physics objects. Task 2.1 vegetation sources/resources, hero/HUD, enemies, combat, quests/saves and dragon retain their original bytes. The sole changed pre-existing source is a four-line candidate-only module hook in `island_landscape.gd`; rollback checkpoint is recorded in `preservation.json`.

## Rendering cost

Actual desktop Intel Iris Xe, Godot 4.7.2 GL Compatibility, 1280×720, shadows off, MSAA off, screen-space AA off. Each view has 30 warm-up frames then 90 measured frame intervals; actors held still and HUD hidden in both runs. Whole-scene draw calls and submitted render primitives are engine monitors; these are triangle-based mesh scenes, not a GPU time trace. Timings include CPU/driver scheduling and desktop variability. No other benchmark ran concurrently. New shaders add rock normal samples; low draw counts do not alone prove low Android GPU cost.

| View | Draw calls before / after | Render primitives before / after | Median ms before / after | p95 ms before / after |
|---|---:|---:|---:|---:|
| Mountain overview | 29 / 31 | 170,060 / 171,443 | 3.321 / 3.531 | 4.508 / 4.754 |
| Mountain texture close-up | 5 / 7 | 117,755 / 119,138 | 2.848 / 2.840 | 3.809 / 3.804 |
| Mountain-to-terrain connection | 12 / 14 | 161,951 / 163,334 | 3.529 / 3.504 | 5.006 / 5.204 |
| Cave entrance | 49 / 51 | 143,202 / 143,694 | 3.222 / 3.213 | 4.094 / 4.281 |
| Cave interior | 40 / 42 | 148,560 / 149,052 | 3.876 / 3.957 | 5.464 / 6.648 |
| Waterfall from distance | 5 / 7 | 117,755 / 119,138 | 2.909 / 3.471 | 5.121 / 5.750 |
| Waterfall/river connection | 5 / 7 | 117,755 / 119,138 | 2.938 / 3.506 | 4.146 / 4.524 |

| Monitor | Before MiB | After MiB |
|---|---:|---:|
| static | 130.71 | 135.73 |
| texture | 263.43 | 260.09 |
| video | 316.48 | 314.94 |


Memory values are Godot monitors, not Android RSS or a complete driver allocation census. Texture/video totals can decrease because scoped rock materials stop retaining some old regional albedo bindings; unchanged original files remain for rollback. New 1K maps include S3TC and ETC2 compressed mip variants; exact source/import sizes are in `texture_usage.json`.

**Android testing pending:** local adb was available but no device was attached. No APK was built and no Android FPS, memory or thermal claim is made.

## Capture diagnostic

One initial final-view capture wrote all seven images and counters, then exited with Windows access-violation code 0xC0000005 during shutdown. The capture fixture was changed to let SceneTree own final cleanup instead of explicitly queuing scene deletion and awaiting another draw. The final clean rerun and gameplay run are recorded separately in the final logs; the original failed invocation is retained in `logs/diagnostics/`. The underlying cause is not proven; this was a capture-process failure, not a regression assertion. Final evidence must have clean zero exits before packaging.

## Remaining limitations

- Imported mountain silhouette still has angular peaks and some existing cut/graded surfaces show narrow dark cracks or green slivers at grazing angles. Normal/material work softens shading, not the protected terrain/collision topology. These are visible in the uncropped evidence; not claimed repaired.
- Cave entrance is more integrated but retains a rounded, deliberately wide existing vault shape; it is not a hand-sculpted production cave. Small grass slivers can remain along the wall/floor perimeter, and ambient daylight is not physically occluded. Lighting is restrained without expensive dynamic cave shadows.
- Waterfall is a small stylized mobile cascade, not volumetric water. Crest/edge segmentation and flat source-rock geometry remain visible close up. Impact uses sparse flecks; no mist, physical spray, refraction or real-time fluid simulation. Existing river appearance/geometry remains as approved.
- Added outer mantle is visual-only over the existing cave/rock collision envelope. It is not a new walkable rooftop or additional playable route; all original traversals remain unchanged. Any future collision redesign requires separate approval.
- Screenshots and native desktop counters require visual review. Android cost and final art acceptance remain pending.

## Files and commands

`CHANGED_FILES.json` lists the exact Task 3 runtime/source/test files and hashes; `ASSET_SOURCES.md` records provenance. `candidate_patch/` contains their review copies with repository-relative paths. It is a patch for the current candidate checkout, not a standalone exported game. Original source island/old map and previous approved work remain intact.

Commands executed locally: Blender background `--threads 6 --disable-autoexec --python-exit-code 1 --python bake_task3_rock.py`; Godot `--headless --editor --import`; seven-view native capture using `--rendering-method gl_compatibility --resolution 1280x720`; native controller capture with `--fixed-fps 30`; 20 regression scripts with isolated APPDATA and VEYRA_TEST=1; ffmpeg H.264 encoding and ffprobe stream validation; adb device availability check; archive CRC/SHA and fresh-folder offline gallery validation. Exact test/render invocations and exit codes are in `logs/*.run.json`.

Stop here for visual approval. Production still launches `res://scenes/main.tscn`.
