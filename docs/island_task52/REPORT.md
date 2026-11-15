# Veil of Vera — Task 5.2 review

Candidate-only scale, river-access and collision corrections are implemented and ready for owner review. Production main scene remains `res://scenes/main.tscn`. Task 5.3 has not started. This is not a commercial-completion claim.

## A — Measured scale

One Godot unit is treated as one metre. The unchanged hero physics capsule is 1.80 m high, radius 0.42 m. Visible-model runtime mesh bounds measure approximately 1.87 m high; animated bounds are conservative, not a skeletal anthropometric measurement.

The mountain summit is 12.83 → 24.72 m above world zero. Only elevated northern mountain vertices are raised, with smooth perimeter/river exclusions. The open hill at (-14,-8) receives up to 3.2 m of local uplift; grassland regional maximum becomes 6.97 → 9.16 m. Region X/Z, island footprint and geographic connections are unchanged. No whole-GLB scale is applied.

The existing waterfall is extended with the same selective height function, retaining its footprint and impact pool. Its actual mesh height is 3.78 → 7.55 m, with unchanged maximum width 3.22 m. Full bounds are in `before_measurements.json` / `after_measurements.json`. The river surface levels, centre line, width function, flow shader and estuary/sea connection are retained. Its z-span is 186 m (-68 to118), excluding the waterfall. Typical channel width is approximately 4–6 m, widening into the estuary. The winding centre-line length is longer than its z-span.

The playable vault already has 5.2 m width, 3.8 m maximum clear height and 16 m length; it stays unchanged. Grounded camera clearance and actual cave traversal/save reload were tested. Render meshes and their collision shapes are built from the same corrected vertices.

Region AABB extents in metres (include buried/support/source geometry, not exclusively walkable area):

| Region | Before XYZ extent | After XYZ extent | Maximum world Y |
|---|---|---|---|
| EasternCaves | (48.25, 9.888481, 50.16567) | (48.25, 9.888481, 50.16567) | 8.25 → 8.25 |
| RiverGrassland | (65.0, 8.519792, 65.0) | (65.0, 10.71388, 65.0) | 6.97 → 9.16 |
| SouthernBeach | (86.25, 6.633791, 73.75) | (86.25, 6.633791, 73.75) | 4.31 → 4.31 |
| WaterfallMountains | (67.5, 18.81851, 66.25) | (67.5, 30.70392, 66.25) | 12.83 → 24.72 |
| WesternForest | (50.27635, 23.81788, 64.7158) | (50.27635, 23.81788, 64.7158) | 13.12 → 13.12 |

The shared terrain sampling domain is 240 × 240 m, including submerged perimeter. This is not a claim that every square metre is dry or traversable. The ten real-controller regional approach/return legs verify intended routes.

## B — River escape

Before: 20/26 walking entry-and-return fixtures passed. Upper-course entries/exits at z=-62,-52,-40 reproduced failures. Both the abrupt outer banks and steep bed of the narrow winding channel contributed.

After: **26/26 normal walking entries and escapes passed**, at 13 positions on both banks from z=-62 through105. No jumping, damage, rescue reset or teleport was used during a fixture. Only independent fixture initialisation places the hero at its starting bank. Tests use the unchanged real player controller at 4× simulated time, not a surrogate capsule motor.

The upper bed is approximately 0.75 m deep, blending back to the original 1.45 m depth below the gorge. The upper banks use broad graded shoulders, up to 24 m outside the water edge, fitting the surrounding elevations. Obsolete overlapping rock faces are removed from that corridor; existing shared terrain owns the visible ground and collision. No invisible platforms or arbitrary teleport exits were added. The downstream bed, sea and water materials remain unchanged.

Start bank positions and actual movement outcomes are in `river_movement.json`; these are real terrain slopes, not special trigger locations:

| River z (m) | Bank | Tested bank endpoint XYZ (m) | Entry / walking escape |
|---|---|---|---|
| -62 | west | (-5.134206, 2.938726, -62.0) | Pass / Pass |
| -62 | east | (17.46092, 1.501898, -62.0) | Pass / Pass |
| -52 | west | (3.738342, 1.245703, -52.0) | Pass / Pass |
| -52 | east | (25.69546, 1.048727, -52.0) | Pass / Pass |
| -40 | west | (10.01022, 0.001703, -40.0) | Pass / Pass |
| -40 | east | (32.30392, 0.60895, -40.0) | Pass / Pass |
| -25 | west | (14.12903, 2.887472, -25.0) | Pass / Pass |
| -25 | east | (37.92283, 2.721125, -25.0) | Pass / Pass |
| -10 | west | (16.51082, 2.274645, -10.0) | Pass / Pass |
| -10 | east | (39.47449, 2.754892, -10.0) | Pass / Pass |
| 5 | west | (13.71222, 2.30612, 5.0) | Pass / Pass |
| 5 | east | (37.44279, 2.387594, 5.0) | Pass / Pass |
| 20 | west | (9.256392, 2.983591, 20.0) | Pass / Pass |
| 20 | east | (32.54395, 2.063223, 20.0) | Pass / Pass |
| 35 | west | (6.437733, 2.316816, 35.0) | Pass / Pass |
| 35 | east | (29.69383, 1.371061, 35.0) | Pass / Pass |
| 50 | west | (7.686308, 1.678602, 50.0) | Pass / Pass |
| 50 | east | (31.43764, 0.675806, 50.0) | Pass / Pass |
| 65 | west | (12.59527, 1.451761, 65.0) | Pass / Pass |
| 65 | east | (35.55593, 0.622862, 65.0) | Pass / Pass |
| 80 | west | (15.75619, 1.761152, 80.0) | Pass / Pass |
| 80 | east | (39.53423, 0.542708, 80.0) | Pass / Pass |
| 95 | west | (14.72908, 0.531622, 95.0) | Pass / Pass |
| 95 | east | (39.54669, -0.273153, 95.0) | Pass / Pass |
| 105 | west | (9.824873, -0.854357, 105.0) | Pass / Pass |
| 105 | east | (39.36611, -1.065966, 105.0) | Pass / Pass |

## C — Solid scenery collisions

The unchanged wolf controller detects layer1; supplementary tree cylinders were on layers4/8 only. They now also advertise layer1. The hidden fused prototype forest shape no longer matched the approved instanced trees; that inaccurate collider is removed, while its original source is retained for rollback. Thirty-five missing mature-root proxies now match the original visual anchors. The 37 valid supplementary cylinders are retained. Simple cylinders avoid dense per-tree mesh collision.

The existing visual-only 96-triangle cave entrance mantle is now solid; the established walking corridor is unchanged. The existing coastal guard is also detectable by wolves. Mountain render/collision vertices match the selective feature and bank corrections. No new AI/navigation system was added; existing collision-based movement is preserved.

Final static shape count: 47 -1 inaccurate hidden forest shape +35 missing trunk proxies +1 cave mantle = **82**. The two EasternCaves shapes and playable grotto remain byte-identical. Other differences are the documented terrain/collision-layer corrections. Historical approved baselines are preserved; four preservation tests now allow only the Task 5.2 corrections while retaining their visual, water, cave and budget checks.

Actual hero movement tests contact a tree and cave wall; the real wolf chase controller is blocked by a tree. Real wolf and boar bodies were swept into exposed mountain, eastern rock/cliff and cave faces using their actual shapes and `move_and_slide`; AI is held only for these isolated collision sweeps. These sweeps verify physical collision, not intelligent route planning. All cases contact solids. Sixteen spring-arm camera poses are clear.

All six existing enemy/boar spawn positions are unchanged. Their actual collision shapes are clear of solid scenery. A small 3 m support adjustment under the long boar capsule fixes a pre-existing slope overlap at the same spawn; neither the enemy nor its gameplay settings is moved.

## Regression evidence

**23/23 final suites passed without script/shader/engine errors.** This includes the 21 existing regressions plus the two new river/collision suites. Five-region controller traversal completed outward and back, without teleports between legs, fall/rescue or damage. Cave entry, relic collection, quest/campaign progression, save/reload, persistent pickups, fast travel, HUD and combat regressions passed in their documented fixture contexts.

Earlier failed exploratory checks are retained in raw logs. Two existing audio fixtures initially passed their assertions but emitted exit-time resource warnings. Their test-only teardown now waits 0.25 s for mixer release, following the other audio fixtures; final rerun is clean. No gameplay/audio behavior was changed.

`test_results.json`, `collision_tests.json`, `geometry_check.json`, `connection_walk.json`, `preservation.json` and raw `logs/` provide the evidence. Automated fixtures are desktop/headless tests, **not phone playtests**. They cover representative solids/exits/routes and do not prove every possible motion at every island coordinate.

## Rendering cost — desktop comparison only

Accepted 720p rendering bootstrap and profiler bytecode are identical to the owner's accepted B APK. Physical output is1920×1080; only the 3D buffer is capped at1280×720. Native HUD layout is unchanged. Shadows off, GL Compatibility. Each view uses 60 warmup+120 measured frames, frozen actor physics for render isolation. No concurrent regression/build workload ran during these samples. Single before/after trials are indicative; several measured frame intervals increased despite similar draw submissions, so a phone retest is required; animated shader phases and ordinary timing variance remain.

| Matched view | Draw calls before → after | Submitted primitives before → after | Median frame ms before → after | Median GPU ms before → after |
|---|---:|---:|---:|---:|
| 01_mountain_scale | 123 → 123 | 177460 → 176853 | 8.55 → 8.37 | 3.52 → 3.92 |
| 02_hills_scale | 239 → 239 | 467724 → 460436 | 11.59 → 12.32 | 6.60 → 7.11 |
| 03_waterfall_scale | 119 → 119 | 147114 → 146192 | 8.58 → 8.28 | 4.32 → 4.39 |
| 04_cave_scale | 169 → 169 | 181311 → 181775 | 8.20 → 11.26 | 4.09 → 4.56 |
| 05_upper_river | 283 → 283 | 459875 → 455440 | 11.03 → 12.24 | 8.58 → 7.99 |
| 06_middle_river | 184 → 184 | 389443 → 383304 | 9.66 → 10.37 | 6.95 → 6.49 |
| 07_lower_river | 265 → 265 | 388881 → 387812 | 11.01 → 12.22 | 6.12 → 6.05 |
| 08_forest_collision | 172 → 172 | 364597 → 359022 | 15.29 → 16.34 | 12.21 → 12.31 |
| 09_island_overview | 259 → 259 | 349349 → 348358 | 9.24 → 13.94 | 6.12 → 6.55 |

Raw memory counters, frame p95, GPU times and all views are in `rendering_cost.json`. Counters are Windows backend observations, not Android RAM estimates or isolated CPU/GPU utilisation percentages. No textures, vegetation density, shadows or costly shaders were added. Native distance LOD generation is retained on the fitted grassland/beach patches. An intermediate export lost those LODs; it was corrected and the final APK and all 23 regressions were rebuilt/retested afterward. New original-tree proxies add 35 simple shapes plus one small entrance mesh collider; corrected terrain largely reuses existing topology and removes obsolete rock triangles. Startup fitting/normal generation has a cost; sustained phone physics/thermal cost remains unmeasured.

## Android build and owner test

No authorised physical phone was connected. Device model/version, sustained FPS, frame-time distribution, PSS, thermal and battery observations for Task 5.2 are **pending**. The owner's Samsung A37/8GB Task 5.1 720p/60 FPS approval is prior feedback, not a new Task 5.2 measurement.

Review APK: `APK/Veil_of_Vera_Task52_720p_Candidate.apk` (150,979,898 bytes). SHA-256: `24d3bcd13417f28f00a3cf476da72ea94bf138cf18339df0dea3eb5ee11f1dbc`. ARM64 debug package `com.hirukshanan.veilofveyra.islandtest`, same signing identity as the accepted B APK, no INTERNET permission. In-place update preserves that test package's save sandbox; do not uninstall or clear app data. The production package/map is unchanged. Existing startup defaults remain30 FPS/shadows off; select60 FPS in Settings for the same owner comparison.

Signature, package, 720p config, identical bootstrap/profiler bytecode and ZIP integrity were checked. The actual exported APK assets were also loaded locally for bootstrap/resizing/HUD/profile checks. That local Windows run is packaging validation, not Android execution; desktop ETC2 fallback warnings are not phone results.

Use the same phone settings and route as the accepted B build. Check both banks at the listed exits, forest trunk contact, mountain/rock contact and cave entry/reload. Repeat forest → hills → mountain → river → cave → coast gameplay at 60 FPS and collect local profiles with the existing `tools/profile_island_android.py`. Compare sustained frame times/memory/temperature before accepting mobile performance. No unrelated optimisation redesign was applied.

## Files, sources and reproduction

`changed_files.json` lists the candidate scripts, test changes, capture source and builder. No new third-party or AI asset was generated. Existing owner-created island and existing licensed/CC0 materials are reused; their original credits/licenses remain unchanged. Original map and original GLBs/.blend files are retained. `art_source/island/task52/baseline/` preserves the pre-change scripts/tests; the source patch in this ZIP requires the existing project. The APK contains the complete runnable review candidate.

From the repository root, use the installed Godot console with `VEYRA_TEST=1` and an isolated `APPDATA`. Create `.validation/island_task52/review` before running. The two new fixtures accept the output folder after `--`:

```powershell
$env:VEYRA_TEST='1'
$env:APPDATA="$PWD/.validation/island_task52/review_profile"
New-Item -ItemType Directory -Force .validation/island_task52/review | Out-Null
& $godot --headless --path . --script res://tests/island_river_escape_check.gd -- "$PWD/.validation/island_task52/review"
& $godot --headless --path . --script res://tests/island_accessibility_collision_check.gd -- "$PWD/.validation/island_task52/review"
```

Define `$godot` as the local Godot 4.7.2 console executable. Run the existing regressions with their unchanged commands; the forest readback test requires native GL rather than headless. Build with `tools/build_island_android.py --task 5.2 --render-height 720` and the existing required Godot/SDK/Java/templates/staging/output arguments (separate option names and values with spaces).

## Remaining limitations / approval boundary

- Mountain source topology remains visibly angular in places. Selective height changes improve proportion, not art completeness.
- Waterfall remains a stylised inexpensive mesh effect. Local dark/sliver artifacts and abrupt source-rock edges remain around its rock/ground junction; this task does not claim final cliff/toe polish.
- Grass/foliage aliasing and the previously accepted cave/waterfall art limitations remain. No forest, lighting, hero or HUD redesign was attempted.
- Simple trunk proxies approximate the main stems, not every high branch or leaf. Tests do not prove exhaustive collision coverage of every tiny prop.
- Sustained Samsung A37 FPS, memory, physics cost, thermals and battery use remain unverified until owner/device retest.

Stop for Task 5.2 visual and phone approval. Do not activate the production map or begin Task 5.3.
