extends SceneTree

func _initialize():
	call_deferred("run")

func mesh_from_file(path: String) -> Mesh:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	assert(document.append_from_file(path, state) == OK)
	var imported := document.generate_scene(state)
	var mesh: Mesh = imported.find_children("*", "MeshInstance3D", true, false)[0].mesh
	imported.free()
	return mesh

func run():
	var output: String = OS.get_cmdline_user_args()[0]
	var before := mesh_from_file(output + "/baseline/assets/environment/new_island/task542/cave_exterior.glb")
	var after := mesh_from_file("res://assets/environment/new_island/task542/cave_exterior.glb")
	assert(before.get_faces() == after.get_faces(), "Material correction must preserve every ordered collision triangle")
	var old_arrays := before.surface_get_arrays(0)
	var new_arrays := after.surface_get_arrays(0)
	assert(old_arrays[Mesh.ARRAY_VERTEX] == new_arrays[Mesh.ARRAY_VERTEX])
	assert(old_arrays[Mesh.ARRAY_INDEX] == new_arrays[Mesh.ARRAY_INDEX])
	assert(old_arrays[Mesh.ARRAY_NORMAL] == new_arrays[Mesh.ARRAY_NORMAL])
	var old_colors: PackedColorArray = old_arrays[Mesh.ARRAY_COLOR]
	var new_colors: PackedColorArray = new_arrays[Mesh.ARRAY_COLOR]
	var changes := 0
	for index in old_colors.size():
		if old_colors[index] != new_colors[index]:
			assert(old_colors[index] == Color.WHITE and new_colors[index] == Color(0, 0, 0, 1))
			changes += 1
	assert(changes > 0)
	FileAccess.open(output + "/godot_geometry_verification.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "ordered_faces_exact": true, "positions_exact": true, "indices_exact": true, "normals_exact": true, "changed_render_vertices": changes, "triangles": after.get_faces().size() / 3, "only_changed_attribute": "Interior vertex color white to black; alpha retained"}, "  "))
	print("PASS: all ordered triangles, positions, indices and normals identical; only interior mask changed")
	quit()
