extends SceneTree

const STORE = preload("res://scripts/campaign_store.gd")
const QUESTS = preload("res://scripts/chapter_one_quests.gd")
const JOURNAL := preload("res://scripts/candidate_journal.gd")
const GUARDIANS := preload("res://scripts/chapter_guardians.gd")
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

func marker(id: String) -> Dictionary:
	for item in scene.guardian_map_markers():
		if item.id == id:
			return item
	return {}

func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	await open_world()
	assert(scene.remaining_enemies == 5 and scene.keeper.remaining() == 2)
	assert(scene.guardian_journal_ids().is_empty() and scene.guardian_map_markers().is_empty())
	assert(scene.seal_fragments.collected_ids.is_empty() and scene.seal_fragments.fragments.is_empty())
	assert(not QUESTS.future_prerequisites(scene).chapter_victory)
	scene._show_journal()
	scene._accept_scroll_quest()
	scene._complete_scroll_quest()
	assert(scene.keeper.accepted and not scene.keeper.reported and scene.keeper.remaining() == 2)
	assert("ACTIVE" in scene._journal_text() and "Reward:" in scene._journal_text())
	scene._resume()
	scene.player.position = scene.seal_fragments.get_node("Scenery").global_position
	scene._update_objective()
	assert(scene.interact_button.accessibility_name == "Investigate broken seal")
	scene.interact_button.pressed.emit()
	var overview := JOURNAL.entry(scene, "main")
	assert(overview.title == GUARDIANS.TITLE and overview.description == GUARDIANS.DESCRIPTION)
	assert(scene.guardian_journal_ids().size() == 4 and scene.guardian_map_markers().size() == 3)
	var badges := []
	for guardian in GUARDIANS.GUARDIANS:
		var entry := JOURNAL.entry(scene, guardian.id)
		var pin := marker(guardian.id)
		assert(guardian.region in entry.description and entry.value == 0 and entry.total == 1)
		assert(pin.radius > 0.0 and pin.point == guardian.center and pin.badge not in badges)
		badges.append(pin.badge)
	assert(JOURNAL.entry(scene, GUARDIANS.LANTERN).locked)
	scene.set_tracked_quest(GUARDIANS.LANTERN)
	assert(scene.tracked_quest == "guardian_warg")
	scene._show_journal()
	scene.journal_view.choose("Main", "guardian_fox")
	scene.journal_view.track()
	assert(scene.tracked_quest == "guardian_fox" and marker("guardian_fox").tracked and not marker("guardian_warg").tracked)
	scene._resume()
	var hint: Dictionary = scene.guardians.hud(scene.tracked_quest)
	assert(hint.title == "DEFEAT THE DEMON FOX" and "Western Forest" in hint.message and "0/1" in hint.progress)
	var fox = scene.get_node("DemonFox")
	assert(scene.hide_enemy_map_dot(fox) and marker("guardian_fox").point != fox.global_position)
	scene.player.position = scene.landscape.ground_point(GUARDIANS.GUARDIANS[1].center)
	for frame in range(20):
		await physics_frame
	assert(marker("guardian_fox").radius == 0.0 and marker("guardian_fox").point == fox.global_position)
	fox.take_damage(10000)
	assert(scene.seal_fragments.collected_ids == [1] and marker("guardian_fox").is_empty())
	assert(scene.tracked_quest == "guardian_warg" and scene.keeper.remaining() == 2)
	assert(JOURNAL.entry(scene, "guardian_fox").done)
	fox.take_damage(10000)
	assert(scene.seal_fragments.collected_ids == [1])
	scene._show_journal()
	scene.journal_view.choose("Completed", "guardian_fox")
	assert(scene.journal_view.selected == "guardian_fox")
	scene._resume()
	print("PASS: investigation reveals three distinct search rings; Journal tracking, far HUD guidance and local pin reveal")
	scene.player.position = scene.lantern.position
	scene._interact_world()
	assert(not scene.lantern_lit, "Lantern must remain locked at 1/3")
	await reload_world()
	assert(scene.keeper.accepted and not scene.keeper.reported and scene.keeper.remaining() == 2)
	assert(scene.seal_fragments.collected_ids == [1] and scene.remaining_enemies == 5)
	assert(scene.get_node_or_null("DemonFox") == null and JOURNAL.entry(scene, "guardian_fox").value == 1)
	assert(1 in scene.world_data[GUARDIANS.SAVE_KEY].regions and scene.tracked_quest == "guardian_warg")
	evidence.append("Fox first: defeat recovered Fragment 2 once, completed objective stayed saved, and its pin vanished immediately")
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
	scene.get_node("CampDemon0").take_damage(10000)
	scene.get_node("CampDemon1").take_damage(10000)
	scene._show_journal()
	scene._complete_scroll_quest()
	assert(scene.keeper.reported and scene.shards == 25, "Accepted bounty retains its existing post-victory payment")
	scene._resume()
	scene.get_node("DemonBoar").take_damage(10000)
	assert(scene.seal_fragments.collected_ids == [1, 2] and scene.shards == 45)
	scene.player.position = scene.lantern.position
	scene._interact_lantern()
	assert(not scene.lantern_lit, "Lantern must remain locked at 2/3")
	scene.set_tracked_quest("relic")
	scene.get_node("CampDemon2").take_damage(10000)
	assert(scene.seal_fragments.collected_ids == [1, 2, 0] and scene.tracked_quest == GUARDIANS.LANTERN)
	assert(scene.guardian_map_markers().size() == 1 and marker(GUARDIANS.LANTERN).tracked)
	assert(not JOURNAL.entry(scene, GUARDIANS.LANTERN).locked and scene.remaining_enemies == 2)
	assert(scene.interact_button.visible and not scene.interact_button.disabled)
	scene.interact_button.pressed.emit()
	assert(scene.boss_spawned and scene.lantern_lit and not scene.completed)
	assert(JOURNAL.entry(scene, GUARDIANS.LANTERN).done and scene.guardian_map_markers().is_empty())
	assert(STORE.load_progress().data.world_data.lantern)
	print("PASS: Fox → Boar → Warg restored the Northern Lantern at 3/3 with two ordinary camp wolves still alive")
	assert(QUESTS.current(scene).title == "THE TIDEWRAITH")
	assert(not QUESTS.future_prerequisites(scene).chapter_victory)
	scene.get_node("Tidewraith Dragon").take_damage(10000)
	assert(scene.completed and scene.shards == 140)
	scene._resume()
	await relic(0)
	await relic(2)
	assert(scene.world_data.relic_reward and scene.world_data.bounty_reward and scene.shards == 160)
	for repeat in range(4):
		scene._claim_optional_rewards()
		scene._on_boss_defeated()
	assert(scene.shards == 160)
	assert(QUESTS.future_prerequisites(scene).values().all(func(value): return value))
	await reload_world()
	assert(scene.completed and scene.shards == 160 and scene.relic_hunt.collected == 3)
	assert(scene.world_data.relic_reward and scene.world_data.bounty_reward and scene.world_data.grove_reward)
	scene._claim_optional_rewards()
	assert(scene.shards == 160)
	evidence.append("Three-fragment gate, lantern/boss flow, +80 victory/+15 bounty/+20 relic rewards and duplicate prevention survive reload")
	var config := ConfigFile.new()
	assert(config.load(STORE.PATH) == OK and config.get_value("campaign", "version") == 4)
	assert(not scene.world_data.has("quest_states"), "Existing saved objective fields remain canonical")
	var output: String = OS.get_cmdline_user_args()[0]
	FileAccess.open(output + "/quest_progression_results.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "cases": evidence, "final_shards": scene.shards, "save_schema": 4, "future_story_prerequisites_derived_only": true}, "  "))
	scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.75, true, false, true).timeout
	var legacy := STORE.DEFAULTS.duplicate()
	legacy.world_data = STORE.fresh_world()
	legacy.world_data.cleared = [2, 5]
	legacy.world_data.boar_defeated = true
	legacy.world_data.seal_fragments = [1]
	assert(STORE.save_progress(legacy) == OK)
	await open_world()
	assert(scene.seal_fragments.complete() and 1 in scene.seal_fragments.collected_ids)
	assert(scene.get_node_or_null("DemonBoar") == null and scene.get_node_or_null("CampDemon2") == null)
	assert(scene.tracked_quest == GUARDIANS.LANTERN)
	print("PASS: legacy Fragment 2 preserved; retired Warg and Boar receive credit and cannot block restoration")
	scene.queue_free()
	paused = false
	await process_frame
	await create_timer(.3, true, false, true).timeout
	print("PASS: candidate guardian objectives, region discovery, legacy migration, and one-time existing rewards")
	quit()
