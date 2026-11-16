# Veil of Vera — Task 5.4.2 review

The existing cave exterior now has broader uneven mountain shoulders, a lower entrance brow, a descending rear spur and terrain slopes at its toes. The curved passage, inner chamber, reserved Dragon hall and relic retain their accepted positions. All 1,848 interior shell vertices and existing chamber formations were carried forward from the Task 5.4.1 Blender source. The rock mesh grows from 8,162 to 8,624 triangles (+462, 5.66%). The added front-band subdivisions reduce broad triangular shading around the entrance. The source is an exterior refinement of the accepted mesh.

## Exterior and waterfall

The eastern apron previously ended at a separate graded-patch boundary. Its existing terrain cells now use ConnectedTerrain and the same height sampler. This removes that open patch edge and consolidates its static body. Nearby ground rises gradually into the ridge outside the retained passage corridor. The final static shape count is **79**, compared with 80 before this task. The collision fixture records this deliberate consolidation and still exercises the actual hero, wolf/boar bodies, all 35 mature tree proxies, spawn clearance and spring-arm camera.

The outer shell carries an exterior vertex mask, allowing the same limestone material to blend with reused grass/sand near suitable slopes. Cave interiors retain their earlier dark rock treatment. The waterfall's buried rock triangles are clipped to the sampled bank surface, and cliff-adjacent ground shares limestone texture/color at the junction. The original mountain collision remains as underground support. River water geometry/color, crest ribbon, foam, river scale and all 26 tested entry/escape routes retain their functionality. There are no new textures, real-time lights, volumetric effects or fluid simulation.

## Verification cleanup

Heavy-attack shutdown diagnostics reproduced the retained sword audio stream in **2/4** verbose pre-fix repetitions. The audio mixer still held an AudioStreamPlaybackWAV and sword_swing.wav when the test immediately quit. The player already stops its stream on exit. The fixture now waits 0.3 real seconds after freeing its scene before engine shutdown. **Five consecutive post-fix repetitions** and the final heavy-attack regression completed with exit code 0 and clean stderr. A campaign rerun exposed the same asynchronous retirement issue for death.wav despite its existing 0.25-second wait. That fixture now allows 0.75 real seconds and its final rerun is clean. Combat source and behavior are hash-identical.

**27/27 regression programs pass** against the final candidate. River escape is **26/26**, exit **0**, with stdout, stderr and run metadata provided. The cave also passed six floor/ceiling/capsule headroom probes and an actual hero walkthrough from outside through the relic, bend and inner chamber and back outside, using normal movement. The recording contains 253 original captured frames at 15 fps playback, approximately 17 seconds. Enemy physics is held only for controlled recording. The deeper reserved hall has visual inspection only.

Tests cover cave collision/camera, quest/relic collection and reload, campaign progression, autosave/persistent world/fast travel, enemy navigation and repeated boar combat, ordinary/heavy attacks, mobile multitouch/zoom/sprint, customization, Settings, safe areas and layouts. [Full results](test_results.json), [river stdout](logs/island_river_escape_check.stdout.log), [river stderr](logs/island_river_escape_check.stderr.log), [audio investigation](audio_investigation.json) and raw logs are included. Final recorded checks have no script, shader or engine errors. A pre-existing filled draw_rect width warning remains in premium_hud.gd during some HUD tests.

## Actual visual evidence

The gallery includes 11 matched before/after pairs, with exact recorded desktop camera positions/targets. They show hero-height entrance, side thickness, elevated three-quarter exterior, top-down integration, owner-west waterfall bearing, east riverbank bearing, crest/base and preserved interiors. Owner-image camera transforms were unavailable, so the two phone-angle reproductions are approximate bearings. Both revisions use the same desktop cameras, 1600×720 landscape canvas, shadows off and the accepted 720-high 3D quality. These captures and the walkthrough are actual Godot output. The top-down view is perspective and shows the full exterior rather than a schematic cutaway.

## Desktop rendering cost

Windows / Intel Iris Xe / Godot 4.7.2 GL Compatibility, shadows off, 1600×720, 30 FPS cap. Each view has 40 warmup and 90 measured frames. Before / after values follow. Captures were sequential after other verification completed. Frame intervals include pacing and are not an Android FPS measurement.

| View | Draw calls | Submitted primitives | Median frame ms | p95 frame ms | Static MiB |
| --- | ---: | ---: | ---: | ---: | ---: |
| 01_entrance_hero | 184 / 183 | 190216 / 190591 | 33.35 / 33.33 | 33.88 / 33.45 | 136.0 / 135.9 |
| 02_exterior_side | 166 / 165 | 358203 / 358632 | 33.34 / 33.33 | 33.82 / 33.47 | 136.0 / 135.9 |
| 03_elevated_three_quarter | 157 / 156 | 351760 / 352685 | 33.33 / 33.33 | 33.69 / 33.46 | 136.0 / 135.9 |
| 04_top_down | 154 / 153 | 346575 / 347269 | 33.33 / 33.34 | 33.60 / 33.48 | 136.0 / 135.9 |
| 05_waterfall_owner_west | 130 / 130 | 165401 / 166096 | 33.33 / 33.34 | 33.66 / 33.45 | 136.0 / 135.9 |
| 06_river_owner_east | 112 / 111 | 144711 / 145404 | 33.33 / 33.34 | 34.08 / 33.62 | 136.0 / 135.9 |
| 07_waterfall_crest | 22 / 22 | 145056 / 145751 | 33.33 / 33.33 | 33.63 / 33.99 | 136.0 / 135.9 |
| 08_waterfall_base | 7 / 7 | 118149 / 118844 | 33.33 / 33.33 | 33.58 / 33.47 | 136.0 / 135.9 |
| 09_passage_preserved | 126 / 125 | 344075 / 343823 | 33.32 / 33.33 | 33.74 / 33.49 | 136.0 / 135.9 |
| 10_inner_chamber | 71 / 71 | 168320 / 168556 | 33.34 / 33.34 | 34.60 / 33.46 | 136.0 / 135.9 |
| 11_reserved_hall | 10 / 10 | 122915 / 123241 | 33.33 / 33.34 | 33.72 / 33.50 | 136.0 / 135.9 |

Render CPU/GPU timer samples plus video/texture counters are included in [rendering_cost.json](rendering_cost.json). Static allocator memory and driver counters do not represent total Android memory. No physical Samsung A37 was measured in this task. The 720p bootstrap, native HUD, selected 60 FPS option and lower-FPS fallback are preserved exactly in source.

## Files and review package

Changed existing project files are listed below. Exact before/after hashes are in preservation.json. New assets are under assets/environment/new_island/task542. Editable source and the refinement script are under art_source/island/task542. The package includes a complete runtime project with the original production main-scene setting, the candidate scene, all required existing runtime assets, tests and local build templates. Generated import caches and signing profiles are excluded. Open project/scenes/island_candidate.tscn in Godot and run that scene for independent review, or use the command in REVIEW.md.

- scripts/island_landscape.gd
- scripts/island_rock_water_polish.gd
- scripts/island_surface_data.gd
- assets/environment/new_island/land.gdshader
- assets/environment/new_island/task4/land.gdshader
- tests/heavy_attack_check.gd
- tests/island_accessibility_collision_check.gd
- tests/island_campaign_check.gd

The complete changed set also includes the new task542 asset/source/evidence folders. Existing Task 5.4.1 changes remain in the working tree. No Git commit or push was made for this task.

## Sources and remaining limitations

The model refinement and vertex masks are original local work derived from the existing Task 5.4.1 mesh. Materials reuse the project's existing CC0 Poly Haven rock/grass/sand textures and retain existing license files. No external asset was downloaded.

The broad ridge still has a stylized low-poly silhouette, with repeating rock texture visible in elevated views. Exterior grass-to-rock transitions remain authored material blends. The waterfall uses lightweight ribbons and foam. Final physical-phone appearance and performance, and animated Dragon clearance in the reserved hall, await separate testing. No lantern quest, awakening, new story trigger or production-map activation is included. The existing campaign main scene, HUD, player/combat, enemy behavior, quest/save schema and river water shader have exact preservation hashes.

Stop for owner visual approval after reviewing the gallery and walkthrough.
