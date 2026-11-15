extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	for resolution in [Vector2i(800, 450), Vector2i(1280, 720), Vector2i(1920, 864)]:
		root.size = resolution
		for frame in range(5):
			await process_frame
		var buttons: Array[Button] = []
		for layer in scene.get_children():
			if layer is CanvasLayer and layer != scene.overlay:
				for button in layer.find_children("*", "Button", true, false):
					buttons.append(button)
		for button in buttons:
			assert(is_equal_approx(button.size.x, button.size.y), "HUD buttons must be circles: " + button.name)
			assert(button._has_point(button.size * 0.5))
			assert(not button._has_point(Vector2.ZERO), "Circle corners must not capture camera touches")
			for other in buttons:
				if other != button:
					assert(not button.get_global_rect().intersects(other.get_global_rect()), "HUD buttons must not overlap")
		var sprint = scene.find_child("SprintButton", true, false)
		assert(sprint.get_global_rect().get_center().x < resolution.x * 0.5)
	scene.find_child("QuestScrollButton", true, false).pressed.emit()
	assert(scene.journal_open and paused)
	scene._accept_scroll_quest()
	assert(scene.keeper.accepted and scene.journal_open)
	scene._complete_scroll_quest()
	assert(not scene.keeper.reported, "Incomplete quest must not be claimable")
	scene.queue_free()
	await process_frame
	paused = false
	print("PASS: circular bounds/hit areas, separate controls at three resolutions, movement-side sprint, scroll access and incomplete quest guard")
	quit()
