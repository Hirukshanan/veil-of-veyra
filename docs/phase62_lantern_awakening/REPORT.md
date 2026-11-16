# Phase 6.2 — The Lantern Awakening

The existing candidate island now contains a once-per-journey cave cinematic. The hero interacts with the inner-chamber altar, places a lantern, watches the stone platform descend, sees a fractured seal break into falling stones, hears a distant Dragon roar and rising music, and follows a cinematic camera into the reserved dark hall. One enlarged crimson eye opens. Music cuts, the screen fades black, and normal hero control returns with the passage permanently open.

## Prerequisites and inventory decision

The approved Phase 6.1 dependency view already requires Chapter I victory, a complete three-fragment seal and cave relic ID 1. Phase 6.2 also checks the restored Northern Lantern flag, which is already implied by a valid completed Chapter I save. Existing bounty/grove quests, the other two relics and the optional Boar are not required.

The current inventory has potions, upgrades and saved collectible IDs, but no portable lantern item. The restored northern light and cave relic therefore authorize a ceremonial lantern prop at this altar. The original Northern Lantern remains its existing world interaction. No saved item, seal fragment, relic, shard or potion is consumed. This decision reuses the approved flags without adding an inventory architecture. Existing rewards remain owned by the established campaign functions.

## Sequence and implementation

| Time in event | Action |
| --- | --- |
| 0–1.2 s | Lantern moves from beside the hero to the carved stone platform and begins glowing. |
| 1.2–4.1 s | The complete pedestal physically lowers 2.8 m, accompanied by stone rumble and a bounded dust burst. |
| 4.2–5.8 s | Branching fractures spread over the rock seal. |
| 5.8–8 s | Twenty fitted stone cells fall with gravity and rotation; the blocking collision disables. Dust and fracture audio accompany the break. |
| 7.2–12.4 s | A spatial roar echoes from the deep hall; the camera eases from the altar/wall views through the opened passage while darkness builds. |
| 12.4–13.3 s | The camera shows complete darkness, with Skip still available. |
| 13.3–15.7 s | One crimson eye slowly opens. |
| 15.7–18 s | Music cuts, black fade holds briefly, then fades back to the hero and HUD. |

All camera motion, geometry movement, light, audio and particles run inside Godot. The timeline directly controls scene nodes. Twenty original fitted fracture cells come from a deterministic Voronoi generator. Four small rubble pieces remain at the sides after completion and reload. The approved cave GLB and its collision source remain unchanged; the new seal and pedestal are separate event props. The original relic and inner-chamber routes stay accessible. The existing reserved-hall approach is sealed until this story event opens it.

The eye is a cropped surface patch read directly from the approved Charcoal Dragon mesh resource. Its local eye region is enlarged and uses a crimson opening mask. The teaser instantiates no Dragon actor, skeleton, complete face, wings or body. The approved source GLB and existing Dragon rendering/combat scripts are hash-identical.

The normal world lighting is reused during the approach. A local shadow-free light supplies altar readability. A bounded screen fade builds passage darkness, followed by an eye-only render layer against black. This avoids changing the island sun/sky during the event. The earlier offscreen prewarm experiment was removed because measured stalls remained; it is not a loading requirement.

## Control, Skip and persistence

Existing Pick/Interact calls route to the altar only within 2.7 m and after all prerequisites. While active, the controller clears queued input, holds hero/enemy physics, disables hero camera input, protects health and hides gameplay layers. Existing process/input states, the original hero camera and HUD are restored at the end. Skip and the normal back action apply the same final world state. The event awards no currency and cannot replay after completion.

The optional boolean `world.lantern_awakening` is validated inside the existing version-4 campaign save. Older saves without it load as unplayed. A true flag requires completed Chapter I and the cave relic, alongside the existing completed-save validation. The existing atomic temporary/backup save path persists the final state. Save errors leave the in-session opening intact and expose a save-pending message; the campaign autosave can retry. An interrupted event that was never completed can start again after reload.

## Verification and evidence

**14/14 regression programs pass** with exit code 0 and no final script/shader/engine errors. The focused test covers each missing prerequisite, optional side quests remaining incomplete, valid Interact entry, immunity, duplicate starts, descending geometry, wall collision removal, camera clearance, one-eye mask, real hero-body traversal and return, unchanged 80-shard balance, saved completion, journal completion and Skip idempotence. Existing quest/relic/lantern/boss, old-save/equipment, atomic-save, persistent-world, cave-floor/collision, river escape, repeated Boar attack, heavy combat, gestures, HUD customization and Settings tests also pass. Raw logs and exact run metadata are included.

The full movie is recorded by Godot's movie writer with its actual stereo engine audio. The MP4 is a delivery encode of that recording, not a slideshow. It includes normal hero approach, the complete event, restored gameplay and the completed journal entry. The recording uses a synthetic eligible save with optional quests incomplete; enemy physics is held for framing. Matched before/after wall and pedestal inspection views use a consistent cave inspection camera. The 20 fps fixed-step recording is not live Android FPS evidence.

Earlier diagnostics include a Windows `0xC0000005` teardown exit and an intermittent resource-release warning. Temporary cave audio-bus ownership was made explicit and the complete Dragon-node instantiation was removed. Final native recording, final live cost run and focused tests exit cleanly. These earlier diagnostics remain included; their sole root cause was not established. The existing filled `draw_rect` width warning remains in some HUD logs.

## Measured desktop rendering cost

1280x720, native HUD, 720-high 3D, shadows off, 30 FPS cap, actors held; live timing, no movie writer. Baseline uses a copied pre-Phase-6.2 candidate with the approved journal. Wall inspection views use the same camera. Live cinematic sampling spans its changing camera views, so its primitive average is not a matched fixed view. Static allocator and video-memory counters describe this Windows engine/driver, not Android process RAM.

| Sample | Draw calls | Submitted primitives | Median ms | p95 ms | Max ms | Render CPU median ms | GPU median ms | Engine static MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| baseline_cave | 14.0 | 142654 | 33.34 | 33.47 | 33.68 | 0.80 | 3.23 | 134.6 |
| sealed_cave | 34.0 | 143070 | 33.34 | 33.59 | 33.84 | 1.05 | 3.14 | 136.3 |
| live_cinematic | 40.6 | 115807 | 33.34 | 33.48 | 4493.05 | 1.08 | 3.84 | 136.5 |
| opened_cave | 18.0 | 142770 | 33.33 | 33.49 | 33.58 | 1.05 | 3.68 | 136.4 |

**The live cinematic still has transition stalls, with a measured maximum of 4493.05 ms on this Windows machine.** The median and p95 values must not be read as uninterrupted smooth playback. Exact spike stages/times are in `rendering_cost.json`. Reducing global lighting changes reduced some transition work, but these remaining stalls are unresolved. Cold-start Android behavior requires physical testing. Do not use the fixed-step video to approve mobile performance or claim stable 30/60 FPS. The next performance investigation should profile these transition stalls on the target A37 before production activation.

Geometry/effect bounds are modest: twenty stone cells during fracture, four settled pieces afterward, one cropped eye surface, one shadow-free event light, one lantern light and 32 short-lived dust particles. Meshes cull beyond 100 m. There is no volumetric simulation or full cave/terrain rebuild.

## Files and audio licensing

Existing files changed in this phase are `scripts/island_candidate.gd` (candidate trigger, input/menu guards and HUD hint), `scripts/candidate_journal.gd` (one new Main/Completed quest projection) and `scripts/campaign_store.gd` (optional flag validation). New runtime files are `scripts/lantern_awakening.gd`, the five WAVs/license/manifest in `assets/audio/lantern_awakening/`, and `assets/environment/lantern_awakening/seal_cells.json`. New focused/reproduction tests are under `tests/lantern_awakening_*.gd`. Generators are in `art_source/phase62_lantern_awakening/`. This evidence directory supplies logs, captures, movie and preservation hashes.

Stone, fracture, breathing and the tension score are original deterministic procedural audio. The roar combines original synthesis with the existing CC0 fvcalderan vocal derivative, credited in its manifest and license. Runtime gains and source peak headroom are bounded; recorded PCM peak/RMS and clipping checks are in `media_verification.json`. The tension bed is long enough to remain available through delayed frames and is explicitly stopped at the eye cue. Existing sound-volume preferences remain in effect.

## Limits and review

The prop placement animation preserves the hero's existing rig/stance; a bespoke hand-placement animation was not added. The stone altar and fracture surfaces use the existing stylized rock material. The eye is a localized stylized teaser treatment. Physical Samsung A37 timing, sound, visual comfort and performance remain unverified. Transition stalls above are the main remaining performance issue.

Extract the ZIP and open `gallery.html`. The `project/` directory contains the current runtime and tests for independent review in Godot 4.7.2. Run `scenes/island_candidate.tscn` directly. The production main scene setting remains `scenes/main.tscn`; old map source and approved cave assets remain present. Use fresh temporary APPDATA and `VEYRA_TEST=1` for synthetic tests. No Phase 6.3, new boss, Chapter II, production activation or external upload was performed. Stop for visual approval.

## Independent ZIP validation

The archive was extracted into a fresh directory. Every supplied manifest hash and all 17 original PNG hashes matched. The offline gallery loaded all images without missing links. The extracted project passed the full event, Skip, traversal and save/reload test with exit code 0.

The first headless editor import crashed with Windows exit code 3221225477 (`0xC0000005`) while importing resources, with no script error. Repeating the same import against the partially imported extraction completed successfully (exit 0), then the extracted runtime test passed. This is a recorded import reliability limitation, not a clean first-import pass. Its root cause remains unestablished; both raw import attempts are supplied under `package_checks/`. Independent reviewers may need to rerun the import if the same native-engine failure occurs. No engine binary or production configuration was changed to hide this failure.
