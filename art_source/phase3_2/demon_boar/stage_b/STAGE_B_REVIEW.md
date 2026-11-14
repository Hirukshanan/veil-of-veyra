# Demon Boar — Phase 3.2 Stage B review

Status: the five combat clips are implemented and locally verified. Visual review is pending. Phase 3.3 gameplay/AI integration has not started.

## Delivered behavior

- **charge_warning**: 1.8 s anticipation; lowers the head, braces the chest, lifts/scrapes the right front hoof and returns it to support. The deliberate scrape is excluded from planted-foot slip measurements.
- **charge_attack**: 0.5 s repeating charge; faster coordinated diagonal stride, lowered head and tusks, torso momentum. It is in-place, with a nominal 3.12 m/s movement speed. Apply displacement through the future game controller, not animation root motion.
- **charge_recovery**: 1.4 s controlled stop. The review actor decelerates from 3.12 m/s to zero over 0.5 s, travelling 0.78 m. World-space stance anchors remain planted while the other legs land. The head rises, breathing settles and the last pose matches idle.
- **hit_reaction**: 0.8 s recoil through chest, neck and head, supported knees and small body stagger. It returns to idle without root drift.
- **death**: 2.8 s authored collapse. Knees buckle, ground-side limbs tuck beneath the body, the creature rolls onto its flank and head/limbs settle. The final 0.6 s is static and the last pose remains after playback. It is not a repeating animation or a runtime ragdoll.

All eight separate named clips are present: the five above plus the exact approved idle, walk and run actions. The existing model, corrected watertight surface, UVs, 4K original base color, 2K normal map and skin weights are preserved. No replacement creature or external model was used. Model-generation credit remains **Hirukshanan using Tripo3D**.

## Actual previews

`previews/combat_showcase.mp4` concatenates five real Godot captures in the order above. Each capture shows front, side and three-quarter views simultaneously. Cuts between clips are review edits, not an implemented gameplay state machine. Separate MP4s, full-size stills and sampled-pose sheets accompany every clip. No AI concept image is used as proof.

The actor wrapper travels only for charge/stop review. Exported actor/root-node translation remains zero. The death's local skeletal displacement is intentionally retained so the body can collapse while its gameplay actor stays fixed.

## Verification

| Clip | Duration | Playback | Maximum IK target error | Maximum planted slip | Godot skin-matrix error |
|---|---:|---|---:|---:|---:|
| charge_warning | 1.80 s | one-shot | 0.0000462 m | 0.0000021 m/frame | 0.00000146 |
| charge_attack | 0.50 s | loop | 0.0001076 m | 0.0018769 m/frame | 0.00000118 |
| charge_recovery | 1.40 s | one-shot | 0.0000719 m | 0.0000005 m/frame | 0.00000134 |
| hit_reaction | 0.80 s | one-shot | 0.0000005 m | 0.0000005 m/frame | 0.00000137 |
| death | 2.80 s | one-shot | 0.0000951 m | 0.0000000 m/frame | 0.00000148 |

The source was independently re-imported from GLB in a fresh Blender session and compared at every keyed frame. Godot independently checked all eight clips, duration/loop flags, in-place actor movement, skin matrices and one-shot stopping/final-pose hold. The greatest Godot matrix difference is 0.00000164. The GLB round-trip tolerance is 0.0001.

No limb length changes exceed 0.00000080 relative error. Lowest surface points during supported combat motions deviate only about 0.18 mm below the floor from the original sole mesh. Death is corrected to 3 mm minimum clearance; the final flank is 1.01 cm above the lowest fur/limb contact rather than being propped up by an elbow. Final death hold matrix difference is zero.

The mesh remains closed: zero boundary, loose and nonmanifold edges. Godot's 28,237 UV/normal split duplicates have matching skin weights (maximum difference 0.0). No previous body seam openings have been reintroduced. Both high/low skins are normalized, with at most four influences and no unweighted vertices.

All 52 existing Stage A files and 367 baseline game files match their pre-task hashes. Original locomotion deformation matrices have zero difference. High-source vertices/UVs and original packed color pixels match the approved source. Verification JSONs are in `verification/`.

## Files and reproduction

- `demon_boar_stage_b.blend`: editable 41-bone rig, all eight named actions, packed textures and hidden original-resolution source. Runtime deformation uses the same 30 joints.
- `demon_boar_stage_b.glb`: skinned review derivative with all eight baked animation clips; no IK helpers, studio lights or cameras.
- `godot_stage_b_review.zip`: self-contained Godot 4.7.2 review project. Extract separately and run `project.godot`.
- `animate_stage_b.py`: standalone authoring and runtime baking script, run on the unchanged Stage A `.blend`. `combat_authoring.py` is the authoring section used to construct that standalone script.
- `export_stage_b.py`: clean-session export and independent round-trip comparison.
- `verify_skin.py`, `verify_appearance.py`, `make_godot_reference.py`: local verification/reference tools.

Example PowerShell commands, using the existing installations:

```powershell
$stageA = 'C:/Users/Dark/Desktop/Projects/veil-of-veyra/art_source/phase3_2/demon_boar/stage_a'
$stageB = 'C:/Users/Dark/Desktop/Projects/veil-of-veyra/art_source/phase3_2/demon_boar/stage_b'
$blender = 'C:/Users/Dark/Documents/Codex/2026-11-13/c/work/phase3_tools/blender/blender-4.2.9-windows-x64/blender.exe'
& $blender --background --threads 8 --disable-autoexec "$stageA/demon_boar_stage_a.blend" --python-exit-code 1 --python "$stageB/animate_stage_b.py" -- $stageB
& $blender --background --threads 8 --disable-autoexec --factory-startup --python-exit-code 1 --python "$stageB/export_stage_b.py" -- $stageB
& $blender --background --threads 8 --disable-autoexec "$stageB/demon_boar_stage_b.blend" --python-exit-code 1 --python "$stageB/verify_skin.py" -- $stageB
& $blender --background --threads 8 --disable-autoexec "$stageB/demon_boar_stage_b.blend" --python-exit-code 1 --python "$stageB/verify_appearance.py" -- $stageB
$python = 'C:/Users/Dark/Documents/Codex/2026-11-13/c/work/phase3_tools/blender/blender-4.2.9-windows-x64/4.2/python/bin/python.exe'
& $python "$stageB/make_godot_reference.py" $stageB
$godot = 'C:/Users/Dark/Documents/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
$review = 'C:/path/to/extracted/godot_stage_b_review'
& $godot --headless --editor --path $review --import --quit
& $godot --headless --path $review --script res://configure_import.gd
& $godot --headless --editor --path $review --import --quit
& $godot --headless --path $review --script res://verify_playback.gd
& $godot --path $review --rendering-method gl_compatibility --rendering-driver opengl3 --write-movie "$review/death.png" --fixed-fps 30 --quit-after 94 -- --clip=death
```

Other capture counts at 30 FPS: charge_warning 64, charge_attack 60, charge_recovery 52, hit_reaction 34. Native PNG frames were encoded locally to H.264, CRF 18, yuv420p, without audio. Runtime snapshot `.blend` is an intermediate recreated by the authoring script and ignored by Git. Original Stage A sources are required to regenerate; final deliverables and packed `.blend`/GLB are self-contained.

## Integration notes and limits

- The runtime actor must supply charge displacement at the declared speed and the specified recovery deceleration. No enemy AI, damage windows, collision decisions, target-facing or movement code has been changed.
- Warning-to-charge needs a short runtime crossfade (approximately 0.12–0.18 s). Recovery starts at charge phase zero; blend from other charge phases. Recovery/idle and hit/idle endpoint matching is checked in `transition_verification.json`. No gameplay state machine or transition behavior is claimed as integrated.
- Godot precise import disables optimizer/compression and immutable-track removal. Clip loop flags are configured in `.glb.import`; standard GLB alone does not guarantee engine-specific loop metadata. Four looping locomotion/charge clips, four one-shots.
- Death is authored for a flat floor, with a fixed fall side. Slopes, ledges, terrain collision, interruptions and runtime ragdolls remain integration decisions. No spinning, long root translation, morph targets or simulation was added.
- Mesh/material/texture budgets are unchanged: 120,000 triangles, 88,201 imported render vertices, 30 runtime joints, four weights, one material, original 4K base color and packed 2K normal. Extra clips add storage/animation tracks; no new per-frame visual effect. No physical-phone FPS or memory benchmark is claimed.
- Local headless Godot editor profile safe-save warnings may appear; actual asset import, error-free runtime verification and native rendered playback succeeded. No security settings were changed.
- Commercial animation quality still requires visual approval. Extreme interruption blends and real combat readability must be tested during integration.

Stage B work is confined to this ignored art-source folder and `.validation` evidence. No APK, branch, commit, push, sound effect, enemy AI, HUD, hero, quest or environment modification was performed.

STOP: wait for explicit approval before Phase 3.3 integration.
