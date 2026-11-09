# Quest journal artwork and fonts

- `quest_parchment.jpg`: user-supplied reference artwork, used at the user's request. No third-party redistribution license was supplied; confirm rights before public distribution.
- `fonts/Cinzel.ttf`: Cinzel, from https://github.com/google/fonts/tree/main/ofl/cinzel . SIL Open Font License; see `fonts/Cinzel-OFL.txt`.
- `fonts/CrimsonText-Regular.ttf`: Crimson Text, from https://github.com/google/fonts/tree/main/ofl/crimsontext . SIL Open Font License; see `fonts/CrimsonText-OFL.txt`.

The quest screen uses Cinzel headings/buttons and Crimson Text body copy. The camp title and primary action also use Cinzel; secondary controls use the normal UI font. The parchment background remains fixed while its inner content scrolls.

## Approved launcher and camp artwork

`brand/dragon_lantern.png` was generated with the built-in image generation tool and approved by the project owner on 2026-11-09. It supplies the camp artwork and launcher derivatives. No private project files or screenshots were used as generation inputs.

Final prompt (built-in image generation):

> Use case: logo-brand. Create a finished premium mobile fantasy action RPG app icon, square 1024x1024, edge-to-edge opaque artwork (no rounded outer corners, no external white margin). One powerful charcoal black dragon head in three-quarter view, anatomically coherent, heavy angular volcanic scale plates, two elegant ivory-white curved horns, one luminous amber eye, emerging around a small bright turquoise magical lantern emblem below its jaw. Original dragon design, no existing franchise. Sculptural painted 3D fantasy game key art finish, exceptionally clean bold silhouette, crisp focal face, restrained metallic warm gold accents and subtle sea-teal mist on deep midnight navy backdrop. Face and white horns occupy the central 60 percent so Android circular/squircle masks keep all important detail. Strong small-size readability, dramatic warm/cool rim lighting, rich but disciplined contrast. No lettering, no words, no initials, no UI mockup, no phone, no extra heads, no full body, no busy landscape. Produce one icon only.


`brand/launcher.png` is the 512px project/legacy launcher icon. `brand/launcher_foreground.png` and `brand/launcher_background.png` are 432px adaptive layers. Rebuild derivatives locally with `godot --headless --path . --script res://tools/prepare_launcher.gd`. The original generated image is retained in the project.

Android icon configuration follows the [Godot 4.7 Android export settings](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html) and [launcher icon guidance](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html). Device launcher appearance is verified only after a new APK is installed.

## Gameplay control icons

The original project-native SVGs in `controls/` represent sword attack, dodge, sprint, Spirit Burst, healing, pause, collection and lantern interaction. They contain no lettering. Screen-reader action names remain available through Godot accessibility properties. Resource/hold rings are drawn by `round_button.gd`; combat shortcuts remain documented in Field guide.
