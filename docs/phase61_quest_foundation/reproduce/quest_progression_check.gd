extends SceneTree

const STORE = preload("res://scripts/campaign_store.gd")
const QUESTS = preload("res://scripts/chapter_one_quests.gd")
var scene
var evidence: Array = []

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

func reload_world():
	assert(scene._save_progress())
	scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.3, true, false, true).timeout
	await open_world()

func relic(id: int):
	for item in scene.relic_hunt.relics.duplicate():
		if int(item.get_meta("pickup_id")) == id:
			scene.player.position = item.global_position
			await physics_frame
			await physics_frame
			break
	scene._update_objective()
	assert(id in scene.relic_hunt.collected_ids)

func herb(id: int):
	for item in scene.herbs.plants.duplicate():
		if int(item.get_meta("pickup_id")) == id:
			scene.player.position = item.global_position
			scene._interact_world()
			break
	assert(id in scene.herbs.collected_ids)

func seal(id: int):
	for item in scene.seal_fragments.fragments.duplicate():
		if int(item.get_meta("pickup_id")) == id:
			scene.player.position = item.global_position
			scene._interact_world()
			break
	assert(id in scene.seal_fragments.collected_ids)

func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	await open_world()
	assert(scene.remaining_enemies == 5 and scene.keeper.remaining() == 2)
	assert(QUESTS.current(scene).title == "THE LANTERN'S SEAL")
	assert(not QUESTS.future_prerequisites(scene).chapter_victory)
	scene._show_journal()
	scene._accept_scroll_quest()
	scene._complete_scroll_quest()
	assert(scene.keeper.accepted and not scene.keeper.reported and scene.keeper.remaining() == 2)
	assert("ACTIVE" in scene._journal_text() and "Reward:" in scene._journal_text())
	scene._resume()
	scene.get_node("CampDemon2").take_damage(10000)
	assert(scene.keeper.remaining() == 2, "Unrelated camp kill must not fulfill western bounty")
	scene.get_node("CampDemon0").take_damage(10000)
	assert(scene.keeper.remaining() == 1)
	seal(0)
	var shards: int = scene.shards
	scene._interact_world()
	assert(scene.shards == shards and scene.seal_fragments.collected_ids.size() == 1)
	await reload_world()
	assert(scene.keeper.accepted and not scene.keeper.reported and scene.keeper.remaining() == 1)
	assert(scene.seal_fragments.collected_ids == [0] and scene.remaining_enemies == 3)
	evidence.append("New/partial game: western bounty tracks actual candidate wolves; independent kills and partial seal/save progress preserved")
	await relic(1)
	assert(scene.quest_feedback.title == "RELIC DISCOVERED")
	herb(0)
	assert(scene.potions == 4)
	for id in [8, 9, 10]:
		herb(id)
	assert(scene.world_data.grove_reward and scene.shards == 25 and scene.potions == 7)
	for repeat in range(3):
		scene._claim_optional_rewards()
	assert(scene.shards == 25)
	await reload_world()
	assert(1 in scene.relic_hunt.collected_ids and scene.shards == 25 and scene.potions == 7)
	assert(scene.world_data.grove_reward)
	evidence.append("Cave relic, ordinary herb and grove collected through existing systems; potion and one-time grove reward persist")
	scene.get_node("CampDemon1").take_damage(10000)
	scene._show_journal()
	scene._complete_scroll_quest()
	assert(scene.keeper.reported and scene.shards == 25, "Accepted bounty retains its existing post-victory payment")
	scene._resume()
	for id in [3, 4]:
		scene.get_node("CampDemon%d" % id).take_damage(10000)
	scene.player.position = scene.lantern.position
	scene._interact_lantern()
	assert(not scene.lantern_lit, "Cleared camps cannot skip missing fragments")
	seal(1)
	seal(2)
	assert(QUESTS.current(scene).title == "THE NORTHERN LANTERN")
	scene.player.position = scene.lantern.position
	scene._interact_lantern()
	assert(scene.boss_spawned and scene.lantern_lit and not scene.completed)
	assert(QUESTS.current(scene).title == "THE TIDEWRAITH")
	assert(not QUESTS.future_prerequisites(scene).chapter_victory)
	scene.get_node("Tidewraith Dragon").take_damage(10000)
	assert(scene.completed and scene.shards == 120)
	scene._resume()
	await relic(0)
	await relic(2)
	assert(scene.world_data.relic_reward and scene.world_data.bounty_reward and scene.shards == 140)
	for repeat in range(4):
		scene._claim_optional_rewards()
		scene._on_boss_defeated()
	assert(scene.shards == 140)
	assert(QUESTS.future_prerequisites(scene).values().all(func(value): return value))
	await reload_world()
	assert(scene.completed and scene.shards == 140 and scene.relic_hunt.collected == 3)
	assert(scene.world_data.relic_reward and scene.world_data.bounty_reward and scene.world_data.grove_reward)
	scene._claim_optional_rewards()
	assert(scene.shards == 140)
	evidence.append("Existing camps AND seal gate, lantern/boss flow, +80 victory/+15 bounty/+20 relic rewards and duplicate prevention survive reload")
	var config := ConfigFile.new()
	assert(config.load(STORE.PATH) == OK and config.get_value("campaign", "version") == 4)
	assert(not scene.world_data.has("quest_states"), "Existing saved objective fields remain canonical")
	var output: String = OS.get_cmdline_user_args()[0]
	FileAccess.open(output + "/quest_progression_results.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "cases": evidence, "final_shards": scene.shards, "save_schema": 4, "future_story_prerequisites_derived_only": true}, "  "))
	scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.75, true, false, true).timeout
	print("PASS: candidate Chapter I quest dependencies, actual collections, partial/reloaded progress and one-time existing rewards")
	quit()
