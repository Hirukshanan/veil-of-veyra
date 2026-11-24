# Vegetation asset sources and licenses

No private assets, code, screenshots or conversation data were uploaded. No new external asset downloads were needed.

| Component | Source / derivation | License / credit |
|---|---|---|
| New tree trunks | Reduced locally from existing `assets/environment/forest_tree_mobile.res`, originally [Poly Haven Island Tree 01](https://polyhaven.com/a/island_tree_01). Existing branch bark texture reused with a single material. | Poly Haven contributors, CC0 1.0. |
| Leaf canopies / low shrubs | Original deterministic leaf placement/lobes, using the unchanged existing `island_tree_01_leaves_diff_1k.jpg` atlas from the same tree asset. | Atlas: Poly Haven CC0 1.0; new arrangement is original project work. |
| Curved grass and fern meshes | Generated locally for Veil of Vera by `prepare_vegetation.gd`; no third-party geometry input. | Original project work, no additional third-party license. |
| Ground variation | Existing [Leafy Grass](https://polyhaven.com/a/leafy_grass), [Forest Ground 04](https://polyhaven.com/a/forest_ground_04), [Coast Sand 01](https://polyhaven.com/a/coast_sand_01) maps, reused without image changes. | Poly Haven contributors, CC0 1.0. |
| Existing region placement and original forest collision source | Logachandran Hirukshanan's supplied Island.glb, generated using Tripo3D; source and collision mesh unchanged. Original tree-root coordinates retained for replacement visuals. | Existing owner-provided asset and attribution remain; no new ownership certification or relicensing performed. |

Poly Haven's [official asset license](https://polyhaven.com/license) was checked during this task on 2026-11-15: its assets are CC0 and may be used commercially. [CC0 summary](https://creativecommons.org/publicdomain/zero/1.0/). Existing `assets/environment/README.md` documents original acquisition and derivatives. Unrelated character/enemy licenses and credits were not modified.

The new tree/grass LOD resources introduce no new raster maps. Existing bark, leaf, grass, soil and sand files retain their original bytes and mipmapped compressed imports.
