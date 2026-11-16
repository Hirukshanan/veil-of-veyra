extends SceneTree
var scene
var output: String

func _initialize():
	call_deferred("run")

func shot(name: String):
	for frame in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output + "/" + name + ".png") == OK)
	print("CAPTURE ", name)

func scroll_to_heading(heading: String):
	for frame in range(3):
		await process_frame
	for child in scene.menu_box.get_children():
		if child is Label and heading in child.text:
			var measure := Label.new()
			measure.autowrap_mode = child.autowrap_mode
			measure.add_theme_font_override("font",child.get_theme_font("font"))
			measure.add_theme_font_size_override("font_size",child.get_theme_font_size("font_size"))
			measure.add_theme_constant_override("line_spacing",child.get_theme_constant("line_spacing"))
			measure.text = child.text.substr(0, child.text.find(heading))
			measure.size.x = child.size.x
			measure.hide()
			root.add_child(measure)
			for frame in range(3):
				await process_frame
			scene.menu_scroll.scroll_vertical = int(child.position.y + measure.get_minimum_size().y - 60)
			measure.queue_free()
			return

func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = Vector2i(1600,720)
	scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	scene._resume()
	scene.shadows_enabled = false
	scene._apply_settings()
	scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):
		actor.set_physics_process(false)
	scene.player.position = scene.landscape.ground_point(Vector3(-30,0,20)) + Vector3.UP * .08
	scene.player._camera_pivot.position = scene.player.position + Vector3.UP * 1.2
	scene.player._camera_pivot.rotation = Vector3(-.1,.3,0)
	scene._update_objective()
	await shot("01_new_game_hud")
	scene._show_journal()
	await shot("02_new_game_scroll")
	scene._accept_scroll_quest()
	await shot("03_accepted_bounty_scroll")
	await scroll_to_heading("KEEPER'S RELICS")
	await shot("04_optional_rewards_scroll")
	await scroll_to_heading("BEYOND THE LANTERN")
	await shot("05_future_story_scroll")
	scene._resume()
	var fragment = scene.seal_fragments.fragments[0]
	scene.player.position = fragment.global_position
	scene.player._camera_pivot.position = scene.player.position + Vector3.UP * 1.2
	scene._interact_world()
	await shot("06_fragment_feedback_gameplay")
	scene.player.position = Vector3(76,1.58,5)
	scene.player._camera_pivot.position = scene.player.position + Vector3.UP * 1.2
	scene.player._camera_pivot.rotation = Vector3(-.12, PI, 0)
	for frame in range(3):
		await physics_frame
	scene._update_objective()
	await shot("07_cave_relic_feedback_gameplay")
	scene._show_journal()
	await shot("08_partial_progress_scroll")
	scene._resume()
	# Controlled progress fixtures exercise existing award logic, never change balance.
	for id in [8,9,10]:
		for herb in scene.herbs.plants.duplicate():
			if int(herb.get_meta("pickup_id")) == id:
				scene.player.position = herb.global_position
				scene._interact_world()
	scene.player._camera_pivot.position = scene.player.position + Vector3.UP * 1.2
	scene._update_objective()
	await shot("09_grove_reward_gameplay")
	scene.seal_fragments.restore([0,1,2])
	for id in range(5):
		var actor = scene.get_node_or_null("CampDemon%d" % id)
		if actor != null:
			actor.take_damage(10000)
	scene._show_journal()
	scene._complete_scroll_quest()
	await shot("10_lantern_ready_scroll")
	await scroll_to_heading("WESTERN WATCH")
	await shot("11_bounty_secured_scroll")
	var file := FileAccess.open(output + "/capture_context.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"actual_Godot": true, "platform": "Windows", "resolution": [1600,720], "3D_height": 720, "enemy_physics_held": true, "collection_screens_use_existing_interactions": true, "last_two_views_use_controlled_completion_fixture": true, "screens_are_not_Android_performance_evidence": true}, "  "))
	file.close()
	scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.75,true,false,true).timeout
	quit()
