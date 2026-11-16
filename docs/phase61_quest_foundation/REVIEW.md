# Independent Phase 6.1 review

Extract the ZIP into a new folder and open `gallery.html`. Read `REPORT.md`, `QUEST_AUDIT.md` and `QUEST_DEPENDENCIES.md`. Screenshot images and raw logs use relative local links. `project/` includes the latest candidate and the existing production map for rollback.

Use Godot 4.7.2 Compatibility. Import the project locally, then run the candidate scene directly. Do not change the production main scene setting.

```powershell
$godot = 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe'
$env:VEYRA_TEST = '1'
$env:APPDATA = Join-Path $env:TEMP ('VeyraPhase61Review_' + [guid]::NewGuid())
& $godot --headless --editor --path ./project --import
& $godot --path ./project res://scenes/island_candidate.tscn
```

For a controlled quest test use a fresh temporary APPDATA directory per program, create a local `evidence` directory, then run:

```powershell
$env:APPDATA = Join-Path $env:TEMP ('VeyraPhase61Test_' + [guid]::NewGuid())
New-Item -ItemType Directory -Force ./evidence | Out-Null
& $godot --headless --path ./project --script res://tests/quest_progression_check.gd -- (Resolve-Path ./evidence)
```

Repeat with `quest_save_compatibility_check.gd` or any program listed in `test_results.json`. Isolated profiles prevent owner save changes. The captured state fixtures and helper are in `reproduce/`; the helper's output directory is its final argument. Python helpers contain owner-local root paths that must be adjusted for another checkout. No Android export/signing configuration is included in this review bundle.
