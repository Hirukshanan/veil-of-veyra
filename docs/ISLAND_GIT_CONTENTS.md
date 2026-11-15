# Connected island source-control contents

The connected island remains a separate review candidate at `scenes/island_candidate.tscn`. Production still launches `scenes/main.tscn`. Visual Tasks 1–4 were approved only for their stated scope. Task 5 provides a separate Android test build/profiling workflow; actual Samsung A37 / 8 GB measurements remain pending.

## Versioned content

- `assets/environment/new_island/`: complete runtime regional geometry, shared terrain surface, vegetation, textures/materials and approved polish resources. Keep Godot `.import` settings and `.uid` sidecars.
- `art_source/island/`: original owner-supplied island, editable Blender sources, generation/repair recipes, collision baseline and the archived pre-refinement vegetation source required by the forest regression test.
- Candidate scripts/scene, shared compatibility hooks, original behavior defaults and island regression/capture fixtures.
- `tools/build_island_android.py`, `profile_island_android.py` and build-only `.gd.template` sources. They build a copied project with a distinct test package and leave the production project/preset unchanged.
- Island reports, original before/after PNGs, short footage, galleries, JSON summaries and raw verification logs. Large binary source/media use the repository's existing Git LFS workflow.

APK/build outputs, signing material, `.godot`, `.validation`, duplicate delivery ZIPs and `candidate_patch` / `source_patch` review copies remain local and ignored. Canonical versions of the copied source files are already versioned in their normal directories. No local evidence or backup is deleted. Historical package manifests describe the complete delivered review archives, so they can include APK/duplicate-patch entries intentionally absent from the Git checkout; they are not manifests of the Git tree.

Machine-local paths in historical command/profiling records are provenance, not required checkout locations. Use the portable rebuild instructions in `docs/island_task5/REBUILD.md` and phone protocol in `docs/island_task5/ANDROID_TEST_PROTOCOL.md`. No credential/signing secret belongs in these records.

## Checkout and validation

Use Git LFS when cloning/checking out this work and hydrate the tracked binaries before Godot import. Keep the existing third-party asset licensing/install requirements from the main README; Git access does not relicense those assets.

Godot 4.7.2 GL Compatibility is the tested engine. Open the project, import resources, then run the candidate scene with F6. The optional licensed wolf model has its existing installation process and is intentionally not redistributed as a standalone model in Git.

For regression fixtures that write historical evidence paths, create their ignored output folders before invoking them. Run with `VEYRA_TEST=1` and an isolated APPDATA profile, as in the main README:

```powershell
$folders = @(
    '.validation/island_2026-11-15',
    '.validation/island_visual_2026-11-15',
    '.validation/island_polish_task1',
    '.validation/island_polish_task2',
    '.validation/island_polish_task21',
    '.validation/island_polish_task3',
    '.validation/island_polish_task4'
)
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force $folder | Out-Null
}
```

`tests/island_forest_refinement_check.gd` needs the native renderer for GPU instance-data readback. Its archived comparison source now lives in `art_source/island/polish_task21/baseline_vegetation.gd`, rather than an untracked cache. Run that fixture with the native GL Compatibility engine; use headless mode for the separate collision/gameplay fixtures. Per-check coverage and final results are recorded in `docs/island_task5/test_results.json`.

The two combat/boar fixture teardown changes release audio before test process shutdown. Their gameplay assertions and runtime enemy/combat code are unchanged.

The targeted native forest check was rerun after changing the baseline source path: functional assertions passed with exit code 0. The renderer printed texture cleanup diagnostics at process shutdown; these are retained under `docs/island_task5/logs/staging_check/` and are not presented as a clean shutdown or an Android runtime memory result.
