extends "res://tests/island_vegetation_check.gd"

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/island/polish_task2/collision_baseline.json"))
	var current:Dictionary=fingerprint(scene.landscape)
	assert(original==current and current.collision_shapes.size()==47,"All 47 original colliders and approved terrain/water/grotto positions must remain identical")
	var polish:Node3D=scene.landscape.get_node("RockWaterPolish")
	assert(polish.find_children("*","CollisionObject3D",true,false).is_empty())
	assert(polish.material_regions==4 and polish.smoothed_surfaces==5)
	assert(polish.added_triangles<2000)
	var faces:PackedVector3Array=polish.get_node("FittedCaveRockMantle").mesh.get_faces()
	for i in range(0,faces.size(),3):
		var center:Vector3=(faces[i]+faces[i+1]+faces[i+2])/3.0
		assert(not(center.x>74 and center.x<78 and center.y<3.1),"Cave mantle must leave the established walking corridor clear")
	var water_faces:PackedVector3Array=polish.get_node("WaterfallImpactFoam").mesh.get_faces()
	for point in water_faces:
		assert(absf(point.y-scene.landscape.SURFACE.river_level(point.z)-.014)<.002,"Impact effect follows the immutable river water level")
	for label in ["rock_albedo","rock_normal"]:
		var texture:Texture2D=load("res://assets/environment/new_island/task3/"+label+".png")
		assert(texture.get_width()==1024 and texture.get_height()==1024)
	var file:=FileAccess.open("res://.validation/island_polish_task3/geometry_check.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"collision_shapes":47,"original_collision_fingerprints_identical":true,"approved_mesh_fingerprints":current.geometry,"new_colliders":0,"rock_material_surfaces":polish.material_regions,"normals_only_surface_passes":polish.smoothed_surfaces,"added_visual_triangles":polish.added_triangles,"cave_walking_corridor_visual_clear":true,"foam_matches_existing_river_level":true,"new_texture_dimensions":[1024,1024]},"  "))
	print("PASS: Task 3 geometry/material budget, fitted cave corridor, river-matched impact effect; all 47 collision fingerprints and approved meshes exact")
	scene.queue_free();await process_frame;quit()
