# Task 5.4.1 candidate review
The eastern ridge uses one editable mesh with connected inner and outer surfaces, a walkable floor, closed rear and rock buttresses. The hero route enters from z=-14, collects relic 1, follows the curved passage through ten outward/return waypoints and exits using normal movement. The new static mesh uses the existing collision layers and rock albedo/normal material. Coverage includes real hero movement, camera, enemy sweeps, quest and save regressions. The older shape-count fixture and narrow-wall assertion were updated for the new geometry. See raw logs and results for individual outcomes.

## Samsung screenshot investigation
1. EasternCaves imported cliff surface, PlayableGrotto vault, FittedCaveRockMantle and rear cap overlapped. Two-sided task3/rock.gdshader displayed both sides of the thin shell. These now share the replacement closed ridge.
2. WaterfallMountains_GradedTerrain and ConnectedTerrain used different mesh sampling around FlowingRiver. Clipped wet faces on nearly level banks produced stripes and polygon corners; the original mountain rock stopped near the falling ribbon. The affected mountain ground cells now belong to ConnectedTerrain, the headwater slopes share a continuous profile and the cascade has its own collidable crest support.
3. The channel edges followed adaptive coarse/fine triangles. Fine edge vertices now interpolate the adjacent coarse edge. Water normals are transformed from world space to view space. Body geometry and river water use the same terrain sampler. Pixel attribution in the owner images is inferred from the scene and staged renders; screenshots have no saved camera transforms. The three north/west/east views approximate the phone bearings. The north-looking camera point is inside the larger new ridge; compare the entrance and overview views for the playable exterior.

## Rendering cost
Matched Windows Godot compatibility captures, 1280x720, shadows off. Before / after. Timings include contention from local verification and are not device benchmarks.

|View|Draw calls|Submitted primitives|Median ms|p95 ms|
|---|---:|---:|---:|---:|
| 01_south_cave | 19.0 / 16.0 | 131451.0 / 133207.0 | 3.2 / 3.3 | 4.1 / 4.5 |
| 02_west_waterfall | 26.0 / 26.0 | 149325.0 / 149258.0 | 3.8 / 3.8 | 5.3 / 4.6 |
| 03_east_bank | 19.0 / 21.0 | 142106.0 / 157531.0 | 3.6 / 3.4 | 5.9 / 4.7 |
| 04_cave_entrance | 51.0 / 48.0 | 144560.0 / 149557.0 | 3.0 / 3.3 | 3.8 / 4.4 |
| 05_cave_interior | 42.0 / 39.0 | 149552.0 / 152851.0 | 4.0 / 4.4 | 4.9 / 5.8 |
| 06_waterfall_distance | 7.0 / 7.0 | 118216.0 / 118149.0 | 3.3 / 2.7 | 5.0 / 4.6 |
| 07_waterfall_river | 7.0 / 7.0 | 118216.0 / 118149.0 | 3.2 / 3.1 | 4.6 / 4.3 |
| 08_bend | 89.0 / 86.0 | 166199.0 / 169507.0 | 3.6 / 4.2 | 4.9 / 5.8 |
| 09_chamber | 67.0 / 62.0 | 181907.0 / 160843.0 | 4.3 / 4.0 | 5.5 / 5.1 |
| 10_dragon | 19.0 / 15.0 | 154193.0 / 141926.0 | 4.2 / 3.2 | 5.9 / 4.7 |

Memory counters (bytes, before / after): static 143152068 / 142210058, texture 274104433 / 274104433, video 330923601 / 330732745.

## Limitations
The river is still a lightweight strip at the fall lip. Some cliff/ground intersections and strongly lit bank contrasts remain visible. Interior walls are dark and comparatively uniform. Phone screenshots and desktop perspectives are approximate matches. Android frame times, visual parity and the eventual animated Dragon clearance are unverified. Use the unchanged production map for rollback; the original local candidate checkpoint is task541_checkpoint_20261115_221102.zip. No progression trigger or production activation was added.

## Changed project files
- assets/environment/new_island/task541/cave.obj
- assets/environment/new_island/task541/cave.obj.import
- assets/environment/new_island/river.gdshader
- scripts/island_landscape.gd
- scripts/island_surface_data.gd
- scripts/island_rock_water_polish.gd
- tests/island_accessibility_collision_check.gd
- art_source/island/task541/model.py
- art_source/island/task541/Cave.blend
- art_source/island/task541/.gdignore
- docs/island_task541/ (this evidence folder; exact entries in the ZIP manifest)
