param([Parameter(Mandatory=$true)][string]$ArchivePath)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$source=Join-Path $repo '.validation\hero_upgrade_2026-11-14\source'
$assets=Join-Path $repo 'assets\characters\aru'
New-Item -ItemType Directory -Force -Path $source,$assets | Out-Null
$prefix='Modular Character Outfits - Fantasy[Standard]/'
$files=@{
 'Exports/glTF (Godot-Unreal)/Outfits/Male_Ranger.gltf'='Male_Ranger.original.gltf'
 'Exports/glTF (Godot-Unreal)/Outfits/Male_Ranger.bin'='Male_Ranger.bin'
 'Textures/Ranger/T_Ranger_BaseColor.png'='Ranger_Color.png'
 'Textures/Ranger/T_Ranger_Normal.png'='Ranger_Normal.png'
 'Textures/Ranger/T_Ranger_ORM.png'='Ranger_ORM.png'
 'Textures/Base/T_Regular_Male_Dark_BaseColor.png'='Skin_Color.png'
}
$resolved=(Resolve-Path -LiteralPath $ArchivePath).Path
$archive=[IO.Compression.ZipFile]::OpenRead($resolved)
try {
 foreach($relative in $files.Keys){
  $entry=$archive.GetEntry($prefix+$relative)
  if(!$entry){throw ('Required author asset missing: '+$relative)}
  $target=[IO.Path]::GetFullPath((Join-Path $source $files[$relative]))
  if(!$target.StartsWith($source+[IO.Path]::DirectorySeparatorChar)){throw 'Invalid staging path'}
  [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target,$true)
 }
 $license=$archive.GetEntry($prefix+'License_Standard.txt')
 if(!$license){throw 'Bundled author license missing'}
 [IO.Compression.ZipFileExtensions]::ExtractToFile($license,(Join-Path $assets 'OUTFIT_LICENSE.txt'),$true)
} finally {$archive.Dispose()}
$gltf=Get-Content -LiteralPath (Join-Path $source 'Male_Ranger.original.gltf') -Raw|ConvertFrom-Json -Depth 100
$gltf.images=@(@{uri='Ranger_Color.png';name='Ranger_Color'},@{uri='Skin_Color.png';name='Skin_Color'})
$gltf.textures=@(@{source=0},@{source=1})
$gltf.materials=@(for($index=0;$index -lt 2;$index++){
 @{name=$gltf.materials[$index].name;pbrMetallicRoughness=@{baseColorTexture=@{index=$index};metallicFactor=0;roughnessFactor=0.85}}
})
$gltf|ConvertTo-Json -Depth 100|Set-Content -LiteralPath (Join-Path $source 'Male_Ranger.gltf') -Encoding utf8
Copy-Item -LiteralPath (Join-Path $repo 'assets\characters\quaternius\LICENSE.txt') -Destination (Join-Path $assets 'BASE_CHARACTER_LICENSE.txt')
Write-Output 'Staged the selected public CC0 model and texture sources. No downloads or project changes outside the selected asset are performed.'
