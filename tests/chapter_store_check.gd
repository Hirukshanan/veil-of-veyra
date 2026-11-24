extends SceneTree

const SAVE := preload("res://scripts/campaign_store.gd")
var game
var output := ""

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for frame in count:
		await process_frame

func capture(file: String) -> void:
	if output.is_empty():
		return
	await frames(5)
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(file + ".png")) == OK)

func tap(target: Button) -> void:
	var screen_transform := root.get_final_transform()
	var point := screen_transform * target.get_global_rect().get_center()
	var touch := InputEventScreenTouch.new()
	touch.position = point
	touch.pressed = true
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
	await process_frame
	touch.pressed = false
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
	await frames(3)

func open_game() -> void:
	assert(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene")) == OK)
	await scene_changed
	game = current_scene
	while not is_instance_valid(game.title_screen):
		await process_frame
	await frames(8)

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	root.size = Vector2i(1600, 738)
	Input.emulate_mouse_from_touch = true
	var seed := SAVE.DEFAULTS.duplicate()
	seed.shards = 19
	seed.veil_gems = 4
	seed.world_data = SAVE.fresh_world()
	assert(SAVE.save_progress(seed) == OK)
	await open_game()
	game.title_screen.find_child("Store",true,false).pressed.emit()
	await frames(6)
	var store = game.get_node("StoreScreen")
	assert(store.card_buttons.size() == 1 and store.selected == 0)
	assert(game.get_node("ChapterIslandMusic").exploration.playing)
	var card_size: Vector2 = store.card_buttons[0].size
	assert(card_size.x < store.card_scroll.size.x * .50)
	await capture("Consumables_1600x738")
	await tap(store.category_buttons[1])
	assert(store.card_buttons[1].size.is_equal_approx(card_size))
	root.size = Vector2i(1280, 720)
	await frames(9)
	for index in 3:
		await tap(store.category_buttons[index])
		assert(store.item_name.get_global_rect().end.x <= root.get_visible_rect().end.x)
		assert(store.item_name.get_global_rect().end.y < root.get_visible_rect().end.y)
		if index < 2:
			assert(store.purchase.get_global_rect().end.y <= root.get_visible_rect().end.y)
		await capture(["Consumables_1280x720","Equipment_1280x720","Cosmetics_1280x720"][index])
	root.size = Vector2i(1600, 738)
	await frames(9)
	await tap(store.category_buttons[1])
	assert(store.category == 1 and store.card_buttons.size() == 3)
	await tap(store.card_buttons[3])
	assert(store.selected == 3 and store.item_name.text == "Reinforced Ranger Armor")
	await tap(store.card_buttons[1])
	assert(store.selected == 1 and store.item_name.text == "Embersteel Sword")
	assert(store.purchase.text == "Buy" and not store.purchase.disabled)
	await tap(store.purchase)
	assert(store.feedback.text == "Insufficient Tide Shards" and game.shards == 19 and not game.owns_gear("blade",1))
	await capture("Equipment_1600x738")
	await tap(store.category_buttons[2])
	assert(store.card_buttons.is_empty() and not store.purchase.visible and store.price_icon.texture == store.CURRENCIES.GEM)
	await capture("Cosmetics_1600x738")
	game.shards = 80
	var old_gear: Dictionary = game.gear_selection()
	var old_attack: int = game.player.attack_damage
	var old_health: int = game.player.max_health
	store._choose_category(1)
	store.buy_after = 0
	await frames(5)
	await tap(store.purchase)
	assert(store.feedback.text == "Purchase Successful" and store.header_balances.shard_label.text == "60")
	assert(store.purchase.disabled and game.owns_gear("blade",1) and game.blade_level == 0)
	assert(game.buy_store_item(1) == "Already owned" and game.shards == 60)
	await capture("Purchase_success")
	assert(game.buy_store_item(2) == "Purchase Successful")
	assert(game.buy_store_item(3) == "Purchase Successful")
	assert(game.gear_selection() == old_gear and game.player.attack_damage == old_attack and game.player.max_health == old_health)
	assert(game.shards == 25 and game.veil_gems == 4)
	store._choose_category(0)
	store.buy_after = 0
	store.purchase.pressed.emit()
	store.purchase.pressed.emit()
	assert(game.shards == 17 and game.potions == 4)
	store.buy_after = 0
	store.purchase.pressed.emit()
	assert(game.shards == 9 and game.potions == 5)
	assert(game.buy_store_item(0) == "Potion pouch is full" and game.shards == 9)
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(4)
	assert(game.title_screen.visible and not game.has_node("StoreScreen"))
	game.title_screen.find_child("Armory",true,false).pressed.emit()
	var armory = game.get_node("Armory")
	armory._inspect(1)
	assert(not armory.equip_button.disabled)
	await capture("Armory_owned")
	assert(game.select_gear("blade",1) == "Loadout saved.")
	assert(game.select_gear("shield",0) == "Loadout saved.")
	assert(game.select_gear("armor",1) == "Loadout saved.")
	armory._close()
	await open_game()
	assert(game.gear_selection() == {"blade":1,"shield":0,"armor":1} and game.shards == 9 and game.veil_gems == 4 and game.potions == 5)
	game.continue_button.pressed.emit()
	game._pause_game()
	for button in game.menu_box.get_children():
		if button is Button and button.text == "Store":
			button.pressed.emit()
			break
	await frames(3)
	assert(paused and game.has_node("StoreScreen"))
	game.get_node("StoreScreen").close()
	await frames(4)
	assert(paused and game.pause_menu_open and game.overlay.visible)
	var legacy := ConfigFile.new()
	assert(legacy.load(SAVE.PATH) == OK)
	legacy.set_value("campaign", "version", 5)
	legacy.set_value("campaign", "blade_level", 1)
	legacy.set_value("campaign", "armor_level", 1)
	var old_world: Dictionary = legacy.get_value("campaign", "world")
	old_world.erase(SAVE.OWNED_EQUIPMENT)
	legacy.set_value("campaign", "world", old_world)
	assert(legacy.save(SAVE.PATH) == OK)
	await open_game()
	assert(game.gear_selection() == {"blade":1,"shield":0,"armor":1} and game.shards == 9 and game.veil_gems == 4)
	assert(game.owns_gear("blade",1) and game.owns_gear("shield",0) and game.owns_gear("armor",1))
	print("PASS touch tabs, selection, insufficient/success, balances, rapid tap, potion cap, Armory ownership, in-game Store, Back, reload and v5 migration")
	game.queue_free()
	await process_frame
	quit()
