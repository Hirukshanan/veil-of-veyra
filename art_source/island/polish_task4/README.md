# Task 4 source and review reproduction

Runtime: `scripts/island_atmosphere.gd` applies candidate-only lighting, palette material variants and original flush stone-inlay geometry after the approved landscape/vegetation is constructed. Original terrain, water, mountain/cave/waterfall and vegetation source/resources remain unchanged.

`bake_journey_mask.gd` builds the 512×512 RGBA mask from accepted tree anchors and the previously verified routes in `.validation/island_visual_2026-11-15/connection_routes.json`. Run the existing `tests/island_connections_review.gd` first to recreate that local input if absent. The original procedural grass/tree placements remain deterministic and unchanged. Red encodes small footpath hints, green approximate static canopy shade. Preserve the mask's mipmapped lossless import settings.

`capture_review.gd` takes an output directory after `--`, native GL Compatibility, 1280×720. Baseline mode `--baseline` loads `.validation/island_polish_task4/baseline_candidate.gd`, an exact copy of `approved_task3_candidate.gd` retained here. It constructs the approved Task 3 landscape with no Task 4 atmosphere hook. The top-down overview alone uses a documented culling/LOD review override; other views retain runtime visibility rules. Optional-shadow views are separate from shadows-off low-quality views.

`capture_exploration.gd` takes an output directory, native renderer with `--fixed-fps 30`. It records 480 frames of real player movement and camera follow. Use VEYRA_TEST=1 and a unique APPDATA profile for every fixture. No saved user progress is used. This is offline recording, not device FPS evidence.

The candidate is not the production main scene. Stop for visual approval.
