extends SceneTree
var scene
const E="res://.validation/island_polish_task2/"
func _initialize():call_deferred("run")
func fingerprint(landscape:Node3D)->Dictionary:
	var rows:Array[String]=[]
	for node in landscape.find_children("*","CollisionShape3D",true,false):
		assert(not node.disabled)
		var shape:Shape3D=node.shape
		var bytes:=PackedByteArray()
		if shape is ConcavePolygonShape3D:bytes=shape.get_faces().to_byte_array()
		elif shape is CylinderShape3D:bytes=var_to_bytes([shape.radius,shape.height])
		else:bytes=var_to_bytes(shape.get_debug_mesh().get_faces())
		var hashing:=HashingContext.new();hashing.start(HashingContext.HASH_SHA256);hashing.update(bytes)
		rows.append(str(node.global_transform)+"|"+shape.get_class()+"|"+hashing.finish().hex_encode()+"|"+str(node.get_parent().collision_layer))
	rows.sort()
	var surfaces:Dictionary={}
	for name in ["ConnectedTerrain","FlowingRiver","Sea","PlayableGrotto"]:
		var mesh:Mesh=landscape.get_node(name).mesh
		var hashing:=HashingContext.new();hashing.start(HashingContext.HASH_SHA256)
		for surface in range(mesh.get_surface_count()):
			var arrays:Array=mesh.surface_get_arrays(surface)
			hashing.update(arrays[Mesh.ARRAY_VERTEX].to_byte_array())
			if arrays[Mesh.ARRAY_INDEX]!=null:hashing.update(arrays[Mesh.ARRAY_INDEX].to_byte_array())
		surfaces[name]=hashing.finish().hex_encode()
	return {"collision_shapes":rows,"geometry":surfaces}
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	# Baseline uses the archived Task 1 landscape code and unchanged regional assets.
	var before:Dictionary
	if FileAccess.file_exists(E+"baseline_candidate.gd"):
		scene=load(E+"baseline_candidate.gd").new();root.add_child(scene)
		while not scene.placement_ready:await physics_frame
		before=fingerprint(scene.landscape)
		var baseline_file:=FileAccess.open(E+"collision_baseline.json",FileAccess.WRITE)
		baseline_file.store_string(JSON.stringify(before,"  "));baseline_file.close()
		scene.queue_free();await process_frame;await physics_frame
	else:
		before=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/island/polish_task2/collision_baseline.json"))
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	var after:=fingerprint(scene.landscape)
	assert(before==after,"Every original tree/rock/terrain collision and ground/water mesh must remain exact")
	var vegetation:Node=scene.landscape.get_node("CandidateVegetation")
	assert(vegetation.find_children("*","CollisionObject3D",true,false).is_empty())
	assert(vegetation.tree_positions.size()>=65 and vegetation.tree_positions.size()<=85)
	for point in vegetation.grass_positions:
		assert(point.z<=53 and Vector2(point.x,point.z).length()<=91,"No grass on sandy shoreline")
		assert(absf(point.x-scene.landscape.SURFACE.river_center(point.z))>=scene.landscape.SURFACE.river_width(point.z)+1.6,"Keep river channel clear")
		assert(vegetation._clear(point,1.59),"Quest and pickup visibility clearings retained")
	for visual in vegetation.find_children("*","GeometryInstance3D",true,false):
		assert(visual.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var saved:Vector3=scene.player.position
	var sample:Dictionary=vegetation.patches[0]
	scene.player.position=sample.center;vegetation._update_density()
	assert(sample.levels[0].visible and not sample.levels[1].visible)
	scene.player.position=sample.center+Vector3.RIGHT*28;vegetation._update_density()
	assert(sample.levels[1].visible and sample.levels[1].multimesh.visible_instance_count<=sample.count and vegetation.density_at(28)<vegetation.density_at(0))
	scene.player.position=Vector3(4000,0,4000);vegetation._update_density()
	for patch in vegetation.patches:
		for visual in patch.levels:assert(not visual.visible,"Distant grass must be culled")
	scene.player.position=saved;vegetation._update_density()
	var triangle_counts:Dictionary={}
	for type in ["trunk","canopy","grass"]:
		var levels:=[]
		for level in range(3):
			var mesh:Mesh=load("res://assets/environment/new_island/vegetation/refinement/%s_lod%d.res"%[type,level])
			levels.append(mesh.get_faces().size()/3)
		triangle_counts[type]=levels
	var f:=FileAccess.open(E+"vegetation_verification.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"original_static_collisions_identical":true,"collision_shape_count":after.collision_shapes.size(),"approved_ground_water_grotto_geometry_identical":after.geometry,"tree_instances":vegetation.tree_positions.size(),"grass_clumps":vegetation.grass_positions.size(),"grass_chunks":vegetation.patches.size(),"no_new_vegetation_colliders":true,"quest_clearings_and_shoreline_clear":true,"distance_density_and_culling_passed":true,"lod_triangle_counts":triangle_counts},"  "))
	print("PASS: archived Task 1 collision fingerprints and terrain/river meshes identical; vegetation LOD/density, clearings and clean shoreline verified")
	scene.queue_free();await process_frame;quit()
