extends "res://tests/tidewarden_visual_review_check.gd"

const REVIEW := "res://scenes/previews/chapter_one_bear_spoor_review.tscn"
const SHRINE := preload("res://scripts/previews/spoor_shrine.gd")
const BANK := preload("res://scripts/previews/spoor_grove.gd")

func open_game() -> void:
	assert(change_scene_to_file(REVIEW)==OK)
	await scene_changed
	game=current_scene
	while not is_instance_valid(game.tidewarden) or not is_instance_valid(game.title_screen):
		await physics_frame
	game.continue_button.pressed.emit()
	hero=game.player
	tide=game.tidewarden
	await ticks(12)

func check_clean_ground() -> void:
	assert_layout()
	# All remaining direct ground meshes in this shrine are the footing and the two print groups.
	for child in tide.get_children():
		if child is MeshInstance3D:
			assert(child in [tide.grove_tracks,tide.eastern_tracks,tide.get_node("FittedStoneCourt")],str(child.name))
	assert(not game.opening.has_node("OpeningClues/BeachAshApproach"))
	assert(tide.find_children("*","CollisionObject3D",true,false).size() == 6, "Three pillars, two beacon shapes on separate bodies and the tree")

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST")=="1")
	root.size=Vector2i(854,480)
	Input.emulate_mouse_from_touch=true
	var fresh := STORE.DEFAULTS.duplicate(true)
	fresh.world_data = STORE.fresh_world()
	assert(STORE.save_progress(fresh)==OK)
	await open_game()
	assert(tide.has_node("InlaidBrokenSeal") and game.opening.has_node("OpeningClues/BeachAshApproach"))
	await place(game.seal_fragments.get_node("Scenery").global_position)
	keyboard()
	await ticks(3)
	assert(game.guardians.revealed() and not tide.has_node("InlaidBrokenSeal"))
	check_clean_ground()
	seed_journey()
	var data: Dictionary = STORE.load_progress().data
	data.world_data.lantern=false
	assert(STORE.save_progress(data)==OK)
	await open_game()
	assert(not game.has_node("ChapterLantern") and not game.grove.has_node("SplitSealstone"))
	assert(not game.get_node("IslandExploration").has_node("Waystone2") and game.grove.routes.is_empty())
	assert(not tide.grove_tracks.visible and not tide.eastern_tracks.visible and not tide.read_claws())
	await place(Vector3(0,0,-20))
	keyboard()
	assert(not game.lantern_lit)
	await place(TIDEWARDEN.CENTER+Vector3(1.74,0,0))
	keyboard()
	check_clean_ground()
	assert(game.lantern_lit and game.shards==96 and not game._temple_unlocked())
	await place(SHRINE.TREE+Vector3(0,0,3))
	keyboard()
	assert(not tide.tree_in_reach() and not tide.read_claws())
	for index in [2,1,0]:
		await place(front(index))
		if index==0:
			mobile()
		else:
			keyboard()
		await ticks(13)
		assert(tide.seated(index))
		if index==2:
			await open_game()
			assert(tide.count()==1 and not tide.grove_tracks.visible)
	await ticks(350)
	assert(tide.complete() and tide.grove_tracks.visible)
	check_clean_ground()
	check_ground(tide.grove_tracks)
	assert(marker("main").point == SHRINE.TREE)
	await place(Vector3(-45.5,0,53.8))
	for point in SHRINE.spoor_route().slice(1):
		assert(await walk_to(point),"Blocked spoor route %s at %s"%[point,hero.position])
	assert(tide.tree_in_reach() and game.interact_button.accessibility_name==SHRINE.PROMPT)
	assert(game._save_progress())
	var unread := STORE.load_progress().data as Dictionary
	keyboard()
	assert(tide.read_claws() and not tide.tree_in_reach() and game.grove.stage()==0 and game.shards==96)
	assert(SHRINE.FINDING in game.guardian_journal("main").description and marker("main").point!=SHRINE.TREE)
	await open_game()
	assert(tide.read_claws() and not game._temple_unlocked())
	check_clean_ground()
	assert(STORE.save_progress(unread)==OK)
	await open_game()
	await ticks(12)
	assert(tide.tree_in_reach())
	mobile()
	await ticks(8)
	assert(tide.read_claws() and not game._temple_unlocked())
	for point in [Vector3(17,0,-26),Vector3(13,0,-31),Vector3(9,0,-36)]:
		assert(await walk_to(point),"Blocked Grove approach at %s"%point)
	for i in 3:
		var clue: Node3D=game.grove.clues[i]
		await place(clue.to_global(Vector3(0,0,.97)) if i==1 else clue.global_position)
		assert(game._can_investigate_grove())
		keyboard()
		assert(game.grove.stage()==i+1)
	await open_game()
	assert(game._temple_unlocked() and tide.read_claws() and game.shards==104)
	assert(marker("main").badge=="C" and tide.eastern_tracks.visible and game.relic_hunt.collected_ids.is_empty())
	await place(Vector3(-6,0,-29))
	assert(game.relic_hunt.collected_ids.is_empty())
	await place(Vector3(2,0,-44))
	assert(game.relic_hunt.collected_ids == [2])
	assert(game._save_progress())
	await open_game()
	assert(game.relic_hunt.collected_ids == [2] and not game.relic_hunt.has_node("KeeperRelic3"))
	print("PASS physical spoor route, grounded prints, sealed and restored states, keyboard and touch inspections, reload, legacy Lantern reward, Grove and cave gate")
	game.queue_free()
	await ticks(12)
	assert(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)==0)
	print("PASS grounded relic ID and reload, zero orphan nodes on teardown")
	quit()
