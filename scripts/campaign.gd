extends "res://scripts/main.gd"

const SAVE_PATH := "user://campaign.cfg"
const CAMPAIGN_STORE = preload("res://scripts/campaign_store.gd")
const SETTINGS_PATH := "user://settings.cfg"
const RELIC_HUNT_SCRIPT = preload("res://scripts/relic_hunt.gd")
const CHAPTERS := [
	["The Silent Shore", "The western lantern has gone dark. Defeat the shore demons, then approach the lantern and light it to draw out the dragon."],
	["The Broken Grove", "Follow the keeper's trail. Clear the grove's demons and light its lantern to expose the Tidewraith's next manifestation."],
	["The Last Lantern", "Break the final seal: defeat the demons and light the last lantern. Destroy the dragon to restore Veyra's light."]
]
var chapter := 0
var shards := 0
var blade_level := 0
var armor_level := 0
var completed := false
var overlay: CanvasLayer
var menu_box: VBoxContainer
var menu_scroll: ScrollContainer
var notice := ""
var progress_unreadable := false
var potions := 3
var started := false
var camera_sensitivity := 1.0
var camera_distance := 6.3
var sound_volume := 0.7
var shadows_enabled := true
var frame_limit := 60
var pause_menu_open := false
var journal_open := false
var lantern: Node3D
var lantern_flame: MeshInstance3D
var lantern_label: Label3D
var interact_button: Button
var lantern_lit := false
var relic_hunt: Node3D
var relic_status: Label

func _process(_delta: float) -> void:
	if started and not game_finished:
		_update_objective()
		if Input.is_action_just_pressed(&"interact"):
			_interact_lantern()

func _build_lantern() -> void:
	lantern = Node3D.new()
	lantern.name = "ChapterLantern"
	lantern.position = [Vector3(-7, 0, 1), Vector3(7, 0, 1), Vector3(5, 0, 5)][chapter]
	add_child(lantern)
	var pedestal := MeshInstance3D.new()
	var stone := CylinderMesh.new()
	stone.top_radius = 0.45
	stone.bottom_radius = 0.7
	stone.height = 1.4
	pedestal.mesh = stone
	pedestal.position.y = 0.7
	pedestal.material_override = _material(Color(0.3, 0.35, 0.38))
	lantern.add_child(pedestal)
	lantern_flame = MeshInstance3D.new()
	var flame := SphereMesh.new()
	flame.radius = 0.3
	flame.height = 0.8
	lantern_flame.mesh = flame
	lantern_flame.position.y = 1.8
	var glow := _material(Color(0.3, 0.75, 0.9))
	glow.emission_enabled = true
	glow.emission = Color(0.2, 0.65, 0.85)
	lantern_flame.material_override = glow
	lantern_flame.hide()
	lantern.add_child(lantern_flame)
	lantern_label = Label3D.new()
	lantern_label.text = "SEALED LANTERN"
	lantern_label.position.y = 2.7
	lantern_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lantern_label.font_size = 40
	lantern.add_child(lantern_label)
	_bind_keys(&"interact", [KEY_E])

func _update_objective() -> void:
	var objective := "Defeat shore demons: %d" % remaining_enemies
	if boss_spawned:
		objective = "Defeat the Tidewraith Dragon"
	elif remaining_enemies == 0:
		objective = "Light the lantern: %.0f m | E / LIGHT" % player.global_position.distance_to(lantern.global_position)
	status_label.text = "%s | Potions: %d" % [objective, potions]
	relic_status.text = relic_hunt.call("progress_text")
	interact_button.visible = remaining_enemies == 0 and not lantern_lit
	interact_button.disabled = player.global_position.distance_to(lantern.global_position) > 2.5

func _interact_lantern() -> void:
	if not started or game_finished or get_tree().paused or remaining_enemies > 0 or lantern_lit:
		return
	if player.global_position.distance_to(lantern.global_position) > 2.5:
		return
	lantern_lit = true
	lantern_flame.show()
	lantern_label.text = "LANTERN RESTORED"
	_spawn_boss()
	_update_objective()

class PauseOverlay extends CanvasLayer:
	signal pause_requested
	signal journal_requested

	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q:
			journal_requested.emit()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			pause_requested.emit()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(overlay) and started and not game_finished and not get_tree().paused:
			_pause_game()

func _toggle_pause() -> void:
	if game_finished or not started:
		return
	if pause_menu_open:
		_resume()
	elif not get_tree().paused:
		_pause_game()

func _ready() -> void:
	_load_progress()
	environment_chapter = chapter
	super._ready()
	_load_settings()
	player.set("max_health", 100 + armor_level * 25)
	player.set("health", 100 + armor_level * 25)
	player.set("attack_damage", 1 + blade_level)
	_on_health_changed(int(player.get("health")), int(player.get("max_health")))
	_build_campaign_ui()
	_build_lantern()
	relic_hunt = RELIC_HUNT_SCRIPT.new()
	relic_hunt.set("player", player)
	relic_hunt.set("chapter", chapter)
	add_child(relic_hunt)
	_show_camp()

func _build_enemies() -> void:
	remaining_enemies = 3 + chapter * 2
	for index in range(remaining_enemies):
		var enemy: CharacterBody3D = ENEMY_SCRIPT.new()
		var angle := TAU * float(index) / float(remaining_enemies)
		enemy.position = Vector3(cos(angle) * 10, 0, sin(angle) * 10)
		enemy.set("target", player)
		enemy.set("health", 3 + chapter * 2)
		# Introduce the scout on the shore; later chapters mix all three kinds.
		enemy.set("kind", (1 if index == 2 else 0) if chapter == 0 else index % 3)
		enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
		add_child(enemy)

func _spawn_boss() -> void:
	super._spawn_boss()
	var dragon := get_node_or_null("Tidewraith Dragon")
	if dragon != null:
		var maximum := 34 + chapter * 14
		dragon.set("max_health", maximum)
		dragon.set("health", maximum)
		_on_boss_health_changed(maximum, maximum)

func _build_campaign_ui() -> void:
	var controls_layer := CanvasLayer.new()
	add_child(controls_layer)
	var controls := preload("res://scripts/safe_area.gd").new()
	controls_layer.add_child(controls)
	var pause_button := Button.new()
	pause_button.text = "PAUSE"
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -180
	pause_button.offset_right = -40
	pause_button.offset_top = 20
	pause_button.offset_bottom = 68
	pause_button.pressed.connect(_pause_game)
	controls.add_child(pause_button)
	var heal_button := Button.new()
	heal_button.text = "HEAL"
	heal_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	heal_button.offset_left = -180
	heal_button.offset_right = -40
	heal_button.offset_top = 80
	heal_button.offset_bottom = 128
	heal_button.pressed.connect(_heal)
	controls.add_child(heal_button)
	relic_status = Label.new()
	relic_status.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.05, 0.95))
	relic_status.add_theme_constant_override("outline_size", 4)
	relic_status.position = Vector2(30, 84)
	relic_status.add_theme_font_size_override("font_size", 15)
	relic_status.add_theme_color_override("font_color", Color(0.95, 0.8, 0.45))
	controls.add_child(relic_status)
	interact_button = _make_button("LIGHT [E]", Vector2(-470, -105), Vector2(-330, -35))
	interact_button.pressed.connect(_interact_lantern)
	interact_button.hide()
	controls.add_child(interact_button)
	overlay = PauseOverlay.new()
	overlay.connect("pause_requested", _toggle_pause)
	overlay.connect("journal_requested", _toggle_journal)
	overlay.layer = 20
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.055, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var menu_safe := preload("res://scripts/safe_area.gd").new()
	overlay.add_child(menu_safe)
	menu_scroll = ScrollContainer.new()
	menu_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_scroll.follow_focus = true
	menu_safe.add_child(menu_scroll)
	menu_box = VBoxContainer.new()
	menu_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_box.add_theme_constant_override("separation", 12)
	menu_scroll.add_child(menu_box)
	menu_safe.resized.connect(_layout_menu)
	_layout_menu()

func _layout_menu() -> void:
	var margin := maxf(24.0, (menu_scroll.get_parent().size.x - 700.0) * 0.5)
	menu_scroll.offset_left = margin
	menu_scroll.offset_right = -margin
	menu_scroll.offset_top = 24
	menu_scroll.offset_bottom = -24

func _clear_menu(title: String, message: String) -> void:
	journal_open = false
	pause_menu_open = false
	get_tree().paused = true
	player.call("set_move_input", Vector2.ZERO)
	player.call("clear_target_lock")
	player.set("_burst_requested", false)
	player.call("cancel_swing")
	get_tree().call_group("movement_joysticks", "reset")
	overlay.show()
	menu_scroll.scroll_vertical = 0
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 36)
	menu_box.add_child(heading)
	var body := Label.new()
	body.text = message
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.y = 95
	body.add_theme_font_size_override("font_size", 20)
	menu_box.add_child(body)

func _menu_button(text: String, action: Callable, disabled := false) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.disabled = disabled
	button.pressed.connect(action)
	menu_box.add_child(button)

func _show_camp() -> void:
	var story: String = CHAPTERS[chapter][1]
	if completed:
		story = "Veyra's lanterns shine again. Aru has broken the Tidewraith's hold. Replay the final hunt or begin a new journey."
	_clear_menu("VEIL OF VEYRA", "%s\n\nShards: %d  |  Blade: %d  |  Armor: %d\n%s" % [story, shards, blade_level + 1, armor_level + 1, notice])
	_menu_button("Begin: " + str(CHAPTERS[chapter][0]), _resume)
	_menu_button("Upgrade blade — %d shards" % _cost(blade_level), func(): _upgrade(true), shards < _cost(blade_level) or blade_level >= 4)
	_menu_button("Upgrade armor — %d shards" % _cost(armor_level), func(): _upgrade(false), shards < _cost(armor_level) or armor_level >= 4)
	_menu_button("New journey", _confirm_reset)
	_menu_button("Keeper's request (+20 bonus shards)", _show_keeper_request)
	_menu_button("Enemy guide", _show_enemy_guide)
	_menu_button("Spirit Burst guide", _show_burst_guide)
	_menu_button("Settings", func(): _show_settings(_show_camp))
	_menu_button("Quit", func(): get_tree().quit())

func _cost(level: int) -> int:
	return (level + 1) * 20

func _show_keeper_request() -> void:
	_clear_menu("THE KEEPER'S REQUEST", "Three relics remain scattered around this island. Walk near each golden relic to recover it. Find all three and defeat the dragon in the same hunt to earn 20 bonus shards.\n\nThis quest is optional. Restarting a hunt resets collected relics.")
	_menu_button("Back to camp", _show_camp)

func _show_burst_guide() -> void:
	_clear_menu("SPIRIT BURST", "Each sword swing that damages an enemy grants 25 spirit. Missing grants nothing; hitting a crowd still grants only 25.\n\nAt 100 spirit, press L or BURST to spend it on a 3-metre area attack dealing three times your blade damage. It interrupts ordinary enemies but not the dragon.\n\nSpirit resets when you restart a hunt. An empty burst still spends the charge.")
	_menu_button("Back to camp", _show_camp)

func _show_enemy_guide() -> void:
	_clear_menu("KNOW YOUR ENEMY", "LOCK ON: press Tab or LOCK to face the nearest living enemy within 14 metres. Press again to release. Dragging the camera or opening a menu also releases the lock.\n\nEMBER WOLF: a corrupted wolf. Balanced movement and melee damage.\n\nASH STALKER: a smaller, fast and fragile wolf. Its short warning leads to a lighter strike.\n\nDIRE WARG: a large, tough wolf. Its wide attack deals heavy damage after a longer warning.\n\nLeave their warning circles or interrupt their windups with a sword hit.\n\nTIDEWRAITH DRAGON: move aside from breath and dodge sideways from charges. At half health it becomes ENRAGED: shorter warnings and recovery, faster charges. Sword hits do not interrupt the dragon.")
	_menu_button("Back to camp", _show_camp)

func _upgrade(blade: bool) -> void:
	var level := blade_level if blade else armor_level
	if level >= 4 or shards < _cost(level):
		return
	shards -= _cost(level)
	if blade:
		blade_level += 1
		player.set("attack_damage", 1 + blade_level)
	else:
		armor_level += 1
		player.set("max_health", 100 + armor_level * 25)
		player.set("health", 100 + armor_level * 25)
	_on_health_changed(int(player.get("health")), int(player.get("max_health")))
	_save_progress()
	_show_camp()

func _resume() -> void:
	journal_open = false
	pause_menu_open = false
	started = true
	relic_hunt.set("active", true)
	overlay.hide()
	get_tree().paused = false
	_update_objective()

func _pause_game() -> void:
	if game_finished or not started:
		return
	_clear_menu("HUNT PAUSED", "Progress is saved between chapters. Restarting resets enemies, potions, and relic collection.")
	pause_menu_open = true
	_menu_button("Resume", _resume)
	_menu_button("Quest Journal [Q]", _show_journal)
	_menu_button("Restart hunt", _reload)
	_menu_button("Settings", func(): _show_settings(_pause_game))
	_menu_button("Quit", func(): get_tree().quit())

func _show_settings(back: Callable) -> void:
	_clear_menu("SETTINGS", "Adjust the camera, sound, and graphics. Changes apply immediately; use Save and back to keep them.")
	_settings_slider("Camera sensitivity", 0.25, 2.0, 0.05, camera_sensitivity, func(value: float):
		camera_sensitivity = value
		_apply_settings())
	_settings_slider("Sound volume", 0.0, 1.0, 0.05, sound_volume, func(value: float):
		sound_volume = value
		_apply_settings())
	_settings_slider("Camera distance", 4.0, 9.0, 0.1, camera_distance, func(value: float):
		camera_distance = value
		_apply_settings())
	var shadows := CheckButton.new()
	shadows.name = "ShadowsToggle"
	shadows.text = "Shadows (turn off for better performance)"
	shadows.custom_minimum_size.y = 48
	shadows.button_pressed = shadows_enabled
	shadows.toggled.connect(func(enabled: bool):
		shadows_enabled = enabled
		_apply_settings())
	menu_box.add_child(shadows)
	var frame_label := Label.new()
	frame_label.text = "Frame-rate limit (30 uses less rendering work)"
	frame_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(frame_label)
	var frame_choice := OptionButton.new()
	frame_choice.name = "FrameLimitChoice"
	frame_choice.custom_minimum_size.y = 48
	frame_choice.add_item("30 FPS", 30)
	frame_choice.add_item("60 FPS", 60)
	frame_choice.select(0 if frame_limit == 30 else 1)
	frame_choice.item_selected.connect(func(index: int):
		frame_limit = frame_choice.get_item_id(index)
		_apply_settings())
	menu_box.add_child(frame_choice)
	_menu_button("Preview sound", func(): player.call("play_sound", "sword"))
	var feedback := Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_box.add_child(feedback)
	_menu_button("Save and back", func():
		if _save_settings() == OK:
			back.call()
		else:
			feedback.text = "Settings could not be saved. Try again or go back without saving.")
	_menu_button("Back without saving", func():
		_load_settings()
		back.call())

func _settings_slider(title: String, minimum: float, maximum: float, increment: float, value: float, changed: Callable) -> void:
	var label := Label.new()
	label.text = "%s: %.2f" % [title, value]
	menu_box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = increment
	slider.value = value
	slider.custom_minimum_size.y = 44
	slider.value_changed.connect(func(updated: float):
		label.text = "%s: %.2f" % [title, updated]
		changed.call(updated))
	menu_box.add_child(slider)

func _apply_settings() -> void:
	Engine.max_fps = frame_limit
	for child in get_children():
		if child is DirectionalLight3D:
			child.shadow_enabled = shadows_enabled
	player.set("camera_sensitivity", camera_sensitivity)
	player.call("set_camera_distance", camera_distance)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(sound_volume, 0.0001)))
	AudioServer.set_bus_mute(0, sound_volume == 0.0)

func _save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("settings", "camera_sensitivity", camera_sensitivity)
	config.set_value("settings", "camera_distance", camera_distance)
	config.set_value("settings", "sound_volume", sound_volume)
	config.set_value("settings", "shadows_enabled", shadows_enabled)
	config.set_value("settings", "frame_limit", frame_limit)
	return config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	camera_sensitivity = _setting_number(config, "camera_sensitivity", 1.0, 0.25, 2.0)
	camera_distance = _setting_number(config, "camera_distance", 6.3, 4.0, 9.0)
	sound_volume = _setting_number(config, "sound_volume", 0.7, 0.0, 1.0)
	var saved_shadows: Variant = config.get_value("settings", "shadows_enabled", true)
	shadows_enabled = saved_shadows if saved_shadows is bool else true
	var saved_limit: Variant = config.get_value("settings", "frame_limit", 60)
	frame_limit = saved_limit if saved_limit is int and saved_limit in [30, 60] else 60
	_apply_settings()

func _setting_number(config: ConfigFile, key: String, fallback: float, minimum: float, maximum: float) -> float:
	var value: Variant = config.get_value("settings", key, fallback)
	if (value is float or value is int) and is_finite(float(value)):
		return clampf(float(value), minimum, maximum)
	return fallback

func _heal() -> void:
	if game_finished or potions <= 0 or int(player.get("health")) <= 0:
		return
	var maximum := int(player.get("max_health"))
	if int(player.get("health")) >= maximum:
		return
	potions -= 1
	player.set("health", mini(maximum, int(player.get("health")) + 50))
	_on_health_changed(int(player.get("health")), maximum)
	_update_objective()

func _on_enemy_defeated() -> void:
	remaining_enemies = maxi(0, remaining_enemies - 1)
	if remaining_enemies == 0 and not game_finished:
		lantern_label.text = "LIGHT THE LANTERN"
	_update_objective()

func _on_boss_defeated() -> void:
	if game_finished:
		return
	super._on_boss_defeated()
	relic_hunt.set("active", false)
	var bonus := int(relic_hunt.call("reward"))
	var reward := 40 + chapter * 20 + bonus
	shards += reward
	var final_hunt := chapter == CHAPTERS.size() - 1
	if final_hunt:
		completed = true
	else:
		chapter += 1
	var saved := _save_progress()
	_clear_menu("VEYRA RESTORED" if final_hunt else "LANTERN RECLAIMED", "The Tidewraith falls. Aru gathers %d Tide Shards (relic bonus: %d).\n%s\n%s" % [reward, bonus, "The island is free." if final_hunt else "A new path opens deeper into the island.", notice])
	_menu_button("Return to camp" if saved else "Retry save and return", _reload if saved else _retry_save_and_return)
	if not saved:
		_menu_button("Return without saving this session", _reload)

func _retry_save_and_return() -> void:
	if _save_progress():
		_reload()
	else:
		_show_save_failure()

func _show_save_failure() -> void:
	_clear_menu("PROGRESS NOT SAVED", notice)
	_menu_button("Retry save and return", _retry_save_and_return)
	_menu_button("Return without saving this session", _reload)

func _on_player_defeated() -> void:
	super._on_player_defeated()
	_clear_menu("THE HUNT IS NOT OVER", "The lantern's light calls Aru back. Your chapter progress and purchased upgrades are safe.")
	_menu_button("Retry hunt", _reload)
	_menu_button("Quit", func(): get_tree().quit())

func _confirm_reset() -> void:
	_clear_menu("BEGIN A NEW JOURNEY?", "This replaces your saved chapter progress, shards, and upgrades.")
	_menu_button("Keep my journey", _show_camp)
	_menu_button("Reset progress", func():
		chapter = 0
		shards = 0
		blade_level = 0
		armor_level = 0
		completed = false
		progress_unreadable = false
		if _save_progress():
			_reload()
		else:
			_show_save_failure())

func _reload() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _save_progress() -> bool:
	if progress_unreadable:
		notice = "Save protected: unreadable progress was not overwritten. Use New journey to reset it."
		return false
	var data := {}
	for key in ["chapter", "shards", "blade_level", "armor_level", "completed"]:
		data[key] = get(key)
	var result: Error = CAMPAIGN_STORE.save_progress(data)
	notice = "Progress saved." if result == OK else "Save failed. Keep the game open to retain this session."
	return result == OK

func _load_progress() -> void:
	var result: Dictionary = CAMPAIGN_STORE.load_progress()
	progress_unreadable = result.error != OK
	if progress_unreadable:
		notice = "Progress and backup could not be read. Temporary play is available; saving is blocked until New journey."
		return
	for key in result.data:
		set(key, result.data[key])
	if result.recovered:
		notice = "Previous progress recovered from backup. The most recent save may be lost."

func _toggle_journal() -> void:
	if journal_open:
		_resume()
	elif not get_tree().paused:
		_show_journal()

func _journal_text() -> String:
	var cleared := remaining_enemies == 0
	var wave := "COMPLETE" if cleared else "%d remaining" % remaining_enemies
	var light := "COMPLETE" if lantern_lit else ("READY - approach within 2.5 m and press E / LIGHT" if cleared else "LOCKED - clear the demons first")
	var dragon := "ACTIVE - defeat the Tidewraith Dragon" if boss_spawned else "LOCKED - restore the lantern first"
	return "%s\n\n1. Clear the demons: %s\n\n2. Restore the lantern: %s\n\n3. Break the seal: %s\n\nOPTIONAL - Keeper's request\n%s\nCollect all three relics and defeat the dragon in this hunt for 20 bonus shards.\n\nRestarting the hunt resets these objectives. Progress is saved between chapters." % [CHAPTERS[chapter][1], wave, light, dragon, relic_hunt.call("progress_text")]

func _show_journal() -> void:
	if not started or game_finished or (get_tree().paused and not pause_menu_open):
		return
	_clear_menu("QUEST JOURNAL - " + str(CHAPTERS[chapter][0]), _journal_text())
	journal_open = true
	pause_menu_open = true
	_menu_button("Return to hunt [Q / Esc]", _resume)
	menu_box.move_child(menu_box.get_child(menu_box.get_child_count() - 1), 1)
	_menu_button("Pause menu", _pause_game)