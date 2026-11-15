# Task 3 editable source and review fixtures

The geometry is authored procedurally in `scripts/island_rock_water_polish.gd`. The underlying imported GLBs, terrain surface resource and 47 original collision shapes are unchanged. `bake_rock.py` regenerates the original 1K rock maps with Blender 4.2.9 background execution. Preserve the PNG import settings (VRAM compression and mipmaps).

Review fixtures run in Godot 4.7.2 with `VEYRA_TEST=1` and an isolated APPDATA profile. `capture_review.gd` accepts an absolute output folder after `--`; use native GL Compatibility at 1280×720. `capture_cave_gameplay.gd` also takes an output folder, with native `--fixed-fps 30`. It drives the existing player controller and spring-arm camera; it does not teleport the hero during the recorded walk. The footage is offline capture, not a mobile performance benchmark.

Production uses `scenes/main.tscn`. The review candidate is `scenes/island_candidate.tscn`. Do not activate without visual approval.
