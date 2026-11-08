# Charcoal Black Dark Dragon

- Creator: Pigcraft (@s8819296).
- Source: https://sketchfab.com/3d-models/charcoal-black-dark-dragon-25c51b198dd54e538f62569d52f61d8e
- License: Creative Commons Attribution 4.0 International (CC BY 4.0).
- License text: https://creativecommons.org/licenses/by/4.0/legalcode

Credit: "Charcoal Black Dark Dragon" by Pigcraft, CC BY 4.0.
Modified for Veil of Veyra: reduced mesh, consolidated duplicate UV channels,
normalized orientation/scale, added 21-bone skinning and eight combat motion clips.
Original black scales, wing textures, and ivory horns are retained.
The creator does not endorse this game.

The optimized GLB is included under CC BY 4.0. Retain this attribution and indicate
further changes when sharing it. The original 53 MB download is not included.

## Rebuild

With Blender 4.5 LTS available on PATH, run from the repository root:

    blender --background --python tools/prepare_charcoal.py -- /path/to/source.glb assets/characters/pigcraft/charcoal_dragon.glb

Preparation is offline. The source must be the original 2K GLB linked above.
The script verifies duplicate UV channels before consolidation and outputs one
34,999-triangle mesh with 2K textures. The rig uses anatomical envelopes and small
hover/attack arcs, rather than a ground-walking or free-flight locomotion system.

Runtime visuals sample animation from the boss state clock; animation never deals
damage. The detached death visual finishes behind the paused victory menu.
