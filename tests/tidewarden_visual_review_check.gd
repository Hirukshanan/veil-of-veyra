extends "res://tests/tidewarden_shrine_check.gd"

const VISUAL_SCENE := "res://scenes/previews/chapter_one_tidewarden_visual_review.tscn"

func open_game() -> void:
	assert(change_scene_to_file(VISUAL_SCENE) == OK)
	await scene_changed
	game = current_scene
	while not is_instance_valid(game.tidewarden) or not is_instance_valid(game.title_screen):
		await physics_frame
	game.continue_button.pressed.emit()
	hero = game.player
	tide = game.tidewarden
	await ticks(12)

func seed_journey() -> void:
	var data := STORE.DEFAULTS.duplicate(true)
	data.shards = 84
	data.world_data = STORE.fresh_world()
	data.world_data.merge({"lantern":true,"seal_fragments":[0,1,2],"position":Vector3(-44.4,2.5,40.5),
		"cleared":[2,5],"boar_defeated":true,"guardian_quest":{"investigated":true,"regions":[],"fox_defeated":true}},true)
	assert(STORE.save_progress(data) == OK)

func check_ground(ground_mesh: MeshInstance3D) -> void:
	var vertices: PackedVector3Array = ground_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for index in range(0,vertices.size(),19):
		var point := vertices[index]
		var supported: Vector3 = game.landscape.ground_point(point)
		assert(absf(supported.y - point.y) < .12, "Mesh lifted from the terrain at %s" % point)

func assert_layout() -> void:
	assert(tide.pillars.size() == 3 and game.seal_fragments.get_node("Scenery").get_child_count() == 0)
	assert(tide.has_node("InlaidBrokenSeal") == (not game.guardians.revealed()))
	var collar: MeshInstance3D = tide.get_node("FittedStoneCourt")
	for vertex: Vector3 in collar.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		assert(Vector2(vertex.x,vertex.z).distance_to(Vector2(TIDEWARDEN.CENTER.x,TIDEWARDEN.CENTER.z)) < 2.33, "Paving extends into the grass")
	assert(game.seal_fragments.find_children("*","Label3D",false,false).is_empty())
	for index in tide.pillars.size():
		var post: Node3D = tide.pillars[index]
		var expected: Vector3 = game.landscape.ground_point(TIDEWARDEN.SITES[index])
		assert(post.global_position.is_equal_approx(expected))
		assert(post.get_child_count() > 5)
	assert(marker(TIDEWARDEN.ID).point == TIDEWARDEN.CENTER if not tide.complete() else marker(TIDEWARDEN.ID).is_empty())

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	root.size = Vector2i(854,480)
	Input.emulate_mouse_from_touch = true
	seed_journey()
	await open_game()
	assert_layout()
	assert(tide.count() == 0)
	assert(await walk_to(Vector3(-43.45,0,47.4)))
	assert(await walk_to(Vector3(-46.2,0,47.7)))
	assert(await walk_to(front(2)))
	await ticks(3)
	assert(tide.use_index() == 2)
	keyboard()
	assert(tide.count() == 1 and tide.inserts[2].visible and not tide.inserts[1].visible)
	await open_game()
	assert(tide.count() == 1 and tide.inserts[2].visible and not tide.inserts[0].visible)

	assert(await walk_to(front(1)))
	keyboard()
	assert(tide.count() == 2)
	assert(await walk_to(front(0)))
	await ticks(5)
	assert(game.interact_button.accessibility_name == TIDEWARDEN.FACES[0])
	mobile()
	await ticks(360)
	assert(tide.complete() and tide.beacon_light.emission_energy_multiplier > 1.65)
	assert(not game._temple_unlocked())
	assert(game.shards == 84 and game.seal_fragments.collected_ids.size() == 3 and game.relic_hunt.collected_ids.is_empty())
	await open_game()
	assert_layout()
	assert(tide.complete() and tide.beacon_light.emission_energy_multiplier > 1.65)
	assert(not game._temple_unlocked())
	for n in 3:
		var clue: Node3D = game.grove.clues[n]
		await place(clue.to_global(Vector3(0,0,1)) if n == 1 else clue.global_position)
		assert(game._can_investigate_grove())
		keyboard()
	await ticks(240)
	assert(game.grove.routes[3].visible)
	assert(game._temple_unlocked() and marker("main").badge == "C")
	assert(game.relic_hunt.collected_ids.is_empty() and game.shards == 92)
	await open_game()
	assert(game.grove.stage() == 3 and game._temple_unlocked())
	print("PASS fixed shrine anchors, obsolete props, confined beacon footing, 0/1/2/3 restoration, touch, saves, Grove handoff and cave gate")
	game.queue_free()
	await ticks(12)
	quit()
