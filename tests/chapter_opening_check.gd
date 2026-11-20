extends SceneTree

const CANDIDATE := preload("res://scenes/island_candidate.tscn")
const JOURNAL := preload("res://scripts/candidate_journal.gd")
const STORE := preload("res://scripts/campaign_store.gd")
const OPENING := preload("res://scripts/chapter_opening.gd")
const GUARDIANS := preload("res://scripts/chapter_guardians.gd")

var _scene
var _hero
var _ticks := 0
var _clearance := INF
var _opening_ticks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	Engine.physics_ticks_per_second = 30
	root.size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	await _load_scene()
	_opening_ticks = _ticks
	assert(_hint().message == "Follow the ash to Tideseal Ruins.")
	assert(not paused and _hero.position.distance_to(Vector3(0, _hero.position.y, 27)) < 1.0)
	await _wait(20)
	assert(_scene.opening.has_beat(OPENING.BELL) and _scene.opening._bell.stream != null)
	assert(not paused and _hero.is_physics_processing())
	print("PASS: The warning starts at the existing beach with control active")
	for point in [Vector2(-4, 27), Vector2(-5.6, 34.4), Vector2(-12.2, 39.3), Vector2(-20.4, 43.2),
		Vector2(-28.9, 46.1), Vector2(-36.4, 48.8), Vector2(-40, 52), Vector2(-44, 54)]:
		assert(await _walk(point), "Reach the shore route waypoint " + str(point))
	assert(_scene.interact_button.accessibility_name == "Investigate broken seal")
	_key(KEY_E)
	assert(_scene.guardians.revealed() and _scene.seal_fragments.collected_ids.is_empty())
	assert(_hint().title == "DEFEAT THE DIRE WARG" and _hint().message == "Three cursed guardians hold the seal.")
	_key(KEY_E)
	assert(_scene.seal_fragments.collected_ids.is_empty())
	var bank := STORE.load_progress()
	assert(bank.error == OK and bank.data.world_data[GUARDIANS.SAVE_KEY].investigated)
	print("PASS: Walked the shore clue route, used E, and revealed the guardian objectives")
	var camp: Vector3 = _scene.opening._camp
	for point in [Vector2(-44, 48.5), Vector2(-44.4, 43.9), Vector2(-46.1, 37.7), Vector2(-49.4, 32.4),
			Vector2(camp.x, camp.z)]:
		assert(await _walk(point), "Reach the east-side camp bypass waypoint " + str(point))
	await process_frame
	assert(_hero.health == 100 and _scene.get_node("CampDemon4").health > 0)
	assert(_scene.interact_button.visible and _scene.interact_button.accessibility_name == "Inspect abandoned camp")
	_scene._pause_game()
	_key(KEY_E)
	assert(not _scene.opening.has_beat(OPENING.CAMP))
	_scene._resume()
	await process_frame
	_touch_interact(true)
	_touch_interact(false)
	assert(_scene.opening.has_beat(OPENING.CAMP) and _hint().message == OPENING.CAMP_FINDING)
	assert(_scene.interact_button.accessibility_name != "Inspect abandoned camp")
	var state: int = _scene.world_data[OPENING.SAVE_KEY]
	_key(KEY_E)
	assert(_scene.world_data[OPENING.SAVE_KEY] == state)
	_scene.set_tracked_quest("main")
	_scene._show_journal()
	assert(paused and _scene.journal_open and _journal_shows_finding())
	_scene._resume()
	print("PASS: Wolf bypass, ranged and paused interaction guards, real touch inspection, and journal discovery")
	for point in [Vector2(-49, 28.6), Vector2(-44.4, 27.9), Vector2(-40.9, 27.1), Vector2(-37, 27)]:
		assert(await _walk(point), "Reach the woodland junction waypoint " + str(point))
	assert(_scene.opening.has_beat(OPENING.JUNCTION) and _hint().message == OPENING.JUNCTION_LINE)
	assert("0/3" in _hint().progress and JOURNAL.entry(_scene, GUARDIANS.LANTERN).locked)
	assert(_scene.remaining_enemies == 5 and _scene.shards == 0 and not _scene.lantern_lit)
	assert(_clearance > 28.5, "Beginner route stays beyond the Fox encounter and its leash")
	print("RESULT bypass route %.2f simulated seconds; nearest Fox distance %.1f m" % [float(_ticks - _opening_ticks) / 30.0, _clearance])
	assert(_scene._save_progress())
	var saved := STORE.load_progress()
	assert(saved.error == OK and not saved.migrated)
	assert(saved.data.world_data.seal_fragments.is_empty() and saved.data.world_data[OPENING.SAVE_KEY] == 7)
	await _unload_scene()
	await _load_scene()
	await _wait(8)
	assert(_scene.opening.has_beat(OPENING.JUNCTION) and _scene.opening._bell.stream == null)
	assert(_hint().title == "DEFEAT THE DIRE WARG" and "0/3" in _hint().progress)
	assert(JOURNAL.entry(_scene, "main").finding == OPENING.CAMP_FINDING)
	assert(_scene.world_data[OPENING.SAVE_KEY] == 7 and _scene.seal_fragments.collected_ids.is_empty())
	print("PASS: Junction lead, missing fragments, no camp/reward changes, and durable v4 reload without repeat triggers")
	await _unload_scene()
	assert(STORE.save_progress(bank.data) == OK)
	await _load_scene()
	await _wolf_route()
	await _unload_scene()
	print("PASS: Chapter I opening played through its bypass and fight paths")
	quit()

func _load_scene() -> void:
	_scene = CANDIDATE.instantiate()
	root.add_child(_scene)
	while not _scene.placement_ready:
		await physics_frame
	_hero = _scene.player
	_scene.camp_menu.play_requested.emit()
	await process_frame

func _unload_scene() -> void:
	_scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.20, true, false, true).timeout

func _hint() -> Dictionary:
	return _scene.tracked_hint(_scene.CHAPTER_QUESTS.hud(_scene))

func _walk(point: Vector2, radius := .63) -> bool:
	for step in range(185):
		var offset := point - Vector2(_hero.position.x, _hero.position.z)
		if offset.length() <= radius:
			_hero.set_move_input(Vector2.ZERO)
			await _wait(2)
			return true
		_move(offset.normalized())
		var fox: Node3D = _scene.get_node_or_null("DemonFox")
		if fox:
			_clearance = minf(_clearance, Vector2(_hero.position.x - fox.position.x, _hero.position.z - fox.position.z).length())
		await _wait(1)
	_hero.set_move_input(Vector2.ZERO)
	print("RESULT blocked walking toward ", point, " from ", _hero.position)
	return false

func _wolf_route() -> void:
	assert(_scene.guardians.revealed() and _scene.seal_fragments.collected_ids.is_empty() and not _scene.opening.has_beat(OPENING.CAMP))
	var wolf = _scene.get_node("CampDemon4")
	for point in [Vector2(-46, 49), Vector2(-51.5, 42), Vector2(-56.9, 38), Vector2(-60.1, 35)]:
		assert(await _walk(point), "Reach the existing southwestern wolf's approach")
	var saw_attack: bool = _scene.opening.has_beat(OPENING.SWORD)
	var approach := Vector2(wolf.position.x, wolf.position.z) - Vector2(_hero.position.x, _hero.position.z)
	for tick in range(80):
		if wolf._windup > 0.0:
			break
		approach = Vector2(wolf.position.x, wolf.position.z) - Vector2(_hero.position.x, _hero.position.z)
		_move(approach.normalized() if approach.length() > 1.23 else Vector2.ZERO)
		await _wait(1)
		saw_attack = saw_attack or _scene.opening.has_beat(OPENING.SWORD)
	_hero.set_move_input(Vector2.ZERO)
	assert(saw_attack and wolf._windup > 0.0, "Expected actual alert and crouch")
	await _wait(1)
	assert("Dodge sideways" in _hint().message)
	while wolf._windup > .11:
		await _wait(1)
	var health: int = _hero.health
	_move(approach.orthogonal().normalized())
	_hero.dodge()
	_hero.set_move_input(Vector2.ZERO)
	for tick in range(8):
		if wolf._strike_time > 0.0:
			break
		await _wait(1)
	assert(wolf._strike_time > 0.0 and _hero.health == health)
	await _wait(1)
	assert(_hint().message == "Counter while it recovers." and _scene.opening.has_beat(OPENING.DODGE))
	await _wait(6)
	var target := Vector2(wolf.position.x, wolf.position.z)
	assert(await _walk(target, 1.55), "Reach sword range without crossing the wolf's body")
	var wolf_health: int = wolf.health
	_hero.attack()
	await _wait(7)
	assert(wolf.health < wolf_health and _scene.remaining_enemies == 5)
	print("PASS: Actual wolf alert, wind-up and lunge triggered cues. Hero dodge and recovery sword hit verified")

func _move(direction: Vector2) -> void:
	_hero.set_move_input(direction.rotated(_hero._camera_pivot.global_rotation.y))

func _wait(frames: int) -> void:
	for frame in range(frames):
		await physics_frame
		_ticks += 1

func _journal_shows_finding() -> bool:
	if not is_instance_valid(_scene.journal_view):
		return false
	for label in _scene.journal_view.find_children("*", "Label", true, false):
		if OPENING.CAMP_FINDING in label.text:
			return true
	return false

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event)

func _touch_interact(pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = _scene.interact_button.get_global_rect().get_center()
	event.pressed = pressed
	root.push_input(event)
