# Independent cinematic review

Extract this archive and open gallery.html. Read REPORT.md and rendering_cost.json, including the unresolved transition-spike section. Play lantern_awakening.mp4 with sound.

Open project/ in Godot 4.7.2 Compatibility and run scenes/island_candidate.tscn directly. To reproduce controlled tests, use an isolated profile and an existing output directory.

```powershell
$env:VEYRA_TEST = '1'
$env:APPDATA = Join-Path $env:TEMP ('VeyraPhase62_' + [guid]::NewGuid())
New-Item -ItemType Directory -Force ./evidence | Out-Null
godot --headless --editor --path ./project --import
godot --headless --path ./project --script res://tests/lantern_awakening_check.gd --fixed-fps 60 -- (Resolve-Path ./evidence)
```

The capture test seeds an eligible synthetic Chapter I save with 80 shards and only cave relic 1. Run it graphically with --fixed-fps 20 and --write-movie ./cinematic.avi, passing an output directory after --. The live metrics test takes its output JSON path and the word candidate after --. Its baseline variant requires the copied pre-event scripts supplied under baseline/. Reproduction Python helpers use owner-local checkout paths and can be adjusted to another checkout. The runtime project uses relative resource paths.

Initial isolated import encountered a native-engine crash; the identical import retry and extracted runtime test passed. See REPORT.md and package_checks/ for both attempts.
