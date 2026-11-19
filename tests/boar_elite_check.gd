extends SceneTree

# Run against the actual island, hero controller and combat bodies at 30 physics ticks/s.
var scene
var boar
var hero
var output: String
var recording := false
var camera: Camera3D
var caption: Label
var results: Array[Dictionary] = []
var damage_states: Array[int] = []
var previous_health := 100
const STORE = preload("res://scripts/campaign_store.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	output = args[0]
	recording = args.has("--record")
	Engine.physics_ticks_per_second = 30
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	scene._resume()
	scene.shadows_enabled = false
	scene.frame_limit = 30
	scene._apply_settings()
	boar = scene.get_node("DemonBoar")
	hero = scene.player
	hero.health_changed.connect(_on_health)
	for actor in get_nodes_in_group("combat_enemies"):
		actor.set_physics_process(false)
	assert(boar.elite and is_equal_approx(boar.size_factor, 1.32))
	assert(boar.animator.has_animation("elite/tusk_sweep") and boar.animator.has_animation("elite/ground_stomp"))
	assert(scene.get_node("IslandAtmosphere/IslandLighting").night_weight == 0.0)
	if recording:
		_setup_camera()
		await _charge_dodge()
	await _melee(false, false)
	await _melee(false, true)
	await _melee(true, false)
	await _melee(true, true)
	await _stagger()
	if not recording:
		await _selection()
		await _pursuit()
		await _riverbank()
		await _death()
		await _reward_and_reload()
	var log_file := FileAccess.open(output.path_join("elite_combat.json"), FileAccess.WRITE)
	log_file.store_string(JSON.stringify({"passed": true, "physics_ticks_per_second": 30,
		"recording": recording, "checks": results}, "  "))
	log_file.close()
	scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.3, true, false, true).timeout
	print("PASS: elite Demon Boar hits, dodges, attack timing, and recovery in the real candidate")
	quit()

func _on_health(current: int, _maximum: int) -> void:
	if current < previous_health:
		damage_states.append(boar.state)
	previous_health = current

func _reset(distance: float, origin := Vector3(-36, 0, 12)) -> void:
	if paused:
		scene._resume()
	boar.set_physics_process(false)
	hero.set_physics_process(false)
	boar.position = scene.landscape.ground_point(origin) + Vector3.UP * .08
	boar.rotation = Vector3.ZERO
	boar.velocity = Vector3.ZERO
	boar._home = boar.position
	boar._attack_delay = 0.0
	boar._reposition_time = 0.0
	boar._sense_time = 0.0
	boar._close_time = 0.0
	boar._last_melee = boar.State.IDLE
	boar._enter(boar.State.IDLE)
	hero.position = scene.landscape.ground_point(origin + Vector3.FORWARD * distance) + Vector3.UP * .08
	hero.rotation.y = PI
	hero.velocity = Vector3.ZERO
	hero._charge_knockback = Vector3.ZERO
	hero._invulnerability_time = 0.0
	hero._dodge_time = 0.0
	hero.cancel_swing()
	hero._attack_cooldown = 0.0
	hero.health = 100
	hero.stamina = 100.0
	hero.spirit = 100.0
	hero.set_move_input(Vector2.ZERO)
	hero._camera_pivot.rotation = Vector3.ZERO
	hero._camera_pivot.global_position = hero.position + Vector3.UP * 1.2
	previous_health = hero.health
	damage_states.clear()
	if recording:
		camera.position = boar.position + Vector3(-4.0, 2.35, -4.8)
		camera.look_at(boar.position + Vector3(0, .85, -1.3))
		camera.make_current()
	await physics_frame
	await physics_frame
	boar.set_physics_process(true)

func _melee(stomp: bool, dodge: bool) -> void:
	await _reset(1.85)
	var name := "Ground Stomp" if stomp else "Tusk Sweep"
	_label("%s  ·  %s" % [name, "Dodge" if dodge else "Hit"])
	var prep: int = boar.State.STOMP_PREP if stomp else boar.State.SWEEP_PREP
	var active: int = boar.State.STOMP_ACTIVE if stomp else boar.State.SWEEP_ACTIVE
	var windup: float = boar.STOMP_WINDUP if stomp else boar.SWEEP_WINDUP
	var window: float = boar.STOMP_ACTIVE if stomp else boar.SWEEP_ACTIVE
	var recovery: float = boar.STOMP_RECOVERY if stomp else boar.SWEEP_RECOVERY
	if stomp:
		# Isolate the stomp geometry and timing. Unforced attack selection is tested separately.
		boar._enter(prep)
	else:
		assert(await _wait_for(prep, 32), "Boar chooses a sweep at close range")
	var committed: Transform3D = boar._warning.global_transform
	var prep_ticks := 0
	var dodged := false
	while boar.state == prep and prep_ticks < 40:
		assert(boar._warning.visible and hero.health == 100, "Preparation warns before causing damage")
		assert(boar._warning.global_transform.is_equal_approx(committed), "The visible footprint stays on the committed ground")
		if dodge and boar._elapsed >= windup - .23 and not dodged:
			_dodge(Vector2(0, -1))
			dodged = true
		await physics_frame
		prep_ticks += 1
	assert(boar.state == active)
	var strike_ticks := 0
	while boar.state == active and strike_ticks < 14:
		assert(boar._warning.visible, "The footprint still marks the active strike")
		await physics_frame
		strike_ticks += 1
	assert(boar.state == boar.State.MELEE_RECOVERY and not boar._warning.visible)
	var expected_damage := 0 if dodge else (16 if stomp else 12)
	assert(hero.health == 100 - expected_damage, "%s damage: got %d" % [name, 100 - hero.health])
	assert(damage_states.size() == (0 if dodge else 1))
	if not dodge:
		assert(damage_states[0] == active)
	assert(strike_ticks >= floori(window * 30) and strike_ticks <= ceili(window * 30) + 1)
	var recovery_ticks := 0
	while boar.state == boar.State.MELEE_RECOVERY and recovery_ticks < 45:
		await physics_frame
		recovery_ticks += 1
	assert(recovery_ticks >= floori(recovery * 30) - 1 and boar._attack_delay > .30)
	assert(hero.health == 100 - expected_damage, "Recovery cannot deal extra damage")
	results.append({"attack": name, "dodged": dodge, "damage": expected_damage, "prep_ticks": prep_ticks,
		"active_ticks": strike_ticks, "recovery_ticks": recovery_ticks})
	print("PASS: ", name, " damage=", expected_damage, " at 30 ticks/s")

func _charge_dodge() -> void:
	await _reset(4.25)
	_label("Charge  ·  Sidestep and punish")
	assert(await _wait_for(boar.State.WARNING, 60))
	while boar._elapsed < 1.40:
		await physics_frame
	_dodge(Vector2.RIGHT)
	assert(await _wait_for(boar.State.RECOVERY, 115))
	assert(hero.health == 100 and not boar._charge_damaged)
	for n in range(22):
		await physics_frame
	results.append({"attack": "Charge", "dodged": true, "damage": 0})

func _dodge(direction: Vector2) -> void:
	hero.set_physics_process(true)
	hero.set_move_input(direction)
	hero.dodge()
	hero.set_move_input(Vector2.ZERO)

func _stagger() -> void:
	await _reset(1.8)
	_label("Heavy counter  ·  Attack interrupted")
	hero.set_physics_process(true)
	boar._enter(boar.State.STOMP_PREP)
	var health: int = boar.health
	hero.heavy_attack()
	assert(await _wait_for(boar.State.HURT, 28), "The hero's actual heavy attack should interrupt the wind-up")
	assert(boar.health < health and not boar._warning.visible)
	assert(await _wait_for(boar.State.CHASE, 38), "Boar recovers from stagger")
	results.append({"heavy_counter_damage": health - boar.health, "interrupted": true, "recovered": true})

func _selection() -> void:
	await _reset(1.7)
	assert(await _wait_for(boar.State.SWEEP_PREP, 32))
	assert(await _wait_for(boar.State.STOMP_PREP, 125), "A player crowding the boar draws a different close attack")
	results.append({"natural_close_sequence": ["Tusk Sweep", "Ground Stomp"]})

func _pursuit() -> void:
	for distance in [5.25, 9.5, 11.0]:
		await _reset(distance)
		assert(await _wait_for(boar.State.WARNING, 115), "Boar must pursue and align within sensing distance")
		results.append({"starting_distance": distance, "result": "Pursuit reached charge preparation"})

func _death() -> void:
	await _reset(1.85)
	hero.health = 10
	previous_health = 10
	boar._enter(boar.State.STOMP_PREP)
	for frame in range(36):
		if hero.health == 0:
			break
		await physics_frame
	assert(hero.health == 0 and scene.game_finished, "A lethal stomp reaches the original defeat flow")
	results.append({"player_death": true, "damage_during_stomp": damage_states == [boar.State.STOMP_ACTIVE]})

func _riverbank() -> void:
	var z := 50.0
	var terrain: Resource = scene.landscape.SURFACE
	var x: float = terrain.river_center(z) - terrain.river_width(z) - 4.2
	await _reset(5.0, Vector3(x, 0, z))
	var start: Vector3 = boar.position
	assert(await _wait_for(boar.State.WARNING, 95), "Bank pursuit can set a clear charge")
	assert(await _wait_for(boar.State.CHARGE, 65))
	assert(await _wait_for(boar.State.RECOVERY, 65))
	assert(start.distance_to(boar.position) > 3.0 and boar.is_on_floor(), "Scaled boar traverses the uneven bank")
	assert(await _wait_for(boar.State.CHASE, 60), "Bank charge recovers into pursuit")
	results.append({"riverbank": "west bank at z=50", "distance_m": start.distance_to(boar.position), "grounded": true})

func _reward_and_reload() -> void:
	await _reset(2.0)
	var before: int = scene.shards
	var camps: int = scene.remaining_enemies
	boar.take_damage(boar.health)
	assert(boar.state == boar.State.DEAD and scene.shards == before + 20)
	assert(scene.world_data.boar_defeated and scene.remaining_enemies == camps)
	boar.take_damage(1)
	assert(scene.shards == before + 20)
	var saved: Dictionary = STORE.load_progress()
	assert(saved.error == OK and saved.data.world_data.boar_defeated)
	scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.25).timeout
	scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	assert(scene.get_node_or_null("DemonBoar") == null and scene.shards == before + 20 and scene.remaining_enemies == camps)
	results.append({"boar_death": true, "reward_shards": 20, "paid_once": true, "candidate_reload": true, "quest_camps": camps})

func _wait_for(state: int, ticks: int) -> bool:
	for n in range(ticks):
		if boar.state == state:
			return true
		await physics_frame
	return false

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 58.0
	scene.add_child(camera)
	var overlay := CanvasLayer.new()
	overlay.layer = 45
	root.add_child(overlay)
	caption = Label.new()
	caption.position = Vector2(25, 252)
	caption.add_theme_font_size_override("font_size", 23)
	caption.add_theme_color_override("font_shadow_color", Color(.04, .03, .02, .95))
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(caption)

func _label(text: String) -> void:
	if recording:
		caption.text = text
