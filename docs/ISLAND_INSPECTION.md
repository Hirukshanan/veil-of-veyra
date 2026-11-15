# Island replacement — inspection before assembly

The owner supplied Island.glb and identifies it as their own Tripo3D generation. Credit: **Hirukshanan, generated using Tripo3D**. No independent license/ownership certification or third-party asset upload was performed. The original is retained unchanged at art_source/island/Island_original.glb. The editable derivative will be saved alongside it. All processing is local.

## Verified file

20,802,060 bytes. Five scene-root mesh objects, one primitive/material/image per object; 65,581 triangles. Five embedded JPEG color textures, each 4096×4096. No authored rig, animations, collision, navigation, separate water material, normal map or named gameplay region. Node transforms are identity; offsets are baked into vertices. Blender reports Z-up values; Godot maps that vertical axis to Y.

| Index | Actual region | Triangles | Original X/Y/Z bounds size (Blender) | Suitability |
|---|---|---:|---|---|
| 0 | Waterfall mountains | 14,130 | 0.179260 / 0.178558 / 0.099045 | Real rocky height and a static textured waterfall cleft. Steep peaks are scenery/boundaries; only low slopes are walkable. No flowing water animation or route network. |
| 1 | Western forest | 10,648 | 0.167526 / 0.179260 / 0.115860 | Ground, thin trunks and clustered canopies exist, fused into one mesh. Trees are not independent reusable instances; use mesh collision and ground-level route validation. Dense forest in the concept is richer than actual geometry. |
| 2 | River grassland | 13,428 | 0.179253 / 0.178024 / 0.136703 | Real rolling terrain/rock relief and water-colored areas, but the complete winding river in the concept is not a separately authored water system. A terrain/water implementation is required. |
| 3 | Eastern cave cliffs | 13,450 | 0.158783 / 0.165947 / 0.093704 | Real arches/overhangs/recesses; no guaranteed human-width complete cave tunnel or prepared interior floor. Must inspect/augment at gameplay scale. |
| 4 | Southern beach | 13,925 | 0.171722 / 0.179260 / 0.112881 | Real coastal terrain slab with rocks and a baked water-colored margin; the source water is opaque static texture rather than the existing animated sea. Lower/trim it where it would conflict with sea. |

The objects occupy a straight X row from -0.5 to +0.5 in normalized source units. This is a collection of regional dioramas, not a ready-to-use continuous island. Scaling that whole row into a world would retain five slab boundaries and disconnected paths.

## Assembly decision

Use individually sized regional assets in a north/west/center/east/south layout. Build a fresh connected Godot ground surface, coastal shelves and graded exploration routes around their real silhouettes, bury slab foundations, and supply lightweight moving water and a practical cave floor/route only where geometry allows. Keep the sea shader's existing lighting/ripple approach. Use exact static regional surface collisions and a modest-resolution connector ground mesh; do not use convex hulls that fill cave arches. Use separate candidate scene and isolated profiles before any main-scene activation. Keep all existing item/enemy IDs, progression, equipment, hero and approved HUD. Ground/revalidate placements on actual collision, with safe save-location relocation when necessary.

Downsample each runtime color image to 2048² (one-quarter pixels; five originals remain in the source). Enable mipmaps and engine mesh LOD; split rendering by region. Measure desktop candidate performance but do not infer Android acceptance. The 2K close-view result must be assessed in actual gameplay.

## Recoverability

Verified pre-change backup: `C:\Users\Dark\Documents\Codex\Backups\Veil_of_Vera_PreIsland_20261115_024603/original_game.zip` (406 files), with independently checked SHA-256 manifest. No branch, commit, deletion of old source or personal-save modification.
