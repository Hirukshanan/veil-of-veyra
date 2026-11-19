extends SceneTree

var _game
var _lighting
var _sun: DirectionalLight3D
var _environment: Environment
var _sky: ProceduralSkyMaterial

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	_game = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(_game)
	while not _game.placement_ready:
		await physics_frame
	_game._resume()
	_game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):
		enemy.set_physics_process(false)
	var atmosphere: Node = _game.get_node("IslandAtmosphere")
	_lighting = atmosphere.get_node("IslandLighting")
	var suns: Array[Node] = _game.find_children("*", "DirectionalLight3D", false, false)
	var worlds: Array[Node] = _game.find_children("*", "WorldEnvironment", false, false)
	assert(suns.size() == 1 and worlds.size() == 1)
	_sun = suns[0]
	_environment = worlds[0].environment
	_sky = _environment.sky.sky_material
	var dusk := _settings()
	assert(is_equal_approx(_sun.light_energy, .76) and _lighting.night_weight == 0.0)
	assert(_environment.fog_enabled and not _environment.volumetric_fog_enabled and not _environment.glow_enabled)
	_game.shadows_enabled = false
	_game.frame_limit = 30
	_game._apply_settings()
	assert(not _sun.shadow_enabled and Engine.max_fps == 30)
	atmosphere.set_boss_night(true, .6)
	await _transition(true)
	assert(is_equal_approx(_sun.light_energy, .34) and _sky.sky_top_color.b > _sky.sky_top_color.r)
	assert(not _sun.shadow_enabled and Engine.max_fps == 30)
	atmosphere.set_boss_night(false, .6)
	await _transition(false)
	assert(_settings() == dusk, "Dusk is restored exactly")
	_game.player.position = Vector3(69, 3, 18)
	await process_frame
	await process_frame
	var cave := _settings()
	assert(is_equal_approx(_sun.light_energy, 1.12) and is_equal_approx(_environment.ambient_light_energy, .38))
	assert(_sun.rotation_degrees.is_equal_approx(Vector3(-39, -32, 0)) and _sky.sky_cover_modulate.a == 0.0)
	atmosphere.set_boss_night(true, 0)
	assert(_settings() == cave, "The cave uses the approved baseline under either exterior preset")
	_game.player.position = Vector3(0, 3, 20)
	await process_frame
	await process_frame
	assert(is_equal_approx(_sun.light_energy, .34))
	_game.shadows_enabled = true
	_game.frame_limit = 60
	_game._apply_settings()
	assert(_sun.shadow_enabled and Engine.max_fps == 60 and _sun.directional_shadow_max_distance == 26.0)
	atmosphere.set_boss_night(false, 0)
	assert(_settings() == dusk)
	print("PASS: start at dusk, blend both ways, restore exactly, protect cave, preserve graphics settings and reuse existing lights")
	_game.queue_free()
	await process_frame
	await create_timer(.3, true, false, true).timeout
	quit()

func _transition(darkening: bool) -> void:
	var previous: float = _lighting.night_weight
	var middle_samples := 0
	for index in range(80):
		await process_frame
		var weight: float = _lighting.night_weight
		assert(weight >= previous if darkening else weight <= previous)
		if weight > .01 and weight < .99:
			middle_samples += 1
		previous = weight
		if weight == (1.0 if darkening else 0.0):
			break
	assert(middle_samples >= 5 and previous == (1.0 if darkening else 0.0))

func _settings() -> Array:
	return [_sun.light_energy, _sun.rotation_degrees, _sun.light_color, _environment.ambient_light_energy,
		_environment.ambient_light_color, _environment.fog_light_color, _environment.fog_density,
		_sky.sky_top_color, _sky.sky_horizon_color, _sky.sky_cover_modulate]
