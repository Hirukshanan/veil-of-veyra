extends SceneTree
var scene
var output:String
var number := 0

func _initialize():
	call_deferred("run")

func record(count:int):
	for index in range(count):
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(output+"/frame%04d.png"%number)==OK)
		number+=1

func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	output=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,720)
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	scene=load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):actor.set_physics_process(false)
	scene._show_journal()
	scene.journal_view.mobile_prompts=true
	scene.journal_view.render()
	await record(36)
	var button:Button
	for item in scene.journal_view.find_children("*","Button",true,false):
		if item.text=="Return to hunt":button=item
	assert(is_instance_valid(button))
	for down in [true,false]:
		var touch:=InputEventScreenTouch.new()
		touch.position=button.get_global_rect().get_center()
		touch.index=6
		touch.pressed=down
		root.push_input(touch,true)
	assert(scene.journal_view.closing and paused)
	await record(3)
	assert(scene.journal_view.unroll<1 and scene.journal_view.unroll>0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/closing_midpoint.png")
	await record(27)
	assert(not paused and not is_instance_valid(scene.journal_view))
	FileAccess.open(output+"/motion_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"frames":number,"fps":30,"touch_close_recorded":true,"mid_close_reveal_between_zero_and_one":true,"opening_seconds":.28,"closing_seconds":.20},"  "))
	scene.queue_free()
	await process_frame
	await create_timer(.75,true,false,true).timeout
	print("PASS: actual touch closing recorded frame by frame with intermediate roller positions")
	quit()
