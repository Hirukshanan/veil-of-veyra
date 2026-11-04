# Android development setup

Status checked on 2026-11-04: Java 21, Android Studio, and SDK/platform/build tools are installed. Matching Godot 4.7.2 Android templates were downloaded from the official GitHub release, SHA512-verified, and installed. The initial Android Debug export produced a signed ARM64 APK (49,496,107 bytes). The latest build replaces `builds/android/veyra-debug.apk`. APK signature verification passed. No phone/emulator was connected to the development machine. The owner subsequently reported smooth gameplay and saved progress after reopening on Samsung A37. Background/resume, measured performance and AAB/release signing remain pending. The sandbox redirects LOCALAPPDATA, so use the explicit local paths below.

## Check prerequisites without opening a window

From the repository root, run `powershell -NoProfile -File tools/check_android.ps1 -SdkPath "C:\Users\Dark\AppData\Local\Android\Sdk" -TemplatePath "C:\Users\Dark\AppData\Roaming\Godot\export_templates\4.7.2.stable"` on this machine. Exit 1 means a prerequisite is missing. For a custom SDK location, supply `-SdkPath C:\path\to\sdk`; a custom template directory can be supplied with `-TemplatePath`.

This checks file presence only. It does not install software, accept SDK licenses, start an emulator, or modify a connected device.

## Prepare a debug APK

1. Finish the SDK setup in Android Studio or use Godot's Android build setup if offered by the installed editor. Follow the [Godot 4.7 Android export instructions](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html) for compatible package versions. OpenJDK 17 is recommended there; newer JDKs are supported but must be validated with the chosen build tools.
2. Install export templates matching the exact installed Godot version, currently `4.7.2.stable`. Android debug/release templates are installed on this machine; other-platform templates and the Gradle source template are not installed by this step.
3. Configure Godot's Java SDK Path and Android SDK Path. These are local editor settings, not repository secrets.
4. The checked-in `Android Debug` preset uses `com.hirukshanan.veilofveyra.dev`, version `0.2.0-dev` (code 8), ARM64, and the app label `Veil of Veyra Dev`. Project orientation is landscape. Tests, tools, and development Markdown documents are excluded. x86_64 is disabled; enable it separately for a compatible emulator.
5. Export to `builds/android/veyra-debug.apk`. Run the prerequisite checker, then validate the actual export log.

## Device acceptance

On a developer-enabled test device, verify installation/startup, simultaneous joystick plus attack/dodge, camera drag, lock-on, Spirit Burst, all chapter objectives, readable controls around display cutouts, pause/resume on backgrounding, save persistence after relaunch, sound/mute, and sustained frame rate/temperature. Record device model, Android version, build identifier and failures. A desktop screenshot is not device acceptance.

Release signing, the production package identifier, Gradle/AAB setup and Play Console requirements remain separate work. Never commit signing keys or passwords. A successful debug export does not establish Play Store readiness.

## Repeat the debug export

Use Godot's Export dialog with the `Android Debug` preset, or run from the repository root:

```powershell
& 'C:\Users\Dark\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-debug 'Android Debug' builds/android/veyra-debug.apk
```

Create `builds/android` first if it does not exist. Check the process exit code and export log before using the APK. The APK, local template downloads, and signing keys stay outside version control. This development preset uses debug signing and the default Godot icon; it is not the production store configuration.
Before exporting the intended wolf visuals, install the local licensed model as described in assets/characters/literock/README.md. Run combat_pose_check to verify it is loaded; source checkout alone uses procedural fallback art.
