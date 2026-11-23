# Veil of Vera development and cleanup

1. Integrate each approved replacement into the actual playable game. Verify it through the normal entry points and run focused regression checks.
2. Treat cleanup as a separate, explicitly approved pass after the development phase is finished. Keep the existing implementation until its replacement is approved, integrated and verified.
3. Before cleanup, preserve a reversible Git checkpoint and audit scene, script, resource, save, runtime and export references. Confirm that each removal is obsolete and that shared dependencies still work. A filename containing `old`, `backup` or `test` is insufficient evidence.
4. Remove verified obsolete implementations, duplicate assets and scenes, superseded scripts, outdated VFX and audio, broken references and temporary resources. Ensure production and exported builds use the approved versions. Keep review evidence outside the production asset pipeline.
5. Preserve legacy save compatibility, player save data, original editable Blender sources, licenses and required attribution.
6. Investigate orphan nodes and resource-cleanup warnings, including `buried_temple.gd`. Keep cleanup scoped to resource ownership and obsolete content. Preserve approved gameplay and presentation.
7. After cleanup, verify the actual game, quests, enemies, equipment, menus, audio, save/reload and Android export. Report exactly what was removed, what was retained and why.
