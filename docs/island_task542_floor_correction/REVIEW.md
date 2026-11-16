# Independent review

Extract the ZIP and open gallery.html. The original before/after PNGs and cave_walkthrough.mp4 use relative paths. REPORT.md explains the root cause, exact changes, testing and measured desktop cost.

Open project/ in Godot 4.7.2 and run scenes/island_candidate.tscn directly. The production default remains scenes/main.tscn. Import caches are generated locally. Use a temporary APPDATA directory for isolated test saves.

```powershell
godot --editor --path ./project --import
godot --path ./project res://scenes/island_candidate.tscn
```

The source/ folder contains the corrected editable model, GLB and generator. source/floor_correction/baseline/ preserves the pre-fix mask. The repair script can be run in Blender 4.2.9 background mode with the pre-fix .blend path and an output directory as its final two arguments. Reproduction Python helpers use owner-local root paths that can be adjusted for another checkout.
