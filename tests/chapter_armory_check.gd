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

func send_touch(index: int, at: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.position = root.get_final_transform() * at
	touch.pressed = pressed
	Input.parse_input_event(touch)
	Input.flush_buffered_events()

func send_drag(index: int, old: Vector2, at: Vector2) -> void:
	var drag := InputEventScreenDrag.new()
	drag.index = index
	drag.position = root.get_final_transform() * at
	drag.relative = root.get_final_transform().basis_xform(at - old)
	Input.parse_input_event(drag)
	Input.flush_buffered_events()

func tap(target: Button) -> void:
	var point := target.get_global_rect().get_center()
	send_touch(0, point, true)
	await process_frame
	send_touch(0, point, false)
	await frames(4)

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
	Input.emulate_mouse_from_touch = true
	root.size = Vector2i(1280, 720)
	var seed := SAVE.DEFAULTS.duplicate()
	seed.shards = 70
	seed.veil_gems = 4
	seed.world_data = SAVE.fresh_world()
	assert(SAVE.save_progress(seed) == OK)
	await open_game()
	game.title_screen.find_child("Store",true,false).pressed.emit()
	assert(game.buy_store_item(1) == "Purchase Successful")
	assert(game.buy_store_item(2) == "Purchase Successful")
	assert(game.buy_store_item(3) == "Purchase Successful")
	assert(game.shards == 15 and game.gear_selection() == {"blade":0,"shield":-1,"armor":0})
	game.get_node("StoreScreen").close()
	await frames(3)
	game.title_screen.find_child("Armory",true,false).pressed.emit()
	await frames(8)
	var screen = game.get_node("Armory")
	assert(game.get_node("ChapterIslandMusic").exploration.playing)
	assert(screen.preview._visual.animator.current_animation == "Idle")
	await tap(screen.choices[1])
	assert(screen.option == 1 and screen.modular_preview.sword.visible and game.gear_selection().blade == 0)
	assert(screen.item.text == "Embersteel Sword" and not screen.upgrade_button.disabled)
	assert(screen.status.text.is_empty() and screen.next_stats.text.contains("[color=#a3c89b]Attack  2[/color]"))
	assert(screen.next_stats.text.count("[color=") == 1 and "[color=" not in screen.stats.text)
	assert("Preview only" in screen.detail.text and "Equipped" in screen.choices[0].find_child("Ownership",true,false).text)
	await tap(screen.upgrade_button)
	assert(screen.status.text == "Insufficient Tide Shards" and game.shards == 15 and game.blade_level == 0)
	assert(root.get_visible_rect().encloses(screen.upgrade_button.get_global_rect()))
	await capture("Weapons_1280x720")

	var view_rect: Rect2 = screen.canvas.get_global_rect()
	var point := view_rect.get_center()
	var start_yaw: float = screen.yaw
	send_touch(0, point, true)
	await frames(2)
	assert(screen.fingers.has(0))
	send_drag(0, point, point + Vector2(70, 0))
	await frames(2)
	assert(absf(angle_difference(start_yaw, screen.yaw)) > .4)
	send_touch(0, point + Vector2(70,0), false)
	await frames(2)
	send_touch(0, point - Vector2(45,0), true)
	send_touch(1, point + Vector2(45,0), true)
	await frames(2)
	assert(screen.fingers.size() == 2)
	send_drag(1, point + Vector2(45,0), point + Vector2(110,0))
	await frames(2)
	assert(screen.zoom < screen.STAGE.DEFAULT_ZOOM and screen.zoom >= screen.STAGE.MIN_ZOOM)
	send_touch(0, point - Vector2(45,0), false)
	send_touch(1, point + Vector2(110,0), false)
	await frames(2)
	screen._reset_view()
	await frames(18)
	assert(is_equal_approx(screen.zoom, screen.STAGE.DEFAULT_ZOOM))
	assert(absf(screen.camera.size - screen.STAGE.DEFAULT_ZOOM) < .07)

	root.size = Vector2i(1600, 738)
	await frames(7)
	await tap(screen.equip_button)
	assert(game.gear_selection().blade == 1 and game.player.attack_damage == 1)
	game.shards = 64
	screen.upgrade_after = 0
	screen.upgrade_button.pressed.emit()
	screen.upgrade_button.pressed.emit()
	assert(screen.status.text == "Upgrade Successful · Level 1 · 16 Tide Shards spent" and game.blade_level == 1 and game.shards == 48)
	assert(screen.balance.shard_label.text == "48" and screen.stats.text.contains("Attack  2"))
	await capture("Upgrade_1600x738")
	await tap(screen.tabs[1])
	assert(not screen.upgrade_button.visible and screen.item.text == "Thornward Shield")
	await tap(screen.equip_button)
	assert(game.gear_selection().shield == 0 and screen.modular_preview.shield.visible)
	await capture("Shields_1600x738")
	await tap(screen.equip_button)
	assert(game.gear_selection().shield == -1)
	await tap(screen.tabs[2])
	await tap(screen.choices[1])
	assert(screen.modular_preview.plates[0].visible and game.gear_selection().armor == 0)
	await tap(screen.equip_button)
	assert(game.gear_selection().armor == 1)
	screen.upgrade_after = 0
	await tap(screen.upgrade_button)
	assert(game.armor_level == 1 and game.shards == 32 and game.player.max_health == 125)
	assert(screen.stats.text.contains("Max Health  125") and screen.next_stats.text.contains("[color=#a3c89b]Max Health  150[/color]"))
	assert(screen.next_stats.text.count("[color=") == 1 and "Preview only" not in screen.detail.text)
	assert(root.get_visible_rect().encloses(screen.upgrade_button.get_global_rect()))
	await capture("Armor_1600x738")
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames(4)
	assert(game.title_screen.visible and not game.has_node("Armory"))
	await open_game()
	assert(game.gear_selection() == {"blade":1,"shield":-1,"armor":1})
	assert(game.blade_level == 1 and game.armor_level == 1 and game.shards == 32 and game.veil_gems == 4)
	assert(game.player.attack_damage == 2 and game.player.max_health == 125)
	game.blade_level = game.LEVEL_CAP
	game.title_screen.find_child("Armory",true,false).pressed.emit()
	await frames(4)
	screen = game.get_node("Armory")
	assert(screen.upgrade_button.disabled and not screen.cost_row.visible)
	screen._change(true)
	assert(game.blade_level == game.LEVEL_CAP and game.shards == 32)
	screen._close()
	await frames(4)
	print("PASS relaxed idle, preview/equipped tags, upgrade-only highlights, touch drag/pinch/reset, equip, upgrade feedback/cap, balances, Back and save/reload")
	game.queue_free()
	await frames(5)
	quit()
