extends "res://tests/cursed_bear_cave_check.gd"

const SCENE := "res://scenes/chapter_one.tscn"
var output := ""

func open_world() -> void:
	assert(change_scene_to_file(SCENE) == OK)
	await scene_changed
	await ready_world()

func ready_world() -> void:
	game = current_scene
	while not game.placement_ready or not game.grove:
		await physics_frame
	await process_frame
	hero = game.player

func screenshot(file: String) -> void:
	if output.is_empty():
		return
	for i in 25:
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output+"/"+file+".png") == OK)

func menu_button(prefix: String) -> Button:
	for node in game.menu_box.get_children():
		if node is Button and node.text.begins_with(prefix):
			return node
	return null

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	assert(ProjectSettings.get_setting("application/run/main_scene") == SCENE)
	if OS.get_cmdline_user_args().size() == 1:
		output = OS.get_cmdline_user_args()[0]
	await open_world()
	assert(not game._has_valid_journey() and game.title_screen.visible)
	var store_button: Button = game.title_screen.find_child("Store", true, false)
	assert(not store_button.disabled)
	store_button.pressed.emit()
	var storefront = game.get_node("StoreScreen")
	assert(not storefront.purchase.disabled)
	assert(game.buy_store_item(0).begins_with("Start or continue"))
	storefront.close()
	await process_frame
	assert(game.title_screen.visible)
	game.new_game_button.pressed.emit()
	await scene_changed
	await ready_world()
	assert(game.started and not paused and game.shards == 0 and game.veil_gems == 0 and game.potions == 3)
	assert(game.gear_selection() == {"blade":0,"shield":-1,"armor":0})
	hero.position = game.seal_fragments.get_node("Scenery").global_position
	game._interact_world()
	assert(game.guardians.revealed() and game.seal_fragments.collected_ids.is_empty())
	game.get_node("CampDemon0").take_damage(10000)
	assert(game.shards == 4 and game.veil_gems == 0)
	game._defeat_world_enemy(0)
	assert(game.shards == 4 and game.veil_gems == 0)
	game.get_node("CampDemon2").take_damage(10000)
	assert(game.shards == 24 and game.veil_gems == 1 and game.seal_fragments.collected_ids == [0])
	game._pause_game()
	menu_button("Save and return").pressed.emit()
	assert(game.title_screen.visible and not game.camp_menu and paused)
	game.title_screen.find_child("Store",true,false).pressed.emit()
	storefront = game.get_node("StoreScreen")
	assert(not storefront.purchase.disabled)
	assert(storefront.header_balances.shard_label.text == "24")
	assert(storefront.header_balances.gem_label.text == "1")
	await screenshot("store")
	storefront.purchase.pressed.emit()
	assert(game.shards == 16 and game.potions == 4 and STORE.load_progress().data.world_data.potions == 4)
	assert(storefront.header_balances.shard_label.text == "16")
	storefront.close()
	await process_frame
	assert(game.title_screen.visible)
	game.continue_button.pressed.emit()
	assert(game.change_gear("blade",true) == "Upgrade saved.")
	assert(game.shards == 0 and hero.attack_damage == 2)
	assert(game.select_gear("blade",1) == "Purchase this equipment in the Store.")
	assert(game.select_gear("shield",0) == "Purchase this equipment in the Store.")
	game._resume()
	var fox = game.get_node("DemonFox")
	var fox_feedback = fox.get_node("Feedback")
	assert(fox.animator.get_animation_list().size() == 8)
	assert(not fox_feedback._veil_surfaces.is_empty())
	assert(fox_feedback.audio.CLIPS[&"veil_vanish"].resource_path.ends_with("veil_vanish.ogg"))
	fox_feedback.set_veil(true)
	assert(fox_feedback._materials_swapped)
	fox_feedback.set_veil(false)
	fox.take_damage(10000)
	assert(game.shards == 24 and game.veil_gems == 2 and game.seal_fragments.collected_ids.size() == 2)
	game._defeat_fox()
	assert(game.shards == 24 and game.veil_gems == 2)
	game.get_node("DemonBoar").take_damage(10000)
	assert(game.shards == 52 and game.veil_gems == 3 and game.seal_fragments.complete())
	game._defeat_boar()
	assert(game.shards == 52 and game.veil_gems == 3)
	assert(game.change_gear("armor",true) == "Upgrade saved.")
	assert(game.select_gear("armor",1) == "Purchase this equipment in the Store.")
	assert(game.change_gear("blade",true) == "Upgrade saved.")
	assert(game.shards == 0 and hero.attack_damage == 3 and hero.max_health == 125)
	assert(game.change_gear("blade",true) == "You need more Tide Shards.")
	for index in 3:
		game.tidewarden.interact(index)
	hero.position = game.lantern.global_position
	game._interact_lantern()
	assert(game.shards == 12 and game.lantern_lit and not game.boss_spawned and not game._temple_unlocked())
	game._interact_lantern()
	assert(game.shards == 12)
	hero.global_position = game.tidewarden.landmark.to_global(Vector3(0, 0, 2.6))
	game.tidewarden.inspect_tree()
	assert(game.tidewarden.read_claws())
	for i in 3:
		hero.position = game.grove.clues[i].global_position + Vector3.BACK*1.4
		game._interact_world()
		assert(game.grove.stage() == i+1)
		if i < 2:
			assert(game.shards == 12 and not game._temple_unlocked())
		if i == 1:
			await open_world()
			assert(game.grove.stage() == 2 and game.shards == 12 and not game._temple_unlocked())
			game.continue_button.pressed.emit()
	assert(game.shards == 20 and game._temple_unlocked())
	game._interact_world()
	assert(game.shards == 20)
	print("PASS New Game, zero gems for wolves, guardian payouts, Store balances, upgrades, Northern Lantern and Ancient Grove")
	assert(game._save_progress())
	await open_world()
	assert(game.shards == 20 and game.potions == 4 and game.lantern_lit and game._temple_unlocked())
	assert(game.gear_selection() == {"blade":0,"shield":-1,"armor":0})
	assert(game.player.attack_damage == 3 and game.player.max_health == 125)
	game.title_screen.find_child("Armory",true,false).pressed.emit()
	var armory: CanvasLayer = game.get_node("Armory")
	assert(armory.item.text == "Aru's Curved Blade" and armory.equip_button.text == "Unequip")
	assert(armory.balance.gem_label.text == "3" and armory.balance.shard_label.text == "20")
	await screenshot("armory")
	armory._close()
	assert(game.title_screen.visible)
	game.continue_button.pressed.emit()
	hero.position = Vector3(76,1.65,-17)
	for point in ROUTE:
		await walk(point)
	await ticks(100)
	await threshold(Vector2(67.8,22),true)
	assert(game.shrine.in_cell and game.awakening.extend_passage)
	assert(game.awakening.chunks.is_empty() and game.awakening.cracks == null)
	await walk(Vector2(0,-4.7))
	await ticks(16)
	bear = game.cave_bear
	assert(is_instance_valid(bear) and bear.is_on_floor())
	for i in 90:
		if game.bear_intro.active:
			break
		steer(Vector3.BACK)
		await physics_frame
	assert(game.bear_intro.active)
	assert(bear.get_node("Feedback").score == game.score and game.score.bed.stream != null)
	game._toggle_pause()
	assert(game.world_data.bear_awakening_seen and bear.target == hero and not game.bear_intro.active)
	bear.take_damage(10000)
	assert(game.shards == 58 and game.veil_gems == 5 and game.world_data[QUEST.BEAR_FLAG] and not game.completed)
	game._bear_victory()
	assert(game.shards == 58 and game.veil_gems == 5)
	# Pass around the fallen Bear before entering the sanctum.
	await walk(Vector2(2.7, hero.position.z))
	await walk(Vector2(2.7,17))
	await walk(Vector2(0,19))
	assert(game._save_progress())
	await open_world()
	assert(game.shards == 58 and game.veil_gems == 5 and game.world_data.bear_shards_paid and not game.completed)
	game.continue_button.pressed.emit()
	assert(game.shrine.in_cell and game.awakening.passage != null)
	await walk(Vector2(0,26))
	await walk(Vector2(-1.1,30.6))
	game._interact_world()
	assert(game.awakening.active)
	for i in 1500:
		if not game.awakening.active:
			break
		await physics_frame
	assert(game.shards == 100 and game.veil_gems == 6 and game.completed and game.awakening.finished() and not game.boss_spawned)
	game._finish_bear_chapter()
	assert(game.shards == 100 and game.veil_gems == 6)
	await open_world()
	assert(game.completed and game.shards == 100 and game.veil_gems == 6 and game.awakening.finished() and game.potions == 4)
	assert(game.shrine.in_cell and game.awakening.gate.get_child(0).disabled)
	game.title_screen.find_child("Store",true,false).pressed.emit()
	storefront = game.get_node("StoreScreen")
	storefront.purchase.pressed.emit()
	assert(game.shards == 92 and game.veil_gems == 6 and game.potions == 5 and not storefront.purchase.disabled)
	assert(game.buy_store_item(0) == "Potion pouch is full")
	assert(game.shards == 92 and game.veil_gems == 6 and game.potions == 5)
	var old_file := ConfigFile.new()
	assert(old_file.load(STORE.PATH) == OK)
	old_file.set_value("campaign", "version", 4)
	old_file.erase_section_key("campaign", "veil_gems")
	var old_world: Dictionary = old_file.get_value("campaign", "world")
	old_world.relics = [0, 1, 2]
	old_world.relic_reward = true
	old_file.set_value("campaign", "world", old_world)
	assert(old_file.save(STORE.PATH) == OK)
	await open_world()
	assert(game.veil_gems == 6 and game.shards == 92 and game.awakening.finished())
	assert(not game.world_data.has("relics") and not game.world_data.has("relic_reward"))
	var altar_position: Vector3 = hero.global_position
	game.continue_button.pressed.emit()
	hero.health = 0
	game._on_player_defeated()
	assert(game._save_progress())
	await open_world()
	assert(game.veil_gems == 6 and game.shards == 92 and game.awakening.finished())
	assert(not STORE.load_progress().migrated)
	assert(game.owns_gear("blade", 1) and game.owns_gear("shield", 0) and game.owns_gear("armor", 1))
	var legacy: Dictionary = STORE.load_progress().data
	legacy.shards = 11
	legacy.completed = false
	legacy.veil_gems = 5
	legacy.world_data.position = altar_position
	legacy.world_data.health = 125
	legacy.world_data.erase("lantern_awakening")
	legacy.world_data.erase("bear_shards_paid")
	assert(STORE.save_progress(legacy) == OK)
	await open_world()
	assert(game.shards == 11 and game._chapter_shard_reward() == 80)
	assert(game.grove.stage() == 3 and not game._can_investigate_grove())
	game.continue_button.pressed.emit()
	game._interact_world()
	assert(game.awakening.active)
	game.awakening.skip()
	assert(game.shards == 91 and game.veil_gems == 6 and game.awakening.finished())
	print("PASS Bear and finale award six gems total, duplicate guards, legacy migration, death/reload, Store cap, and cinematic Skip")
	current_scene.queue_free()
	await process_frame
	for i in 12:
		await process_frame
	assert(Node.get_orphan_node_ids().is_empty(), "Active scene left orphan nodes after teardown")
	quit()
