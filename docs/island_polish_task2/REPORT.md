# Island Visual Polish — Task 2

Status: vegetation candidate ready for visual review. **Production map is not activated. No Task 3, cave, mountain or waterfall redesign was started. This is not a claim of commercial final-art or Android performance approval.**

## Changes

- Replaced the old fused flat/pole-like forest rendering and supplementary leaf rendering with **72 instanced mature tree visuals**, retaining the original tree positions/supports and every original collision shape. Existing Poly Haven textured trunks, varied width/height/aspect/yaw, asymmetric lower/upper canopy lobes and leaf color variation create a more coherent woodland. Tree placement was not moved to make screenshots appear denser.
- Replaced the old three sharp triangular grass planes with curved, narrow, tapered blade clumps, gentle wind and three distance LODs. **12,228 resident clumps in 56 spatial chunks** are not all drawn at once. Near / middle / far bands are 0–16 / 16–32 / 32–46 m from the hero, at 100% / 50% / 22% chunk density; farther grass is hidden. The ground-camera visibility limit is 65 m.
- Density varies by clustered noise, forest floor, open hills and riverbank proximity. Short fern forms and modest leafy shrubs soften forest edges. Trails, quest/pickup visibility areas, combat spaces, the river channel, steep surfaces, sand and the shoreline remain clear. No new trees were planted across the open hills.
- Added subtle grass/soil tone variation and a woodland litter tint using the existing maps. No terrain vertex, river, sea, slope or region transform was changed.
- Trees use three geometry LODs with 38 / 78 / 155 m boundaries, spatial instancing, one trunk material and alpha-scissor leaf materials. Grass/fern geometry is opaque and double-sided. All new vegetation disables shadow casting. Existing non-vegetation lighting and user settings are unchanged.

## Actual screenshots

[Open the seven before/after pairs](gallery.html). All 14 PNGs are native 1280×720 Godot captures. Camera positions, rotations and quality settings match exactly. No generated concept imagery, retouching, image resizing or screenshot recompression was used. The unchanged hero/HUD remain visible in the six ground-level views. Review fixtures hold actors still for repeatable inspection; the real-controller traversal is tested separately.

The top-down view disables distance culling and shows the far tree/grass LOD for an aerial review. It is explicitly **not a normal gameplay performance sample**. This override exists only in the review fixture.

## Collision and gameplay verification

**18/18 final checks passed; zero failed checks.** Six candidate checks cover new vegetation preservation/density/LOD behavior, Task 1 geometry, collision-derived routes, actual tree blocking/cave camera/coast, legacy campaign/saves and actual five-region traversal. Twelve existing combat, enemy, boar, campaign, save, travel and HUD system regressions retain their original test contexts and run from the same final checkout. Final raw stdout/stderr, timestamps, scopes and exit codes are included under `logs/` and `test_results.json`.

- All **47 pre-existing static collision shapes** match the archived Task 1 candidate exactly: transforms, shape parameters/faces and collision layers. They were not removed, weakened or replaced by visual-only trees.
- Render/collision mesh fingerprints of ConnectedTerrain, FlowingRiver, Sea and PlayableGrotto match Task 1 exactly. All five GLBs and `terrain_surface.res` retain their original bytes. Protected construction/support functions are unchanged.
- No new vegetation collider was added; short grass, ferns and shrubs remain non-blocking. Existing player/quest access, combat clearings and clean sand/river exclusion rules pass. The hero walked all five regional approaches outward and back, without damage, fall rescue or teleporting between legs.
- Hero/HUD, enemies, quests, saves, Dark Dragon, original sea shader, project main scene and all region assets are unchanged. `preservation.json` records the scoped checksum check and rollback checkpoint.

## Rendering cost

Configuration held identical: GL Compatibility, 1280×720, 3D scale 1.0, shadows off, MSAA off, screen-space AA off, no new vegetation shadows. This represents a low mobile-quality configuration. Counters and frame intervals were measured on **desktop Intel Iris Xe**, not on Android. Actors were held still, VSync/frame cap disabled for measurement, with 30 warm-up and 90 measured frames per view. Raw data: `before_metrics.json`, `after_metrics.json`, `rendering_comparison.json`.

| View | Draw calls before / after | Primitives before / after | Desktop median ms before / after | Desktop p95 ms before / after |
|---|---:|---:|---:|---:|
| Forest interior | 126 / 151 | 259,936 / 282,682 | 7.67 / 7.40 | 11.03 / 11.72 |
| Forest edge | 124 / 149 | 214,952 / 211,423 | 9.02 / 9.84 | 14.21 / 13.67 |
| Open grasslands | 168 / 174 | 441,318 / 357,044 | 7.09 / 6.73 | 8.81 / 9.84 |
| Hillside vegetation | 143 / 162 | 309,470 / 262,589 | 5.59 / 6.21 | 7.10 / 8.60 |
| Riverbank vegetation | 169 / 178 | 431,702 / 368,240 | 7.67 / 6.57 | 11.24 / 8.93 |
| Sandy shoreline | 116 / 116 | 142,255 / 142,255 | 4.87 / 4.10 | 6.77 / 6.77 |
| Full island overview | 238 / 247 | 471,870 / 399,290 | 6.57 / 7.23 | 8.90 / 9.82 |


Counts cover the whole candidate render, not vegetation alone. Better art is not free: the forest views have more draw submissions and can cost more frame time, even though several open views render fewer primitives. The final tree-material consolidation reduces submissions compared with the first vegetation attempt. These short desktop timing samples are subject to local machine/thermal variation and are **not an Android FPS guarantee**.

Scene-wide texture memory: 262.09 → 262.09 MiB; video memory: 306.88 → 313.05 MiB; static memory: 119.50 → 128.59 MiB. These are engine counters, not phone memory or OS working set.

Mesh budgets (triangles per instance, near / middle / far): trunk [872, 291, 291], canopy [720, 324, 216], grass [25, 9, 3]. The approved solid terrain budget remains unchanged. There are no new high-resolution texture maps, alpha-blended grass carpets, vegetation shadow passes, screen-space effects or per-frame terrain rebuilds. Grass density updates at 4 Hz; terrain-dependent placement is done once during candidate setup.

**Physical-device FPS, thermal behavior, alpha overdraw and startup cost on Android remain unverified.** Device profiling is required before treating this as a mobile release-performance pass.

## Files, sources and rollback

Existing files changed: `scripts/island_landscape.gd` (vegetation hookup/render replacement only), `assets/environment/new_island/land.gdshader` and `region.gdshader` (ground color only). Added runtime module, deterministic LOD resources/shaders/root data, reproducible source and two test/review fixtures are listed in `files_changed.json`.

[Asset sources and licenses](ASSET_SOURCES.md): existing Poly Haven CC0 trunk, bark, leaf and ground art reused; grass/fern recipes and canopy arrangement are original project work. No external service received private code/assets/screenshots. Original map sources and the Task 1 checkpoint are preserved; Task 2's pre-change candidate checkpoint is recorded in `preservation.json`. No branch, commit, push, APK or production activation was performed.

## Known visual limitations / approval boundary

- The woodland still derives from one gnarly tree scan. Repeated branching forms and some close-range bark/low-poly faceting remain visible. Width, height, rotation, canopy and tint variation do not constitute multiple separately authored tree species.
- Distant canopy proxies and grass density switches can pop or look thinner than close foliage. Ferns are intentionally simple opaque geometry. MSAA-off captures expose thin-blade/leaf aliasing. Forest-floor lighting remains relatively flat in the shadow-free mobile-quality preset.
- Original collision geometry is preserved, so higher branch/canopy colliders follow the old source rather than every new moving leaf. No claim of leaf-accurate collision is made.
- Wider island composition and source mountain/cave/waterfall art remain outside this task. The old map remains active. Stop for visual approval before any further polish task or activation.
