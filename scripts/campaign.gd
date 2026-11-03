extends "res://scripts/main.gd"

const SAVE_PATH := "user://campaign.cfg"
const SETTINGS_PATH := "user://settings.cfg"
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
var notice := ""
var potions := 3
var started := false
var camera_sensitivity := 1.0
var sound_volume := 0.7
var pause_menu_open := false
var lantern: Node3D
var lantern_flame: MeshInstance3D
var lantern_label: Label3D
var interact_button: Button
var lantern_lit := false

func _process(_delta: float) -> void:
	if started and not game_finished:
		_update_objective()
		if Input.is_action_just_pressed(&"interact"):
			_interact_lantern()

func _build_lantern() -> void:
	lantern = Node3D.new()
	lantern.name = "ChapterLantern"
	lantern.position = [Vector3(-7, 0, 1), Vector3(7, 0, 1), Vector3(0, 0, 5)][chapter]
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

	func _unhandled_key_input(event: InputEvent) -> void:
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
	super._ready()
	_load_settings()
	player.set("max_health", 100 + armor_level * 25)
	player.set("health", 100 + armor_level * 25)
	player.set("attack_damage", 1 + blade_level)
	_on_health_changed(int(player.get("health")), int(player.get("max_health")))
	_build_campaign_ui()
	_build_lantern()
	_show_camp()

func _build_enemies() -> void:
	remaining_enemies = 3 + chapter * 2
	for index in range(remaining_enemies):
		var enemy: CharacterBody3D = ENEMY_SCRIPT.new()
		var angle := TAU * float(index) / float(remaining_enemies)
		enemy.position = Vector3(cos(angle) * 10, 0, sin(angle) * 10)
		enemy.set("target", player)
		enemy.set("health", 3 + chapter * 2)
		enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
		add_child(enemy)

func _build_lighting() -> void:
	super._build_lighting()
	var colors := [Color(0.035, 0.075, 0.12), Color(0.06, 0.12, 0.08), Color(0.13, 0.035, 0.04)]
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.background_color = colors[chapter]

func _spawn_boss() -> void:
	super._spawn_boss()
	var dragon := get_node_or_null("Tidewraith Dragon")
	if dragon != null:
		var maximum := 34 + chapter * 14
		dragon.set("max_health", maximum)
		dragon.set("health", maximum)
		_on_boss_health_changed(maximum, maximum)

func _build_campaign_ui() -> void:
	var controls := CanvasLayer.new()
	add_child(controls)
	var pause_button := Button.new()
	pause_button.text = "PAUSE"
	pause_button.position = Vector2(1100, 20)
	pause_button.size = Vector2(140, 48)
	pause_button.pressed.connect(_pause_game)
	controls.add_child(pause_button)
	var heal_button := Button.new()
	heal_button.text = "HEAL"
	heal_button.position = Vector2(1100, 80)
	heal_button.size = Vector2(140, 48)
	heal_button.pressed.connect(_heal)
	controls.add_child(heal_button)
	interact_button = _make_button("LIGHT [E]", Vector2(-470, -105), Vector2(-330, -35))
	interact_button.pressed.connect(_interact_lantern)
	interact_button.hide()
	controls.add_child(interact_button)
	overlay = PauseOverlay.new()
	overlay.connect("pause_requested", _toggle_pause)
	overlay.layer = 20
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.055, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	menu_box = VBoxContainer.new()
	menu_box.custom_minimum_size = Vector2(650, 0)
	menu_box.add_theme_constant_override("separation", 12)
	center.add_child(menu_box)

func _clear_menu(title: String, message: String) -> void:
	pause_menu_open = false
	get_tree().paused = true
	player.call("set_move_input", Vector2.ZERO)
	get_tree().call_group("movement_joysticks", "reset")
	overlay.show()
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 36)
	menu_box.add_child(heading)
	var body := Label.new()
	body.text = message
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(650, 95)
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
	_menu_button("Settings", func(): _show_settings(_show_camp))
	_menu_button("Quit", func(): get_tree().quit())

func _cost(level: int) -> int:
	return (level + 1) * 20

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
	pause_menu_open = false
	started = true
	overlay.hide()
	get_tree().paused = false
	_update_objective()

func _pause_game() -> void:
	if game_finished or not started:
		return
	_clear_menu("HUNT PAUSED", "Progress is saved between chapters. Restarting a hunt restores its enemies and your potions.")
	pause_menu_open = true
	_menu_button("Resume", _resume)
	_menu_button("Restart hunt", _reload)
	_menu_button("Settings", func(): _show_settings(_pause_game))
	_menu_button("Quit", func(): get_tree().quit())

func _show_settings(back: Callable) -> void:
	_clear_menu("SETTINGS", "Adjust camera drag speed and sound volume. Changes apply immediately; use Save and back to keep them.")
	_settings_slider("Camera sensitivity", 0.25, 2.0, 0.05, camera_sensitivity, func(value: float):
		camera_sensitivity = value
		_apply_settings())
	_settings_slider("Sound volume", 0.0, 1.0, 0.05, sound_volume, func(value: float):
		sound_volume = value
		_apply_settings())
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
	player.set("camera_sensitivity", camera_sensitivity)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(sound_volume, 0.0001)))
	AudioServer.set_bus_mute(0, sound_volume == 0.0)

func _save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("settings", "camera_sensitivity", camera_sensitivity)
	config.set_value("settings", "sound_volume", sound_volume)
	return config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	camera_sensitivity = _setting_number(config, "camera_sensitivity", 1.0, 0.25, 2.0)
	sound_volume = _setting_number(config, "sound_volume", 0.7, 0.0, 1.0)
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
	var reward := 40 + chapter * 20
	shards += reward
	var final_hunt := chapter == CHAPTERS.size() - 1
	if final_hunt:
		completed = true
	else:
		chapter += 1
	_save_progress()
	_clear_menu("VEYRA RESTORED" if final_hunt else "LANTERN RECLAIMED", "The Tidewraith falls. Aru gathers %d Tide Shards.\n%s\n%s" % [reward, "The island is free." if final_hunt else "A new path opens deeper into the island.", notice])
	_menu_button("Return to camp", _reload)

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
		_save_progress()
		_reload())

func _reload() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _save_progress() -> void:
	var save := ConfigFile.new()
	for key in ["chapter", "shards", "blade_level", "armor_level", "completed"]:
		save.set_value("campaign", key, get(key))
	var result := save.save(SAVE_PATH)
	notice = "Progress saved." if result == OK else "Save failed. Keep the game open to retain this session."

func _load_progress() -> void:
	var save := ConfigFile.new()
	var result := save.load(SAVE_PATH)
	if result != OK:
		if result != ERR_FILE_NOT_FOUND:
			notice = "Saved progress could not be read. A temporary new journey is available."
		return
	chapter = clampi(int(save.get_value("campaign", "chapter", 0)), 0, CHAPTERS.size() - 1)
	shards = clampi(int(save.get_value("campaign", "shards", 0)), 0, 999999)
	blade_level = clampi(int(save.get_value("campaign", "blade_level", 0)), 0, 4)
	armor_level = clampi(int(save.get_value("campaign", "armor_level", 0)), 0, 4)
	completed = bool(save.get_value("campaign", "completed", false))
