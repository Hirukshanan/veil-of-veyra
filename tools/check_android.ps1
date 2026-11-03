param(
    [string]$SdkPath = $env:ANDROID_HOME,
    [string]$TemplatePath = (Join-Path $env:APPDATA 'Godot/export_templates/4.7.2.stable')
)
$ErrorActionPreference = 'Stop'
if (-not $SdkPath) { $SdkPath = $env:ANDROID_SDK_ROOT }
if (-not $SdkPath) { $SdkPath = Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
$checks = [ordered]@{
    'Java on PATH' = [bool](Get-Command java -ErrorAction SilentlyContinue)
    'Android platform tools (adb)' = (Test-Path -LiteralPath (Join-Path $SdkPath 'platform-tools/adb.exe'))
    'Android platforms installed' = [bool](Get-ChildItem -LiteralPath (Join-Path $SdkPath 'platforms') -Directory -ErrorAction SilentlyContinue)
    'Android build tools installed' = [bool](Get-ChildItem -LiteralPath (Join-Path $SdkPath 'build-tools') -Directory -ErrorAction SilentlyContinue)
    'Godot Android debug template' = (Test-Path -LiteralPath (Join-Path $TemplatePath 'android_debug.apk'))
    'Godot Android release template' = (Test-Path -LiteralPath (Join-Path $TemplatePath 'android_release.apk'))
    'Project export presets' = (Test-Path -LiteralPath (Join-Path $PSScriptRoot '../export_presets.cfg'))
}
Write-Output "SDK: $SdkPath"
Write-Output "Templates: $TemplatePath"
foreach ($entry in $checks.GetEnumerator()) {
    $status = if ($entry.Value) { 'FOUND' } else { 'MISSING' }
    Write-Output "$status - $($entry.Key)"
}
Write-Output 'Presence checks only; versions, signing, exports and device execution still require validation.'
if ($checks.Values -contains $false) { exit 1 }
exit 0
