# Target-lock removal — 2026-11-14

The owner requested removal of the crosshair button and its feature. Target lock is removed throughout the existing game, including the HUD customization screen. Work stays on existing `main`, starting at `d607d5d`; no branch, worktree, commit, push or next-phase work.

## Result

- Removed the gameplay crosshair button, its tap/hold handlers, active-state update and unused lock/switch SVGs with their import sidecars.
- Removed the Tab combat binding, selected-target state, target eligibility/priority/cycling, automatic hero facing/camera steering and floating target marker. Removed obsolete menu, travel, camera-drag and death cleanup calls.
- Removed both retired target controls from HUD geometry, sizes, presets and editor choices. Loading existing primary or backup profiles discards only `TargetLockButton` and `TargetSwitchButton` entries; the preset and remaining controls survive. The profile format and campaign-save format are unchanged.
- Updated the current enemy guide, README and status documentation. Earlier phase reports remain historical and link to this removal.
- Renamed the shared enemy registry from `lock_targets` to `combat_enemies`, updating all runtime consumers and test fixtures. Minimap markers, map/camp state, nearby-enemy travel restrictions and quest checks continue using that registry. The boss-only lock-priority group is removed.

The hero faces movement direction; camera look remains manual. Existing attack/heavy attack, dodge, jump, block/parry, sprint, Spirit Burst, potion, interaction, progression and HUD editing remain available. Hero mesh/rig/animations, combat values, world geometry and personal saves are untouched.

## Verification

Twelve targeted checks passed: `free_combat_check`, `mobile_controls_check`, `hud_customization_check`, `interaction_controls_check`, `combat_check`, `heavy_attack_check`, `spirit_check`, `pause_check`, `fast_travel_check`, `island_map_check`, `campaign_smoke`, `persistent_world_check`.

The new free-combat check replaces the obsolete target-lock suite. It verifies absence of the target API, action binding, marker and buttons; Tab leaves camera/facing alone near an enemy; movement still turns the hero; manual camera look works; a forward sword overlap still deals ordinary damage; menu navigation does not restore the binding or advertise it. The HUD regression verifies migration of both retired control entries and their absence from editor choices. Existing touch coverage verifies simultaneous joystick/camera/attack fingers, pause cancellation, mirrored layouts, three landscape resolutions and cutout insets.

All checks use isolated synthetic APPDATA profiles and `VEYRA_TEST=1`. Diagnostic records are retained in [results](../.validation/target_lock_removal_2026-11-14/results.json). Native Godot GL Compatibility captures verify actual gameplay and customization at 800×450 and 1280×720. This change has no new Android build or phone playtest.

No test script errors or assertion failures occurred. The campaign smoke check records one existing `draw_rect` filled-width warning, and persistence records two of the same warning. Native capture stderr is empty; [native result](../.validation/target_lock_removal_2026-11-14/native_result.json).

Preservation: 369 existing tracked files compared, 328 unchanged, 35 intentional code/test/documentation changes and six retired icon/test files removed. Nineteen changed files contain only the shared-registry rename. No unexpected changes; hero assets, animation library, world geometry, combat values and save formats remain intact. [Hash/diff record](../.validation/target_lock_removal_2026-11-14/preservation.json). `git diff --check` passed.

## Actual native screenshots

- [Gameplay, 1280×720](../.validation/target_lock_removal_2026-11-14/gameplay_1280.png)
- [Gameplay, 800×450](../.validation/target_lock_removal_2026-11-14/gameplay_800.png)
- [HUD customization, 1280×720](../.validation/target_lock_removal_2026-11-14/customization_1280.png)
- [HUD customization, 800×450](../.validation/target_lock_removal_2026-11-14/customization_800.png)

Captures use the existing scene/HUD and current hero, with physics paused for repeatability. Validation images and synthetic profiles remain local and ignored; the supplied review bundle includes screenshots. No source, private assets or session history was uploaded.

The removal drops target-selection queries, marker rendering and lock-follow work. No claim of measured sustained FPS improvement is made. Existing visual approval gates and Phase 3 status remain unchanged.
