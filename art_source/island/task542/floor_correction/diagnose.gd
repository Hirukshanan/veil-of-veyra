extends SceneTree

func _initialize():
	call_deferred("run")

func run():
	var scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	var rows: Array = []
	for point in [Vector3(76, 1.5, 4), Vector3(73, 1.8, 12), Vector3(71, 2.0, 15), Vector3(66, 2.35, 25), Vector3(64, 3, 45)]:
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.0, point - Vector3.UP * 2, 16)
		var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(ray)
		assert(not hit.is_empty())
		var mesh: MeshInstance3D = hit.collider.get_parent()
		var arrays: Array = mesh.mesh.surface_get_arrays(0)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var face: int = hit.face_index
		var corners: Array = []
		for index in range(3):
			var vertex: int = indices[face * 3 + index] if not indices.is_empty() else face * 3 + index
			corners.append({"vertex": vertex, "position": arrays[Mesh.ARRAY_VERTEX][vertex], "color": arrays[Mesh.ARRAY_COLOR][vertex] if not arrays[Mesh.ARRAY_COLOR].is_empty() else "no vertex color"})
		var below := PhysicsRayQueryParameters3D.create(hit.position - Vector3.UP * .01, hit.position - Vector3.UP * 2, 16)
		var underneath: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(below)
		rows.append({"point": point, "visible_support": str(mesh.get_path()), "surface_material": mesh.material_override.shader.resource_path, "hit": hit.position, "face": face, "corners": corners, "below_surface": str(underneath.collider.get_parent().get_path()) if not underneath.is_empty() else "none", "below_height": underneath.position.y if not underneath.is_empty() else null})
	var file := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "  "))
	file.close()
	print("DIAGNOSIS ", JSON.stringify(rows))
	scene.queue_free()
	await process_frame
	await create_timer(.3, true, false, true).timeout
	quit()
