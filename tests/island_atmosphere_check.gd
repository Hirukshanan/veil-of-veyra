extends "res://tests/island_vegetation_check.gd"
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/island/polish_task2/collision_baseline.json"))
	var current:Dictionary=fingerprint(scene.landscape)
	assert(original==current and current.collision_shapes.size()==47)
	var atmosphere:Node3D=scene.get_node("IslandAtmosphere")
	assert(atmosphere.find_children("*","CollisionObject3D",true,false).is_empty())
	assert(atmosphere.landmark_positions.size()==2 and atmosphere.added_triangles<=200)
	for visual in atmosphere.find_children("*","MeshInstance3D",true,false):
		var arrays:Array=visual.mesh.surface_get_arrays(0)
		for normal in arrays[Mesh.ARRAY_NORMAL]:assert(normal.y>.75,"Every inlay surface must face upward for visible ground dressing")
		for p in visual.mesh.get_faces():
			var expected:Vector3=scene.landscape.ground_point(Vector3(p.x,0,p.z))
			assert(absf(p.y-expected.y-.018)<.003,"Inlaid landmarks must remain flush and walkable")
		assert(visual.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var environments:=0;var suns:=0
	for node in scene.get_children():
		if node is WorldEnvironment:
			environments+=1;assert(node.environment.fog_enabled and not node.environment.volumetric_fog_enabled and not node.environment.glow_enabled)
		if node is DirectionalLight3D:
			suns+=1;assert(node.directional_shadow_max_distance==26 and node.directional_shadow_mode==DirectionalLight3D.SHADOW_ORTHOGONAL)
	assert(environments==1 and suns==1)
	scene.shadows_enabled=false;scene._apply_settings()
	for node in scene.get_children():
		if node is DirectionalLight3D:assert(not node.shadow_enabled)
	scene.shadows_enabled=true;scene._apply_settings()
	for node in scene.get_children():
		if node is DirectionalLight3D:assert(node.shadow_enabled)
	var image:Image=load("res://assets/environment/new_island/task4/journey_mask.png").get_image()
	assert(image.get_width()==512 and image.get_height()==512)
	for y in range(376,512):
		for x in range(512):assert(image.get_pixel(x,y).r==0,"No new footpath paint on southern beach")
	var file:=FileAccess.open("res://.validation/island_polish_task4/atmosphere_check.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"original_47_collisions_and_approved_meshes_exact":true,"fingerprints":current.geometry,"new_colliders":0,"landmarks":2,"added_visual_triangles":atmosphere.added_triangles,"landmark_height_offset_m":.018,"one_sun_one_environment":true,"shadow_preference_preserved":true,"optional_shadow_range_m":26,"single_shadow_split":true,"no_volumetric_fog_or_glow":true,"new_paths_do_not_reach_southern_sand":true},"  "))
	print("PASS: Task 4 lighting budget, shadow preference, flush landmarks, shoreline path exclusion; original 47 collisions and protected meshes exact");quit()
