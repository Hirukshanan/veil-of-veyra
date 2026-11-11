extends SceneTree
# Rebuild the forest mesh from the existing CC0 mobile tree, using Godot's simplifier.
func _initialize():
	var tree=load("res://assets/environment/island_tree_01_mobile.scn").instantiate()
	var source: Mesh=tree.find_children("*","MeshInstance3D",true,false)[0].mesh
	var importer:=ImporterMesh.new()
	for surface in range(source.get_surface_count()):
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,source.surface_get_arrays(surface),[],{},source.surface_get_material(surface))
	importer.generate_lods(60.0,25.0,[])
	var result:=ArrayMesh.new()
	var triangles:=0
	for surface in range(source.get_surface_count()):
		# New atlas cards supply the foliage; retain only the opaque trunk/branches.
		var material: StandardMaterial3D=source.surface_get_material(surface)
		if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED: continue
		var arrays:=source.surface_get_arrays(surface)
		if importer.get_surface_lod_count(surface)>1:
			arrays[Mesh.ARRAY_INDEX]=importer.get_surface_lod_indices(surface,1)
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.surface_set_material(result.get_surface_count()-1,material)
		triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
	assert(ResourceSaver.save(result,"res://assets/environment/forest_tree_mobile.res",ResourceSaver.FLAG_COMPRESS)==OK)
	tree.free()
	print("Prepared forest tree: ",triangles," triangles")
	quit()
