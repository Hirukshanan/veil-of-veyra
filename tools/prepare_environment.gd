extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	for id in ["island_tree_01", "fern_02"]:
		var model = load("res://assets/environment/polyhaven/%s/%s.gltf" % [id, id]).instantiate()
		var total := 0
		for node in model.find_children("*", "MeshInstance3D", true, false):
			var importer := ImporterMesh.new()
			for surface in range(node.mesh.get_surface_count()):
				importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, node.mesh.surface_get_arrays(surface), [], {}, node.mesh.surface_get_material(surface))
			importer.generate_lods(60, 60, [])
			var reduced := ArrayMesh.new()
			for surface in range(importer.get_surface_count()):
				var arrays := importer.get_surface_arrays(surface)
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				for level in range(importer.get_surface_lod_count(surface)):
					var candidate := importer.get_surface_lod_indices(surface, level)
					if candidate.size() >= (12000 if id == "island_tree_01" else 6000) and candidate.size() < indices.size():
						indices = candidate
				var builder := SurfaceTool.new()
				builder.begin(Mesh.PRIMITIVE_TRIANGLES)
				for index in indices:
					builder.set_normal(arrays[Mesh.ARRAY_NORMAL][index])
					builder.set_uv(arrays[Mesh.ARRAY_TEX_UV][index])
					builder.add_vertex(arrays[Mesh.ARRAY_VERTEX][index])
				builder.index()
				builder.generate_tangents()
				builder.set_material(importer.get_surface_material(surface))
				builder.commit(reduced)
				total += indices.size() / 3
			node.mesh = reduced
			print(id, " bounds ", node.get_aabb(), " transform ", node.transform)
		for child in model.find_children("*", "", true, false):
			child.owner = model
		var packed := PackedScene.new()
		assert(packed.pack(model) == OK)
		assert(ResourceSaver.save(packed, "res://assets/environment/%s_mobile.scn" % id) == OK)
		print(id, " mobile triangles ", total)
		model.free()
	quit()
