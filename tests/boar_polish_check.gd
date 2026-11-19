extends SceneTree

var _bursts: Dictionary = {}
var _boar
var _polish
var _camera: Camera3D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	Engine.physics_ticks_per_second = 30
	var island = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(island)
	while not island.placement_ready:
		await physics_frame
	island._resume()
	_boar = island.get_node("DemonBoar")
	for enemy in get_nodes_in_group("combat_enemies"):
		enemy.set_physics_process(false)
	var hero: CharacterBody3D = island.player
	hero.set_physics_process(false)
	var origin: Vector3 = island.landscape.ground_point(Vector3(-36, 0, 12))
	_boar.position = origin + Vector3.UP * .08
	_boar.rotation = Vector3.ZERO
	_boar._home = _boar.position
	hero.position = origin + Vector3.FORWARD * 14.0
	_camera = Camera3D.new()
	island.add_child(_camera)
	_camera.position = origin + Vector3(-2, 2, -4)
	_camera.make_current()
	var feedback: Node = _boar._feedback
	_polish = feedback.get_node("CombatPolish")
	_polish.effect_emitted.connect(_on_burst)
	_boar._enter(_boar.State.IDLE)
	_boar.set_physics_process(true)
	await _ticks(21)
	assert(_bursts.get(&"idle_breath", []) == [2])
	for state in [_boar.State.CHASE, _boar.State.WARNING, _boar.State.SWEEP_PREP, _boar.State.STOMP_PREP]:
		_boar.set_physics_process(false)
		_boar._enter(_boar.State.IDLE)
		_boar._enter(state)
		feedback.sync_pose(_boar._clip, 0.0, .17, false, true, true)
		await _ticks(16)
	assert(_bursts.get(&"snort", []) == [6, 6, 6, 6], "Alert and all three attack preparations snort")
	feedback.sync_pose("charge_warning", .64, 1.0 / 30.0, false, true, true)
	feedback.sync_pose("walk", .29, 1.0 / 30.0, true, true, true)
	_boar._enter(_boar.State.CHARGE)
	assert(_bursts.get(&"scrape", []) == [3])
	assert(_bursts.get(&"hoof", []) == [1])
	assert(_bursts.get(&"charge_kick", []) == [5])
	_boar._enter(_boar.State.STOMP_ACTIVE)
	assert(_bursts.get(&"stomp_ring", []) == [8])
	assert(not _bursts.has(&"confirmed_contact"), "A missed stomp has ground dust only")
	await _ticks(16)
	hero.position = island.landscape.ground_point(origin + Vector3.FORWARD * 2.15) + Vector3.UP * .08
	await _ticks(2)
	_boar._enter(_boar.State.STOMP_PREP)
	_boar._enter(_boar.State.STOMP_ACTIVE)
	assert(_bursts.get(&"stomp_ring", []) == [8, 8])
	assert(_bursts.get(&"confirmed_contact", []) == [3] and hero.health == 84)
	_boar.take_weapon_hit(1, false, hero.position)
	assert(not _bursts.has(&"heavy_reaction"))
	_boar.take_weapon_hit(4, true, hero.position)
	assert(_bursts.get(&"heavy_reaction", []) == [4])
	await _ticks(16)
	assert(_polish._active_count == 0 and not _polish.is_processing())
	for attempt in range(8):
		_polish.charge_kick()
	assert(_polish._active_count == _polish.MAX_PUFFS)
	_camera.position += Vector3.RIGHT * 40.0
	await process_frame
	await process_frame
	assert(_polish._active_count == 0 and _polish._batch.multimesh.visible_instance_count == 0)
	var burst_count: int = _bursts[&"charge_kick"].size()
	_polish.charge_kick()
	assert(_bursts[&"charge_kick"].size() == burst_count)
	island.queue_free()
	await process_frame
	await create_timer(.25, true, false, true).timeout
	print("PASS: idle and four snorts, synced scrape/hoof/launch/stomp, confirmed-only hits, heavy response, pool limit and distance culling")
	quit()

func _on_burst(kind: StringName, count: int) -> void:
	if not _bursts.has(kind):
		_bursts[kind] = []
	_bursts[kind].append(count)

func _ticks(count: int) -> void:
	for index in range(count):
		await physics_frame
