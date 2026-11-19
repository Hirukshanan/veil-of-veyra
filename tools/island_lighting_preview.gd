extends SceneTree

# Run as a separate Godot process with an isolated APPDATA profile and VEYRA_TEST=1.
# N toggles the two presets. The optional --auto argument records both directions.
var _game
var _atmosphere
var _camera: Camera3D
var _status: Label
var _night := false
var _toggle_held := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1", "Use an isolated test profile for the lighting preview")
	_game = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(_game)
	while not _game.placement_ready:
		await physics_frame
	_game._resume()
	_game.shadows_enabled = false
	_game._apply_settings()
	_game.player.set_physics_process(false)
	_game.player.set_process_input(false)
	for actor in get_nodes_in_group("combat_enemies"):
		actor.set_physics_process(false)
	for layer in _game.find_children("*", "CanvasLayer", true, false):
		layer.hide()
	_atmosphere = _game.get_node("IslandAtmosphere")
	var boar = _game.get_node("DemonBoar")
	var at: Vector3 = boar.position
	var hero: Vector3 = _game.landscape.ground_point(at + Vector3(0, 0, 4.2))
	_game.player.position = hero
	_game.player.rotation.y = .19
	boar.rotation.y = PI
	boar._enter(boar.State.WARNING)
	_camera = Camera3D.new()
	_camera.fov = 61.0
	_game.add_child(_camera)
	_camera.position = at + Vector3(3.3, 2.35, 7.0)
	_camera.look_at(at + Vector3(0, 1.1, 1.6))
	_camera.make_current()
	var layer := CanvasLayer.new()
	layer.layer = 45
	root.add_child(layer)
	_status = Label.new()
	_status.position = Vector2(26, 24)
	_status.add_theme_font_size_override("font_size", 24)
	_status.add_theme_color_override("font_shadow_color", Color(.02, .03, .05, .95))
	_status.add_theme_constant_override("shadow_offset_x", 2)
	_status.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(_status)
	var args := OS.get_cmdline_user_args()
	if args.has("--timing"):
		await _measure(args[0])
	elif args.has("--auto"):
		await _demonstrate()
	else:
		_status.text = "Exploration Dusk  ·  N to preview Boss Night"
		process_frame.connect(_poll)

func _poll() -> void:
	var pressed := Input.is_physical_key_pressed(KEY_N)
	if pressed and not _toggle_held:
		_night = not _night
		_set_night(_night)
	_toggle_held = pressed

func _set_night(enabled: bool) -> void:
	_atmosphere.set_boss_night(enabled)
	_status.text = "Boss Night" if enabled else "Exploration Dusk"

func _demonstrate() -> void:
	_status.text = "Exploration Dusk"
	await create_timer(1.4).timeout
	_set_night(true)
	await create_timer(4.7).timeout
	_set_night(false)
	await create_timer(4.7).timeout
	await _finish()
	print("PASS: captured the in-engine dusk to night to dusk preview")
	quit()

func _measure(output: String) -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_status.text = "Exploration Dusk"
	for frame in range(90):
		await RenderingServer.frame_post_draw
	var rows := {}
	rows["settled_dusk"] = await _sample(2.0)
	_set_night(true)
	rows["dusk_to_night"] = await _sample(3.5)
	_set_night(false)
	rows["night_to_dusk"] = await _sample(3.5)
	var file := FileAccess.open(output.path_join("timing.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "  "))
	file.close()
	await _finish()
	print("PASS: measured both transitions in a live rendered viewport")
	quit()

func _sample(seconds: float) -> Dictionary:
	var intervals: Array[float] = []
	var start := Time.get_ticks_usec()
	var before := start
	while before - start < seconds * 1000000.0:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		intervals.append((now - before) / 1000.0)
		before = now
	intervals.sort()
	return {"frames": intervals.size(), "median_ms": intervals[intervals.size() / 2],
		"p95_ms": intervals[floori((intervals.size() - 1) * .95)], "max_ms": intervals.back(),
		"over_50ms": intervals.filter(func(value: float) -> bool: return value > 50.0).size()}

func _finish() -> void:
	_game.queue_free()
	await process_frame
	await create_timer(.25, true, false, true).timeout
