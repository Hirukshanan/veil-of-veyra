# Android development setup

Status checked on 2026-11-03: Java 21 and Android Studio are installed. Android SDK/platform tools and Godot export templates were not found in their default locations; no export preset exists. No APK/AAB has been produced or tested.

## Check prerequisites without opening a window

From the repository root, run `powershell -NoProfile -File tools/check_android.ps1`. Exit 1 means a prerequisite is missing. For a custom SDK location, supply `-SdkPath C:\path\to\sdk`; a custom template directory can be supplied with `-TemplatePath`.

This checks file presence only. It does not install software, accept SDK licenses, start an emulator, or modify a connected device.

## Prepare a debug APK

1. Finish the SDK setup in Android Studio or use Godot's Android build setup if offered by the installed editor. Follow the [Godot 4.7 Android export instructions](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html) for compatible package versions. OpenJDK 17 is recommended there; newer JDKs are supported but must be validated with the chosen build tools.
2. Install export templates matching the exact installed Godot version, currently `4.7.2.stable`.
3. Configure Godot's Java SDK Path and Android SDK Path. These are local editor settings, not repository secrets.
4. Add an Android debug APK export preset. Use a distinct development package identifier (proposed: `com.hirukshanan.veilofveyra.dev`), landscape orientation, and ARM64 for a compatible phone. Enable the matching x86_64 architecture only when needed for an emulator. Exclude `tests/*`, `tools/*`, and development documents from exported resources.
5. Export to `builds/android/veyra-debug.apk`. Run the prerequisite checker, then validate the actual export log.

## Device acceptance

On a developer-enabled test device, verify installation/startup, simultaneous joystick plus attack/dodge, camera drag, lock-on, Spirit Burst, all chapter objectives, readable controls around display cutouts, pause/resume on backgrounding, save persistence after relaunch, sound/mute, and sustained frame rate/temperature. Record device model, Android version, build identifier and failures. A desktop screenshot is not device acceptance.

Release signing, the production package identifier, Gradle/AAB setup and Play Console requirements remain separate work. Never commit signing keys or passwords. A successful debug export does not establish Play Store readiness.
