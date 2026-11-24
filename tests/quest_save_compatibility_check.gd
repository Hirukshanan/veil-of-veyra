extends SceneTree
const STORE = preload("res://scripts/campaign_store.gd")
var scene

func _initialize():
	call_deferred("run")

func open_world():
	scene = load("res://scenes/island_candidate.tscn").instantiate()
	root.add_child(scene)
	while not scene.placement_ready:
		await physics_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for actor in get_nodes_in_group("combat_enemies"):
		actor.set_physics_process(false)

func close_world():
	scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.3,true,false,true).timeout

func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	# Synthetic pre-Phase-6.1 v4 save: even the old prematurely reported bounty
	# is honored, without deleting items, changing equipment or revoking credit.
	var data := STORE.DEFAULTS.duplicate(true)
	data.shards = 73
	data.blade_level = 2
	data.armor_level = 3
	data.world_data = STORE.fresh_world()
	data.world_data.merge({"cleared":[0,5], "herbs":[0,8], "relics":[1], "seal_fragments":[0], "accepted":true, "reported":true, "position":Vector3(76,1.58,5), "health":137, "potions":6, "discovered":[true,true,false], "checkpoint":1},true)
	assert(STORE.save_progress(data) == OK)
	await open_world()
	assert(scene.shards == 73 and scene.blade_level == 2 and scene.armor_level == 3)
	assert(scene.player.health == 137 and scene.potions == 6)
	assert(scene.keeper.accepted and scene.keeper.reported and scene.keeper.remaining() == 1)
	assert(not scene.world_data.has("relics") and scene.seal_fragments.collected_ids == [0])
	assert(scene.player.position.distance_to(Vector3(76,1.58,5)) < .1)
	assert(scene._save_progress())
	assert(STORE.load_progress().data.world_data.reported)
	assert(not scene.world_data.bounty_reward)
	await close_world()
	# Legacy collected relics are ignored. The reported bounty still pays once.
	data.world_data.cleared = [0,1,2,3,4,5]
	data.world_data.seal_fragments = [0,1,2]
	data.world_data.relics = [0,1,2]
	assert(STORE.save_progress(data) == OK)
	await open_world()
	assert(scene.shards == 73)
	assert(not scene.world_data.has("relics"))
	scene.player.position = scene.lantern.position
	scene._interact_lantern()
	assert(scene.lantern_lit and not scene.completed and not scene.boss_spawned)
	assert(scene.shards == 73 and not scene.world_data.bounty_reward)
	# Reopen a historical save that had already earned the original victory.
	var historical: Dictionary = STORE.load_progress().data
	historical.completed = true
	historical.shards += 80
	await close_world()
	assert(STORE.save_progress(historical) == OK)
	await open_world()
	assert(scene.completed and scene.lantern_lit and not scene.boss_spawned,
		"Historical victory and lantern must load without a Dragon encounter: %s" % str([scene.completed, scene.lantern_lit, scene.boss_spawned]))
	scene._claim_optional_rewards()
	assert(scene.completed and scene.shards == 168)
	assert(scene.world_data.bounty_reward)
	scene._claim_optional_rewards()
	assert(scene.shards == 168 and scene._save_progress())
	await close_world()
	await open_world()
	assert(scene.completed and scene.shards == 168)
	assert(scene.blade_level == 2 and scene.armor_level == 3 and scene.potions == 6)
	scene._claim_optional_rewards()
	assert(scene.shards == 168)
	var output: String = OS.get_cmdline_user_args()[0]
	FileAccess.open(output+"/quest_save_compatibility_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"synthetic_pre_phase61_version4":true,"reported_bounty_honored":true,"items_equipment_health_potions_cave_position_preserved":true,"removed_relic_state_ignored":true,"final_shards":168,"reload_no_duplicate_payment":true},"  "))
	await close_world()
	await create_timer(.75,true,false,true).timeout
	print("PASS: pre-Phase-6.1 saves, existing bounty credit, inventory, equipment and deferred rewards preserved")
	quit()
