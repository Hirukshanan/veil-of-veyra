extends SceneTree
func _initialize():
	var args:=OS.get_cmdline_user_args()
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var resource=load("res://scripts/island_surface_data.gd").new()
	resource.heights=PackedFloat32Array(data.heights)
	resource.cells=PackedByteArray(data.cells)
	for pair in data.preserved:
		resource.preserved_sources.append(Vector3(pair.source[0],pair.source[1],pair.source[2]))
		resource.preserved_positions.append(Vector3(pair.position[0],pair.position[1],pair.position[2]))
	assert(ResourceSaver.save(resource,"res://assets/environment/new_island/terrain_surface.res",ResourceSaver.FLAG_COMPRESS)==OK)
	print("PASS: shared terrain surface resource saved")
	quit()
