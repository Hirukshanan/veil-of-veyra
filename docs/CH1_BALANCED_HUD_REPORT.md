# Balanced primary HUD — visual review

Date: 2026-11-14. Existing `main`; no new branch, worktree, commit, push or next-phase work. The owner rejected the preceding unequal primary sizing and guard placement. This update implements equal mirrored joystick/attack anchors and a smaller attack-side secondary cluster. **Target lock remains removed**, following the owner's latest explicit correction. Visual approval remains pending.

## Default control structure

Joystick and attack intentionally share the same **144 px base diameter at 100%**, the same responsive factor, a 104 px minimum touch size, a 210 px maximum, and identical edge-margin calculations. At 1280×720, each is 144×144, with centers **(108, 612)** and **(1172, 612)**. Both have 36 px side and bottom edge margins. Their centers are exact horizontal reflections across the safe canvas center; both use a dark circular face and a two-pixel gold outline. The joystick outline now fills its allotted primary footprint instead of appearing smaller inside it.

| Control | Base diameter at 100% | Center at 1280×720 |
| --- | ---: | --- |
| Movement joystick | 144 px | (108, 612) |
| Main attack | 144 px | (1172, 612) |
| Sprint | 54 px | (108, 501) |
| Dodge | 68 px | (1050, 612) |
| Shield / block | 76 px | (1050, 524) |
| Jump | 68 px | (1172, 490) |
| Spirit Burst | 62 px | (1050, 436) |
| Context interaction | 56 px | (1172, 402) |
| Potion | 56 px | (574, 672), within the bottom-center quick-slot group |

Spacing derives from the clamped primary/secondary radii plus a 10–12 px default gap, so minimum touch sizes do not create overlaps on smaller screens. Edge margins stay between 32 and 48 px as the HUD scale changes. At 800×450, both primary controls are approximately **104.5 px**, centered at **(84.3, 365.7)** and **(715.7, 365.7)**; secondary touch diameters remain approximately 48–55.2 px. The default center gameplay area stays clear. The Left-Handed preset mirrors the complete arrangement within the usable safe canvas.

The equal-primary contract describes default/reset presets at the default global scale. Independent user size/position/opacity overrides remain supported in **Settings > Controls > Customize HUD**, and valid saved custom profiles remain intact. Gameplay has no editor/preset/save/reset or layout-adjustment buttons. The larger customization panels appear only in the paused editor.

## Preserved gameplay

Movement, sprint, tap attack/held heavy, dodge, guard/parry, jump, Spirit Burst, interaction and potion handling retain their existing callbacks and gameplay values. No hero asset, rig, animation, save format, combat timing, terrain, enemy or camera implementation changed. Target-lock code, binding, button and marker remain absent. The prior pending target-removal changes remain preserved.

## Verification and screenshots

Eight focused checks pass: `mobile_controls_check`, `hud_customization_check`, `quest_hud_check`, `layout_check`, `safe_area_check`, `interaction_controls_check`, `free_combat_check`, `heavy_attack_check`. The mobile regression now explicitly asserts equal primary sizes, equal vertical centers, reflected horizontal centers and smaller secondary controls at three landscape sizes, both handedness settings and three global HUD scales. Existing checks cover cutout insets, non-overlapping controls, guard/parry, multi-pointer move/look/attack, tap/hold cancellation, customization/save/reset and ordinary combat without target lock.

Heavy-attack assertions pass with the previously observed two ObjectDB instances reported at shutdown. Other checks in this run have no recorded diagnostics. Synthetic isolated APPDATA profiles protect personal saves. Native GL Compatibility renders use the real game scene, HUD and current hero, with physics paused for repeatable captures. Runtime dimensions are recorded alongside the screenshots. These desktop checks do not establish sustained physical-phone performance or a new APK.

- [Gameplay 1280×720](../.validation/balanced_hud_2026-11-14/gameplay_1280.png)
- [Gameplay 800×450](../.validation/balanced_hud_2026-11-14/gameplay_800.png)
- [Gameplay 1920×864](../.validation/balanced_hud_2026-11-14/gameplay_1920.png)
- [Left-Handed 800×450](../.validation/balanced_hud_2026-11-14/left_handed_800.png)
- [Separate editor 1280×720](../.validation/balanced_hud_2026-11-14/customization_1280.png)
- [Separate editor 800×450](../.validation/balanced_hud_2026-11-14/customization_800.png)
- [Regression results](../.validation/balanced_hud_2026-11-14/results.json)
- [Runtime layout measurements](../.validation/balanced_hud_2026-11-14/layout_metrics.json)

Only local files and native rendering were used; private source/assets/session data were not uploaded. Earlier layout reports and images record previous review candidates and are superseded by this default structure.
