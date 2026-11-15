extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	for layer in scene.find_children("*","CanvasLayer",true,false):layer.hide()
	var camera:=Camera3D.new()
	camera.fov=56
	camera.near=.05
	scene.add_child(camera)
	camera.position=Vector3(13,7,103)
	camera.look_at(Vector3(23,-1.45,113))
	camera.make_current()
	for frame in range(12):await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])==OK)
	print("PASS: native fixed estuary inspection view; position ",camera.position," rotation ",camera.rotation)
	scene.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	quit()
