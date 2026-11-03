# Character asset provenance

Author: Quaternius. Downloaded 2026-11-03 from the author's free Standard releases.

- Universal Base Characters: https://quaternius.com/packs/universalbasecharacters.html
  Download: https://quaternius.itch.io/universal-base-characters
  Included: Superhero male full-body glTF, binary geometry, and its seven referenced textures.
  Original license: `LICENSE.txt` (CC0 1.0).
- Universal Animation Library: https://quaternius.com/packs/universalanimationlibrary.html
  Download: https://quaternius.itch.io/universal-animation-library
  Included: `Unreal-Godot/UAL1_Standard.glb`, the non-root-motion variant.
  Original license: `ANIMATION_LICENSE.txt` (CC0 1.0).

The glTF's missing texture references `T_Hair_1_Normal_png.png` and
`T_Eye_Normal_png.png` were corrected to the corresponding included `.png` names.
No original geometry or textures were changed. Godot `.import` sidecars are included;
generated `.godot` caches are not.

`scripts/hero_visual.gd` selects seven clips, adjusts local bone rotation/rest-position
differences onto the base skeleton, loops idle/sprint, and rotates the visual to face -Z.
The original procedural island blade attaches to `hand_r`. Animation never drives
the player's collision body. Existing hit volumes remain
unchanged; animation playback fits action durations, with 0.12-second light and 0.20-second heavy contact windups.

This is a temporary base body, not finished Aru art. Custom clothing/hair, distinct
combo swings, precise strike-frame synchronization, locked-target strafing, and
mobile texture/memory optimization remain future work. The complete donor GLB is
retained for source reproducibility; unused clips should be stripped for release.
