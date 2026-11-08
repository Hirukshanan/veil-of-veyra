extends SceneTree
func _initialize():
	call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	paused=false
	await physics_frame
	assert(scene.player.collision_mask & 8)
	var blockers=0
	for node in scene.find_children("*","StaticBody3D",true,false):
		if node.collision_layer & 8:
			blockers+=1
			assert(node.collision_layer & 4)
	assert(blockers>=36,"Trees and rocks must physically block the player")
	var space=scene.get_world_3d().direct_space_state
	var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(34,5,0),Vector3(34,-3,0),8))
	assert(not hit.is_empty(),"Rock collider must exist at the visible rock")
	scene.queue_free()
	await process_frame
	print("PASS: player collision mask, tree/rock blockers and physical rock ray")
	quit()
