# Android development

This guide covers local development APKs for **Veil of Veyra**. Run commands from the repository root. Installation paths belong in your local environment or Godot editor settings.

## Prerequisites

1. Install the standard Godot **4.7.2** editor.
2. Install export templates matching the editor version through Godot's export-template manager.
3. Install compatible Java and Android SDK components using the [official Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).
4. Configure **Java SDK Path** and **Android SDK Path** in Godot's editor settings.
5. Follow the [wolf asset setup](assets/characters/literock/README.md) for the intended enemy visuals.
6. Open the project and allow imports to finish.

Examples assume the executable is available as `godot` on `PATH`. Substitute your executable name if necessary.

### Optional Windows prerequisite check

```powershell
powershell -NoProfile -File tools/check_android.ps1
```

The helper checks `ANDROID_HOME`, then `ANDROID_SDK_ROOT`, then the standard per-user SDK location. It uses the standard per-user Godot template location. For custom installations, supply your own `-SdkPath` and `-TemplatePath` arguments.

This checks presence only; it does not install dependencies, accept licenses, or validate an export.

## Export a debug APK

Create the output directory:

```powershell
New-Item -ItemType Directory -Force builds/android | Out-Null
```

Export from the repository root:

```sh
godot --headless --path . --export-debug "Android Debug" builds/android/veyra-debug.apk
```

Alternatively, use **Project → Export → Android Debug** in the editor.

| Preset field | Development configuration |
| --- | --- |
| App label | Veil of Veyra Dev |
| Package | `com.hirukshanan.veilofveyra.dev` |
| Architecture | ARM64 |
| Orientation | Landscape |
| Signing | Debug |
| Output | `builds/android/veyra-debug.apk` |

Version name and code are maintained in `export_presets.cfg`. Tests, development tools, and documentation are excluded from exports. Heavy environment source models are excluded; reduced runtime scenes and their textures are included.

## Verify and install

Confirm the export succeeds. With Android SDK build tools and platform tools on `PATH`:

```sh
apksigner verify builds/android/veyra-debug.apk
adb install -r builds/android/veyra-debug.apk
```

`adb` requires an authorized device with USB debugging enabled. Alternatively, transfer and install the APK manually on a test device. Retain the same local debug signing key for compatible updates; do not commit or share it.

## Device testing

Record the app build, device model, Android version, and observed failures.

- Installation, startup, relaunch, and saved campaign progress.
- Simultaneous movement, camera drag, attacks, dodge, and Spirit Burst.
- Keeper dialogue, relics, waystone discovery, and safe travel.
- Chapter objectives, boss encounters, defeat, and retry.
- Readable menus and reachable controls around display cutouts.
- Background/resume, sound, and settings persistence.
- Sustained frame rate, temperature, and battery behavior.

Desktop checks do not establish physical-device acceptance. See [validation notes](VALIDATION.md) for testing scope.

## Production release

The debug preset is not the store configuration. Remaining work includes final artwork and identifier, release signing, Gradle/AAB setup, device acceptance, and store submission requirements.

Keep export outputs, signing keys, passwords, and local SDK settings out of version control. Never include signing credentials in documentation or committed scripts.
