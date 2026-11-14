extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in range(5):
		await process_frame

func _inside(control: Control, bounds: Rect2) -> void:
	assert(bounds.grow(1.0).encloses(control.get_global_rect()), "Control outside viewport: " + control.name)

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await _settle()
	for resolution in [Vector2i(800, 450), Vector2i(1280, 720), Vector2i(1920, 864)]:
		root.size = resolution
		await _settle()
		var bounds := Rect2(Vector2(44, 12), Vector2(resolution) - Vector2(68, 36))
		for control in scene.find_children("*", "Control", true, false):
			if control.get_script() == load("res://scripts/safe_area.gd"):
				control.test_safe_rect = bounds
				control.refresh()
		await _settle()
		for menu in [scene._show_camp, scene._show_keeper_request, scene._show_enemy_guide, scene._show_burst_guide, func(): scene._show_settings(scene._show_camp)]:
			menu.call()
			await _settle()
			_inside(scene.menu_scroll, bounds)
			assert(scene.menu_box.size.x <= scene.menu_scroll.size.x)
			var last: Control = scene.menu_box.get_child(scene.menu_box.get_child_count() - 1)
			scene.menu_scroll.ensure_control_visible(last)
			await _settle()
			assert(scene.menu_scroll.get_global_rect().grow(1.0).encloses(last.get_global_rect()), "Last menu button must be reachable by scrolling")
		scene._resume()
		await _settle()
		var joystick: Control = get_first_node_in_group("movement_joysticks")
		_inside(joystick, bounds)
		assert(joystick.get_global_rect().end.y >= bounds.end.y-50 and joystick.get_global_rect().end.y <= bounds.end.y-30, "Movement margin must survive safe-area scaling")
		# Include the lantern button even though it normally appears after the wave.
		scene.interact_button.show()
		for layer in scene.get_children():
			if layer is CanvasLayer and layer != scene.overlay:
				for control in layer.find_children("*", "Button", true, false):
					_inside(control, bounds)
					assert(not joystick.get_global_rect().intersects(control.get_global_rect()), "Movement and action controls must not overlap")
		scene._pause_game()
	var safe_script = load("res://scripts/safe_area.gd")
	var viewport_rect := Rect2(0, 0, 1280, 720)
	var transform := Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2(100, 40))
	assert(safe_script.logical_rect(Rect2(180, 60, 2400, 1360), transform, viewport_rect) == Rect2(40, 10, 1200, 680))
	assert(safe_script.logical_rect(Rect2(), transform, viewport_rect) == viewport_rect)
	assert(safe_script.logical_rect(Rect2(-100, -100, 5000, 5000), transform, viewport_rect) == viewport_rect)
	assert(safe_script.logical_rect(Rect2(9999, 9999, 1, 1), transform, viewport_rect) == viewport_rect)
	print("PASS: simulated cutout/gesture insets, scaled pixel conversion, invalid rect fallback, HUD bounds, action separation and menu scrolling")
	scene.queue_free()
	await process_frame
	paused = false
	quit()

