# Aru starter warrior

Prepared 2026-11-14. Visual review candidate; owner approval is pending.

The base-body/procedural clothing presentation is replaced by the rigged male Ranger outfit from **Quaternius, Modular Character Outfits – Fantasy, free Standard edition**. Original Universal Base Characters face, eyes and eyebrows are retained and rest-skinned to the outfit skeleton. Original sources and Universal Animation Library remain unchanged in `../quaternius/`.

## Provenance

- Author: https://quaternius.com/packs/modularcharacteroutfitsfantasy.html
- Download: https://quaternius.itch.io/modular-character-outfits-fantasy
- Base: https://quaternius.com/packs/universalbasecharacters.html
- Both releases are CC0 1.0. `OUTFIT_LICENSE.txt` is the actual bundled `License_Standard.txt`; `BASE_CHARACTER_LICENSE.txt` copies the existing base notice. Animation terms remain in `../quaternius/ANIMATION_LICENSE.txt`.
- Source archive: `Modular Character Outfits - Fantasy[Standard].zip`, SHA-256 `C3468B18871CC8C8F05AB14DF7712BAF22CB9F389CBD870BABF130E595187F70`.

Selected sources: `Exports/glTF (Godot-Unreal)/Outfits/Male_Ranger.gltf`, its `.bin`, `Textures/Ranger/T_Ranger_BaseColor.png`, `T_Ranger_Normal.png`, `T_Ranger_ORM.png`, and `Textures/Base/T_Regular_Male_Dark_BaseColor.png`. The full archive and unused outfits are not shipped.

## Runtime preparation

`starter_warrior.scn` references `starter_warrior_mesh.res`, seven prepared PNGs and the existing brown eye texture. The combined mesh has **18,218 triangles, five surfaces, 65 bones and four skin influences per vertex**. Tunic, hood, limbs and hands retain authored weights; boots, bracers, belts and cloth use offline simplification. One duplicate belt is omitted. Head vertices/normals are transformed between source and target rest frames and weighted to target bones. Tangents are rebuilt after merging. No mesh generation occurs during play.

Textures are capped at 1024 pixels; eyebrows/face normal use 512, eyes 256. PNG imports enable mipmaps and native GPU compression. Eyebrows use a dark brown tint. `hero_visual.gd` retargets eleven existing clips to the actual skeleton path and applies a local finger curl for the right-hand sword grip. Wrist motion remains animated. Sword size/position are adjusted visually; gameplay volumes, timing, movement and saves are unchanged.

## Reproduce locally

Download the free Standard archive from the author, then run these commands sequentially from the repository root (substitute your Godot executable):

```powershell
./tools/stage_aru_sources.ps1 -ArchivePath 'C:\path\Modular Character Outfits - Fantasy[Standard].zip'
godot --headless --path . --script res://tools/prepare_aru.gd -- --textures-only
godot --headless --editor --import --quit --path .
godot --headless --path . --script res://tools/prepare_aru.gd
godot --headless --path . --script res://tests/hero_presentation_check.gd
```

The helper extracts only selected files into ignored `.validation/hero_upgrade_2026-11-14/source/`, resolves texture references and copies licenses. The baker reads locally. Game startup needs only the prepared assets, not the archive/staging files. No private project data is sent to the author or a service.
