# Island source and local preparation

Credit: Logachandran Hirukshanan using Tripo3D. `Island_original.glb` is preserved byte-for-byte from the supplied file, with its five original 4K color images. `island_regions.blend` is the editable prepared five-region source with packed 2K images. It has no gameplay rig/animation. Runtime connecting terrain and cave interior are authored in Godot, not baked into this .blend.

Local reproduction from the repository root (substitute installed executables):

```powershell
blender --background --disable-autoexec --python-exit-code 1 --python art_source/island/prepare_regions.py
godot --headless --editor --path . --import --quit
python art_source/island/optimize_imports.py
godot --headless --editor --path . --import --quit
```

The first step rebuilds only prepared derivatives, retaining the original. The optimizer removes only redundant unprefixed derivative JPEGs and enables compression/mipmaps on the five extracted runtime dependencies. Blender's packed images keep the editable source self-contained. `.gdignore` keeps original source data out of game imports/exports. Existing Git LFS rules cover source .blend/.glb files. Do not push Blender .blend1 temporary backups or ignored validation captures.
