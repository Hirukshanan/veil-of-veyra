# New island — visual verification and independent review

**Status: review delivery only. The original main map is NOT activated or replaced. The candidate is NOT commercially finished.** No player, enemy, quest, combat, approved HUD/control, production map or save-system file changed during this verification. SHA-256 checks confirm all **323 production files** match the start of this task. Only new review fixtures, images, measurements, reports and local packages were added.

## Actual appearance

[Open all 22 native images in the gallery](index.html). These are unretouched 1280×720 Godot 4.7.2 Compatibility-renderer screenshots from the existing candidate campaign, not Blender/concept/AI images. Controlled camera placements hold the player/other enemies still in the screenshot fixture; actual walking is separately tested. Third-person shots keep the approved HUD. Inspection close-ups hide UI for clarity. The exact overhead camera uses an orthographic 90° downward view and temporarily disables distance culling only for that review camera so all five regions/trees appear.

- [All five regions overhead](00_top_down.png)
- [Third-person gameplay](01_gameplay.png), [forest/tall trees](02_forest.png), [open grassy hills](03_grassy_hills.png), [mountains/cliffs](04_mountains_cliffs.png)
- [Cave entrance](05_cave_entrance.png), [cave interior](06_cave_interior.png)
- [River](07_river.png), [waterfall](08_waterfall.png), [beach/sea](09_beach_sea.png)
- Connections: [west](10_connection_west.png), [north](11_connection_north.png), [east](12_connection_east.png), [south](13_connection_south.png)
- Terrain seams: [west slab](14_seam_west.png), [mountain transition](15_seam_north.png), [east cliff](16_seam_east.png), [sand/meadow](17_seam_south.png)
- Riverbanks: [upper](18_riverbank_upper.png), [middle](19_riverbank_middle.png), [outlet](20_riverbank_outlet.png); [waterfall detail](21_waterfall_detail.png)

### Visible issues requiring review

The close-ups confirm substantial visual limitations. The western/eastern boundaries retain hard slab faces and stretched textures. The southern sand/meadow junction has visibly clipped/overlapping edges and grass on sand. Source tree crowns contain angular sheets/clumps and density differs from the supplied concept. The cave entrance visibly protrudes as an authored vault and has a roof/rock alignment gap. The river has steep cut banks, a flat opaque water strip, and angular/uncovered-looking outlet transitions. Waterfall foam remains largely based on source geometry/texture with a lightweight animated treatment. These findings are recorded, not fixed or hidden during this verification. Functional reachability does not approve their appearance or turn every straight seam into a walkable shortcut.

## Walking verification

A new fixture uses the unchanged real player controller and actual static collision. It builds conservative capsule-clear routes, then walks from the central spawn approach to each region and back. All **10 outward/return legs** passed without teleporting between legs, health loss, falling or emergency rescue. Camera review placements above are not offered as proof of walking.

| Regional destination | Outward actual distance, m | Return actual distance, m | Result |
|---|---:|---:|---|
| WaterfallMountains | 89.60 | 88.67 | PASS |
| WesternForest | 185.27 | 185.14 | PASS |
| RiverGrassland | 11.12 | 11.07 | PASS |
| EasternCaves | 336.74 | 336.33 | PASS |
| SouthernBeach | 54.07 | 53.63 | PASS |

The eastern cave test chose a **336.74 m conservative detour**. The western route is also indirect. These are observed test routes, not shortest-path claims. No direct cross-river shortcut/bridge is asserted to work. The five regional approaches are mutually reachable through the tested central network; this does **not** prove every local boundary can be crossed straight ahead, nor unrestricted access to steep mountain tops. The separate candidate campaign/collision tests cover actual cave entry, under-roof relic collection, save/reload, tree blocking, camera clearance and sea boundary.

Evidence: [actual walk stdout](logs/island_connections_review.stdout.log), [stderr](logs/island_connections_review.stderr.log), [run/exit metadata](logs/island_connections_review.run.json), [per-leg CSV](connection_walks.csv), [actual sampled movement trace](connection_walk.json), [planned route graph](connection_routes.json).

## The reported 15 tests — actual fresh logs

All exact 15 named tests were rerun in fresh isolated APPDATA profiles with VEYRA_TEST=1. Every run exited **0** and wrote its PASS line. **Three** directly target the new candidate; the other **12** preserve existing main-scene/isolated combat behavior. They must not be described as 15 complete new-map playthroughs. Stdout/stderr are copied from Godot, not reconstructed from summaries. Each run record contains UTC time, command arguments, duration, exit code and isolation scope.

| Test | Scope | Result / exit | Actual logs |
|---|---|---|---|
| island_check | Candidate | PASS / 0 | [stdout](logs/island_check.stdout.log) · [stderr](logs/island_check.stderr.log) · [run](logs/island_check.run.json) |
| island_campaign_check | Candidate | PASS / 0 | [stdout](logs/island_campaign_check.stdout.log) · [stderr](logs/island_campaign_check.stderr.log) · [run](logs/island_campaign_check.run.json) |
| island_collision_check | Candidate | PASS / 0 | [stdout](logs/island_collision_check.stdout.log) · [stderr](logs/island_collision_check.stderr.log) · [run](logs/island_collision_check.run.json) |
| boar_feedback_check | Existing game regression | PASS / 0 | [stdout](logs/boar_feedback_check.stdout.log) · [stderr](logs/boar_feedback_check.stderr.log) · [run](logs/boar_feedback_check.run.json) |
| boar_check | Existing game regression | PASS / 0 | [stdout](logs/boar_check.stdout.log) · [stderr](logs/boar_check.stderr.log) · [run](logs/boar_check.run.json) |
| boar_campaign_check | Existing game regression | PASS / 0 | [stdout](logs/boar_campaign_check.stdout.log) · [stderr](logs/boar_campaign_check.stderr.log) · [run](logs/boar_campaign_check.run.json) |
| heavy_attack_check | Existing game regression | PASS / 0 | [stdout](logs/heavy_attack_check.stdout.log) · [stderr](logs/heavy_attack_check.stderr.log) · [run](logs/heavy_attack_check.run.json) |
| combat_check | Existing game regression | PASS / 0 | [stdout](logs/combat_check.stdout.log) · [stderr](logs/combat_check.stderr.log) · [run](logs/combat_check.run.json) |
| enemy_check | Existing game regression | PASS / 0 | [stdout](logs/enemy_check.stdout.log) · [stderr](logs/enemy_check.stderr.log) · [run](logs/enemy_check.run.json) |
| campaign_smoke | Existing game regression | PASS / 0 | [stdout](logs/campaign_smoke.stdout.log) · [stderr](logs/campaign_smoke.stderr.log) · [run](logs/campaign_smoke.run.json) |
| autosave_check | Existing game regression | PASS / 0 | [stdout](logs/autosave_check.stdout.log) · [stderr](logs/autosave_check.stderr.log) · [run](logs/autosave_check.run.json) |
| persistent_world_check | Existing game regression | PASS / 0 | [stdout](logs/persistent_world_check.stdout.log) · [stderr](logs/persistent_world_check.stderr.log) · [run](logs/persistent_world_check.run.json) |
| fast_travel_check | Existing game regression | PASS / 0 | [stdout](logs/fast_travel_check.stdout.log) · [stderr](logs/fast_travel_check.stderr.log) · [run](logs/fast_travel_check.run.json) |
| hud_customization_check | Existing game regression | PASS / 0 | [stdout](logs/hud_customization_check.stdout.log) · [stderr](logs/hud_customization_check.stderr.log) · [run](logs/hud_customization_check.run.json) |
| quest_hud_check | Existing game regression | PASS / 0 | [stdout](logs/quest_hud_check.stdout.log) · [stderr](logs/quest_hud_check.stderr.log) · [run](logs/quest_hud_check.run.json) |

[Machine-readable results and full diagnostic text](test_results.json). Any pre-existing HUD draw_rect or audio-resource-at-exit warnings remain in stderr and are not silently discarded. Passing functional assertions do not mean a warning-free engine shutdown. The additional all-region walking fixture is separate from the 15 originally reported tests.

## Dimensions and mesh usage

Dimensions below are runtime AABBs in **Godot X/Y/Z metres**. Y extents include buried source foundations and are not visible tree/peak heights. Source node transforms are identity with regional placement baked into vertices.

| Regional mesh | X width × Y extent × Z depth, m | Base triangles |
|---|---|---:|
| WaterfallMountains | 66.00 × 18.82 × 65.74 | 14,130 |
| WesternForest | 50.28 × 23.82 × 64.72 | 7,681 |
| RiverGrassland | 64.00 × 9.13 × 63.56 | 13,428 |
| EasternCaves | 48.00 × 10.50 × 50.17 | 12,462 |
| SouthernBeach | 86.00 × 6.66 × 89.78 | 13,925 |

The five prepared regions total **61,626 triangles** (original input: 65,581). Connecting ground adds **22,952 triangles**; these totals exclude the cave vault, river, reused vegetation, hero, enemies, shadows and minimap passes. Runtime LOD can reduce regional render detail. See [mesh CSV](mesh_dimensions.csv) and [raw bounds/texture/memory data](visual_metrics.json).

Distinct island measurements:

- Connecting terrain geometry: **240 × 240 m**, including submerged outer support.
- Sampled emerged land: approximately **222 × 222 m** in X/Z, about **35,472 m²** of projected above-sea support on a 2 m grid. This includes steep scenery and is not all walkable area.
- Play/wading containment boundary: **235.12 × 234.00 m** in X/Z. The usable shape is irregular, not a filled rectangle.
- Surrounding sea plane: 2000 × 2000 m at Y = -1.45 m.

## Texture and memory usage

The five original 4096² albedos remain in the untouched source GLB. Five runtime albedos are **2048²**, with mipmaps and S3TC desktop / ETC2 mobile imports. Original versus runtime base texels are reduced by 75%. Native desktop image format is compressed DXT1 (enum 17), with 11 mip levels after the base. The five measured compressed image payloads sum to **13.33 MiB** including mipmaps; this is image payload size, not full driver allocation or a phone measurement.

At the native capture snapshot, Godot reported **100.17 MiB engine-managed static memory**, **300.75 MiB total video memory**, and **262.05 MiB texture memory**. These are scene-wide monitors including existing characters, enemies, HUD/minimap, reused assets and new map. Texture memory is part of video memory; do not add them together. Static memory is not the Windows process working set. No Android, thermal, sustained combat FPS or mobile memory acceptance is claimed.

## Independent review package

The delivered ZIP is a source Godot 4.7.2 project, including all current runtime dependencies and asset credits, candidate scene, original map scene, original/editable island source, this gallery and raw logs. It excludes .git, .godot caches, personal save profiles, signing/export credentials and unrelated build outputs. Extract it, import project.godot, then press F5. Its separate REVIEW COPY selects the candidate and uses an isolated custom user directory. The source repository's project.godot/main scene are unchanged. A fresh extraction is imported and launched separately; see package verification files delivered alongside the ZIP. No APK, publishing or production activation is performed.

The original active map and its assets remain in the repository and in the review copy. The earlier verified full rollback archive is retained at `C:/Users/Dark/Documents/Codex/Backups/Veil_of_Vera_PreIsland_20261115_024603/original_game.zip`. [Production hash verification](production_preservation.json) proves this task did not alter the map, player, controls, enemy or quest sources. Only review fixtures, local reports, captures and packages are new.

## Reproduction and stop point

Use the installed Godot 4.7.2 executable and an isolated APPDATA directory. Run `godot --headless --path PROJECT_ROOT --script res://tests/NAME.gd` for each listed test. The visual fixture is `res://tests/island_visual_capture.gd` (native 1280×720); the extra traversal fixture is `res://tests/island_connections_review.gd`. Create `.validation/island_visual_2026-11-15` before using the visual/traversal fixtures. No personal save directory is used by the delivered test runs.

No game-source changes or visual repairs were authorized in this step, and none were made. This delivery stops at native screenshots, truthful evidence and independent candidate files. **Do not activate or call the map commercially finished.**

## Independent package verification result

The review project was extracted into a new directory without a `.godot` cache. A complete fresh import then exited **0**, and the candidate launch check exited **0**, loading all five regional meshes/2K textures, the existing hero/HUD, five camp actors and optional boar. The review copy uses a separate custom user directory. Runtime file hashes match the verified extraction. [Package verification](PACKAGE_VERIFICATION.json), [import stdout](logs/package_import.stdout.log), [import stderr](logs/package_import.stderr.log), [launch stdout](logs/package_launch.stdout.log), [launch stderr](logs/package_launch.stderr.log).

The first parallel cold-import attempt exited with native Windows code **3221225477** at a font-import step; it is retained in [initial stdout](logs/package_import_initial.stdout.log), [initial stderr](logs/package_import_initial.stderr.log), and [initial run metadata](logs/package_import_initial.run.json). The review copy alone sets `editor/import/use_multiple_threads=false` and succeeds from a new extraction. This setting controls editor import threading ([Godot source](https://github.com/godotengine/godot/blob/master/editor/file_system/editor_file_system.cpp)). The observation suggests an import-threading interaction, but does not establish the engine root cause. No font, gameplay asset or production setting was changed to conceal the failed attempt. The final ZIP differs from the successfully tested archive only in review evidence; its runtime sources are checked against that extracted copy before delivery.
