# Commands and reproducibility

All test runs used unique isolated APPDATA profiles and VEYRA_TEST=1; existing owner saves were not opened. Arguments below are recorded from actual runs. PROJECT_ROOT means the existing local repo except the packaged smoke, which uses extracted APK resources. EVIDENCE_ROOT is the local Task 5.4 evidence folder. Paths are local; no remote upload was performed.

## final_mobile_gestures_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/mobile_gestures_check.gd -- PROJECT_ROOT\.validation\island_task54
```

Exit 0; 11.805 seconds; 2026-11-15T15:34:54.894404+00:00

## final_mobile_settings_touch_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/mobile_settings_touch_check.gd -- PROJECT_ROOT\.validation\island_task54
```

Exit 0; 13.57 seconds; 2026-11-15T15:39:54.534628+00:00

## final_mobile_hud_layout_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/mobile_hud_layout_check.gd -- PROJECT_ROOT\.validation\island_task54
```

Exit 0; 0.511 seconds; 2026-11-15T15:35:19.805344+00:00

## final_mobile_controls_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/mobile_controls_check.gd
```

Exit 0; 5.784 seconds; 2026-11-15T15:35:20.338074+00:00

## final_settings_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/settings_check.gd
```

Exit 0; 5.784 seconds; 2026-11-15T15:35:26.133623+00:00

## final_sprint_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/sprint_check.gd
```

Exit 0; 4.028 seconds; 2026-11-15T15:45:51.036756+00:00

## final_pause_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/pause_check.gd
```

Exit 0; 4.781 seconds; 2026-11-15T15:39:49.737682+00:00

## final_layout_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/layout_check.gd
```

Exit 0; 6.288 seconds; 2026-11-15T15:35:39.547491+00:00

## final_safe_area_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/safe_area_check.gd
```

Exit 0; 6.786 seconds; 2026-11-15T15:35:45.851709+00:00

## final_boar_repeated_cycle_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/boar_repeated_cycle_check.gd -- PROJECT_ROOT\.validation\island_task54
```

Exit 0; 32.638 seconds; 2026-11-15T15:35:52.651269+00:00

## final_island_enemy_navigation_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_enemy_navigation_check.gd -- PROJECT_ROOT\.validation\island_task54
```

Exit 0; 11.818 seconds; 2026-11-15T15:36:25.312469+00:00

## final_island_accessibility_collision_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_accessibility_collision_check.gd -- PROJECT_ROOT\.validation\island_task54
```

Exit 0; 30.141 seconds; 2026-11-15T15:36:37.151770+00:00

## final_island_river_escape_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_river_escape_check.gd -- PROJECT_ROOT\.validation\island_task54
```

Exit 0; 35.647 seconds; 2026-11-15T15:37:07.308803+00:00

## final_island_atmosphere_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_atmosphere_check.gd
```

Exit 0; 6.302 seconds; 2026-11-15T15:37:42.975462+00:00

## final_island_rock_water_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_rock_water_check.gd
```

Exit 0; 7.057 seconds; 2026-11-15T15:37:49.293548+00:00

## final_island_forest_refinement_check

```text
Godot_v4.7.2-stable_win64_console.exe --path PROJECT_ROOT --script res://tests/island_forest_refinement_check.gd --resolution 1280x720 --position -20000,-20000 --rendering-method gl_compatibility
```

Exit 0; 32.407 seconds; 2026-11-15T15:37:56.365943+00:00

## final_island_vegetation_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_vegetation_check.gd
```

Exit 0; 6.79 seconds; 2026-11-15T15:38:28.794595+00:00

## final_island_terrain_polish_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_terrain_polish_check.gd
```

Exit 0; 6.538 seconds; 2026-11-15T15:38:35.599839+00:00

## final_island_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_check.gd
```

Exit 0; 7.542 seconds; 2026-11-15T15:38:42.160650+00:00

## final_island_campaign_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_campaign_check.gd
```

Exit 0; 9.795 seconds; 2026-11-15T15:45:55.091881+00:00

## final_island_collision_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_collision_check.gd
```

Exit 0; 10.047 seconds; 2026-11-15T15:39:00.308122+00:00

## final_island_connections_review

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/island_connections_review.gd
```

Exit 0; 41.465 seconds; 2026-11-15T15:39:10.372221+00:00

## final_boar_feedback_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/boar_feedback_check.gd
```

Exit 0; 6.048 seconds; 2026-11-15T15:39:51.863314+00:00

## final_boar_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/boar_check.gd
```

Exit 0; 8.297 seconds; 2026-11-15T15:39:57.929310+00:00

## final_boar_campaign_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/boar_campaign_check.gd
```

Exit 0; 6.286 seconds; 2026-11-15T15:40:06.257966+00:00

## final_heavy_attack_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/heavy_attack_check.gd
```

Exit 0; 9.047 seconds; 2026-11-15T15:40:12.562556+00:00

## final_combat_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/combat_check.gd
```

Exit 0; 6.286 seconds; 2026-11-15T15:40:21.623115+00:00

## final_enemy_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/enemy_check.gd
```

Exit 0; 0.763 seconds; 2026-11-15T15:40:27.925054+00:00

## final_campaign_smoke

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/campaign_smoke.gd
```

Exit 0; 4.03 seconds; 2026-11-15T15:40:28.709018+00:00

## final_autosave_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/autosave_check.gd
```

Exit 0; 6.285 seconds; 2026-11-15T15:40:32.756400+00:00

## final_persistent_world_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/persistent_world_check.gd
```

Exit 0; 9.806 seconds; 2026-11-15T15:40:39.059820+00:00

## final_fast_travel_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/fast_travel_check.gd
```

Exit 0; 5.284 seconds; 2026-11-15T15:40:48.882264+00:00

## final_hud_customization_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/hud_customization_check.gd
```

Exit 0; 7.536 seconds; 2026-11-15T15:40:54.179815+00:00

## final_quest_hud_check

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script res://tests/quest_hud_check.gd
```

Exit 0; 4.279 seconds; 2026-11-15T15:41:01.730600+00:00

## capture_before

```text
Godot_v4.7.2-stable_win64_console.exe --path PROJECT_ROOT --script C:\Users\Dark\Documents\Codex\2026-11-13\c\work\task54_capture.gd --position -20000,-20000 --rendering-method gl_compatibility -- EVIDENCE_ROOT\before
```

Exit 0; 58.764 seconds; 2026-11-15T16:02:46.184031+00:00

## final_capture

```text
Godot_v4.7.2-stable_win64_console.exe --path PROJECT_ROOT --script C:\Users\Dark\Documents\Codex\2026-11-13\c\work\task54_capture.gd --position -20000,-20000 --rendering-method gl_compatibility -- PROJECT_ROOT\.validation\island_task54\after
```

Exit 0; 72.34 seconds; 2026-11-15T16:03:44.949310+00:00

## gesture_feedback

```text
Godot_v4.7.2-stable_win64_console.exe --path PROJECT_ROOT --script C:\Users\Dark\Documents\Codex\2026-11-13\c\work\task54_feedback.gd --position -20000,-20000 --rendering-method gl_compatibility -- PROJECT_ROOT\.validation\island_task54\feedback
```

Exit 0; 47.203 seconds; 2026-11-15T15:58:42.235176+00:00

## input_profile_before

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script C:\Users\Dark\Documents\Codex\2026-11-13\c\work\task54_input_profile.gd -- EVIDENCE_ROOT\input_before
```

Exit 0; 6.556 seconds; 2026-11-15T15:53:03.124063+00:00

## input_profile_after

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path PROJECT_ROOT --script C:\Users\Dark\Documents\Codex\2026-11-13\c\work\task54_input_profile.gd -- PROJECT_ROOT\.validation\island_task54\input_after
```

Exit 0; 6.537 seconds; 2026-11-15T15:53:09.681160+00:00

## packaged_smoke

```text
Godot_v4.7.2-stable_win64_console.exe --path PROJECT_ROOT --script C:\Users\Dark\Documents\Codex\2026-11-13\c\work\mobile_smoke54.gd --position -20000,-20000 --rendering-method gl_compatibility -- EVIDENCE_ROOT\packaged_smoke 720
```

Exit 0; 66.36 seconds; 2026-11-15T16:04:57.290141+00:00

## Android build and local package checks

The existing `tools/build_island_android.py` ran with `--task 5.4 --render-height 720` into an isolated staging project, keeping the existing isolated signing profile. Godot headless import and Android debug export exited 0. See build logs and manifest for exact paths and runtime hashes. Local apksigner signature verification, aapt package/permission inspection, ZIP CRC and profiler-bytecode checks passed. No adb install was run; `adb devices -l` found no authorized physical device.

Final source checks: `git diff --check`, source/baseline SHA256 comparison, all final regression log scans. No commit, branch or push commands were run.

Reproduction scripts are included under `reproduce/` in this ZIP and `art_source/island/task54/` in the repository: `task54_capture.gd`, `task54_feedback.gd`, `task54_input_profile.gd`, `mobile_smoke54.gd`, `run_task54_tests.py` and `run_island_polish.py`. Adjust local root paths when using another checkout. Use isolated APPDATA profiles for reproducible defaults and to protect owner test saves.