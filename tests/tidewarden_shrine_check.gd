extends SceneTree

const STORE := preload("res://scripts/campaign_store.gd")
const TIDEWARDEN := preload("res://scripts/tidewarden_shrine.gd")
const SCENE := "res://scenes/previews/chapter_one_tidewarden_playtest.tscn"
const INVESTIGATION := preload("res://scripts/grove_investigation.gd")
var game
var hero: CharacterBody3D
var tide

func _initialize() -> void:
	call_deferred("run")

func ticks(n: int) -> void:
	for i in n:
		await physics_frame

func open_game() -> void:
	assert(change_scene_to_file(SCENE) == OK)
	await scene_changed
	game = current_scene
	while not is_instance_valid(game.tidewarden) or not is_instance_valid(game.title_screen):
		await physics_frame
	game.continue_button.pressed.emit()
	hero = game.player
	tide = game.tidewarden
	await ticks(8)

func place(point: Vector3) -> void:
	hero.position = game.landscape.ground_point(point) + Vector3.UP*.08
	hero.velocity = Vector3.ZERO
	hero._camera_pivot.global_position = hero.position+Vector3.UP*1.2
	hero.reset_physics_interpolation()
	await ticks(12)

func walk_to(target: Vector3) -> bool:
	for tick in 500:
		var travel: Vector3 = target - hero.position
		travel.y = 0
		if travel.length() < .27:
			hero.set_move_input(Vector2.ZERO)
			return true
		var direction := travel.normalized().rotated(Vector3.UP,-hero._camera_pivot.global_rotation.y)
		hero.set_move_input(Vector2(direction.x,direction.z)*.87)
		await physics_frame
	hero.set_move_input(Vector2.ZERO)
	return false

func front(index: int) -> Vector3:
	return tide.pillars[index].to_global(Vector3(0,0,1.45))

func keyboard() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	root.push_input(event,true)

func mobile() -> void:
	var point: Vector2 = root.get_final_transform() * game.interact_button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func marker(id: String) -> Dictionary:
	for pin in game.guardian_map_markers():
		if pin.id == id:
			return pin
	return {}

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	root.size = Vector2i(854,480)
	Input.emulate_mouse_from_touch = true
	var data := STORE.DEFAULTS.duplicate(true)
	data.world_data = STORE.fresh_world()
	data.world_data.position = Vector3(-4,1.2,-32.55)
	data.world_data.guardian_quest = {"investigated":false,"regions":[],"fox_defeated":false}
	assert(STORE.save_progress(data) == OK)
	await open_game()
	assert(tide.mask() == 0 and marker(TIDEWARDEN.ID).is_empty() and TIDEWARDEN.ID not in game.guardian_journal_ids())
	assert(tide.pillars.size() == 3 and tide.use_index() == -1)
	assert(game.seal_fragments.get_node("Scenery").get_child_count() == 6)
	for index in tide.pillars.size():
		var pillar: Node3D = tide.pillars[index]
		var expected: Vector3 = game.landscape.ground_point(TIDEWARDEN.SITES[index])
		assert(pillar.global_position.is_equal_approx(expected))
		assert(pillar.find_children("*","StaticBody3D",true,false).size() == 1)
	# Start at the forest approach, then cross into the original Tideseal ring.
	await place(Vector3(-44.4,0,38.5))
	assert(await walk_to(Vector3(-46.2,0,47.7)))
	assert(tide.discovered() and tide.count() == 0 and marker(TIDEWARDEN.ID).point == TIDEWARDEN.CENTER)
	# The original broken-seal interaction still introduces the guardian hunt.
	await place(game.seal_fragments.get_node("Scenery").global_position)
	assert(game._can_investigate_seal() and tide.use_index() == -1)
	keyboard()
	assert(game.guardians.revealed())
	assert(await walk_to(front(2)))
	assert(tide.use_index() == 2 and game.interact_button.accessibility_name == "Inspect the Beacon socket")
	keyboard()
	assert(tide.count() == 0 and "Demon Boar" in tide.notice)
	# Existing combat death signals grant the corresponding fragment and normal payout.
	game.get_node("DemonBoar").take_damage(10000)
	assert(game.seal_fragments.collected_ids == [2] and game.shards == 28)
	await ticks(4)
	keyboard()
	assert(tide.seated(2) and tide.inserts[2].visible and tide.count() == 1 and game.shards == 28)
	var recorded: int = STORE.load_progress().data.world_data[STORE.TIDEWARDEN]
	assert(recorded == 12)
	keyboard()
	assert(tide.count() == 1 and game.shards == 28)
	game.set_tracked_quest(TIDEWARDEN.ID)
	var previous_location_save: Dictionary = STORE.load_progress().data
	previous_location_save.world_data.position = Vector3(-4,1.2,-32.55)
	assert(STORE.save_progress(previous_location_save) == OK)
	await open_game()
	assert(tide.count() == 1 and tide.seated(2) and tide.inserts[2].visible and game.tracked_quest == TIDEWARDEN.ID)
	assert(marker(TIDEWARDEN.ID).tracked and game.guardian_journal(TIDEWARDEN.ID).value == 1 and tide.use_index() == -1)

	game.get_node("CampDemon2").take_damage(10000)
	game.get_node("DemonFox").take_damage(10000)
	assert(game.seal_fragments.complete() and game.shards == 72)
	await place(game.lantern.position + Vector3.BACK)
	keyboard()
	assert(game.lantern_lit and game.shards == 84 and not game.boss_spawned)
	assert(not game._temple_unlocked() and tide.guides_main() and marker(TIDEWARDEN.ID).tracked)
	assert(game.tracked_hint({}).progress == "Seals restored 1/3")

	assert(tide.use_index() == -1 and not tide.nearby())
	await place(Vector3(-44.4,0,38.5))
	assert(await walk_to(Vector3(-46.2,0,47.7)))
	# Walk around the solid beacon on the eastern side of the court.
	assert(await walk_to(Vector3(-46.7,0,54.2)))
	assert(await walk_to(front(0)))
	keyboard()
	assert(tide.count() == 2 and tide.seated(0))
	assert(await walk_to(front(1)))
	assert(game.interact_button.accessibility_name == TIDEWARDEN.FACES[1] and tide.use_index() == 1)
	mobile()
	await ticks(8)
	assert(tide.complete() and tide.lighting.is_running(), "Touch must seat the final fragment")
	assert(tide.count() == 3 and game.seal_fragments.collected_ids.size() == 3 and game.shards == 84)
	assert(not game._temple_unlocked())
	assert(marker(TIDEWARDEN.ID).is_empty() and marker("main").badge == "?")
	assert(game.guardian_journal(TIDEWARDEN.ID).done)
	await ticks(345)
	assert(tide.beacon_light.emission_energy_multiplier >= 1.65)
	for groove in tide.grooves:
		assert(is_equal_approx(groove.emission_energy_multiplier,.9))
	assert(not tide.lighting.is_running())
	await open_game()
	assert(tide.complete() and tide.lighting == null)
	assert(game.seal_fragments.collected_ids.size() == 3 and game.shards == 84)

	# Walk the woodland approach from the east side of the court through the woodland.
	await place(Vector3(-45.5,0,53.8))
	for point in TIDEWARDEN.cave_trail().slice(1):
		assert(await walk_to(point), "Tidewarden trail blocked at %s; hero %s" % [point,hero.position])
	assert(hero.position.distance_to(game.grove.clues[0].global_position) < 4.5)

	# The cave is gated by the existing investigation, including with a lit beacon.
	for n in 3:
		var clue: Node3D = game.grove.clues[n]
		var target: Vector3 = clue.to_global(Vector3(0,0,1.0)) if n == 1 else clue.global_position
		await place(target)
		assert(game._can_investigate_grove())
		keyboard()
		assert(game.grove.stage() == n+1)
	assert(game._temple_unlocked() and marker("main").badge == "C" and not game.boss_spawned)
	assert(game.shards == 92)
	await open_game()
	assert(game.grove.stage() == 3 and tide.complete())
	assert(game._temple_unlocked() and not game.boss_spawned)
	print("PASS forest-side original pillar reuse, relocated marker, old site inactive, sockets and guardian IDs, keyboard, mobile, partial reload, beacon sequence, journal/map, preserved awards, walkable Grove trail and cave gate")
	game.queue_free()
	await ticks(10)
	quit()
