# Candidate island vegetation — Task 2 source

The runtime is `scripts/candidate_vegetation.gd`. It changes visuals only; original terrain/river construction and all pre-existing static colliders remain in `scripts/island_landscape.gd`. The original fused WesternForest GLB is hidden for rendering, while its collision remains enabled. Its 35 detected original trunk roots and 37 existing supplementary supports form the 72 new visual tree anchors.

Run the deterministic mesh preparation locally from the repository root:

```powershell
& $godot --headless --path . --script art_source/island/polish_task2/prepare_vegetation.gd
```

It writes only resources under `assets/environment/new_island/vegetation/`, deriving three trunk/canopy/grass LODs and the original fern mesh from local project inputs. The source Poly Haven maps and `forest_tree_mobile.res` remain unchanged. No Blender or network service is needed. See that asset folder's README for licenses.

`collision_baseline.json` contains the verified Task 1 static-collision/geometry fingerprints. `tests/island_vegetation_check.gd` compares the live candidate with those signatures if the local archived baseline scene is unavailable. The review fixture is `tests/island_vegetation_review.gd`; pass an absolute output directory after `--`. Set `VEYRA_TEST=1` and use an isolated APPDATA folder for review/tests.
