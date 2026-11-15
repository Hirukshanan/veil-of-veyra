# Rebuild the isolated candidate Android test

Source project settings/presets are preserved. The helper copies scripts/scenes/assets and the imported cache into a **new directory outside the repository**, creates a test-only bootstrap, and changes the main scene/package only in that copied project. The original `project.godot` still launches `scenes/main.tscn`. Export scripts verify all approved runtime source hashes after the build.

Dependencies used: Godot 4.7.2 console, matching Android export templates, installed Android SDK/build tools and Java 21 (JDK 17 is the Godot documentation recommendation; the installed higher JDK exported successfully). No Gradle/plugin/service/asset download is performed by this helper. Network permission stays off. The test package is `com.hirukshanan.veilofveyra.islandtest`.

From the repository root, set local tool paths, a fresh staging folder and output folder:

```powershell
& $python tools/build_island_android.py --godot $godot --sdk $sdk --java $javaSdk --templates $templates --staging $freshStageOutsideRepo --output builds/android
```

For this machine:

```powershell
$godot = 'C:/Users/Dark/Documents/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
$sdk = 'C:/Users/Dark/AppData/Local/Android/Sdk'
$javaSdk = 'C:/Program Files/Eclipse Adoptium/jdk-21.0.12.101-hotspot'
$templates = 'C:/Users/Dark/AppData/Roaming/Godot/export_templates/4.7.2.stable'
$freshStageOutsideRepo = 'C:/Users/Dark/Documents/Codex/2026-11-13/c/work/island_android_next_build'
```

Use a new staging folder each time. The helper never recursively deletes anything. It reuses the private `island_android_export_profile` adjacent to the staging folder for test signing/settings; keep it local, outside version control and review ZIPs. No signing secrets are written into source, commands, logs or artifacts. No release signing key is used or included.

`tools/mobile_bootstrap.gd.template` and `tools/mobile_probe.gd.template` become runtime scripts only inside the staging copy. The bootstrap keeps original gameplay, adds local profiling and sets initial test quality to 30 FPS/shadows off. It never changes HUD layout or adds editing controls. Current portrait/quest/enemy/dragon/save scripts and all approved island art are identical to source.

The export remains `all_resources` to avoid missing dynamic runtime dependencies; non-resource metadata JSON is explicitly included. Private authoring sources, docs, tests, tools and keys are excluded from the APK. Package size is larger than a future lean release. Build logs, source hashes, tool choices, package metadata and final APK SHA are recorded.

The recipe is functionally reproducible; byte-for-byte APK reproducibility is **not claimed**. Godot regenerated binary scene/sparse-pack export metadata across fresh staging folders, and signing/ZIP timestamps may vary. The final resource payload was extracted and functionally checked again after detecting that difference.
