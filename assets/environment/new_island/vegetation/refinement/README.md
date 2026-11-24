# Task 2.1 asset sources and licenses

- **Trunks and forms:** original branch graph, smooth voxel-union geometry and non-linear form definitions authored locally for Veil of Vera. Broad Fork, Tall Column and Leaning Crown share a master and instanced mesh topology; they are distinct forms, not three separately sourced botanical species. Editable source: `art_source/island/polish_task21/forest_forms.blend`.
- **Bark diffuse and normal:** unchanged existing `island_tree_01_branches_diff_1k.jpg` / `island_tree_01_branches_nor_gl_1k.jpg` from [Poly Haven Island Tree 01](https://polyhaven.com/a/island_tree_01), CC0 1.0.
- **Twig atlas:** new 1024×1024 RGBA cutout atlas rendered locally in Godot from original twig arrangements and the existing CC0 `island_tree_01_leaves_diff_1k.jpg`. This is a real asset bake, not an AI concept image. Original leaf scans remain unchanged. The resulting texture is mipmapped and VRAM compressed.
- **Grass:** original curved geometry/tints refined locally; no new third-party geometry or raster source.
- Existing owner-supplied regional assets and placement attribution remain **Logachandran Hirukshanan, generated using Tripo3D**. Their source/collision assets are unchanged.

Poly Haven's [official CC0 asset license](https://polyhaven.com/license) allows commercial use; [CC0 summary](https://creativecommons.org/publicdomain/zero/1.0/). Existing source acquisition is recorded in `assets/environment/README.md`. Original new geometry/arrangements are project work; this task does not relicense the entire game.

No new external asset downloads or uploads of private files/code/screenshots were performed. Shader implementation references: [Godot spatial custom vertex/instance fields](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html) and [SurfaceTool custom formats](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html).
