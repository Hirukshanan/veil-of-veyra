# Island Visual Polish — Task 1

Status: candidate terrain repair implemented for visual review. **Not activated and not commercially finished.** Stop here for explicit approval; no foliage, lighting, combat, Chapter II or main-map work is included.

## Repairs

- Removed the west grassland and west cave slab faces, replacing cut edges with graded terrain rather than decorative cover. Region transforms remain unchanged.
- Rebuilt grassland/beach surface ownership on one shared height field. Each connecting cell has one terrain owner; the southern junction no longer contains intersecting slab surfaces.
- Smoothed inherited cut-edge height discontinuities into broad shoulders. Retained the original forest mesh, mountain core and cave core; filled actual missing support beneath the open mountain prop.
- Carved a rounded, winding river bed with real sloping banks. Local channel tessellation is 0.3125 m; the rest of the shared grid remains 1.25 m. Water is clipped to the same terrain triangles, instead of using a raised rectangular strip.
- Widened and lowered the estuary, tapering the banks into the sea. Water continues to z=118.75 m at y=-1.49 m, below the unchanged sea at -1.45 m. The extra estuary pair shows the old floating strip termination and the new connection.
- Remeshed grassland/beach use the existing world-space terrain materials so disconnected old UV islands cannot smear across new triangles. Original embedded albedo image bytes remain intact.
- Preserved the original sea shader and rendering setup. River shading matches it at the mouth. No transparency, refraction, screen-space reflection or new texture maps were introduced.

## Evidence

[Before/after gallery](gallery.html) contains eight pairs: four joins, upper/middle river, lower outlet banks and the sea connection. The original seven before images are unchanged prior screenshots. Their after views use identical absolute camera positions, rotations, FOV and resolution. The extra sea pair was captured from a hash-verified pre-task review copy and current candidate. Inspection views hide the HUD; the three additional third-person views retain the existing gameplay HUD. Only review fixtures freeze actor physics for still images. Native PNGs are available under `before/` and `after/`; no generated imagery or image edits were used.

## Verification

**17 test runs passed:** the existing three candidate tests, the existing twelve campaign/combat/HUD regressions, the five-region actual-controller traversal review and a new terrain/collision geometry test. Raw stdout, stderr and command/exit records are in `logs/`; per-run timestamps are in `test_results.json`. The original-world regressions ran during this task before the last candidate-only mesh refinements; candidate and geometry tests were rerun after those refinements.

- The unchanged hero walked outward and back across all five regional approaches, without teleporting between legs, fall rescue, damage or lost health. These are reachable gameplay routes, not a claim that every cliff or river crossing is walkable.
- All 324 real collision samples at the four joins passed; maximum support discrepancy 0.00004452 m.
- 2869 shoreline vertices checked against real collision, maximum water/terrain discrepancy 0.00013518 m.
- All 26 logged existing enemy, item and scenery placements retained within 0.00004208 m (floating-point tolerance).
- Legacy health, gear, partial quests, cave entry/relic, cave reload, one-time boar reward, lantern and dragon progression passed the existing campaign check.
- All five embedded albedo images retained their original bytes. Forest GLB, original island sources, main scene, project settings, campaign, player controller and candidate placement script are unchanged. See `preservation.json`.

## Rendering cost and limits

- Base solid terrain/region triangles: 84,578 before → 143,710 after, excluding water, actors, grass, tree supplements and grotto. The refined river adds 26,897 triangles. This is a deliberate geometry increase; it is **not performance-neutral**.
- Tessellation is limited to the river corridor. Meshes reuse indexed vertices, regional import LOD remains enabled, water casts no shadows and uses one inexpensive opaque material. There are no per-frame terrain rebuilds.
- Scene-wide Godot monitors on the desktop review run: static memory 119.61 MiB, texture memory 262.05 MiB, video memory 298.71 MiB. Texture memory is unchanged from the previous review. These are engine counters, not OS working set or mobile measurements. Original five source maps remain 2048 × 2048 with compressed mipmaps; no texture resolution increase.
- No Android build/device FPS or thermal profiling was performed. Mobile frame rate remains unverified; the increased triangle count is a remaining performance risk.

## Remaining visual limitations

- The imported mountain and cave cores still contain angular forms and stretched source texture areas, visible in the northern close-up. This pass repairs support/connectivity, not a full re-sculpt or retexture of those props.
- Cave facade/interior art alignment, sparse grass, forest density, overall lighting and wider island composition are unchanged and remain unapproved. Water uses simple opaque shading; there is no depth transparency or physically simulated flow.
- Local riverbank tessellation can still be seen at very close distances. This is an improved candidate for review, not final commercial terrain.

## Files and rollback

`files_changed.json` lists existing changes and added runtime/test files. Editable Blender source, rebuild script, recorded placement anchors and the surface bake script are in `art_source/island/polish_task1/`. Existing `Island_original.glb`, `island_regions.blend`, production map source and old main scene remain unchanged. The pre-task candidate checkpoint is recorded in `preservation.json`; do not delete it.

No branch, commit, push, APK or production activation was performed. Wait for visual approval before continuing.
