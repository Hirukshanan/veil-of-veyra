# Veil of Veyra — Chapter I / Phase 2 Report

> Historical controls/outfit implementation report. The owner rejected this HUD appearance and subsequently requested the two-interface redesign. Its HUD layout, editor deferral and next-phase proposal are superseded by [CH1_HUD_REDESIGN_REPORT.md](CH1_HUD_REDESIGN_REPORT.md). Phase 3 remains blocked on the owner's screenshot review.

Date: 2026-11-14 (Asia/Colombo). Baseline: clean `main`, `4f9a6ed`. Owner authorized Phase 2 after reviewing Phase 1.

- **Phase goal:** improve mobile movement/look/target/attack reliability and starter hero presentation while retaining the existing game/controller.
- **Baseline findings (verified / not verified):** working rig, attack/jump/dodge, safe-area root, saved camera sensitivity and keyboard lock existed. No touch lock/cycle, occlusion policy, camera-finger ownership, saved HUD scale/handedness or invert-Y existed. A held native button could fire on release after opening/closing a menu; the new regression reproduced this before the fix.
- **Implemented (with file paths):** `scripts/player.gd`: touch camera ownership, mirrored camera zone, invert-Y, visible-target lock/cycle and initial boss priority. `scripts/boss.gd`: adds a targeting group only. `scripts/main.gd`, new `scripts/mobile_hud.gd`: touch lock/switch controls, active-lock tint, disabled switch when unlocked, two-thumb layout and bounded scale/mirroring. `scripts/campaign.gd`: saved settings, updated guide and menu input cancellation. `scripts/round_button.gd` / `attack_button.gd`: cancel pending button presses/holds across menus. `scripts/hero_visual.gd`: provisional tunic, fitted skinned trousers, belt and boots on the retained rig. Two original SVGs plus import sidecars supply lock/cycle icons. New `tests/mobile_controls_check.gd` plus updated existing checks exercise behavior.
- **Reused without changing:** source hero/Dragon assets, original rig/clips, action hit timings, health/stamina/damage balance, island/sea/Phase 1 routes, quest coordinates/IDs, retired spawn ID 5, reward semantics and campaign save version 4. Existing settings files gain optional fields with safe defaults; no campaign migration/reset.
- **Deferred, with reason:** advanced drag/resize/opacity HUD editor is explicitly deferred until phone-tested default controls. Finished production character art and earned visual equipment upgrades remain open; the starter outfit is a provisional local blockout/CC0 derivative, not final character approval. No dead block/parry button, minimap system, new enemy species, Bear, Dragon story scene or Chapter II content was added.
- **Build / automated tests run and results:** **19/19 targeted checks PASS**; native minimized GL Compatibility mobile-input regression also passes. Actual viewport events test independent move/look/attack fingers, touch selection/cycling, visible boss priority, solid-wall rejection, keyboard compatibility, menu cancellation, both handedness presets, scale/cutout bounds and fresh-scene settings persistence. `git diff --check` passes. Headless asset import resolves new resources but reported an editor-settings safe-save diagnostic; no new Android APK/export success is claimed. The previously documented restricted-runner editor-config/SDK-resolution packaging issue remains.
- **Manual device tests (device, OS, FPS / thermal):** zero Android devices connected at the sanitized ADB probe. No physical two-thumb, native cutout, sustained FPS, thermal or battery test. Native desktop touch-event injection is not handset acceptance. No new phone performance claim.
- **Screenshots / recordings:** eight native captures reviewed: HUD at 1280x720/800x450, mirrored 800x450 HUD, settings, hero idle/walk/attack/roll. No phone recording. Native checks run minimized, without bringing a game window to the foreground.
- **Asset licenses added or changed:** no new external assets/dependencies. Icons are original vectors; flat starter gear is procedural; fitted trouser geometry derives locally from the existing Quaternius CC0 body with its skin weights. Existing attribution/license notices remain. No private code, models, screenshots or traces were uploaded.
- **Known bugs and risks:** provisional outfit still needs final art/animation seam review, especially shoulder/boot attachment polish; no earned gear-model progression. Additional visual geometry has not been profiled on a phone. `heavy_attack_check` passes but retains a two-ObjectDB-instance shutdown warning; other final selected check logs are warning-free. Earlier occasional warnings are not declared globally fixed. Packaging/hardware acceptance remains open. Boss priority applies on initial acquisition; switching deliberately cycles all visible eligible targets.
- **Updated documentation files:** `README.md`, `RELEASE_STATUS.md`, `VALIDATION.md`, `docs/CH1_STATUS.md`, `CH1_BACKLOG.md`, `CH1_ASSETS.md`, `CH1_TEST_MATRIX.md`, this report.
- **Suggested single next phase / small task:** **Phase 3 — common demon variety and combat feedback**, beginning with measured existing wolf/fox identity and one complete boar encounter proposal. Preserve the retired duplicate, current Dragon identity and existing balance; do not import an unlicensed asset or start the Bear/reveal phase early.
- **Waiting for user's review before continuing:** **Yes.** Desktop Phase 2 implementation is ready; device/final-art acceptance remains pending. No Phase 3 implementation, new branch, worktree, commit, push or deployment was performed.

## Control behavior

Crosshair/Tab acquires a visible living target within 14 m, preferring a visible boss; otherwise nearest distance wins. Repeating unlocks. Paired arrows cycle candidates by bearing with a stable tie-break. Solid terrain/props, death/removal, range exit, menus or deliberate camera drag release lock.

Only a finger beginning in unhandled open camera space owns rotation: the right-side 58% by default, mirrored left for the left-handed preset. Moving/attacking fingers do not rotate the view. Menu entry resets camera ownership, movement, attack holds and BaseButton's captured press state. This fixes a real delayed-action-on-menu-return defect rather than only changing button appearance.

Settings persist `hud_scale` (0.85–1.2), `invert_y` and `left_handed`, with validated legacy defaults. Scale is capped further by current safe-area dimensions to avoid overlap. Sprint sits above the movement stick; heal sits near the lower action group. A large attack button and the existing jump/dodge/burst/context actions are retained. Keyboard J/H/K/Space/Tab continue to work.

## Test evidence and scope

Final checks: `mobile_controls_check`, `target_lock_check`, `settings_check`, `layout_check`, `safe_area_check`, `interaction_controls_check`, `hero_animation_check`, `combat_pose_check`, `heavy_attack_check`, `gameplay_check`, `pause_check`, `jump_check`, `sprint_check`, `spirit_check`, `combat_check`, `save_check`, `persistent_world_check`, `beach_seals_check`, `camera_check`.

All checks use isolated synthetic `APPDATA` and `VEYRA_TEST=1` in `.validation/ch1_phase2_2026-11-14/`. Personal saves/settings are not used. Mobile regression covers 800x450 / 1280x720 / 1920x864, both handedness presets and three requested scales, plus inset combinations and saved-profile re-instantiation. These are desktop simulations, not Android certification.

The old `combat_check` teleported an enemy more than its 20 m home leash away, invalidating a contact-warning test. Its fixture now assigns the local home after teleport; gameplay enemy AI is untouched. Original no-touch-button assertions were updated to require the new affordance. Early rigid trouser cylinders clipped through legs; the final fitted derivative keeps the source skin weights and was reviewed in native poses.

Evidence: per-test logs/results JSON, import diagnostics, native touch log, eight PNGs and preservation hashes in the ignored directory. Desktop gameplay/pose checks establish retained behavior; production art quality and mobile cost remain explicit acceptance gaps.

## Review images

[Default 800x450 HUD](../.validation/ch1_phase2_2026-11-14/hud_800.png), [1280x720 HUD](../.validation/ch1_phase2_2026-11-14/hud_1280.png), [left-handed HUD](../.validation/ch1_phase2_2026-11-14/hud_left_800.png), [settings](../.validation/ch1_phase2_2026-11-14/control_settings.png).

[Starter outfit idle](../.validation/ch1_phase2_2026-11-14/hero_Sword_Idle.png), [walk](../.validation/ch1_phase2_2026-11-14/hero_Walk.png), [attack](../.validation/ch1_phase2_2026-11-14/hero_Sword_Attack.png), [roll](../.validation/ch1_phase2_2026-11-14/hero_Roll.png).

## Rollback

Use only this phase's scoped diff against `4f9a6ed` and its new files. Do not whole-tree reset/clean or erase personal saves. Baseline hashes cover 319 tracked files. Phase 1 geography, original assets, save store and export configuration remain untouched. Final comparison is retained as `preservation.json`; current changes remain uncommitted for owner review.

Final comparison: **319 tracked files checked; 18 planned modifications, 301 unchanged, zero unexpected tracked changes.** Nine new files are the HUD/test scripts with UID sidecars, two SVGs with import sidecars, and this report. Branch/HEAD remain `main` / `4f9a6ed`.
