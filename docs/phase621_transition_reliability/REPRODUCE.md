# Independent review

Use Godot 4.7.2 Compatibility. The full project and raw failed/passing evidence are included. No build/signing credentials or owner saves are included.

```powershell
$phase621Engine = 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe'
$env:VEYRA_TEST = '1'
$env:APPDATA = Join-Path $env:TEMP ('VeyraPhase621_' + [guid]::NewGuid())
$env:VEYRA_PROFILE_CINEMATIC = '1'
New-Item -ItemType Directory -Force ./evidence | Out-Null
& $phase621Engine --headless --editor --path ./project --import
& $phase621Engine --path ./project --script res://tests/cinematic_transition_profile.gd --position 50,50 --rendering-method gl_compatibility -- ./evidence/live.json uncapped
& $phase621Engine --headless --path ./project --script res://tests/lantern_awakening_check.gd --fixed-fps 60 -- ./evidence
```

Use a NEW APPDATA directory for each cold user-cache run. Use mode `cap30` for the 30 FPS comparison. Keep the game window on screen for live profiling. The profiler seeds a synthetic eligible Chapter I save, so always keep it isolated from owner saves.

Run the remaining regression scripts named in test_results.json with the same headless pattern. Fresh-import verification must use a new extraction with no .godot folder; no partial-cache retry counts as fresh.

For the visual movie, run reproduce/capture_final.gd with --fixed-fps 20 --write-movie ./cinematic.avi and an existing screenshot directory after --. This is a fixed-step visual recording, not a live FPS benchmark.
