# Task 4 sources and licenses

- Lighting/sky/haze settings, ground palette variants, canopy/path mask and two stone-inlay meshes are original local project work. No new asset downloads, AI image generation, model generation, private uploads or service calls were used.
- Ground maps are the unchanged existing [Poly Haven Leafy Grass](https://polyhaven.com/a/leafy_grass), [Forest Ground 04](https://polyhaven.com/a/forest_ground_04) and [Coast Sand 01](https://polyhaven.com/a/coast_sand_01), CC0 1.0. Existing acquisition/provenance is in `assets/environment/README.md`. [Poly Haven license](https://polyhaven.com/license).
- Landmark stone uses original Task 3 `rock_albedo.png`, already generated locally for this project. No additional raster texture is needed beyond the new 512×512 RGBA ground-control mask.
- Owner-supplied island remains credited to **Hirukshanan, generated using Tripo3D**; the source asset files and their provenance are unchanged. No new license determination about the owner's original generation is made here.
- Existing character, vegetation, enemy and dragon assets/licenses are unchanged. New project work does not relicense the rest of the game.

Public technical references consulted: [Godot Environment](https://docs.godotengine.org/en/stable/classes/class_environment.html), [DirectionalLight3D](https://docs.godotengine.org/en/stable/classes/class_directionallight3d.html), [environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html). Standard depth fog and a single existing sun are used; volumetric fog/GI are not introduced.
