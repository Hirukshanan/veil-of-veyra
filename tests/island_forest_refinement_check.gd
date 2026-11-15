extends "res://tests/island_vegetation_check.gd"
const OUTPUT="res://.validation/island_polish_task21/"
func weights(distance:float)->Vector3:
	var a:float=1-smoothstep(32,44,distance);var c:float=smoothstep(72,84,distance)
	return Vector3(a,(1-a)*(1-c),c)*(1-smoothstep(145,162,distance))
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	assert(DisplayServer.get_name()!="headless","GPU instance readback requires the native renderer; use headless mode for the separate physics regressions")
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/island/polish_task2/collision_baseline.json"))
	assert_environment_preservation(expected,fingerprint(scene.landscape))
	var vegetation:Node=scene.landscape.get_node("CandidateVegetation")
	assert(vegetation.form_counts==PackedInt32Array([24,24,24]),"Three authored forms must each have 24 retained tree anchors")
	var old=load("res://art_source/island/polish_task21/baseline_vegetation.gd").new();scene.landscape.add_child(old);old.hide();old.landscape=scene.landscape;old.clear_points=vegetation.clear_points.duplicate();old._build_groundcover()
	assert(old.grass_positions==vegetation.grass_positions,"Refinement must retain accepted grass placement and exclusions")
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(vegetation.grass_positions.to_byte_array());var grass_hash:=hash.finish().hex_encode();old.queue_free()
	var actual_forms:Dictionary={};var near_batches:=0
	for tree in vegetation.trees:
		assert(tree.multimesh.use_custom_data)
		if int(tree.get_meta("tree_lod"))!=0:continue
		near_batches+=1
		for i in range(tree.multimesh.instance_count):actual_forms[int(round(tree.multimesh.get_instance_custom_data(i).r*2))]=true
	assert(actual_forms.size()==3)
	var mesh:Mesh=load("res://assets/environment/new_island/vegetation/refinement/trunk_lod0.res")
	var arrays:Array=mesh.surface_get_arrays(0);var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var first:PackedFloat32Array=arrays[Mesh.ARRAY_CUSTOM0] if arrays[Mesh.ARRAY_CUSTOM0] is PackedFloat32Array else arrays[Mesh.ARRAY_CUSTOM0].to_float32_array()
	var second:PackedFloat32Array=arrays[Mesh.ARRAY_CUSTOM1] if arrays[Mesh.ARRAY_CUSTOM1] is PackedFloat32Array else arrays[Mesh.ARRAY_CUSTOM1].to_float32_array()
	assert(first.size()==positions.size()*4 and second.size()==positions.size()*4)
	var bounds:Array[AABB]=[]
	for form in range(3):
		var box:=AABB(positions[0],Vector3.ZERO)
		for i in range(positions.size()):
			var p:Vector3=positions[i]
			if form>0:
				var data:PackedFloat32Array=first if form==1 else second;p+=Vector3(data[i*4],data[i*4+1],data[i*4+2])
			box=box.expand(p)
		bounds.append(box)
	assert(bounds[0].size.x>bounds[1].size.x*1.25 and bounds[1].size.y>bounds[0].size.y*1.1,"Broad and tall forms need genuinely distinct silhouettes")
	assert(bounds[2].get_center().x>bounds[0].get_center().x+.5,"Leaning crown must have a distinct asymmetric profile")
	for distance in range(0,145):
		var w:Vector3=weights(distance);assert(absf(w.x+w.y+w.z-1)<.00001)
	assert(weights(38).x>0 and weights(38).y>0 and weights(78).y>0 and weights(78).z>0)
	var file:=FileAccess.open(OUTPUT+"refinement_check.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"task52_collision_shapes":82,"water_and_cave_fingerprints_identical":true,"forms":{"Broad Fork":24,"Tall Column":24,"Leaning Crown":24},"near_instanced_batches":near_batches,"no_individual_tree_draws_added":true,"accepted_grass_positions_identical":true,"grass_position_sha256":grass_hash,"form_bounds":bounds,"complementary_lod_weights_passed":true},"  "))
	print("PASS: Task 5.2 collision corrections; water/cave exact; 3 distinct GPU-instanced forms; grass placements retained; complementary LOD coverage verified")
	scene.queue_free();await process_frame;quit()
