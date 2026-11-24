extends "res://tests/chapter_armory_check.gd"

const STORE_UI := preload("res://scripts/chapter_store_screen.gd")
const SAFE := preload("res://scripts/safe_area.gd")
var armory: CanvasLayer

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var arguments := OS.get_cmdline_user_args()
	if not arguments.is_empty():
		output = arguments[0]
	Input.emulate_mouse_from_touch = true
	root.size = Vector2i(1280, 720)
	var seed := SAVE.DEFAULTS.duplicate()
	seed.shards = 32
	seed.veil_gems = 4
	seed.blade_level = 1
	seed.armor_level = 1
	seed.world_data = SAVE.fresh_world()
	seed.world_data[SAVE.OWNED_EQUIPMENT] = SAVE.REINFORCED | SAVE.THORNWARD | SAVE.EMBERSTEEL
	assert(SAVE.save_progress(seed) == OK)
	await open_game()
	game.title_screen.find_child("Armory", true, false).pressed.emit()
	await frames(8)
	armory = game.get_node("Armory")

	var profiles := [
		{"size":Vector2i(1280,720), "scale":1.0, "insets":Vector4i(0,0,0,0), "name":"1280x720_16x9"},
		{"size":Vector2i(1600,720), "scale":1.0, "insets":Vector4i(54,8,20,13), "name":"1600x720_20x9_safe"},
		{"size":Vector2i(2400,1080), "scale":1.08, "insets":Vector4i(82,20,40,26), "name":"2400x1080_20x9_scaled"},
		{"size":Vector2i(854,480), "scale":.92, "insets":Vector4i(22,5,12,8), "name":"854x480_16x9_scaled"},
	]
	for profile in profiles:
		root.size = profile.size
		root.content_scale_factor = profile.scale
		await frames(9)
		var inset: Vector4i = profile.insets
		var pixels := Rect2(inset.x, inset.y, profile.size.x - inset.x - inset.z, profile.size.y - inset.y - inset.w)
		armory.safe_area.test_safe_rect = SAFE.logical_rect(pixels, root.get_final_transform(), root.get_visible_rect())
		armory.safe_area.refresh()
		await frames(9)
		for decoration in armory.header_panel.get_child(0).get_children():
			assert(not decoration is STORE_UI.CornerTrim, "Unexpected currency frame")
		await tap(armory.tabs[2])
		await tap(armory.choices[1])
		await tap(armory.upgrade_button)
		assert(armory.status.text == "Insufficient Tide Shards" and game.shards == 32)
		assert(armory.balance.shard_label.text == "32" and armory.balance.gem_label.text == "4")
		check_fit(profile.name)
		await gesture_check()
		await capture(profile.name)
		await tap(armory.tabs[1])
		await tap(armory.equip_button)
		assert(game.gear_selection().shield == 0)
		check_fit(profile.name + " shield")
		await tap(armory.equip_button)
		assert(game.gear_selection().shield == -1)
		print("PASS ", profile.name, " scale ", profile.scale, " safe ", armory.safe_area.size)

	await tap(armory.tabs[2])
	await tap(armory.choices[1])
	game.shards = 40
	await tap(armory.upgrade_button)
	assert(game.shards == 4 and game.armor_level == 2 and armory.status.text.begins_with("Upgrade Successful"))
	check_fit("success layout")
	var saved: Dictionary = SAVE.load_progress().data
	assert(saved.shards == 4 and saved.armor_level == 2)
	print("PASS full layout, safe areas, currency frame removal, touch actions, purchase validation and saved upgrade")
	game.queue_free()
	await frames(5)
	quit()

func check_fit(profile: String) -> void:
	var safe: Rect2 = armory.safe_area.get_global_rect().grow(.5)
	var targets := [armory.header_panel, armory.balance, armory.canvas, armory.reset_button,
		armory.item, armory.detail, armory.stats, armory.next_stats, armory.cost_row,
		armory.equip_button, armory.upgrade_button, armory.status]
	targets.append_array(armory.tabs)
	targets.append_array(armory.choices)
	for control: Control in targets:
		if control.is_visible_in_tree():
			assert(safe.encloses(control.get_global_rect()), "%s %s is outside %s at %s" % [
				profile, control.name, safe, control.get_global_rect()])
			if control is Button:
				assert(control.size.y >= 42, "Tap target too short")
	assert(armory.canvas.size.y >= 280 and armory.canvas.size.x >= 280)
	assert(not armory.card_strip.get_h_scroll_bar().visible)
	if armory.upgrade_button.visible:
		assert(not armory.upgrade_button.get_global_rect().intersects(armory.equip_button.get_global_rect()))

func gesture_check() -> void:
	var point: Vector2 = armory.canvas.get_global_rect().get_center()
	var initial: float = armory.yaw
	send_touch(0, point, true)
	await frames(2)
	send_drag(0, point, point + Vector2(65,0))
	await frames(2)
	assert(absf(angle_difference(initial, armory.yaw)) > .4)
	send_touch(0, point + Vector2(65,0), false)
	await frames(2)
	send_touch(0, point - Vector2(40,0), true)
	send_touch(1, point + Vector2(40,0), true)
	await frames(2)
	send_drag(1, point+Vector2(40,0), point+Vector2(98,0))
	await frames(2)
	assert(armory.zoom < armory.STAGE.DEFAULT_ZOOM)
	send_touch(0, point-Vector2(40,0), false)
	send_touch(1, point+Vector2(98,0), false)
	await frames(2)
	await tap(armory.reset_button)
	assert(armory.fingers.is_empty() and is_equal_approx(armory.zoom, armory.STAGE.DEFAULT_ZOOM))
