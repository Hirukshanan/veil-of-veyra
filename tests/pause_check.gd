extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event)
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = false
	root.push_input(event)

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	_escape()
	assert(paused and not scene.started, "Escape must not bypass camp")
	scene._resume()
	var joystick = get_first_node_in_group("movement_joysticks")
	joystick._touch_index = 2
	joystick._set_value(Vector2.UP)
	_escape()
	assert(paused and scene.pause_menu_open)
	assert(joystick._touch_index == -1 and joystick._value == Vector2.ZERO)
	assert(scene.player._touch_move == Vector2.ZERO)
	var position: Vector3 = scene.player.position
	var hp := int(scene.player.health)
	await create_timer(0.2).timeout
	assert(scene.player.position == position and scene.player.health == hp)
	_escape()
	assert(not paused)
	scene.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(paused and scene.pause_menu_open)
	scene.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert(paused, "Returning focus must not silently resume combat")
	scene._show_settings(scene._pause_game)
	_escape()
	assert(paused and not scene.pause_menu_open, "Escape must not bypass settings save/discard")
	scene._pause_game()
	_escape()
	assert(not paused)
	scene.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert(paused)
	print("PASS: Escape pause/resume, focus/background pause, frozen combat, joystick reset, menu guards")
	scene.queue_free()
	await process_frame
	paused = false
	quit()
