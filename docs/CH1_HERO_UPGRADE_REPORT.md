# Aru starter warrior visual review — 2026-11-14

**Review candidate; owner approval pending.** The owner rejected the former hero as a placeholder. This work replaces that body/outfit presentation inside the existing game. It does not start Phase 3 or establish commercial release acceptance.

## What changed

- Replaced the base full-body/procedural tunic, cylinder boots and fitted-trouser overlay with Quaternius's rigged male Ranger outfit: shaped cloth tunic/trousers, leather belts, bracers, fitted boots, hood and one light shoulder plate. It is a simple starting adventurer, with no crown or heavy endgame armor.
- Retained the recognizable base face, eyes and eyebrows, rest-transformed/skinned to the new outfit skeleton. Dark brown eyebrows replace the pale source appearance. The body, hands and clothing now use the authored outfit mesh and its regular human proportions.
- Preserved the 65-bone naming convention, eleven animation choices, animation priority and action durations. Retarget paths resolve the actual new skeleton; right fingers curl around the resized sword grip while the original animation drives the wrist.
- Combined geometry into five skinned material surfaces, simplified selected clothing parts offline, removed a duplicate belt and capped/compressed textures. No clothing generation or physics simulation runs per frame.
- Source details, bundled CC0 notices, exact archive hash and regeneration steps: [asset provenance](../assets/characters/aru/README.md). No private source code, assets or session data were uploaded to obtain the public author pack.

The new runtime model is `assets/characters/aru/starter_warrior.scn`. Original base-model files, textures and animation source remain intact. Only `hero_visual.gd` and the sword's visual geometry/placement in `player.gd` change existing executable game code. Collision shapes, attack volumes, damage, timing, movement, input, saves, HUD, world and enemy systems remain unchanged.

## Actual in-game screenshots

Native Godot 4.7.2 GL Compatibility renders, 1280×720, existing main scene and HUD. Synthetic isolated save profile; player/enemy physics paused for repeatable inspection. Close views use a temporary inspection camera, not a replacement scene or concept render. The default gameplay view uses the existing game camera. These are visual review evidence, not owner approval.

| View | Screenshot |
| --- | --- |
| Normal gameplay camera | [Gameplay](../.validation/hero_upgrade_2026-11-14/after_gameplay.png) |
| Front | [Front](../.validation/hero_upgrade_2026-11-14/after_front.png) |
| Front three-quarter | [Three-quarter](../.validation/hero_upgrade_2026-11-14/after_three_quarter.png) |
| Side | [Side](../.validation/hero_upgrade_2026-11-14/after_side.png) |
| Back | [Back](../.validation/hero_upgrade_2026-11-14/after_back.png) |
| Sword grip detail | [Grip](../.validation/hero_upgrade_2026-11-14/after_grip_detail.png) |
| Walk / sword attack | [Walk](../.validation/hero_upgrade_2026-11-14/after_walk.png), [Attack](../.validation/hero_upgrade_2026-11-14/after_attack.png) |
| Roll / jump | [Roll](../.validation/hero_upgrade_2026-11-14/after_roll.png), [Jump](../.validation/hero_upgrade_2026-11-14/after_jump.png) |
| Rejected baseline | [Old front](../.validation/hero_upgrade_2026-11-14/before_front.png), [Old back](../.validation/hero_upgrade_2026-11-14/before_back.png) |

Screenshots are also supplied in the separate local review bundle because `.validation` is intentionally gitignored.

## Animation and gameplay verification

All eight targeted checks passed after the final finger-pose change: `hero_presentation_check`, `hero_animation_check`, `jump_check`, `heavy_attack_check`, `combat_check`, `gameplay_check`, `hud_customization_check`, `mobile_controls_check`.

The presentation check verifies real skinned geometry, 65 skin binds, normalized finite vertex weights, valid bone indices, capped textures, bounded posed vertices, and actual hand-bone movement across all eleven clips: Sword_Idle, Walk, Sprint, Sword_Attack, Roll, Hit_Chest, Death01, Spell_Simple_Shoot, Jump_Start, Jump and Jump_Land. Animation never moves the CharacterBody collision node. The existing animation check verifies hand weapon attachment, speed scaling, action priority and terminal death. Native screenshots inspect idle, walk, attack, roll and jump.

Both hero checks also passed separately under the native GL Compatibility renderer after regenerating the prepared model from the documented source staging helper; no native-check diagnostics were recorded.

Diagnostics are retained in the evidence JSON: `heavy_attack_check` reports two ObjectDB instances at shutdown; `gameplay_check` reports seven `draw_rect` filled-width warnings. Their behavioral assertions pass. The native screenshot run has no stderr diagnostics. This is not a claim that every project warning or release issue is resolved.

## Performance impact

| Measured item | Rejected baseline | Updated hero |
| --- | ---: | ---: |
| Runtime hero triangles, including sword | 17,000 | 18,358 (+8.0%) |
| Runtime hero vertices, including sword | 16,389 | 15,590 (−4.9%) |
| Runtime hero surfaces, including sword | 16 | 8 |
| Skeleton bones | 65 | 65 |
| Unique imported texture payload including mipmaps | 19,704,624 bytes | 4,762,416 bytes (−75.8%) |
| Stationary whole-scene draw calls | 234 | 212 |
| Stationary whole-scene primitives | 190,003 | 198,157 |
| Sample median frame interval | 29.976 ms | 29.382 ms |
| Sample p95 frame interval | 34.819 ms | 34.633 ms |

Geometry and texture counts are direct runtime inspection. Texture payload is the sum of unique platform-specific imported image data, not peak VRAM, total process memory or a phone measurement. The new body alone has 18,218 triangles and five surfaces; the sword contributes the remainder. Prepared asset files are about 4.8 MB, excluding existing shared sources/import caches.

Frame samples use 30 warmup frames and 90 stationary force-drawn frames in a minimized Windows GL Compatibility window on Intel Iris Xe, with the same scene, camera and hero position. The sample includes CPU scheduling and is short; repeated updated runs varied roughly 26–32 ms median. The final sample above does **not** prove an FPS improvement. The concrete tradeoff is about 8% more hero triangles in return for authored clothing/hands/boots, fewer surfaces/vertices and much smaller texture payload. No extra bones, cloth simulation or expensive UI effects were introduced. Sustained Android FPS, thermal behavior and device-specific texture support remain unverified. No new APK or phone certification is claimed.

## Preservation and handoff

Work stayed on existing `main`, starting at `f8fb330`; no branch, worktree, commit or push was created. A SHA-256 manifest of 344 existing files and scoped source snapshots were captured before changes. The preservation record lists only the intended two scripts and documentation as changed; original character/animation binaries, terrain, sea, HUD, persistence and input sources remain byte-for-byte unchanged. Tests use isolated synthetic save profiles, not the owner's save.

Preservation result: 335 existing files unchanged, nine intended script/documentation changes, no missing files or unexpected changes. `git diff --check` passed. Machine-readable evidence: [headless checks](../.validation/hero_upgrade_2026-11-14/results.json), [native checks](../.validation/hero_upgrade_2026-11-14/native_results.json), [before metrics](../.validation/hero_upgrade_2026-11-14/before_metrics.json), [after metrics](../.validation/hero_upgrade_2026-11-14/after_metrics.json), [texture comparison](../.validation/hero_upgrade_2026-11-14/texture_comparison.json), [preservation](../.validation/hero_upgrade_2026-11-14/preservation.json).

Review this hero's silhouette, starter outfit and animation poses before approving the visual direction. Phase 3 remains unstarted. Visual acceptance and physical mobile playtesting remain pending.
