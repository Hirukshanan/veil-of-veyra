# Veil of Veyra — Chapter I / Phase 1 Report

Date: 2026-11-13 (Asia/Colombo). Authorized by the owner after Phase 0. Starting state: clean `main`, commit `f7203d1`.

- **Phase goal:** connect the existing island's locations, improve navigation and reserve a separate future boss clearing and Dragon viewpoint.
- **Baseline findings (verified / not verified):** island, sea, hills, woodland and quests were reusable. Player-sized sweeps exposed narrow routes around existing rocks/trunks; actual walking exposed a southern ruin-pillar obstruction. Routes now avoid these solid obstacles. A tree initially blocked the proposed vista.
- **Implemented (with file paths):** `scripts/chapter_one_region.gd` plus UID: three appended trails, four solid stone waymarks, Ancient Grove `(9,0,-45)` with 9 m usable radius, and oriented Dragon perch/camera markers. `scripts/island_terrain.gd`: shared trail/mask extension and small central trunk/pillar detour. `scripts/island_forest.gd`: grove/vista exclusions. `scripts/island_exploration.gd`: region attachment. `scripts/island_map.gd` and `scripts/campaign.gd`: map landmarks, compact captions and trail explanation. `tests/chapter_route_check.gd` plus UID: clearance, real traversal and save/reopen regression. Existing regions check now verifies both woodland patches after intentional clearances.
- **Reused without changing:** terrain mesh/heights/radii, sea shader/material, original route indices, optional branches 1–4, all quest/pickup/waystone coordinates and IDs, enemy IDs/stats, retired spawn ID 5, hero/Dragon assets/eyes/animations, reward logic and save version 4. No new branch/worktree or external asset acquisition.
- **Deferred, with reason:** Bear, reveal playback/skip/resume, chapter unlock, hero/HUD/touch-lock and Chapter II content belong to later approved phases. Markers do not create a camera, spawn a Dragon or change progression. Physical-phone acceptance needs connected hardware.
- **Build / automated tests run and results:** **20/20 targeted Godot checks PASS**, with no shutdown warnings in this selected suite. Complete coast test: 117.33 seconds. `git diff --check` passes. The actual-controller test visits 711 waypoints, returns to shore, visits/returns from Moonleaf and reopens a partial-progress save at Ancient Grove. Native rendered rerun also passes. Android packaging retains the Phase 0 editor-config/SDK-resolution blocker in the restricted runner; no new APK was built or existing APK overwritten.
- **Manual device tests (device, OS, FPS / thermal):** current sanitized ADB probe shows zero connected devices. No phone OS/cutout, two-thumb input, sustained FPS, thermal or battery acceptance was performed. Desktop sampling below is not a mobile benchmark.
- **Screenshots / recordings:** native before/after overview/woodland/map views, new grove/vista and validation-only Dragon framing preview reviewed. Full controlled route recorded as a **20.4-second** video, 4x simulation with enemies paused. It exercises geography, not combat balance or phone performance. MP4 decode check passed; representative start/middle/end frames reviewed.
- **Asset licenses added or changed:** none. Original procedural waymarks share the existing CC0 Poly Haven rock material. No private source/assets/screenshots were uploaded. Existing release-license gaps remain in `CH1_ASSETS.md`.
- **Known bugs and risks:** phone acceptance and packaging environment remain open. Both desktop minimized-window samples include a long initial interval; this does not certify hitch-free gameplay. Current Dragon combat boss and temporary hero remain for their later phases. Story reveal readability/trigger semantics are not delivered by this camera reservation. Phase 0's unrelated heavy/sprint shutdown warnings are not declared fixed by this warning-free subset.
- **Updated documentation files:** `README.md`, `RELEASE_STATUS.md`, `VALIDATION.md`, `docs/CH1_STATUS.md`, `docs/CH1_BACKLOG.md`, `docs/CH1_ASSETS.md`, `docs/CH1_TEST_MATRIX.md`, new `docs/CH1_REGION_LAYOUT.md` and this report.
- **Suggested single next phase / small task:** **Phase 2 — touch lock/switch, two-thumb HUD and camera/input stability**, retaining the existing rig/controller. Start only after review; phone acceptance stays open until hardware is available.
- **Waiting for user's review before continuing:** **Yes.** Desktop implementation/verification is complete; full hardware acceptance remains pending. Phase 2 has not started. No commit, push or deployment was performed.

## Tests and preservation

Checks: `chapter_route_check`, `island_regions_check`, `mountain_demons_check`, `terrain_material_check`, `prop_collision_check`, `camera_check`, `navigation_check`, `beach_seals_check`, `grove_check`, `herbal_check`, `persistent_world_check`, `save_check`, `autosave_check`, `gameplay_check`, `island_map_check`, `layout_check`, `safe_area_check`, `fast_travel_check`, `environment_check`, `shallow_water_check`.

All checks use isolated synthetic `APPDATA` and `VEYRA_TEST=1` under `.validation/ch1_phase1_2026-11-13/`. Personal campaign/settings files were not used. New route testing runs the actual controller at approximately 30 Hz simulation steps with 4x wall-time acceleration and frozen enemy AI. Runtime camera collision remains covered by the existing camera/obstacle tests.

Earlier development failures were corrected before the final suite: test type annotations, capsule clearance around existing rocks/trunks/pillar, and a forest-count assumption incompatible with deliberate new clearings. Forest count changes **54 → 38**; each woodland retains at least 12 tall trees, with original mesh/height/culling budgets and solid remaining trunks. The existing minimum-40 check became a 32–65 combined budget plus per-woodland coverage; it was not removed.

Rollback: apply only this phase's scoped diff against `f7203d1` and remove its new region/test/docs/UID files if needed. The ignored evidence directory retains the original 313-file hash manifest and final preservation comparison. Never reset personal saves or clean unrelated work.

Final preservation comparison: 313 original tracked files checked, 13 planned files modified, 300 untouched, zero unexpected tracked changes. Six new files are limited to the region/test scripts with UID sidecars and two phase documents. Branch remains `main` at the starting commit; all changes are uncommitted for owner review.

## Desktop render sample

Windows / Intel Iris Xe / GL Compatibility, minimized native window, 90 stationary force-drawn frames per view. The second view renders both the arrival viewport and a fixed eastern-woodland inspection viewport, so its counters are not a single gameplay-camera budget.

| View | Before draw calls / primitives | After draw calls / primitives | Before median / p95 ms | After median / p95 ms |
| --- | --- | --- | --- | --- |
| Arrival | 534 / 646,633 | 533 / 591,428 | 40.369 / 46.388 | 34.567 / 39.700 |
| Fixed eastern woodland, dual viewport | 705 / 1,077,582 | 704 / 940,270 | 82.307 / 94.888 | 65.169 / 72.788 |

Initial recorded arrival intervals were 16,749.892 ms before and 17,050.598 ms after in this minimized-window capture method. These are not clean sustained gameplay samples; do not infer phone FPS or claim that all hitches are fixed from the medians. The reliable scope is the reproducible method, reduced submitted geometry, reviewed visuals and passing physical traversal. A real-device main-route/thermal baseline remains pending.

## Visual evidence

- [Full controlled route video](../.validation/ch1_phase1_2026-11-13/chapter1-route-review.mp4) — 4x simulation, enemies paused, 711 waypoints and Moonleaf return.
- [Island overview](../.validation/ch1_phase1_2026-11-13/after_overview.png), [woodland trail](../.validation/ch1_phase1_2026-11-13/after_woodland.png), [Ancient Grove](../.validation/ch1_phase1_2026-11-13/after_grove_clearing.png).
- [Map at 1280x720](../.validation/ch1_phase1_2026-11-13/after_map.png), [map at 800x450](../.validation/ch1_phase1_2026-11-13/after_map_800.png).
- [Dragon camera preview](../.validation/ch1_phase1_2026-11-13/after_dragon_camera_preview.png) — retained model appears only in the ignored validation script; this is not an implemented story reveal.

See [region layout](CH1_REGION_LAYOUT.md) for exact routes/anchors and [status](CH1_STATUS.md) for acceptance boundaries.
