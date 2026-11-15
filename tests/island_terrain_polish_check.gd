extends SceneTree

const SURFACE=preload("res://assets/environment/new_island/terrain_surface.res")
var scene
var evidence:={}

func _initialize():call_deferred("run")

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	var patches:=0
	var patch_vertices:=0
	var max_patch_error:=0.0
	for region in scene.landscape.regions:
		for visual in region.find_children("*","MeshInstance3D",true,false):
			if not str(visual.name).contains("GradedTerrain"):continue
			patches+=1
			var arrays:Array=visual.mesh.surface_get_arrays(0)
			for vertex in arrays[Mesh.ARRAY_VERTEX]:
				var p:Vector3=visual.global_transform*vertex
				max_patch_error=maxf(max_patch_error,absf(p.y-SURFACE.sample(Vector2(p.x,p.z))))
				patch_vertices+=1
	assert(patches==4,"Four repaired regional patches must replace cut slab surfaces")
	assert(max_patch_error<.003,"Shared regional terrain must match its collision support field")
	var river:MeshInstance3D=scene.landscape.get_node("FlowingRiver")
	var water:Array=river.mesh.surface_get_arrays(0)
	var shore_vertices:=0
	var max_shore_error:=0.0
	var farthest_z:float=-INF
	var bank_left:=0
	var bank_right:=0
	for index in range(water[Mesh.ARRAY_VERTEX].size()):
		var p:Vector3=water[Mesh.ARRAY_VERTEX][index]
		farthest_z=maxf(farthest_z,p.z)
		if water[Mesh.ARRAY_COLOR][index].r<.99 or p.z>110:continue
		# Compare the actual collision triangles rather than the continuous analytic
		# profile: the latter differs slightly from a finite tessellated surface.
		var ray:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.06,p-Vector3.UP*.06,16)
		var hit:Dictionary=scene.get_world_3d().direct_space_state.intersect_ray(ray)
		assert(not hit.is_empty(),"A water edge needs real terrain beneath it")
		max_shore_error=maxf(max_shore_error,absf(p.y-hit.position.y))
		shore_vertices+=1
		if p.x<SURFACE.river_center(p.z):bank_left+=1
		else:bank_right+=1
	assert(shore_vertices>300 and bank_left>100 and bank_right>100,"Both riverbanks must meet real terrain")
	assert(max_shore_error<.008,"Water boundary must meet the carved channel, not terminate above it")
	assert(farthest_z>115 and SURFACE.river_level(farthest_z)<-1.45,"Outlet continues beneath preserved sea")
	var old_placements:Array=JSON.parse_string(FileAccess.get_file_as_string("res://.validation/island_polish_task1/placement_anchors.json"))
	var placement_error:=0.0
	for index in range(old_placements.size()):
		var previous:Vector3=str_to_var("Vector3"+old_placements[index].after)
		var current:Vector3=scene.placement_log[index].after
		placement_error=maxf(placement_error,previous.distance_to(current))
	assert(placement_error<.012,"Existing grounded enemy and quest placements must be preserved")
	# Real ray support along all four repaired joins, not only visual coincidence.
	var checks:=0
	var ray_error:=0.0
	for point in [Vector2(-27,10),Vector2(0,-35),Vector2(44,-16),Vector2(-5,34)]:
		for dz in range(-4,5):
			for dx in range(-4,5):
				var p:Vector2=point+Vector2(dx,dz)*.35
				var hit:Dictionary=scene.landscape.ground_hit(Vector3(p.x,0,p.y))
				assert(not hit.is_empty(),"Repaired connection cannot contain a collision hole")
				ray_error=maxf(ray_error,absf(hit.position.y-SURFACE.sample(p)))
				checks+=1
	assert(ray_error<.012,"Rendered shared terrain and real collision must agree on all four joins")
	evidence={"repaired_patches":patches,"patch_vertices_checked":patch_vertices,"max_patch_height_error_m":max_patch_error,"shore_vertices_checked":shore_vertices,"max_shore_height_error_m":max_shore_error,"outlet_end_z_m":farthest_z,"outlet_end_y_m":SURFACE.river_level(farthest_z),"sea_y_m":-1.45,"preserved_placement_count":old_placements.size(),"max_placement_change_m":placement_error,"seam_collision_samples":checks,"max_collision_support_error_m":ray_error,"ground_triangles":scene.landscape.ground_triangles,"river_triangles":water[Mesh.ARRAY_INDEX].size()/3}
	var file:=FileAccess.open("res://.validation/island_polish_task1/geometry_check.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"  "))
	print("PASS: four shared joins have real collision support; both refined banks meet channel; outlet extends below original sea; original gameplay placements retained")
	scene.queue_free()
	await process_frame
	quit()
