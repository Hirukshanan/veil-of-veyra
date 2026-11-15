# Commands executed

Blender 4.2.9 background was used only to inspect connected trunk components from the unchanged `island_regions.blend`; it did not save that source. Godot 4.7.2 generated the derivative resources using the delivered `prepare_vegetation.gd`. Existing private models were never uploaded.

Native capture: `Godot --path PROJECT_ROOT --script tests/island_vegetation_review.gd --resolution 1280x720 --position -20000,-20000 --rendering-method gl_compatibility -- OUTPUT_DIRECTORY`. Before capture ran before any vegetation edits; after capture ran with the final LOD/material resources. Exact executed arguments and timestamps are in `logs/*capture.run.json`.

Every regression uses `Godot --headless --path PROJECT_ROOT --script res://tests/TEST_NAME.gd`, with `VEYRA_TEST=1` and a unique isolated APPDATA profile. Test names, scopes, arguments, timestamps and exit codes are retained in `test_results.json` and raw logs. The entire suite ran after the final resource preparation.

Early generator type errors were corrected before the final tests. Intermediate rendering attempts exposed excessive draw calls and sparse distant crowns; the delivered captures use the final consolidated material and LOD resources. Those intermediate renders are not presented as the final result.
