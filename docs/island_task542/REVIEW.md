# Review the candidate locally

Extract the complete ZIP into a new folder. Open gallery.html to inspect the original PNGs and gameplay video. REPORT.md, test_results.json, geometry_verification.json, preservation.json and rendering_cost.json provide the implementation and test evidence.

The project/ folder contains the complete Godot runtime sources and required assets. Import it with Godot 4.7.2. Run scenes/island_candidate.tscn directly for this candidate. The production default remains scenes/main.tscn.

```powershell
godot --editor --path ./project --import
godot --path ./project res://scenes/island_candidate.tscn
```

Use a temporary APPDATA directory when rerunning tests to protect personal test saves. The provided runner creates isolated profiles for each run. Reproduction paths in the Python helpers refer to the owner's workspace and can be adjusted for another checkout. The editable Blender file and refinement script are in source/. The original source is retained under source/baseline/. Evidence captures use Windows Compatibility rendering. No physical Android execution occurred during this task.

Rebuild the exterior from the preserved accepted model with Blender 4.2.9 background execution. The script adjusts only the accepted outer shell, adds the descending rear cap, and checks that interior vertices remain exact.

```powershell
blender --background --threads 4 --python-exit-code 1 --python ./source/refine_exterior.py -- ./source/baseline/Cave.blend ./rebuilt
```

The original owner-provided Samsung images are retained under owner_reference/. Before/after camera positions are recorded in each metrics.json.
