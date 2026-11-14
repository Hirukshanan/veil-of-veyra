# Phase 2 HUD redesign — review pending

Date: 2026-11-14. Existing game, branch `main`, HEAD `4f9a6ed`. The owner requested this redesign after rejecting the earlier Phase 2 HUD. No next phase, new branch, worktree, commit, push or deployment was performed.

## Two distinct interfaces

The supplied `a_detailed_highly_polished_game_hud_proposal_and.png` was inspected locally as a visual reference. Its upper composition guides gameplay; its lower panels guide the separate customization screen. The reference raster is not shipped or uploaded. This adapts the direction to the existing prototype's art and controls.

Gameplay shows a native-rendered portrait of the existing hero, actual level (currently 1), HP and stamina at top-left; compact dark quest panel; compass; top-right minimap and equipment/quest/map/pause shortcuts; reduced movement stick and sprint at bottom-left; circular attack, dodge, jump, guard/parry, lock, cycle, burst and contextual interaction at bottom-right. Bottom-center quick slots contain the existing health potion and two visibly empty slots. Existing skill/context availability rules remain. The central combat view stays clear.

**Settings > Controls > Customize HUD** opens a separate paused editor with touch/mouse drag, corner-handle resize, size (75–150%) and opacity (25–100%) sliders, Battle/Classic/Left-Handed presets, Save layout, Cancel and Reset layout. Large lower panels appear only here. The preview maps the actual safe canvas uniformly. Save applies; Cancel/Escape discard; Reset changes the draft until saved. Menu entry cancels held movement, attack, camera and guard input.

## Actual native screenshots

Rendered captures of the existing game, not mockups. The synthetic fixture freezes enemy AI and positions the camera for legibility. Combat uses the existing Dragon and existing lantern gates; no Phase 5 story encounter was added.

![Gameplay, 1280×720](../.validation/hud_redesign_2026-11-14/gameplay_1280.png)

![Separate customization, 1280×720](../.validation/hud_redesign_2026-11-14/customization_1280.png)

[800×450 gameplay](../.validation/hud_redesign_2026-11-14/gameplay_800.png), [1600×720 gameplay](../.validation/hud_redesign_2026-11-14/gameplay_wide.png), [existing boss combat](../.validation/hud_redesign_2026-11-14/gameplay_combat.png), [800×450 editor](../.validation/hud_redesign_2026-11-14/customization_800.png), [Settings](../.validation/hud_redesign_2026-11-14/settings_path.png), [Controls](../.validation/hud_redesign_2026-11-14/controls_path.png).

## Functionality and preservation

- Existing movement/look, attack/heavy, jump, dodge, sprint, burst, interaction, healing and targeting retain their original gameplay methods. Ordinary enemy melee supports shield/F guard: initial 0.18-second frontal parry, otherwise 70% damage reduction; 20 stamina per blocked hit and 6/second held drain. Guard slows movement; committed actions cancel it. Unguarded, rear, environmental and existing boss-magic damage retain their original path. Enemy stats and boss damage were not rebalanced.
- Versioned normalized layouts persist separately in `user://hud_profile.cfg`. Finite/range validation, overlap/center protection, temporary writes and backup recovery protect profiles. A layout incompatible with another screen falls back visually to its preset, preserving saved coordinates for review. Legacy handedness loads when no HUD profile exists.
- The minimap caches the island render and overlays live player/enemy/objective markers at 10 Hz. Portrait uses the existing model. Both small 3D viewports explicitly stop after initial capture. No continuous extra world rendering, blur or heavy postprocessing. Button styles/header font variation are cached.
- Redundant floating environmental callouts are hidden to clear the combat view; combat health/warning/target labels remain. Lock marker is a compact diamond. Quest, grove, map and interaction information remain available. Geometry/collision, Phase 1 routes, sea, original models, hero outfit/rig, campaign save store/version and export configuration are preserved from the pre-redesign working tree.

`mobile_hud.gd` manages profiles/layouts; new `premium_hud.gd` draws gameplay; new `hud_editor.gd` owns customization. Existing main/campaign/player/enemy scripts integrate controls. Four original SVGs supply guard/map/camp/potion. Pre-existing uncommitted Phase 2 work was retained. No external dependency, upload or telemetry was added.

## Verification and limits

**19/19 targeted checks pass**, without diagnostics or stderr in this selected run: `hud_customization_check`, `mobile_controls_check`, `layout_check`, `safe_area_check`, `quest_hud_check`, `settings_check`, `target_lock_check`, `interaction_controls_check`, `jump_check`, `pause_check`, `heavy_attack_check`, `combat_check`, `enemy_check`, `gameplay_check`, `save_check`, `persistent_world_check`, `beach_seals_check`, `navigation_check`, `camera_check`.

The new regression exercises actual Settings navigation, touch drag/resize, sliders/presets, save/cancel/reset/reopen, malformed-profile recovery, failed-write preservation, overlap/center rejection, landscape/cutout layouts, camera ownership and real guard/parry behavior. Existing tests retain three-pointer movement/look/attack, quests and save coverage. Unique isolated APPDATA and synthetic saves with `VEYRA_TEST=1` protect personal progress.

Native Windows Godot 4.7.2 GL Compatibility editor regression passes in 48.88 seconds; screenshot run passes in 47.11 seconds; both exit 0 with empty stderr. Eight screenshots were visually inspected at 1280×720, 800×450 and 1600×720. Runtime assertions confirm both cached HUD viewports stop rendering.

A minimized-window stationary sample of 60 force-drawn frames after warmup records median 53.741 ms, p95 59.395 ms, 670 draw calls and 730,555 primitives. This is method-specific desktop evidence, **not phone FPS**, sustained play or a controlled before/after comparison. Physical-phone comfort, actual cutouts, sustained thermal/performance and final art acceptance remain pending. No new APK; the earlier editor-config/SDK-resolution packaging limitation remains. Earlier unrelated shutdown warnings are not declared globally fixed.

## Approval and rollback

**Phase 2 awaits screenshot/explanation approval. Do not start Phase 3.** Final production character art and earned visual equipment remain open.

All changes remain uncommitted on `main`. For redesign-only rollback, restore only changed files from `.validation/hud_redesign_2026-11-14/rollback/` and remove only redesign additions. That snapshot preserves previous uncommitted Phase 2 work. Never reset/clean the repository or erase personal saves. The scoped comparison checks 328 existing files: 311 unchanged, 17 planned modifications, zero missing or unexpected changes. `before.json` and `preservation.json` retain the evidence. Tests, diagnostics and metrics remain in the same ignored directory. `git diff --check` passes; Git reports only local LF/CRLF normalization notices.
