extends SceneTree
const STORE = preload("res://scripts/campaign_store.gd")
var scene
func _initialize():
	call_deferred("run")
func open_world():
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("lock_targets"):
		enemy.set_physics_process(false)
func close_world():
	scene.queue_free()
	await process_frame
	paused = false
func run():
	assert(OS.get_environment("VEYRA_TEST") == "1")
	for path in [STORE.PATH,STORE.BACKUP,STORE.TEMP]: DirAccess.remove_absolute(path)
	await open_world()
	assert(scene.remaining_enemies == 5)
	assert(scene.get_node_or_null("CampDemon5") == null)
	var brutes := 0
	for enemy in get_nodes_in_group("lock_targets"):
		if enemy.get_script() == scene.ENEMY_SCRIPT and enemy.kind == scene.ENEMY_SCRIPT.Kind.BRUTE:
			brutes += 1
	assert(brutes == 1, "Exactly one large Dire Warg must remain")
	var hero=scene.player
	var herbs=scene.herbs
	hero.position=herbs.LOCATIONS[0]
	scene._interact_world()
	assert(scene.potions==4 and herbs.collected==1)
	scene._interact_world()
	assert(scene.potions==4)
	var relic=scene.relic_hunt.relics[0]
	hero.position=relic.position
	scene.relic_hunt._physics_process(0.01)
	assert(scene.relic_hunt.collected==1)
	var enemy=scene.get_node("CampDemon0")
	enemy.take_damage(1000)
	await process_frame
	assert(scene.remaining_enemies==4)
	var exploration=scene.get_node("IslandExploration")
	hero.position=Vector3(0,0,2)
	exploration.bind_waystone(1)
	scene.keeper.accept()
	hero.health=63
	scene._process(5.1)
	scene._finish_autosave(true)
	assert(STORE.load_progress().data.world_data.health == 63, "Periodic autosave must persist player state")
	scene._pause_game()
	assert(STORE.read_file(STORE.PATH).error==OK)
	await close_world()
	await open_world()
	assert(scene.remaining_enemies==4 and scene.get_node_or_null("CampDemon0")==null)
	assert(scene.herbs.collected_ids==[0] and scene.potions==4)
	assert(scene.relic_hunt.collected_ids==[0])
	assert(scene.player.health==63 and scene.player.position.distance_to(Vector3(0,0,2))<0.1)
	exploration=scene.get_node("IslandExploration")
	assert(exploration.checkpoint_index==1 and exploration.discovered==[true,true,false])
	assert(scene.keeper.accepted)
	# Death preserves world pickups and returns to the bound waystone.
	scene.player._invulnerability_time=0
	scene.player.take_damage(1000)
	assert(scene.game_finished)
	await close_world()
	await open_world()
	assert(scene.player.health==scene.player.max_health)
	assert(scene.player.position.distance_to(scene.player.rescue_position)<0.1)
	assert(scene.potions==4 and scene.remaining_enemies==4)
	for enemy2 in get_nodes_in_group("lock_targets"):
		if enemy2.get_script()==scene.ENEMY_SCRIPT: enemy2.take_damage(1000)
	await process_frame
	assert(scene.remaining_enemies==0 and not scene.boss_spawned)
	scene.player.position=scene.lantern.position
	scene.seal_fragments.restore([0,1,2])
	scene._interact_lantern()
	assert(scene.lantern_lit and scene.boss_spawned)
	await close_world()
	await open_world()
	assert(scene.remaining_enemies==0 and scene.lantern_lit and scene.boss_spawned)
	var before:int=scene.shards
	var boss=scene.get_node("Tidewraith Dragon")
	boss.take_damage(10000)
	await process_frame
	assert(scene.completed and not scene.game_finished and scene.shards==before+80)
	scene._on_boss_defeated()
	assert(scene.shards==before+80)
	scene._resume()
	# Optional quests can finish after victory, with exactly one payment.
	for item in scene.relic_hunt.relics.duplicate():
		scene.player.position=item.position
		scene.relic_hunt._physics_process(0.01)
	assert(scene.shards==before+100)
	scene._show_journal()
	scene._complete_scroll_quest()
	assert(scene.shards==before+115)
	scene._complete_scroll_quest()
	assert(scene.shards==before+115)
	scene._resume()
	scene._pause_game()
	await close_world()
	await open_world()
	assert(scene.completed and not scene.game_finished)
	assert(scene.get_node_or_null("Tidewraith Dragon")==null)
	assert(scene.relic_hunt.collected==3 and scene.keeper.reported)
	assert(scene.shards==before+115)
	assert(scene._save_progress())
	await close_world()
	print("PASS: persistent island, pickups, cleared demons, waystones, health/potions, death resume, lantern resume, continued exploration and one-time rewards")
	quit()
