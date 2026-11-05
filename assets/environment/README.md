# Environment asset provenance

Downloaded 2026-11-05 from Poly Haven's official public API/CDN.
License: CC0 1.0, https://polyhaven.com/license
https://creativecommons.org/publicdomain/zero/1.0/
Commercial use and redistribution are permitted. Credit: Poly Haven contributors.

Sources:
- https://polyhaven.com/a/coast_sand_01
- https://polyhaven.com/a/forest_ground_04
- https://polyhaven.com/a/leafy_grass
- https://polyhaven.com/a/rocky_terrain_02
- https://polyhaven.com/a/island_tree_01
- https://polyhaven.com/a/fern_02

Ground textures use 1K diffuse, OpenGL normal and roughness JPEGs, with mipmaps
and VRAM compression. Native triplanar mapping uses world coordinates.
The tree and fern source glTF packages are retained for reproducibility, but
excluded from game export. Generated mobile SCNs depend only on their textures.
Run `godot --headless --path . --script res://tools/prepare_environment.gd`
after importing sources to regenerate the reduced scenes using native mesh LODs.
Final geometry: tree 16,794 triangles; fern cluster (four plants) 6,232 triangles.
Mesh density, tree count and visibility distances were reduced for mobile;
physical-device performance has not been measured on this version.

Rock silhouettes and terrain geometry are procedural; their surface textures
are sourced above. Coastal water shader is original project code. This is a
realism improvement pass, not a photorealistic terrain or swimming simulation.
