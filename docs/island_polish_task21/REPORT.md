# Veil of Vera — Task 2.1 Forest Refinement

Status: existing candidate ready for visual review. **Production map is not activated. No Task 3 or unrelated gameplay/art work was started.**

## What changed

- **Three distinct authored forms:** Broad Fork, Tall Column and Leaning Crown, 24 trees each, at the same 72 accepted anchors. Original curved branch geometry uses smooth voxel-union forks and root collars. Non-linear position/normal variants produce different width, height and lean, rather than only scaling one silhouette. A common master/mesh/material per LOD keeps all forms in the existing spatial MultiMesh batches; no individual tree draws were introduced.
- **Fuller crowns and better branch transitions:** locally baked multi-leaf twig clusters attach around authored branch tips, with broader upper forks and distinct crown profiles. Individual twig proportions are corrected independently of tall-tree scaling. Existing bark diffuse/normal maps add surface detail; the canopy uses one new 1K cutout atlas.
- **Grass:** near blades have five curved sections instead of three, a smoother width profile, softer contrast and stable per-clump tint across LODs. Accepted grass positions and all exclusion areas are byte-identical to Task 2.
- **Reduced LOD jumps:** complementary opaque dither crossfades replace abrupt tree/grass switches; grass density ranks shrink progressively and distant clumps shrink out instead of disappearing as a whole batch. Tree bands blend over 32–44 m and 72–84 m, with a far fade at 145–162 m; grass blends at 10–22 m and 28–40 m, fading out over 44–54 m. Colors remain consistent between levels. Conservative render bounds cover taller/leaning forms so they do not clip at view edges.

## Actual visual evidence

[Gallery](gallery.html): seven matched before/after pairs (14 original PNGs): forest interior, forest edge, bark, canopy/branches, approach from grassland, grass close-up and top-down forest coverage. All are actual Godot candidate renders at 1280×720 with identical camera poses. Images are unedited and retain their original PNG bytes. Bark/canopy/grass close-ups hide UI only in the inspection fixture. The forest overhead view overrides distance culling and uses distant vegetation LODs; it is not a normal gameplay benchmark.

[Moving-camera test](forest_lod_motion.mp4): 360 actual viewport frames, encoded as a 12-second 1280×720 H.264 clip at 30 FPS, without audio, frame interpolation or motion blur. It is a fixed-step accelerated inspection rail, **not live or Android FPS evidence**. Both near/middle and middle/far tree transition bands are crossed. The CPU reference of the shader blend targets changes by at most 0.04429 per captured frame; this is a mathematical coverage check, not a pixel-level popping measurement. Native video remains the visual evidence.

## Verification and preservation

**19 final checks passed; no unresolved failed checks.** Native GL Compatibility validation confirms all three instance form values and distinct authored mesh bounds. The other regression fixtures cover retained vegetation placement/density, original collisions, Task 1 terrain/water, actual player movement, campaign/saves, combat, enemies, boar rewards, travel and HUD. The 12 original-system regressions retain their original scene contexts; seven checks target the candidate directly. Raw final stdout/stderr, scopes, arguments and exit codes are in `logs/` and `test_results.json`.

- All **47 original static collision shapes** and approved ground/river/sea/grotto mesh fingerprints match the accepted baseline exactly.
- Accepted grass positions match the previous runtime exactly; checksum `0eab2ccb8181dea180b6e52a233f68b4b3a524d3ecb001ced1c19cfd758bd584`. Forest anchors, walking/quest clearings, open hills and sand exclusions are preserved. Real-controller traversal still walks all five regional approaches outward and back without damage, fall rescue or teleporting between legs.
- Hero, HUD, enemies, quests, save code, Dark Dragon, sea, cave, mountain, waterfall, regional GLBs, terrain surface resource and production main-scene settings retain their original bytes. `preservation.json` records the scoped comparison.
- The existing vegetation test was adapted to overlapping LOD visibility and shader density, and reads the actual refined resources. Its collision, shoreline, clearing and movement checks remain. Early verifier setup issues (dummy-renderer custom-data readback and a float-array type assumption) were corrected; native form verification now passes. Initial diagnostics are retained separately under `logs/diagnostics/`.

## Before / after rendering cost

Matched low mobile-quality configuration: GL Compatibility, 1280×720, shadows off, MSAA and screen-space AA off, no vegetation shadow casting. Measurements are from desktop Intel Iris Xe: 30 warm-up and 90 sampled frames per view with actors held still. Counts cover the whole candidate. Desktop timings can vary with machine load/thermal state and **do not establish Android performance**.

| View | Draw calls before / after | Primitives before / after | Desktop median ms before / after | Desktop p95 ms before / after |
|---|---:|---:|---:|---:|
| Forest interior | 151 / 163 | 282,682 / 325,681 | 5.80 / 8.20 | 6.86 / 11.34 |
| Forest edge | 149 / 169 | 211,423 / 268,614 | 8.08 / 8.03 | 10.16 / 11.60 |
| Bark close-up | 33 / 39 | 222,935 / 239,630 | 4.95 / 6.10 | 5.93 / 8.15 |
| Canopy / branch close-up | 27 / 34 | 197,580 / 203,148 | 8.42 / 7.72 | 10.63 / 10.75 |
| Approach from grassland | 164 / 184 | 255,030 / 332,457 | 5.77 / 5.72 | 7.08 / 8.06 |
| Close-range grass | 43 / 57 | 210,522 / 250,067 | 4.21 / 5.01 | 5.04 / 6.69 |
| Top-down forest coverage | 155 / 157 | 242,074 / 220,237 | 4.92 / 5.50 | 5.82 / 8.17 |


Texture memory: 262.09 → 263.43 MiB; static memory: 128.60 → 130.39 MiB; video memory: 317.11 → 318.50 MiB (engine counters, not OS working set or phone memory).

Near/middle/far triangles per instance: trunk [1049, 427, 119]; canopy [238, 136, 68]; grass [36, 9, 3]. Crossfade overlap and finer near grass add render work even though canopy LOD geometry is smaller. Three forms still use the same **12 near spatial part-batches**, not a separate draw per tree. No new shadow or screen-space rendering passes were added. One new 1K atlas is compressed/mipmapped; grass stays opaque and tree transitions use dither discard rather than alpha blending.

**Android results: not measured.** No APK/device FPS, thermal or phone overdraw result is claimed.

## Sources and changed files

[Asset sources/licenses](ASSET_SOURCES.md): original project-authored trunks, forms, grass and twig arrangement; existing Poly Haven CC0 leaf/bark/normal scans reused. No new third-party model, private upload or AI concept imagery was used as model proof. Editable source and reproducible Blender/Godot recipes are in `art_source/island/polish_task21/`.

Existing runtime change: `scripts/candidate_vegetation.gd`. Existing verification change: `tests/island_vegetation_check.gd`. New refined assets/shaders, source and review/test fixtures are listed in `files_changed.json`. Task 2 assets and the pre-refinement rollback checkpoint remain available. No branch, commit, push or production activation was performed.

## Remaining limits and approval boundary

The forms share one consistent leaf/bark style and a master branch graph; they are not three botanical species. Bark tiling and planar twig cards remain visible at very close range. Dither transitions can show fine grain, especially in motion without antialiasing; fine grass/leaf edge aliasing is reduced in appearance, not eliminated. The shadow-free mobile preset remains relatively flat. Upper branch/canopy physics deliberately retain the original collision geometry instead of tracking every new visual leaf.

The forest is fuller but still preserves deliberate walking/combat gaps. Performance costs increased in several close views and require physical-device profiling. Wider island composition and all excluded systems remain outside scope. **Stop here for explicit visual approval.**
