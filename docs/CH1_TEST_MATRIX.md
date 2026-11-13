# Chapter I baseline test and device matrix

Date: 2026-11-13 (Asia/Colombo). Existing checks run with Godot 4.7.2, per-check isolated `APPDATA` under `.validation/ch1_audit_2026-11-13/saves/`, and `VEYRA_TEST=1`. Personal campaign/settings files were not used. No new gameplay tests were added in Phase 0.

## Current evidence

**28/28 selected existing checks passed**, each with exit 0, PASS output and no script assertion/parse failures. The long shallow-water check exceeded the initial 60-second runner limit, then passed fully in 113.53 seconds with a 210-second budget. A temporary result-classification issue in the local PowerShell wrapper marked early successful checks FAIL; records were reconciled against actual exit codes, stdout PASS markers and stderr. This was a harness classification error, not a gameplay repair. Only the timed-out coastal check needed a rerun.

Evidence directory (ignored/local): `.validation/ch1_audit_2026-11-13/`. Per-check stdout/stderr, structured `results.json`, isolated saves, tracked-file hash manifest, native captures and build logs are retained there. Only synthetic audit data is in these files.

| Group | Existing checks | Result / limit |
| --- | --- | --- |
| Core flow | `gameplay_check`, `campaign_smoke`, `enemy_check`, `boss_phase_check` | PASS; proves current Dragon-combat prototype, not proposed Bear chapter. |
| Quest/pickups | `beach_seals_check`, `navigation_check`, `grove_check`, `herbal_check`, `keeper_check`, `journal_check` | PASS; seal gates/migration, scroll-only bounty, herbs/healing and optional rewards. |
| Saves | `persistent_world_check`, `save_check`, `autosave_check` | PASS; synthetic legacy/corrupt/backup/failure/one-time reward cases; no hardware power-interruption claim. |
| Controls/layout | `target_lock_check`, `settings_check`, `layout_check`, `safe_area_check`, `interaction_controls_check`, `heavy_attack_check`, `sprint_check`, `jump_check` | PASS; touch event simulation and keyboard lock. Heavy/sprint checks each report two leaked ObjectDB instances at exit. |
| Art/obstacles | `hero_animation_check`, `dragon_check`, `wolf_feedback_check`, `prop_collision_check`, `camera_check`, `island_regions_check` | PASS; sampled physical geometry/animations; not full phone visual acceptance. |
| Coastal motion | `shallow_water_check` | PASS on full 113.53-second retry: real motion at 60/15 physics ticks/second, seam checks, safe water/rescue, all seal pickups and save relocation. Initial 60-second runner timeout retained as attempt history. |

Reproduction from repository root, restoring the environment afterward:

```powershell
$auditRoot = Join-Path (Get-Location) '.validation/ch1_audit_manual'
New-Item -ItemType Directory -Force -Path $auditRoot | Out-Null
$previousAppData = $env:APPDATA
$previousTestMode = $env:VEYRA_TEST
try {
    $env:APPDATA = $auditRoot
    $env:VEYRA_TEST = '1'
    $godotExe = 'C:\Users\Dark\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
    & $godotExe --headless --path . --script res://tests/beach_seals_check.gd
} finally {
    $env:APPDATA = $previousAppData
    $env:VEYRA_TEST = $previousTestMode
}
```

Use separate storage per test. Some checks reset their synthetic campaigns intentionally. Allow at least 210 seconds for the complete real-time shallow-water traversal; its two physics-rate loops are longer than a short unit test.

## Plan acceptance coverage

| ID | Status | Evidence / remaining requirement |
| --- | --- | --- |
| T01 phone move/look | Partial | Desktop input/settings only; no connected phone. |
| T02 attack/dodge/move | Partial | Gameplay/heavy/sprint/jump checks; physical two-thumb recording pending. |
| T03 mobile lock/switch | Incomplete | Keyboard lock passes; touch affordance/switch absent. |
| T04 coastline | Partial | Regions coast-clearance assertions and fresh native beach/overview captures reviewed; phone route not accepted. |
| T05 dense forest | Partial | All generated tall trunks ray-tested, camera/prop tests pass; full route footage/phone review pending. |
| T06 fox/wolf | Audited | Five wolves; HP 18/17/21; retired ID 5; no active separate fox. |
| T07 boar/serpent | Absent | Shared wolf variants/fallback geometry are not the requested encounters. |
| T08 seal quest | Desktop verified | Beach gate/collection/save/migration and journal tests pass; fresh-player phone walkthrough pending. |
| T09 herbs/potion | Desktop verified | Herbal/grove/campaign checks pass. |
| T10 equipment upgrade | Partial | Saved numerical upgrades work; visible equipment progression absent. |
| T11 Cursed Bear | Absent | Current tests fight Tidewraith Dragon. |
| T11A recurring reveal | Absent | Model inspection does not satisfy story trigger/skip/resume/reveal footage. |
| T12 next chapter | Absent | No story threshold/unlock state. |
| T13 save upgrade | Partial | Existing v1–v4 migration tested; future Bear/reveal/unlock migration absent. |
| T14 ratios/safe area | Partial | Simulated 800x450 / 1280x720 / 1920x864 and cutout-coordinate tests; phone acceptance pending. |
| T15 sustained performance | Unknown on phone | Desktop snapshot/sample only; no 20-minute handset CPU/GPU/thermal/battery measurement. |
| T16 asset rights | Partial | Local register and gaps in `CH1_ASSETS.md`; no release clearance. |

## Device/build availability

| Target | Available evidence | Current limitation |
| --- | --- | --- |
| Windows desktop, Godot 4.7.2 GL Compatibility | 28 checks and seven fresh native renders; stationary sample: 534 draw calls / 646,633 primitives; median 43.463 ms, p95 48.453 ms, max 52.322 ms over 120 force-drawn frames | Restricted method-specific sample, not sustained route timing or handset FPS. |
| Samsung A37 | Prior release notes record owner-reported smooth play and saved progress | Not attached/identified/tested in this audit. OS, memory and sustained performance unknown. |
| Android over ADB | SDK tools installed; sanitized device probe shows zero authorized and zero unauthorized devices | No install, touch, background/resume or thermal test possible now. No device serials recorded. |
| Representative mid-range Android | Not selected/connected | 30 FPS through ~20-minute session is a planning target, not a measured result. |
| Wider/cutout handset | Not connected | Native safe-area and actual multitouch test required. |

The default SDK helper initially resolved sandbox-remapped LOCALAPPDATA and reported missing SDK tools. Re-running with `-SdkPath 'C:\Users\Dark\AppData\Local\Android\Sdk'` found adb, platform/build tools, Java, matching debug/release templates and export preset. No environment or project configuration was changed for this correction.

## Fresh Android export and precise blocker

The installed Godot executable was invoked with `--headless --path . --export-debug "Android Debug" .validation/ch1_audit_2026-11-13/ch1-phase0-baseline.apk` and a log path inside the evidence directory. It exited 1 in 6.86 seconds. No APK was produced at that path; existing `builds/android` APKs were left untouched.

The restricted runner could not create/write `C:/Users/Dark/AppData/Roaming/Godot` editor data/config and feature-profile directories; Editor Settings then reported an invalid Android SDK location with missing `platform-tools/adb` and `build-tools/apksigner`. Those tools exist at the explicit actual SDK location above. Therefore **fresh export reproducibility is blocked by editor-config access/resolution**, not proven broken gameplay code. Templates being present alone does not establish a working export.

To complete packaging verification later, run with permitted Godot editor configuration or a sanitized isolated editor profile that points to the existing SDK, Java and matching templates; retain the existing local debug signing identity. Do not print/copy signing credentials into reports. Then inspect the newly built archive/signature and install on a connected handset. No additional global-editor permission was requested solely to turn this audit into an environment reconfiguration task.

## Capture evidence and scope

Reviewed PNGs: `arrival_hud.png`, `island_overview.png`, `forest.png`, `beach.png`, `ruins.png`, `dragon_identity_inspection.png`, `dragon_eye_inspection.png`. Capture script and logs are local in the evidence directory. The Dragon appears in a separate inspection scene; no cameo trigger or story scene was added. The arrival hero remains temporary art. No video/full player route was recorded in this audit.

`preservation.json` records 306 original tracked-file hashes checked, zero changed, branch `main`. Only six new documentation files are added to the tracked scope; test/capture data is ignored.

## Phase 1 follow-up (separate from the Phase 0 results above)

**20/20 targeted checks PASS** on the final Phase 1 code, including new `chapter_route_check` and existing terrain/regions, mountain, material, prop/camera collision, navigation, beach seals, grove/herbal, persistent-world/save/autosave/gameplay, island-map/layout/safe-area, fast-travel, environment and complete shallow-water checks. No warnings in this selected subset; unrelated Phase 0 heavy/sprint warnings are not declared fixed.

Evidence is isolated in `.validation/ch1_phase1_2026-11-13/`. The new test uses oversized capsule sweeps and actual controller movement for a 711-waypoint shore/foothills/forest/ruins/grove loop, eastern return, Moonleaf round trip and partial-seal save/reopen. Native rendered rerun passes and provides a 20.4-second controlled route video at 4x simulation with enemy AI frozen. This advances desktop T04/T05 route evidence, not mobile combat/touch acceptance.

Grove floor and reserved Dragon camera/perch orientation/sightlines are checked; native retained-model framing is previewed only in validation. T11/T11A story boss/reveal remain absent; no Phase 5 progression feature was added. Save version, rewards and quest coordinates are retained.

Two map sizes (1280x720 and 800x450), overview, woodland and new clearing were visually reviewed. Desktop before/after counters and capture-method limitations are in [Phase 1 report](CH1_PHASE1_REPORT.md). No connected handset, sustained thermal test or new APK. Packaging keeps the Phase 0 environment blocker. Hardware acceptance remains open.
