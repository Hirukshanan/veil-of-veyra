# Chapter I status

Audit date: 2026-11-13 (Asia/Colombo). Project: **Veil of Veyra**, existing Godot repository.

Planning input: `Veil_of_Vera_Chapter_I_Agent_Plan_UPDATED.md`, v1.1, supplied by the owner. This is a design specification to reconcile with the actual game, not evidence that its features already exist. Preserve the repository's Veyra name and established Aru/lantern content until a naming change is explicitly requested.

## Execution boundaries

- Work on the existing `main` branch. Do not create another branch or worktree.
- Phase 0 covered inspection, isolated tests, baseline rendering/builds, and documentation only. Its report records that phase's unchanged gameplay baseline.
- The owner authorized Phase 1 after reviewing the audit. Work is limited to existing-island routes, wayfinding, a separate grove clearing and future Dragon sightline anchors. Review is required before Phase 2.
- Chat communication uses Thanglish; repository documents, source comments, and any future commit messages use English.
- No commit, push, deployment, external source-code upload, or telemetry enrollment was performed.

## Milestones

| Phase | State | Evidence / next action |
| --- | --- | --- |
| 0: Repository audit | AUDITED | Owner authorized Phase 1. Audit: 28 checks passed, seven renders, Android editor-config export blocker and phone limits documented. |
| 1: Geography/navigation | IN_PROGRESS — hardware acceptance pending | Desktop implementation verified: 20 targeted checks, full rendered 711-waypoint route, grove/vista/map captures. Owner review and physical-device performance acceptance remain open. See `CH1_PHASE1_REPORT.md`. |
| 2: Hero/mobile controls | AUDITED | Rig, jump, sensitivity, safe-area layouts and keyboard lock exist. Touch lock/switch, control scale and visible equipment progression remain. |
| 3: Common demons | AUDITED | Five live wolf-variant spawns; retired duplicate ID 5 remains cleared. No active standalone fox, charge-boar or poison-serpent system. |
| 4: Quest/progression | AUDITED | Three seal fragments, scroll-only quests, herbs, healing, numerical upgrades and v4 persistence exist. Inventory/crafting and visual gear improvements are incomplete. |
| 5: Boss/reveal/unlock | AUDITED | Existing Tidewraith Dragon is a combat boss. Cursed Bear, non-combat dragon reveal and Chapter II story threshold are absent. Migration/reconciliation required. |
| 6: Polish/profiling | AUDITED | Foliage batching/culling and placeholder audio exist. Sustained physical-device profiling and HUD editor remain unverified/absent. |
| 7: Release candidate | NOT_STARTED | Licensing gaps, phone QA, release signing/AAB and release checks remain. Existing debug APK is not a release candidate. |

`AUDITED` means inspected, not implemented. Desktop checks do not establish phone playability. Phase 1 will retain a physical-device acceptance limitation until a phone is available.

## Preserved working-tree baseline

Starting HEAD: `015e1d4` (`feat: add jump button and character jump animations`). Existing modified files: `RELEASE_STATUS.md`, `VALIDATION.md`, `export_presets.cfg`. Existing untracked file: `tests/jump_check.gd.uid`. These belong to the pre-audit state and must not be reset, staged wholesale, overwritten or included in an unrelated commit.

Git inspection required an explicit `--work-tree` in this execution environment; it resolves to the requested existing repository. No Git configuration was changed.

Final preservation check: all 306 tracked files match their pre-audit SHA-256 hashes; the branch remains `main`. New tracked-scope additions consist only of six `docs/CH1_*.md` documents. Test/capture artifacts remain ignored. Existing dirty files remain byte-for-byte unchanged.

Rollback for this phase: remove only the new `docs/CH1_*.md` documentation and this audit's ignored `.validation/ch1_audit_2026-11-13/` artifacts if desired. Never use a whole-tree reset or clean. A tracked-file hash manifest is retained privately in that evidence directory to check preservation.

Related documents: `CH1_AUDIT.md`, `CH1_BACKLOG.md`, `CH1_ASSETS.md`, `CH1_TEST_MATRIX.md`.

## Phase 1 implementation boundary

The owner committed Phase 0 as `f7203d1`; Phase 1 began with a clean `main` working tree (313 tracked files). A new per-file hash snapshot is local in `.validation/ch1_phase1_2026-11-13/tracked-before.json`.

Implemented source changes: `scripts/chapter_one_region.gd` (shared region/route/anchor definitions and small wayfinding markers), `scripts/island_terrain.gd` (append trails, avoid an existing central trunk/pillar and reuse the cached mask for the grove floor), `scripts/island_forest.gd` (reserve grove/vista clearance), `scripts/island_exploration.gd` (attach region landmarks), `scripts/island_map.gd` and the map legend in `scripts/campaign.gd`. Added `tests/chapter_route_check.gd`, adapted the existing regions check to per-woodland coverage, and updated documentation. New script UID sidecars were generated with Godot ResourceUID.

Risk/rollback: new trails can expose narrow collisions and the reserved clearing changes deterministic tree placement. Verify swept player clearance, real out-and-back motion, existing quest access, camera/vista rays and foliage budgets. Keep terrain height/radii, sea shader, enemies, quest IDs and save schema untouched. Retain solid obstacles; route around them. No new third-party assets or per-frame path generation. Roll back only the phase's scoped diff against `f7203d1`; never reset the whole tree or personal saves.

Final desktop evidence: 20/20 checks pass with no warnings in this subset; full native route rerun passes and records 20.4 seconds at 4x simulation with enemies paused. Seven principal after screenshots include the new clearing, map at two sizes and validation-only Dragon framing. Forest count is 38, with both woodland patches retaining at least 12 tall trees. No phone is connected; sustained mobile performance remains unverified. Android packaging retains the previously documented editor-config access/SDK-resolution blocker; no APK is claimed. Phase 2 is not started and requires owner review.

Final preservation check: 313 pre-phase tracked files compared; 13 planned files modified, 300 unchanged, no unexpected changes. Six new region/test/UID/document files are added. All Phase 1 changes remain uncommitted on `main` for review.
