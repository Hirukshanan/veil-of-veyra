# Task 1 terrain source

`island_terrain.blend` is the editable repaired terrain source. The original prepared `../island_regions.blend` and imported `../Island_original.glb` remain unchanged.

Rebuild locally from the repository root (Blender 4.2.9 LTS / Godot 4.7.2 used):

```powershell
& $blender --background --threads 6 --disable-autoexec --python-exit-code 1 --python art_source/island/polish_task1/repair_island_terrain.py
& $godot --headless --path . --script art_source/island/polish_task1/bake_surface.gd -- .validation/island_polish_task1/terrain_grid.json
& $godot --headless --path . --editor --import --quit
```

Set `$blender` and `$godot` to your installed executable paths. The first command writes the four repaired region GLBs, the new Blender file and the generated grid; it preserves the current original embedded albedo bytes. The second compresses the shared grid into the Godot resource. The unchanged forest GLB is not exported. The recorded anchors preserve the previously grounded gameplay placements.

Do not rerun the older `prepare_regions.py` over the repaired assets: it would replace them with the pre-polish meshes. Preserve the pre-task rollback checkpoint.

Run candidate checks with `VEYRA_TEST=1` and a unique isolated APPDATA directory; see the exact local commands and raw logs in `docs/island_polish_task1/logs/`. The fixed review fixture is `tests/island_polish_capture.gd`; the extra sea-mouth fixture is `tests/island_estuary_capture.gd`, which takes an absolute output PNG path after `--`.
