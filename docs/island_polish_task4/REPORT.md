# Veil of Vera — Task 4: environmental lighting, atmosphere and exploration

Status: existing candidate submitted for visual approval. **Production main map remains unchanged. No Chapter II, next task, commit, push, APK build or commercial-completion claim.**

## Implemented

- One existing directional sun is balanced to a warm, lower-angle daylight key with cooler restrained ambient fill and a coherent sky/horizon. The saved shadow toggle still works. Optional shadows use one orthogonal split and 26 m distance, replacing the broader original shadow setup. No added lights, dynamic GI, shadowed foliage, glow or volumetric effects.
- Standard depth fog adds modest cool atmospheric separation from 40 to 300 m, maximum density 0.25. Forest canopies/trunks remain the approved geometry/materials. Their ground gains approximate locally baked soft canopy shade from the same 72 anchors; this is a static albedo cue, not true dynamic occlusion or an additional transparent shadow pass.
- Original candidate ground/region shader variants soften the existing trail blend, add patchy narrow worn-grass hints along four already traversed approaches, and gently desaturate inland ground. The new mask samples once per fragment; no per-frame route/shade loops. No path or biome geometry is moved. New path paint stops before southern sand, and the original sea shader/mesh is unchanged.
- Two original ground-level exploration details: **Wayfarer Sunwheel** near the western forest approach (-34,15), and **River Compass** beside open river grassland (12,31). Weathered broken slate rings/rays follow actual support with an 18 mm render offset. They are small points of interest for close-range orientation, not new quest objects, rewards, walls or horizon-scale towers. Two extra visual draws and **170 triangles** total, culled after 110 m, no new colliders or shadow casting. Open hillsides and clean shoreline remain.

## Actual visual evidence

`gallery.html` includes **12 matched before/after pairs (24 original native PNGs)**: full island overview, forest interior and approach, grassy hills, mountains, river/waterfall, cave exterior, sand, both landmarks, and two optional-shadow comparisons. All are actual unedited Godot 1280×720 captures with matching poses and settings. The top-down overview intentionally uses far vegetation LODs and a review visibility override so the whole layout can be inspected; it is not a normal player-camera benchmark. Every other view uses existing runtime culling. UI is hidden only for static inspection readability.

`exploration_gameplay.mp4` is a **16-second** actual Godot recording with existing hero/controller, mobile HUD and spring-arm camera. It walks 55.80 m continuously from open grassland approach into the forest and along the woodland path; both legs completed with health preserved. No teleport after initial fixture placement. Five extra original gameplay PNGs are included. The 480 frames are fixed-step offline capture encoded at 30 FPS, **not live FPS or an Android performance measurement**. No frame interpolation, motion blur or audio is added.

## Regression and preservation evidence

**21/21 final checks passed. Failed checks: none.** Raw logs, arguments, timestamps, exit codes and explicit error scans are included in `logs/` and `test_results.json`. Nine candidate checks cover Task 4 budgets/landmark support/shadow preference/beach exclusion, Task 3 geometry and water effects, native forest instance data, vegetation, approved terrain, real-controller movement, all regional connections, collision/camera behavior, cave relic pickup/reload and campaign progression. Twelve original gameplay fixtures retain their original scene context for combat, enemies, boar, campaign, quests/HUD, autosaves, persistent progress and fast travel.

All **47 original collision shapes** and approved ground/river/sea/grotto geometry fingerprints match exactly. The accepted forest/grass system, terrain support data, regional GLBs, mountain/cave/waterfall source, hero/HUD/enemy/combat/quest/save/dragon code and production settings keep their original bytes. The sole pre-existing source changed is a four-line atmosphere hook in `scripts/island_candidate.gd`; `preservation.json` records all baseline hashes and rollback checkpoint. Original map and original island source remain intact.

## Rendering costs

Actual desktop Intel Iris Xe / Godot 4.7.2 GL Compatibility, 1280×720, MSAA off and screen-space AA off, 30 warm-up frames plus 90 measured frame intervals per view. Main comparisons are shadows-off low mobile-quality settings. The last two pairs separately compare optional shadows enabled in both before and after. Whole-scene calls and submitted primitives come from Godot monitors. These scenes primarily use triangle meshes, but submitted primitive counts include all engine-rendered geometry and shadow passes, not unique asset triangle counts.

| View | Calls before / after | Primitives before / after | Median ms before / after | p95 ms before / after | Median-interval FPS before / after |
|---|---:|---:|---:|---:|---:|
| Full island top-down overview | 251 / 251 | 379,583 / 379,583 | 10.958 / 8.518 | 18.809 / 13.349 | 91.3 / 117.4 |
| Forest interior | 50 / 50 | 279,484 / 279,484 | 11.521 / 7.764 | 15.419 / 10.462 | 86.8 / 128.8 |
| Forest approach | 54 / 55 | 252,290 / 252,378 | 9.890 / 8.099 | 11.901 / 10.700 | 101.1 / 123.5 |
| Open grassy hills | 120 / 120 | 418,149 / 418,149 | 7.995 / 7.434 | 11.157 / 10.928 | 125.1 / 134.5 |
| Mountain landscape | 33 / 33 | 171,495 / 171,495 | 5.428 / 4.956 | 8.412 / 7.731 | 184.2 / 201.8 |
| River and waterfall surroundings | 7 / 7 | 119,138 / 119,138 | 3.883 / 5.492 | 6.260 / 9.237 | 257.5 / 182.1 |
| Cave exterior | 51 / 51 | 143,694 / 143,694 | 4.473 / 6.014 | 6.196 / 9.017 | 223.6 / 166.3 |
| Sandy shoreline | 4 / 4 | 114,279 / 114,279 | 3.111 / 4.266 | 6.074 / 6.360 | 321.4 / 234.4 |
| Wayfarer Sunwheel landmark | 50 / 51 | 231,824 / 231,912 | 7.334 / 4.345 | 10.144 / 6.292 | 136.4 / 230.1 |
| River Compass landmark | 22 / 23 | 170,664 / 170,746 | 3.669 / 4.273 | 7.690 / 9.008 | 272.6 / 234.0 |
| Optional shadows — hills | 184 / 141 | 978,982 / 531,303 | 16.698 / 16.666 | 18.948 / 17.165 | 59.9 / 60.0 |
| Optional shadows — forest | 57 / 52 | 588,490 / 360,768 | 17.116 / 16.661 | 20.178 / 17.144 | 58.4 / 60.0 |

| Engine monitor | Before MiB | After MiB |
|---|---:|---:|
| static | 135.41 | 135.63 |
| texture | 260.09 | 261.43 |
| video | 308.85 | 316.29 |


FPS here is 1000 divided by the measured median frame interval during the uncapped stationary desktop fixture; it is not sustained mobile FPS. Frame intervals include CPU/driver scheduling and are not GPU timer traces. Static memory is engine allocations, video/texture are engine estimates, not process RSS or a complete driver census. The one new 512×512 RGBA8 mipmapped mask costs about 1.33 MiB uncompressed; original rock/ground maps are reused. No additional 4K textures or foliage layers.

**Android testing pending:** adb was available but no device was connected. No Android FPS, memory, thermal or battery measurement is reported. Desktop thermal behavior was not measured either. Optional shadow cost and native depth-fog cost still need real low-end Android profiling before release.

The optional-shadow hill view reduces calls from 184 to 141 and submitted primitives from 978,982 to 531,303. Shadows-off geometry stays exact except the visible 82/88-triangle inlays. Some measured views have longer frame intervals after this pass (river, cave and shoreline), despite fewer shadow submissions elsewhere. There is no general FPS-improvement claim. A single stationary desktop run cannot isolate shader cost from driver/compositor/machine variability.

## Diagnostics and remaining limitations

- An initial Task 4 shader variant reused an existing uniform name for a local path variable and failed to compile. It was corrected before final capture; its raw diagnostic is retained under `logs/diagnostics/`. The final native captures and regression logs are checked for shader/script/engine errors. No unresolved regression failures are hidden.
- This is a restrained atmosphere pass, not photoreal final art. Some imported regional silhouettes/bases still look angular or constructed, with grazing-angle dark/green seam slivers, recognizable ground texture tiling and broad empty grass areas. No approved geometry was rebuilt to conceal those defects.
- Cave remains a short, rounded connected grotto with limited physical light occlusion; it is not a final sculpted cave. Waterfall remains a simple mobile cascade with visible sheet/filament structure and sparse impact flecks. No further cave/waterfall redesign was attempted.
- Static canopy shade cannot follow moving foliage or the optional sun shadow exactly. Approved vegetation remains shadow-free for cost; optional shadows come from existing opaque geometry/actors. Single-split shadow resolution/aliasing and shadow fade can be visible.
- The two inlays are intentionally low, decorative and traversable. Grass can overlap their broken edges, and their visibility is strongest nearby. They are not new gameplay systems or large distant navigational silhouettes.
- Haze affects the perceived sea and terrain colors through lighting/atmosphere, while preserving their source geometry/materials. Distant shapes lose contrast; close-range navigation and combat remain clear. Final art acceptance and Android performance are pending.

## Changed files, sources and reproduction

`CHANGED_FILES.json` lists exact runtime, assets, source and test files with hashes; `candidate_patch/` contains copies at repository-relative paths for review in the existing checkout. This patch is not a standalone game export. `ASSET_SOURCES.md` records original local work and existing CC0 texture reuse. No private code/assets/screenshots were sent to external services.

Commands executed: local candidate checkpoint/hash; Godot background mask bake; Godot headless import; native before/after capture (`--rendering-method gl_compatibility --resolution 1280x720`); actual player capture (`--fixed-fps 30`); 21 isolated-profile regressions; ffmpeg H.264 encoding and ffprobe validation; adb availability check; complete ZIP CRC/hash and fresh-folder offline gallery verification. Exact render/test invocation arguments and exits are in `logs/*.run.json`. Review scripts and original procedural mask recipe are in `art_source/island/polish_task4/`.

Stop after Task 4 for visual approval. Production still opens `res://scenes/main.tscn`.
