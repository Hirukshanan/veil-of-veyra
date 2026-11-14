# Phase 2 gameplay HUD cleanup

> Superseded follow-up: the owner subsequently requested removal of the crosshair button and the entire target-lock feature. Tap/hold locking described below is historical. Current behavior and evidence: [CH1_TARGET_LOCK_REMOVAL_REPORT.md](CH1_TARGET_LOCK_REMOVAL_REPORT.md).

Date: 2026-11-14. Baseline: existing `main`, `564098e`. No branch/worktree, commit, push or next-phase work.

The separate paired-arrow button is removed from normal gameplay. It previously cycled combat targets; that functionality is now available by holding the target-lock crosshair for 0.4 seconds. A short tap still locks/unlocks. Holding cycles once; releasing after a hold does not unlock. Dragging outside the circle or opening a menu cancels the pending gesture. The existing cancellable attack tap/hold implementation is reused, without changing attack behavior.

Gameplay contains movement, sprint, attack/heavy, dodge, jump, shield/block, target lock, potion, optional burst and contextual interaction. Existing portrait/stats, quests, compass, minimap and navigation shortcuts remain. No rotate/reposition, side-swap, layout-edit or customization button is exposed during exploration/combat.

All move/resize/opacity/preset/handedness/save/reset functionality remains exclusively in **Settings > Controls > Customize HUD**. Large configuration panels appear only in that paused screen. The retired target-cycle entry is also removed from the editor's control list. Loading an older profile discards only its retired `TargetSwitchButton` entry, preserving the preset and all other custom controls. Campaign saves are unchanged.

## Current native screenshots

These are actual existing-game renders using an isolated synthetic profile and controlled frozen enemies, not mockups.

![Clean gameplay HUD, 1280×720](../.validation/hud_cleanup_2026-11-14/gameplay_1280.png)

![Customization remains separate](../.validation/hud_cleanup_2026-11-14/customization_1280.png)

[800×450 gameplay](../.validation/hud_cleanup_2026-11-14/gameplay_800.png), [wide gameplay](../.validation/hud_cleanup_2026-11-14/gameplay_wide.png), [existing boss combat](../.validation/hud_cleanup_2026-11-14/gameplay_combat.png), [800×450 editor](../.validation/hud_cleanup_2026-11-14/customization_800.png), [Settings](../.validation/hud_cleanup_2026-11-14/settings_path.png), [Controls](../.validation/hud_cleanup_2026-11-14/controls_path.png).

## Verification

**9/9 targeted checks pass:** `mobile_controls_check`, `hud_customization_check`, `layout_check`, `safe_area_check`, `quest_hud_check`, `target_lock_check`, `interaction_controls_check`, `pause_check`, `settings_check`. Native Windows Godot 4.7.2 GL Compatibility input/editor/screenshot runs also pass. All selected diagnostic arrays and stderr logs are empty. `git diff --check` passes.

Coverage includes the gameplay-only visible-button allowlist, removed arrow button, actual tap/hold targeting, one action per hold, release/drag/menu cancellation, old-profile migration, actual Settings/editor navigation, drag/resize/opacity/presets/save/reset/recovery, safe areas, targeting, interactions, pause and settings. Eight native screenshots were captured; gameplay/editor at 1280×720 and 800×450 were visually reviewed. All runs use unique isolated APPDATA and `VEYRA_TEST=1`, protecting personal saves/settings. Results are in the accompanying `results.json` and three native result files.

Only main HUD wiring, layout/profile migration, in-game guidance, two relevant regression tests and English documentation changed. Original world/character/enemy/player systems and assets remain intact. No dependency, external upload or telemetry was introduced. Physical-phone comfort/performance and new Android packaging remain unverified. Phase 3 still waits for the owner's Phase 2 screenshot approval.

The pre-change tracked-file inventory and scoped backups are retained locally in `.validation/hud_cleanup_2026-11-14/`. Preservation checks cover 343 files: 333 unchanged, 10 planned modifications, zero missing or unexpected changes. This report is the only new source-tree addition. For rollback, restore only this cleanup's changed files and remove only its new report. Preserve earlier committed/uncommitted work and personal saves; never whole-tree reset/clean.
