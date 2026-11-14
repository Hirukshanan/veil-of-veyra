# Chapter I backlog

Date: 2026-11-13. Status derives from the local Phase 0 audit. Items are deduplicated; working systems are reused. No gameplay work in this list was implemented by the audit.

| ID | Scope / phase | Work | Acceptance / dependency |
| --- | --- | --- | --- |
| C1-01 | Chapter I / 1 | Establish the connected shore/hill/forest/ruin/grove route using existing geography. | Out-and-back traversal, solid obstacles, unblocked quest access, clear coast, saved-position regression. |
| C1-02 | Chapter I / 1 | Reserve Bear arena and distant dragon camera/perch sightline. | Document unobstructed footprints; preserve optional Moonleaf clearing and current sea; no boss/cinematic implemented yet. |
| C1-03 | Chapter I / 2 | Add touch lock, unlock and switch with clear camera/input priorities. | Move + look + attack with separate pointers; invalid/range/occlusion behavior; no UI swipe capture conflict. Retain Tab. |
| C1-04 | Chapter I / 2 | Refine two-thumb HUD, control scale and safe areas; consider handedness preset. | Real phone aspect/cutout test; primary attack clear; settings persist; menu input guards. Correct stale LOCK guide. |
| C1-05 | Chapter I / 2,4 | Grounded adventurer outfit and visibly better earned equipment. | Reuse rig/controller; keep earned levels; at least one model/material/weapon improvement visible and statistically useful. |
| C1-06 | Chapter I / 3 | Decide intended fox identity using current source/model evidence; balance with measured encounters. | Current active enemies have 18/17/21 HP, not an independently verified fox. Do not inflate HP or restore spawn ID 5. |
| C1-07 | Chapter I / 3 | Add one complete Demon Boar encounter before expanding roster. | Licensed asset, telegraphed charge/recovery, collider, feedback/reward and distance AI behavior; fair dodge window. |
| C1-08 | Chapter I / 3 | Optional Venom Serpent after representative encounter is stable. | Only if asset/AI budget permits; visible strike/poison warning. Procedural fallback is not a shipped specialist. |
| C1-09 | Chapter I / 4 | Extend restrained inventory/material progression and potion crafting if needed. | Reuse 13 finite herbs, existing healing and numerical upgrades; no grind gate; useful visible payoff and persistence. |
| C1-10 | Chapter I / 4,5 | Reconcile existing lantern/seals and completion saves with Bear story. | Versioned migration preserving all earned progress and one-time rewards, including old completed journeys. Approve semantics before replacement. |
| C1-11 | Chapter I / 5 | Cursed Bear regional boss. | Licensed rig, fair claws/slam/roar/charge, phases, arena/camera, one-time reward and saved completion. Dragon is not the Chapter I combat boss. |
| C1-12 | Chapter I / 5 | Recognizable recurring Dark Dragon observation/departure after Bear. | Reuse existing black body/ivory horns/skinned eyes; on-screen footage; once/skip/resume/load tests; no forced Dragon combat. |
| C1-13 | Chapter I / 5 | Chapter II story threshold without a real download service. | Locked/unlocked-not-downloaded state saves; older regions remain explorable. Never present an unimplemented download as functional. |
| C1-14 | Chapter I / 6 | Cohesive environment/audio/hit-feedback polish and profiling. | Maintain sea/collisions; readable boss tells; measure CPU/GPU/frame time/memory and ~20-minute thermal behavior on agreed phone. |
| C1-15 | Chapter I / 6 | Investigate shutdown ObjectDB leaks observed in heavy/sprint checks. | Determine ownership, fix only reproduced leaks; behavior passes are not a clean shutdown claim. |
| C1-16 | Chapter I / 7 | Resolve asset ledger gaps, especially parchment and standalone wolf license evidence. | Document commercial-use provenance for all shipped art/audio/fonts; replace unclear artwork locally only with approval for the concrete change. |
| C1-17 | Chapter I / 7 | New-player/save/resume/offline/phone QA and release-candidate build. | Bear + reveal + unlock full walkthrough; old saves; no critical blockers; documented device results. |
| C1-18 | Chapter I / 7 | Release signing/AAB/store/privacy readiness near launch. | Separate release review; no key/password disclosure; no forced ads/pay-to-win/boss gates. Debug APK is insufficient. |
| D-01 | Phase 2 / desktop implemented, review pending | Separate drag/resize/opacity HUD editor, explicitly requested by owner. | Battle/Classic/Left-Handed presets, normalized safe-area bounds, overlap/center rejection, Save/Cancel/Reset and backup recovery tested. Screenshot approval and phone comfort remain pending. |
| D-02 | Deferred | Complex Dragon locomotion/attack overhaul. | Ground gait, weighted legs, neck/wing polish and final combat remain deferred. This never defers visible Chapter I presence. |
| L-01 | Later chapter | Chapter II geography, quests and asset delivery. | Begin only after Chapter I review; preserve connected island and separate story unlock from asset readiness. |
| L-02 | Later chapter | Increasing purposeful Dragon presence in every chapter; final confrontation. | Same main Dragon identity throughout; each future scene separately designed/authorized. |
| L-03 | Deferred | Full economy/ads/billing, cloud/accounts, multiplayer, mounts, huge inventories/skill trees and additional species. | No forced advertisements or paid story/boss gate introduced as a roadmap side effect. |

Already reusable: persistent island, beach/forest meshes and collision, sea shader, hero rig/jump/controller, scroll-only bounty, three seal fragments, herbs/grove quest, fast travel, numeric upgrades and version-4 save/backup/async autosave. Passing desktop tests do not remove physical-device acceptance requirements.

Next authorized scope after review: **Phase 1 only**. Preserve `main`, original user changes, the retired giant-wolf spawn, no mandatory NPC, original Dragon eyes/identity and personal saves.

## Phase 1 implementation update

The owner subsequently authorized Phase 1. C1-01 and C1-02 now have desktop implementations: connected routes, existing trunk/pillar avoidance, four solid waymarks, separate Ancient Grove floor, map landmarks and a clear, oriented Dragon camera/perch reservation. See `CH1_REGION_LAYOUT.md` and `CH1_PHASE1_REPORT.md` for exact evidence and phone/build limitations. This does not implement C1-11/C1-12 boss/reveal behavior. Phase 2 remains a proposal until owner review.

## Phase 2 implementation update

C1-03/C1-04 and D-01 now include the owner's concept-guided gold/dark gameplay HUD and separate Settings > Controls > Customize HUD editor. Actual screenshots and 19 current desktop checks are in CH1_HUD_REDESIGN_REPORT.md. C1-05 retains provisional starter clothing; final art and earned visual upgrades remain open. Physical-phone input, cutouts and sustained performance are unverified. Phase 3 must wait for explicit approval of the Phase 2 screenshots and explanation.
