extends "res://scripts/main.gd"

const SAVE_PATH := "user://campaign.cfg"
const CHAPTERS := [
	["The Silent Shore", "The western lantern has gone dark. Clear the shore and drive back the dragon's first manifestation."],
	["The Broken Grove", "The lantern keeper's trail leads through a corrupted grove. Break the tide demons' hold on the island."],
	["The Last Lantern", "The Tidewraith guards the source of the darkness. Defeat its final manifestation and restore Veyra's light."]
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

func _ready() -> void:
	_load_progress()
	super._ready()
	player.set("max_health", 100 + armor_level * 25)
	player.set("health", 100 + armor_level * 25)
	player.set("attack_damage", 1 + blade_level)
	_on_health_changed(int(player.get("health")), int(player.get("max_health")))
	_build_campaign_ui()
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
	overlay = CanvasLayer.new()
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
	get_tree().paused = true
	player.call("set_move_input", Vector2.ZERO)
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
	started = true
	overlay.hide()
	get_tree().paused = false
	status_label.text = "%s | Shore demons: %d | Potions: %d" % [CHAPTERS[chapter][0], remaining_enemies, potions]

func _pause_game() -> void:
	if game_finished or not started:
		return
	_clear_menu("HUNT PAUSED", "Progress is saved between chapters. Restarting a hunt restores its enemies and your potions.")
	_menu_button("Resume", _resume)
	_menu_button("Restart hunt", _reload)
	_menu_button("Quit", func(): get_tree().quit())

func _heal() -> void:
	if game_finished or potions <= 0 or int(player.get("health")) <= 0:
		return
	var maximum := int(player.get("max_health"))
	if int(player.get("health")) >= maximum:
		return
	potions -= 1
	player.set("health", mini(maximum, int(player.get("health")) + 50))
	_on_health_changed(int(player.get("health")), maximum)
	status_label.text = "Healing draught used | Potions: %d" % potions

func _on_enemy_defeated() -> void:
	super._on_enemy_defeated()
	if not boss_spawned:
		status_label.text = "%s | Shore demons remaining: %d" % [CHAPTERS[chapter][0], remaining_enemies]

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
