# Island integration — candidate review

**Status: implemented and tested as a separate scene; main-map activation is held for explicit visual approval.** This is not a claim that the supplied miniature regions have become finished commercial environment art. The old active scene is unchanged. Stop here for review; no unrelated phase, APK, branch, commit or push.

## Inspection and recoverability

Read [inspection before assembly](ISLAND_INSPECTION.md) for original hierarchy, identity node transforms, baked offsets, original bounds, materials, actual geometry and per-region suitability. The source has five separate regions in a row, 65,581 triangles and five 4096² embedded albedos, not a connected playable island. Generation credit is **Hirukshanan using Tripo3D**. Original SHA-256: `e9553774acb68227f1779d2d73fbe17510a210db057dfaa37f13a113b2ddfa1e`.

Verified pre-change backup: `C:\Users\Dark\Documents\Codex\Backups\Veil_of_Vera_PreIsland_20261115_024603/original_game.zip`, 406 files with SHA-256 manifest. All original procedural-map scripts/assets remain in place. The new source is recoverable at `art_source/island/Island_original.glb`, with an editable packed `island_regions.blend`. No personal save folder was read/modified and no private asset/code/session history was uploaded.

## Assembly

The five sources are individually sized and placed around a new continuous ground surface; they are not a straight row or five levels. Metric widths were selected from approximately 48–86 m, within an approximately 230 m island footprint. No whole-GLB giant scale is used. X/Z positions of existing objective IDs remain familiar, while actual Y support and unsafe nearby locations are corrected against collision. World-origin node transforms remain identity because placement/deformation is baked into the regional vertices.

| Region | Center X/Z, m | Prepared X / depth / height, m | Triangles |
|---|---|---|---:|
| WaterfallMountains | (0, -68) | 66.0 / 65.7 / 18.8 | 14,130 |
| WesternForest | (-64, -8) | 50.3 / 64.7 / 23.8 | 7,681 |
| RiverGrassland | (5, 2) | 64.0 / 63.6 / 9.1 | 13,428 |
| EasternCaves | (68, -10) | 48.0 / 50.2 / 10.5 | 12,462 |
| SouthernBeach | (0, 66) | 86.0 / 89.8 / 6.7 | 13,925 |

Prepared regional geometry totals **61,626 triangles**. Four sources have 7 m boundary tapers into the shared terrain and ground-color edge transitions. The forest removes broad stretched reconstruction components and low fragments, replants retained tree parts relative to detected trunk roots, and supplements them with the existing game's instanced trunk/canopy assets. Their original attribution remains valid. Imported foliage still has stylized/angular shapes and some irregular fragments; this is disclosed rather than called finished art.

New connecting ground is a modest-resolution collision mesh with low hills, graded coastal shelves, paths and an irregular coastline. Buried support is intentional; visible duplicated top surfaces are reduced by tapering and grading. Existing Poly Haven ground materials are reused, with independent source-region albedos retained. The visual transitions still need user art review.

The river is real water geometry over a carved bed, extending from the mountain outflow to the southern sea, with lightweight moving ripples. The mountain's actual water-colored surfaces receive a restrained animated treatment; the source's baked waterfall is not replaced by a fluid simulator. Channels are graded into source meadow/beach meshes rather than placed as disconnected scenery ribbons. Banks remain visibly authored and are not presented as final natural erosion.

The original cave did not yield hero-clear interior points in the initial scan. A human-size opening is cut in the cliff derivative and a **15 m grotto, approximately 5 m wide with 3.8 m center headroom**, supplies real floor, rough rock vault, end wall and exact two-sided collision. One existing relic (ID 1) is moved inside. The original dark openings are not counted as additional playable caves. A low-cost unshadowed fill makes the interior readable.

The sea reuses the existing ripple/foam shader. A backward-compatible amplitude uniform matches the new coastline; default values preserve the old scene. Water lowers into sea level at the outlet. The old shallow-water wall pattern still limits deep-water travel, and physical tests verify the player stops without a health reset.

## Gameplay and save compatibility

`scenes/island_candidate.tscn` extends the existing campaign rather than replacing combat or persistence. A small campaign factory lets it select an exploration instance that keeps waystone/travel behavior and omits the old terrain/forest constructors. The main scene still selects the original campaign. A checkpoint-position method returns unchanged defaults in the original scene and actual grounded supports in the candidate.

The candidate grounds all five required camp actors, the optional boar, herbs, fragments, ruins, lantern and waystones on valid nearby support. Enemy home/patrol origins update together. One journal-only quest Node is correctly kept out of physical placement. The camera retains its existing spring arm and collision mask; no HUD positions, input bindings, hero, boar art/animations/audio/combat values, wolf controller, inventory/equipment or save format is redesigned.

Save validation preserves the existing schema/IDs. Unsafe saved support is relocated locally while keeping health, potions, upgrades, shards and collected IDs. An already valid cave floor is sampled below the saved position instead of moving the player to the roof. The candidate legacy fixture preserves 240 shards, blade 3, armor 2, HP 73, six potions and partial herb/relic/seal/camp progress. Actual cave traversal collects the same relic ID, reload stays inside, the optional boar pays exactly once, and the lantern/dragon completion path still saves correctly.

The repository currently implements wolf variants, not a separate fox enemy system. Its implemented chapter ending is the Tidewraith encounter. Cursed Bear and Chapter II passage encounters were already unimplemented; this map task does not silently claim to add them or change the recurring dragon design.

## Validation

**15 functional tests passed.** New candidate tests cover the collision-derived connected-route graph, capsule headroom, actual hero travel without fall/rescue, forest interior, actual tree blocking, cave camera clearance, coastal boundary, legacy data preservation, cave relic/reload and complete existing rewards/progression. The route graph has 7,381 valid support cells, 7,199 in the spawn-connected set. It verifies reachable approaches for every region and collectible outside the cave; a separate real-controller test covers the cave's under-roof layer.

Existing checks also pass: boar_feedback_check, boar_check, boar_campaign_check, heavy_attack_check, combat_check, enemy_check, campaign_smoke, autosave_check, persistent_world_check, fast_travel_check, hud_customization_check and quest_hud_check. No parse/runtime assertion failure remains in successful runs. Exact summaries and any engine warnings are in `island_replacement/verification.json`. Pre-existing HUD draw_rect and intermittent audio-resource-at-exit warnings, where observed, are disclosed; protected HUD/audio sources were not edited to hide them.

One native desktop benchmark initially exited with Windows code 3221225477 **after** writing measurements and its PASS line, without a script error. Its output is retained. The fixture was updated to drain an empty render frame and allow cleanup before quitting, and the benchmark was repeated. This is disclosed as a shutdown diagnostic; it is not silently equated with a warning-free engine or Android acceptance.

All fixtures use unique APPDATA profiles and VEYRA_TEST=1. Reviews are controlled native-engine views of the actual campaign, not AI concept images or a standalone replacement game. Other enemies are held still only in review/benchmark fixtures for reproducibility; the final candidate gameplay does not freeze them.

## Mobile preparation and desktop measurements

Five runtime albedos are 2048², **75% fewer texels than the five original 4K images**. Original 4K data remains in the untouched GLB. Mipmaps, S3TC desktop and ETC2 mobile VRAM-compressed imports are verified; the project already enabled ETC2/ASTC import, so that global setting is unchanged. Only five extracted runtime image dependencies remain; unused duplicate external derivatives are removed. Godot generates regional mesh LODs/shadow meshes. Regional drawing has distance limits and native frustum culling. Grass uses small distance-culled MultiMesh patches with no shadows/collision. Supplementary trees use instancing plus simple cylinder blockers; regional meshes use static triangle collision so cave arches are not filled by convex hulls.

Native uncapped 1280×720 Compatibility-renderer environment measurements on the existing **Intel Iris Xe** computer, taken without Movie Maker or simultaneous regression jobs. Enemies are held static for repeatability. These are short desktop samples, **not Android/combat/thermal acceptance**:

| Actual view position | Average FPS | Median / p95 frame ms |
|---|---:|---:|
| (0.0, 3.87155, 27.0) | 66.0 | 14.85 / 19.47 |
| (-64.0, 1.910605, 12.0) | 63.2 | 15.65 / 19.07 |
| (26.0, 1.546602, -48.0) | 91.2 | 10.65 / 14.88 |
| (68.0, 1.088801, -38.0) | 90.0 | 11.09 / 13.22 |

Godot-reported total scene static memory: 99.7 MiB; total video memory: 313.4 MiB; texture memory: 262.1 MiB. These include the existing hero, enemies, HUD/minimap and environment, not just the five new images. No phone, sustained thermal, app memory or touch-latency acceptance was performed. See [Godot texture importer documentation](https://docs.godotengine.org/en/stable/classes/class_resourceimportertexture.html) for VRAM-compression tradeoffs.

## Actual running-game evidence

- [Top-down native overview](island_replacement/island_overview.png)
- [Third-person gameplay](island_replacement/island_third_person.png)
- [Forest](island_replacement/island_forest.png), [grassland](island_replacement/island_grassland.png), [mountains](island_replacement/island_mountains.png)
- [Waterfall/outflow](island_replacement/island_waterfall.png), [river](island_replacement/island_river.png)
- [Cave approach](island_replacement/island_cave.png), [real interior and relic](island_replacement/island_cave_interior.png)
- [Beach and sea](island_replacement/island_beach.png)

Only the overview review camera suppresses HUD; third-person shots retain the approved gameplay interface. Hero positions are controlled camera-review placements; movement correctness is proven separately by actual-controller collision tests, not inferred from a screenshot.

## Files and commands

Existing modified files: `scripts/campaign.gd` (exploration factory), `scripts/island_exploration.gd` (grounded checkpoint compatibility), `assets/environment/coastal_water.gdshader` (default-preserving contour parameter). `scenes/main.tscn`, project.godot, HUD, hero, boar, old enemy/boss, save store and export/release files match their pre-change hashes.

Added: `scripts/island_candidate.gd`, `scripts/island_candidate_exploration.gd`, `scripts/island_landscape.gd`, `scenes/island_candidate.tscn`; prepared regional GLBs, five extracted albedos/import metadata and shaders under `assets/environment/new_island/`; original/editable source and reproducible local preparation scripts under `art_source/island/`; five island review/test scripts and generated UIDs; inspection/report/evidence in docs. `docs/.gdignore` was already present and remains unchanged.

Executed: local SHA-256 ZIP checkpoint/verification; Blender background original inspection/renders; repeated local background mesh preparation/export; Godot headless editor imports; explicit texture import optimization; Godot isolated regression scripts; native Godot screenshot and desktop measurement fixtures; local preservation-hash checks; `git diff --check`. No remote asset service, source upload, APK export, branch, commit or push.

To review in the editor, open `scenes/island_candidate.tscn` and press F6 (Run Current Scene). F5 still runs the old map. Isolate APPDATA when testing to avoid touching personal progress. **Do not switch main until the user approves the new map's visible quality.** Activation is one scene-script selection after that gate; rollback remains the untouched main scene and original source/checkpoint.

## Remaining limitations and decision

The candidate is connected and functionally tested, but source foliage fragments, stylized tree crowns, residual regional texture differences, some clipped slab/rock boundaries and deliberately simple river banks remain visible. The broad connector terrain also needs the owner's visual approval for density, route placement and scale. This work is not labeled a finished, commercially approved open world. The old active map is intentionally kept while this concrete candidate is reviewed. No further expansion or development phase begins without direction.
