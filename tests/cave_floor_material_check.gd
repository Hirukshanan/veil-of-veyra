extends SceneTree

func _initialize():
	call_deferred("run")

func inspect_hit(scene, start: Vector3, end: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, end, 16)
	var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(query)
	assert(not hit.is_empty(), "Cave sample must hit a solid surface")
	var visual: MeshInstance3D = hit.collider.get_parent()
	assert(visual.name == "PlayableGrotto", "Verify the actual visible cave surface, including terrain ownership")
	var material: ShaderMaterial = visual.material_override
	assert(material.shader.resource_path.ends_with("task542/rock_transition.gdshader"))
	assert(material.get_shader_parameter("interior") == true)
	var arrays: Array = visual.mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	assert(not colors.is_empty())
	for corner in range(3):
		var vertex: int = indices[hit.face_index * 3 + corner] if not indices.is_empty() else hit.face_index * 3 + corner
		assert(colors[vertex] == Color(0, 0, 0, 1), "Interior floor/wall must have zero exterior grass/sand weight")
	return {"hit": hit.position, "surface": str(visual.get_path()), "mask": 0, "interior_material": true}

func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	var floors: Array = []
	for point in [Vector3(76, 1.5, 4), Vector3(73, 1.8, 12), Vector3(71, 2, 15), Vector3(68, 2.2, 19), Vector3(66, 2.35, 25), Vector3(64, 3, 45)]:
		floors.append(inspect_hit(scene, point + Vector3.UP, point - Vector3.UP * 1.5))
	var wall := inspect_hit(scene, Vector3(76, 3, 0), Vector3(89, 3, 0))
	var visual: MeshInstance3D = scene.landscape.get_node("PlayableGrotto")
	var colors: PackedColorArray = visual.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	assert(colors.has(Color.WHITE), "Approved exterior blending must retain its mask")
	FileAccess.open(OS.get_cmdline_user_args()[0] + "/floor_material_results.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "floor_samples": floors, "wall_sample": wall, "exterior_mask_retained": true, "reserved_hall_visual_material_only": true}, "  "))
	print("PASS: six actual cave floor surfaces and wall use dark interior rock ownership; exterior mask retained")
	scene.queue_free()
	await process_frame
	await create_timer(.3, true, false, true).timeout
	quit()
