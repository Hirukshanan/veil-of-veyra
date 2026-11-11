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
Original reduced geometry: tree 16,794 triangles; fern cluster (four plants) 6,232 triangles. The current gameplay tree uses the smaller derivative described below.
Mesh density, tree count and visibility distances were reduced for mobile;
physical-device performance has not been measured on this version.

Rock silhouettes and terrain geometry are procedural; their surface textures
are sourced above. Coastal water shader is original project code. This is a
realism improvement pass, not a photorealistic terrain or swimming simulation.

The island now uses one opaque ground material blending sand, grass and soil.
A cached 512x512 single-channel mask over a 256 m span is rasterized from the navigation trails.
World-space planar diffuse/normal samples preserve detail across boundaries.
The grass edge varies along the coastline; wet sand darkens and becomes less
rough near the water. Water foam follows the same radial shoreline function.
There are no transparent ground overlays or per-frame path-distance loops.
Rocks retain the original StandardMaterial3D triplanar setup. The ground shader
uses fixed dry/wet roughness instead of the source roughness maps.
Shader reference: https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html

The mountain rim is original procedural geometry: seven multi-peak formations
and six lower connecting ridges, with matching terrain/camera collision.
Its original shader samples the existing CC0 rock diffuse map with world-space
triplanar mapping and desaturates it to a grey-brown rock palette. These are
scenic perimeter formations, not a designed mountain-climbing quest area.

## Expanded island woodland and hills

The current land mesh extends to a base radius of 120 m (previously 96 m), with
six broad hills built into the same visible/collision surface. Tree-free sand
and shallow water surround the inland grass. Ground, foam, boundary and map
use the shared radii from island_terrain.gd. Existing quest locations are retained.

forest_tree_mobile.res reuses the original CC0 tree's textured trunk/branches
with 1,835 triangles. Regenerate it with:

```sh
godot --headless --path . --script res://tools/prepare_forest_tree.gd
```

The existing Poly Haven leaf atlas supplies 500 original leaf cards (1,000
triangles) per canopy, rendered with an alpha-scissor shader. No new raster art
or external asset download was added. The original dense leaf surface is omitted
from the derivative. Forest trees are spatially batched in 20 m cells, culled at
70 m, and use individual player/camera trunk colliders. Existing central/grove
trees use the same wood/canopy meshes with taller proportions. New woodland
placement excludes trails, camp/waystone clearings, pickups and the coastal strip.
These are mobile geometry budgets, not a physical-device performance guarantee.
