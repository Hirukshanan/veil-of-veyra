# Task 2.1 original forest refinement source

`forest_forms.blend` retains the normalized editable branch master and three displayed forms. It is trunk geometry source; the textured twig canopies and GPU form streams are built in Godot. Required input maps are existing local Poly Haven CC0 assets. No external service is used.

From the repository root, using Blender 4.2.9 and Godot 4.7.2:

```powershell
& $blender --background --threads 6 --disable-autoexec --python-exit-code 1 --python art_source/island/polish_task21/model_trunks.py
& $blender --background --threads 4 --disable-autoexec --python-exit-code 1 --python art_source/island/polish_task21/sync_editable_forms.py
& $godot --path . --script art_source/island/polish_task21/bake_twig_atlas.gd --resolution 1024x1024 --position -20000,-20000 --rendering-method gl_compatibility
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --script art_source/island/polish_task21/prepare_refined_vegetation.gd
```

The atlas bake requires the native renderer. Preserve its tracked import settings: VRAM compression and mipmaps. The form/instance verification (`tests/island_forest_refinement_check.gd`) also runs natively; headless dummy rendering cannot read GPU MultiMesh custom data. Physics/campaign tests still run headless. Use `VEYRA_TEST=1` and an isolated APPDATA profile.

Tree form is encoded in per-instance custom data; per-vertex custom streams carry position/normal variants. All three forms share the same mesh/material per spatial batch and LOD. `candidate_vegetation.gd` remains the runtime. Original anchor positions, grass placement and all physical colliders are preserved. Source `branch_tips.json` and normalized GLBs live under the refinement asset folder; legacy Task 2 resources are retained for rollback.
