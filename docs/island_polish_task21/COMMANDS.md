# Executed verification commands

Blender 4.2.9 LTS background authored/validated the original trunk mesh and synchronized editable forms; `--threads 6 --disable-autoexec --python-exit-code 1 --python model_trunks.py`. Native Godot baked the 1K twig atlas; headless Godot built custom-stream LOD resources. Source recipes are retained in the art-source folder. Raw model/source logs are included.

Before/after captures: `Godot --path PROJECT_ROOT --script res://tests/island_forest_refinement_review.gd --resolution 1280x720 --position -20000,-20000 --rendering-method gl_compatibility -- OUTPUT_DIRECTORY`.

Motion capture: same native flags with `res://tests/island_forest_motion_review.gd --fixed-fps 30 -- OUTPUT_DIRECTORY`. 360 actual viewport frames were encoded with FFmpeg/libx264, CRF18, yuv420p, no interpolation/motion blur/audio. ffprobe verifies 1280×720, 360 frames and 12 seconds.

The form verification runs natively to read actual GPU MultiMesh custom data. The 18 other final regressions use `--headless --path PROJECT_ROOT --script res://tests/TEST_NAME.gd`. Every run sets `VEYRA_TEST=1` with a unique isolated APPDATA profile. Exact arguments, times, exit codes and test scopes are in `test_results.json` and `logs/*.run.json`; diagnostic attempts are separated from final passing records.
