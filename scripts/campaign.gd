extends "res://scripts/main.gd"

const SAVE_PATH := "user://campaign.cfg"
const CAMPAIGN_STORE = preload("res://scripts/campaign_store.gd")
const SETTINGS_PATH := "user://settings.cfg"
const RELIC_HUNT_SCRIPT = preload("res://scripts/relic_hunt.gd")
const WORLD_STORY := "Explore Veyra. Recover three seal fragments from the beach ruins, clear the demon camps, and light the northern lantern to confront the Tidewraith. Your island progress is saved as you explore."
var world_data := CAMPAIGN_STORE.fresh_world()
var _world_ready := false
var _autosave_time := 0.0
var _autosave_thread: Thread
var _save_failed := false
var shards := 0
var blade_level := 0
var armor_level := 0
var completed := false
var overlay: CanvasLayer
var menu_box: VBoxContainer
var quest_parchment: TextureRect
var camp_menu: Control
var menu_scroll: ScrollContainer
var notice := ""
var progress_unreadable := false
var potions := 3
var herbs: Node3D
var seal_fragments: Node3D
var started := false
var camera_sensitivity := 1.0
var hud_scale := 1.0
var invert_y := false
var left_handed := false
var mobile_hud: Node
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
var keeper: Node

func _process(delta: float) -> void:
	_finish_autosave()
	if started and not game_finished:
		_update_objective()
		_autosave_time += delta
		if _autosave_time >= 5.0:
			_autosave_time = 0.0
			_start_autosave()

func _build_lantern() -> void:
	lantern = Node3D.new()
	lantern.name = "ChapterLantern"
	lantern.position = Vector3(0, 0, -20)
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
	var destination: Node3D = null
	var objective := "Wolves %d" % remaining_enemies
	if completed:
		objective = "Explore Veyra - Tidewraith defeated"
	elif boss_spawned:
		objective = "Dragon"
		destination = get_node_or_null("Tidewraith Dragon")
	elif remaining_enemies == 0 and not seal_fragments.complete():
		objective = "Seal fragments %d/3" % seal_fragments.collected_ids.size()
		destination = seal_fragments.nearest(player.global_position, INF)
	elif remaining_enemies == 0:
		objective = "Lantern"
		destination = lantern
	else:
		var nearest := INF
		for candidate in get_tree().get_nodes_in_group("lock_targets"):
			if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or candidate.get("health") <= 0:
				continue
			var distance: float = player.global_position.distance_squared_to(candidate.global_position)
			if distance < nearest:
				nearest = distance
				destination = candidate
	var guidance := ""
	if is_instance_valid(destination):
		guidance = " | " + preload("res://scripts/island_exploration.gd").direction_hint(player.global_position, destination.global_position, player._camera_pivot.global_basis)
	status_label.text = "%s%s | Potions %d" % [objective, guidance, potions]
	if player.global_position.distance_to(herbs.GROVE.CENTER) < 18.0:
		status_label.text += " | Grove complete +25 shards" if world_data.grove_reward else " | Grove %d/3" % mini(herbs.grove_count(), 3)
	if not lantern_lit:
		status_label.text += " | Seal %d/3" % seal_fragments.collected_ids.size()
		if remaining_enemies == 0:
			lantern_label.text = "LIGHT THE LANTERN" if seal_fragments.complete() else "RECOVER THE LANTERN SEAL"
	if _save_failed:
		status_label.text += " | SAVE FAILED - open camp to retry"
	relic_status.text = relic_hunt.call("progress_text")
	if is_instance_valid(keeper):
		relic_status.text += "\n" + keeper.hint(player.global_position, player._camera_pivot.global_basis)
	interact_button.text = ""
	interact_button.icon = preload("res://assets/ui/controls/lantern.svg")
	interact_button.accessibility_name = "Light lantern"
	interact_button.visible = remaining_enemies == 0 and seal_fragments.complete() and not lantern_lit
	interact_button.disabled = player.global_position.distance_to(lantern.global_position) > 2.5
	if seal_fragments.nearest(player.global_position) != null:
		interact_button.icon = preload("res://assets/ui/controls/collect.svg")
		interact_button.accessibility_name = "Collect seal fragment"
		interact_button.visible = true
		interact_button.disabled = false
	elif herbs.nearest(player.global_position) != null:
		interact_button.icon = preload("res://assets/ui/controls/collect.svg")
		interact_button.accessibility_name = "Collect herb"
		interact_button.visible = true
		interact_button.disabled = false

func _interact_lantern() -> void:
	if not started or game_finished or get_tree().paused or remaining_enemies > 0 or not seal_fragments.complete() or lantern_lit:
		return
	if player.global_position.distance_to(lantern.global_position) > 2.5:
		return
	lantern_lit = true
	lantern_flame.show()
	lantern_label.text = "LANTERN RESTORED"
	_spawn_boss()
	_save_progress()
	_update_objective()

class PauseOverlay extends CanvasLayer:
	signal pause_requested
	signal journal_requested
	signal interaction_requested

	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed(&"interact"):
			interaction_requested.emit()
			get_viewport().set_input_as_handled()

	func _unhandled_key_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q:
			journal_requested.emit()
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			pause_requested.emit()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _world_ready:
		_quit_world()
		return
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
	herbs = preload("res://scripts/herbal_plants.gd").new()
	herbs.name = "HerbalPlants"
	add_child(herbs)
	_load_progress()
	# Retain the retired spawn ID as cleared so version-2 quest saves stay compatible.
	if 5 not in world_data.cleared:
		world_data.cleared.append(5)
	environment_chapter = 0
	super._ready()
	_load_settings()
	player.set("max_health", 100 + armor_level * 25)
	player.set("health", 100 + armor_level * 25)
	player.set("attack_damage", 1 + blade_level)
	_on_health_changed(int(player.get("health")), int(player.get("max_health")))
	_build_campaign_ui()
	mobile_hud = preload("res://scripts/mobile_hud.gd").new()
	add_child(mobile_hud)
	_apply_settings()
	find_child("ControlsHint", true, false).hide()
	_build_lantern()
	var exploration := preload("res://scripts/island_exploration.gd").new()
	exploration.name = "IslandExploration"
	exploration.player = player
	add_child(exploration)
	relic_hunt = RELIC_HUNT_SCRIPT.new()
	relic_hunt.set("player", player)
	add_child(relic_hunt)
	keeper = preload("res://scripts/shore_keeper.gd").new()
	add_child(keeper)
	seal_fragments = preload("res://scripts/beach_seals.gd").new()
	add_child(seal_fragments)
	_restore_world()
	get_tree().auto_accept_quit = false
	_world_ready = true
	relic_hunt.progress_changed.connect(_world_changed)
	exploration.progress_changed.connect(_world_changed)
	_show_camp()

func _build_enemies() -> void:
	remaining_enemies = 0
	for index in range(6):
		if index in world_data.cleared:
			continue
		remaining_enemies += 1
		var enemy: CharacterBody3D = ENEMY_SCRIPT.new()
		enemy.name = "CampDemon%d" % index
		var camp: Vector3 = preload("res://scripts/island_exploration.gd").CAMPS[index % 3]
		enemy.position = camp + Vector3(-2 if index < 3 else 2, 0, 0)
		enemy.set("target", player)
		enemy.set("health", 18)
		enemy.set("kind", index % 3)
		enemy.connect("defeated", _defeat_world_enemy.bind(index))
		add_child(enemy)

func _defeat_world_enemy(index: int) -> void:
	if index in world_data.cleared:
		return
	world_data.cleared.append(index)
	_on_enemy_defeated()
	_save_progress()

func _spawn_boss() -> void:
	if completed or boss_spawned:
		return
	super._spawn_boss()
	var dragon := get_node_or_null("Tidewraith Dragon")
	if dragon != null:
		dragon.set("max_health", 62)
		dragon.set("health", 62)
		_on_boss_health_changed(62, 62)

func _build_campaign_ui() -> void:
	var controls_layer := CanvasLayer.new()
	add_child(controls_layer)
	var controls := preload("res://scripts/safe_area.gd").new()
	controls_layer.add_child(controls)
	var pause_button := _make_button("", Vector2.ZERO, Vector2(60, 60))
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -80
	pause_button.offset_right = -20
	pause_button.offset_top = 20
	pause_button.offset_bottom = 80
	_set_action_icon(pause_button, "pause", "Pause")
	pause_button.name = "PauseButton"
	pause_button.pressed.connect(_pause_game)
	controls.add_child(pause_button)
	var heal_button := _make_button("", Vector2.ZERO, Vector2(60, 60))
	heal_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	heal_button.offset_left = -148
	heal_button.offset_right = -88
	heal_button.offset_top = 20
	heal_button.offset_bottom = 80
	_set_action_icon(heal_button, "potion", "Heal")
	heal_button.name = "HealButton"
	heal_button.pressed.connect(_heal)
	controls.add_child(heal_button)
	var map_button := _make_button("",Vector2.ZERO,Vector2(44,44))
	map_button.name="MapButton"
	_set_action_icon(map_button,"map","Island map")
	map_button.pressed.connect(_show_island_map)
	controls.add_child(map_button)
	var camp_button := _make_button("",Vector2.ZERO,Vector2(44,44))
	camp_button.name="CampButton"
	_set_action_icon(camp_button,"camp","Equipment and camp")
	camp_button.pressed.connect(_show_camp)
	controls.add_child(camp_button)
	var quest_button := _make_button("", Vector2.ZERO, Vector2(48, 48))
	quest_button.name = "QuestScrollButton"
	quest_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	quest_button.position = Vector2(28, 136)
	quest_button.size = Vector2(48, 48)
	quest_button.icon = preload("res://assets/ui/quest_scroll.svg")
	quest_button.expand_icon = true
	quest_button.add_theme_constant_override("icon_max_width", 22)
	quest_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	quest_button.add_theme_font_size_override("font_size", 9)
	quest_button.tooltip_text = "Quest scroll: objectives, rewards and progress [Q]"
	quest_button.pressed.connect(_show_journal)
	controls.add_child(quest_button)
	relic_status = Label.new()
	relic_status.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.05, 0.95))
	relic_status.add_theme_constant_override("outline_size", 4)
	relic_status.anchor_right = 1.0
	relic_status.offset_left = 30
	relic_status.offset_right = -210
	relic_status.offset_top = 84
	relic_status.offset_bottom = 126
	relic_status.clip_text = true
	relic_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	relic_status.add_theme_font_size_override("font_size", 15)
	relic_status.add_theme_color_override("font_color", Color(0.95, 0.8, 0.45))
	controls.add_child(relic_status)
	interact_button = _make_button("", Vector2(-204, -188), Vector2(-124, -108))
	interact_button.name = "InteractButton"
	interact_button.expand_icon = true
	interact_button.add_theme_constant_override("icon_max_width", 38)
	interact_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	interact_button.pressed.connect(_interact_world)
	interact_button.hide()
	controls.add_child(interact_button)
	overlay = PauseOverlay.new()
	overlay.connect("pause_requested", _toggle_pause)
	overlay.connect("journal_requested", _toggle_journal)
	overlay.connect("interaction_requested", _interact_world)
	overlay.layer = 20
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.055, 1.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	quest_parchment = TextureRect.new()
	quest_parchment.texture = preload("res://assets/ui/quest_parchment.jpg")
	quest_parchment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	quest_parchment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parchment_shader := Shader.new()
	parchment_shader.code = """
shader_type canvas_item;
void fragment() {
 vec4 paper = texture(TEXTURE, UV);
 float outside = step(0.96, min(paper.r, min(paper.g, paper.b)));
 COLOR = vec4(paper.rgb, 1.0 - outside);
}
"""
	var parchment_material := ShaderMaterial.new()
	parchment_material.shader = parchment_shader
	quest_parchment.material = parchment_material
	quest_parchment.hide()
	overlay.add_child(quest_parchment)
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
	camp_menu = preload("res://scripts/camp_menu.gd").new()
	camp_menu.name = "CampMenu"
	camp_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_safe.add_child(camp_menu)
	camp_menu.play_requested.connect(_resume)
	camp_menu.blade_requested.connect(func(): _upgrade(true))
	camp_menu.armor_requested.connect(func(): _upgrade(false))
	camp_menu.quests_requested.connect(_camp_journal)
	camp_menu.guides_requested.connect(_show_field_guide)
	camp_menu.settings_requested.connect(func(): _show_settings(_show_camp))
	camp_menu.reset_requested.connect(_confirm_reset)
	camp_menu.quit_requested.connect(_quit_world)
	camp_menu.hide()
	menu_safe.resized.connect(_layout_menu)
	_layout_menu()

func _layout_menu() -> void:
	if journal_open:
		var screen: Vector2 = menu_scroll.get_parent().size
		var width := minf(820.0, screen.x - 12.0)
		quest_parchment.position = menu_scroll.get_parent().position + Vector2((screen.x - width) * 0.5, 4)
		quest_parchment.size = Vector2(width, screen.y - 8)
		menu_scroll.offset_left = (screen.x - width) * 0.5 + width * 0.17
		menu_scroll.offset_right = -menu_scroll.offset_left
		menu_scroll.offset_top = screen.y * 0.19
		menu_scroll.offset_bottom = -screen.y * 0.17
		return
	var margin := maxf(24.0, (menu_scroll.get_parent().size.x - 700.0) * 0.5)
	menu_scroll.offset_left = margin
	menu_scroll.offset_right = -margin
	menu_scroll.offset_top = 24
	menu_scroll.offset_bottom = -24

func _clear_menu(title: String, message: String, save_world := true) -> void:
	if _world_ready and save_world:
		_save_progress()
	camp_menu.hide()
	menu_scroll.show()
	journal_open = false
	quest_parchment.hide()
	_layout_menu()
	pause_menu_open = false
	get_tree().paused = true
	player.call("set_move_input", Vector2.ZERO)
	player.call("clear_target_lock")
	player.call("cancel_touch_camera")
	player.call("end_guard")
	player.set("_burst_requested", false)
	player.call("cancel_swing")
	get_tree().call_group("movement_joysticks", "reset")
	get_tree().call_group("attack_gestures", "cancel_hold")
	get_tree().call_group("gameplay_buttons", "cancel_touch")
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
	button.add_theme_stylebox_override("normal", _button_style(Color(0.06, 0.2, 0.22, 0.9)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.1, 0.34, 0.33, 0.94)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.3, 0.48, 0.34, 0.95)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.06, 0.11, 0.13, 0.8)))
	button.disabled = disabled
	button.pressed.connect(action)
	menu_box.add_child(button)

func _show_camp() -> void:
	_clear_menu("VEIL OF VEYRA", "")
	menu_scroll.hide()
	camp_menu.show()
	var stage := "Recover the beach ruins seal fragments.\nClear the camps to restore the lantern."
	if lantern_lit:
		stage = "The seal is broken.\nDefeat the Tidewraith at the northern ruins."
	elif remaining_enemies == 0:
		stage = "The camps are quiet.\nRecover the beach seal to light the lantern." if not seal_fragments.complete() else "The seal is whole.\nLight the northern lantern to break the curse."
	camp_menu.configure(shards, blade_level, armor_level, _cost(blade_level), _cost(armor_level), completed, notice, stage)

func _camp_journal() -> void:
	started = true
	pause_menu_open = true
	_show_journal()

func _show_field_guide() -> void:
	_clear_menu("FIELD GUIDE", "Prepare for the journey. Learn combat techniques, explore optional quests, or view the game's art credits.")
	_menu_button("Enemy guide", _show_enemy_guide)
	_menu_button("Heavy Attack guide", _show_heavy_guide)
	_menu_button("Spirit Burst guide", _show_burst_guide)
	_menu_button("Keeper's request (+20 bonus shards)", _show_keeper_request)
	_menu_button("Art credits", _show_art_credits)
	_menu_button("Back to camp", _show_camp)

func _cost(level: int) -> int:
	return (level + 1) * 20

func _show_keeper_request() -> void:
	_clear_menu("THE KEEPER'S REQUEST", "Three relics remain scattered around this island. Walk near each golden relic to recover it. Find all three and defeat the dragon to earn 20 bonus shards. The relics may be collected before or after victory.\n\nThis quest is optional. Collected relics are saved.")
	_menu_button("Back to camp", _show_camp)

func _show_burst_guide() -> void:
	_clear_menu("SPIRIT BURST", "Each sword swing that damages an enemy grants 25 spirit. Missing grants nothing; hitting a crowd still grants only 25.\n\nAt 100 spirit, press L or BURST to spend it on a 3-metre area attack dealing three times your blade damage. It interrupts ordinary enemies but not the dragon.\n\nSpirit resets when you reopen the island. An empty burst still spends the charge.")
	_menu_button("Back to camp", _show_camp)

func _show_enemy_guide() -> void:
	_clear_menu("KNOW YOUR ENEMY", "LOCK ON: press Tab or tap the crosshair to face a visible enemy within 14 metres. A visible boss has initial priority; otherwise the nearest enemy is selected. Hold the crosshair for 0.4 seconds to cycle targets. Tap the crosshair again to release. Solid obstruction, camera swipes, menus, death or leaving range also release lock.\n\nEMBER WOLF: a corrupted wolf. Balanced movement and melee damage.\n\nASH STALKER: a smaller, fast and fragile wolf. Its short warning leads to a lighter strike.\n\nDIRE WARG: a large, tough wolf. Its wide attack deals heavy damage after a longer warning.\n\nWolves patrol close to their camps. A yellow !, a low growl and a snarl mean they detected you. These large demons crouch before biting and lunge on contact. They chase nearby hunters, then return home if pulled too far. Leave their warning circles or interrupt their windups with a sword hit.\n\nTIDEWRAITH DRAGON: move aside from breath and dodge sideways from charges. At half health it becomes ENRAGED: shorter warnings and recovery, faster charges. Sword hits do not interrupt the dragon.")
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
	quest_parchment.hide()
	_layout_menu()
	pause_menu_open = false
	started = true
	relic_hunt.set("active", true)
	overlay.hide()
	get_tree().paused = false
	_update_objective()

func _pause_game() -> void:
	if game_finished or not started:
		return
	_clear_menu("EXPLORATION PAUSED", "Island progress saves on quest actions, every five seconds, and when opening menus. Unfinished enemies and the dragon recover health after reloading.")
	pause_menu_open = true
	_menu_button("Resume", _resume)
	_menu_button("Quest Journal [Q]", _show_journal)
	_menu_button("Island Map", _show_island_map)
	_menu_button("Save and return to camp", _show_camp)
	_menu_button("Settings", func(): _show_settings(_pause_game))
	_menu_button("Quit", _quit_world)

func _show_settings(back: Callable) -> void:
	_clear_menu("SETTINGS", "Adjust the camera, sound, and graphics. Changes apply immediately; use Save and back to keep them.")
	_menu_button("Controls",func(): _show_controls(func(): _show_settings(back)))
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
	_settings_slider("Control size",0.85,1.2,0.05,hud_scale,func(value: float):
		hud_scale=value
		_apply_settings())
	for option in ["Invert vertical camera"]:
		var toggle := CheckButton.new()
		toggle.name = "InvertYToggle" if option == "Invert vertical camera" else "LeftHandedToggle"
		toggle.text = option
		toggle.custom_minimum_size.y=48
		toggle.button_pressed = invert_y if option == "Invert vertical camera" else left_handed
		toggle.toggled.connect(func(enabled: bool):
			if option == "Invert vertical camera": invert_y=enabled
			else: left_handed=enabled
			_apply_settings())
		menu_box.add_child(toggle)
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

func _show_controls(back: Callable) -> void:
	_clear_menu("CONTROLS", "Choose your layout, then fine-tune individual controls. Changes in Customize HUD are kept only when you save.")
	_menu_button("Customize HUD",func(): mobile_hud.open_editor(func(): _show_controls(back)))
	_menu_button("Back",back)

func _apply_settings() -> void:
	Engine.max_fps = frame_limit
	for child in get_children():
		if child is DirectionalLight3D:
			child.shadow_enabled = shadows_enabled
	player.set("camera_sensitivity", camera_sensitivity)
	player.set("invert_y", invert_y)
	player.set("left_handed_controls",left_handed or (is_instance_valid(mobile_hud) and mobile_hud.profile.preset=="Left-Handed"))
	if is_instance_valid(mobile_hud):
		mobile_hud.hud_scale=hud_scale
		mobile_hud.left_handed=left_handed
		mobile_hud.refresh()
	player.call("set_camera_distance", camera_distance)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(sound_volume, 0.0001)))
	AudioServer.set_bus_mute(0, sound_volume == 0.0)

func _save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("settings", "camera_sensitivity", camera_sensitivity)
	config.set_value("settings","hud_scale",hud_scale)
	config.set_value("settings","invert_y",invert_y)
	config.set_value("settings","left_handed",left_handed)
	config.set_value("settings", "camera_distance", camera_distance)
	config.set_value("settings", "sound_volume", sound_volume)
	config.set_value("settings", "shadows_enabled", shadows_enabled)
	config.set_value("settings", "frame_limit", frame_limit)
	return config.save(SETTINGS_PATH)

func _load_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	camera_sensitivity = _setting_number(config, "camera_sensitivity", 1.0, 0.25, 2.0)
	hud_scale = _setting_number(config,"hud_scale",1.0,0.85,1.2)
	var saved_invert: Variant = config.get_value("settings","invert_y",false)
	invert_y = saved_invert if saved_invert is bool else false
	var saved_hand: Variant = config.get_value("settings","left_handed",false)
	left_handed = saved_hand if saved_hand is bool else false
	if FileAccess.file_exists("user://hud_profile.cfg"): left_handed=false
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
	if not started or get_tree().paused or game_finished or potions <= 0 or int(player.get("health")) <= 0:
		return
	var maximum := int(player.get("max_health"))
	if int(player.get("health")) >= maximum:
		return
	potions -= 1
	player.set("health", mini(maximum, int(player.get("health")) + 50))
	_on_health_changed(int(player.get("health")), maximum)
	_update_objective()
	_save_progress()

func _on_enemy_defeated() -> void:
	remaining_enemies = maxi(0, remaining_enemies - 1)
	if remaining_enemies == 0 and not game_finished:
		lantern_label.text = "LIGHT THE LANTERN" if seal_fragments.complete() else "RECOVER THE LANTERN SEAL"
	_update_objective()

func _on_boss_defeated() -> void:
	if completed:
		return
	completed = true
	boss_health_bar.hide()
	boss_name_label.hide()
	shards = mini(999999, shards + 80)
	_claim_optional_rewards()
	var saved := _save_progress()
	_clear_menu("VEYRA RESTORED", "The Tidewraith has fallen. You earned 80 Tide Shards. Continue exploring this island and finish any remaining quests.\n" + notice, false)
	_menu_button("Continue exploring", _resume)
	if not saved:
		_menu_button("Retry save", _retry_save_and_return)

func _retry_save_and_return() -> void:
	if _save_progress():
		_show_camp()
	else:
		_show_save_failure()

func _show_save_failure() -> void:
	_clear_menu("PROGRESS NOT SAVED", notice, false)
	_menu_button("Retry save and return", _retry_save_and_return)
	_menu_button("Return without saving this session", _reload)

func _on_player_defeated() -> void:
	super._on_player_defeated()
	_clear_menu("RETURN TO YOUR WAYSTONE", "Return to your bound waystone. Cleared camps, collected items and upgrades remain saved; remaining enemies recover health.")
	_menu_button("Return to waystone", _reload)
	_menu_button("Quit", _quit_world)

func _confirm_reset() -> void:
	_clear_menu("BEGIN A NEW JOURNEY?", "This replaces your saved island progress, shards, and upgrades.")
	_menu_button("Keep my journey", _show_camp)
	_menu_button("Reset progress", _reset_world)

func _reset_world() -> void:
	_finish_autosave(true)
	var data := CAMPAIGN_STORE.DEFAULTS.duplicate()
	data.world_data = CAMPAIGN_STORE.fresh_world()
	var error: Error = CAMPAIGN_STORE.save_progress(data)
	if error == OK:
		_reload()
	else:
		_clear_menu("NEW JOURNEY NOT SAVED", "Your existing world has been kept. Retry when saving is available.", false)
		_menu_button("Retry new journey", _reset_world)
		_menu_button("Keep my journey", _show_camp)


func _reload() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# Capture only plain data on the main thread; the worker never touches the scene.
func _progress_snapshot(capture := true) -> Dictionary:
	if capture and _world_ready:
		_capture_world()
	var data := {}
	for key in ["shards", "blade_level", "armor_level", "completed", "world_data"]:
		data[key] = get(key)
	return data.duplicate(true)

func _write_progress(data: Dictionary) -> Error:
	return CAMPAIGN_STORE.save_progress(data)

func _save_result(result: Error) -> bool:
	_save_failed = result != OK
	notice = "Progress saved." if result == OK else "Save failed. Keep the game open to retain this session."
	return result == OK

func _start_autosave() -> void:
	if progress_unreadable or _autosave_thread != null:
		return
	var snapshot := _progress_snapshot()
	_autosave_thread = Thread.new()
	var error := _autosave_thread.start(_write_progress.bind(snapshot), Thread.PRIORITY_LOW)
	if error != OK:
		_autosave_thread = null
		_save_result(error)

func _finish_autosave(wait := false) -> void:
	if _autosave_thread == null or (not wait and _autosave_thread.is_alive()):
		return
	var result: Error = _autosave_thread.wait_to_finish()
	_autosave_thread = null
	_save_result(result)

func _save_progress(capture := true) -> bool:
	# Serialize quest/menu/exit writes after an in-flight autosave, keeping the newest state.
	_finish_autosave(true)
	if progress_unreadable:
		notice = "Save protected: unreadable progress was not overwritten. Use New journey to reset it."
		return false
	return _save_result(_write_progress(_progress_snapshot(capture)))

func _exit_tree() -> void:
	# A scene reload must not leave a worker writing over the next journey.
	_finish_autosave(true)

func _load_progress() -> void:
	_finish_autosave(true)
	var result: Dictionary = CAMPAIGN_STORE.load_progress()
	progress_unreadable = result.error != OK
	if progress_unreadable:
		notice = "Progress and backup could not be read. Temporary play is available; saving is blocked until New journey."
		return
	for key in result.data:
		set(key, result.data[key])
	if result.get("migrated", false):
		notice = "Journey updated. Saved island progress, shards and upgrades are retained."
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
	var light := "COMPLETE" if lantern_lit else ("READY - approach within 2.5 m and press E / LIGHT" if cleared and seal_fragments.complete() else "LOCKED - recover all 3 seal fragments and clear the demon camps")
	var dragon := "ACTIVE - defeat the Tidewraith Dragon" if boss_spawned else "LOCKED - restore the lantern first"
	if completed:
		dragon = "COMPLETE - continue exploring Veyra"
	return "%s\n\nSEAL FRAGMENTS: %d/3 recovered\n\n1. Clear the camps: %s\n\n2. Restore the lantern: %s\n\n3. Defeat the Tidewraith: %s\n\nOPTIONAL - RELICS\n%s\nFind all three relics and defeat the dragon for a one-time 20-shard reward.\n\n%s\n\nPROGRESS\nCleared enemies, collected plants/relics, waystones, health and potions are saved. You can continue exploring after the dragon falls. Unfinished enemies recover health on reload. Death returns you to the bound waystone.\n\nCONTROLS\nWASD / joystick: move. J / ATTACK: sword. Hold ATTACK / H: charged strike. K / DODGE: evade. Space / jump icon: jump. E / COLLECT / LIGHT: interact." % [WORLD_STORY, seal_fragments.collected_ids.size(), wave, light, dragon, relic_hunt.call("progress_text"), keeper.journal_text()] + "\n\nBoundary: shallow water blocks deep-sea access. Waystone: " + get_node("IslandExploration").rescue_name()


func _show_journal() -> void:
	if not started or game_finished or (get_tree().paused and not pause_menu_open):
		return
	_clear_menu("QUESTS OF VEYRA", _journal_text() + "\n\n" + seal_fragments.journal_text() + "\n\n" + herbs.journal_text() + "\n\n" + herbs.grove_journal(world_data.grove_reward))
	journal_open = true
	pause_menu_open = true
	_menu_button("Return to hunt [Q / Esc]", _resume)
	menu_box.move_child(menu_box.get_child(menu_box.get_child_count() - 1), 1)
	if not keeper.accepted:
		_menu_button("Accept: The Western Watch (+15 shards)", _accept_scroll_quest)
		menu_box.move_child(menu_box.get_child(menu_box.get_child_count() - 1), 2)
	elif not keeper.reported:
		_menu_button("Complete: The Western Watch", _complete_scroll_quest, keeper.remaining() > 0)
		menu_box.move_child(menu_box.get_child(menu_box.get_child_count() - 1), 2)
	_menu_button("Pause menu", _pause_game)
	quest_parchment.show()
	_layout_menu()
	for control in menu_box.get_children():
		if control is Label:
			control.add_theme_font_override("font", preload("res://assets/ui/fonts/Cinzel.ttf") if control == menu_box.get_child(0) else preload("res://assets/ui/fonts/CrimsonText-Regular.ttf"))
			control.add_theme_color_override("font_color", Color("352015"))
			control.add_theme_font_size_override("font_size", 25 if control == menu_box.get_child(0) else 24)
			control.add_theme_constant_override("line_spacing", 5)
		elif control is Button:
			control.add_theme_font_override("font", preload("res://assets/ui/fonts/Cinzel.ttf"))
			control.add_theme_font_size_override("font_size", 16)
			control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			control.add_theme_stylebox_override("normal", _button_style(Color("61442d")))
			control.add_theme_stylebox_override("hover", _button_style(Color("84603c")))
			control.add_theme_stylebox_override("pressed", _button_style(Color("473020")))
func _show_island_map() -> void:
	if not started or game_finished or (get_tree().paused and not pause_menu_open):
		return
	var exploration = get_node("IslandExploration")
	var map = preload("res://scripts/island_map.gd").new()
	map.name = "IslandMap"
	map.player_position = player.global_position
	map.player_heading = player.global_rotation.y
	map.bound_waystone = exploration.checkpoint_index
	map.discovered = exploration.discovered.duplicate()
	for enemy in get_tree().get_nodes_in_group("lock_targets"):
		if enemy.get_script() != ENEMY_SCRIPT or enemy.health <= 0 or enemy.is_queued_for_deletion():
			continue
		for index in range(3):
			if enemy._home.distance_to(exploration.CAMPS[index]) < 6.0:
				map.camps_cleared[index] = false
	var legend := "Cyan diamond: Tideseal Ruins (3 fragments needed for the lantern). Green leaf: Moonleaf Grove (gather 3 grove flowers for 25 shards). Grey triangles: rolling hills. Open QUEST to accept and complete the Western Watch bounty.\nCyan arrow: you and your facing direction. Red camp: wolves remain. Green camp: cleared. Gold square: discovered; grey square: undiscovered; white square: bound.\nWaystones: 1 Beach, 2 Forest, 3 Ruins. North is at the top.\nBoundary: shallow water blocks deep-sea access. Waystone: %s.\nLantern at waystone 3: %s." % [exploration.rescue_name(), "LIT" if lantern_lit else ("READY" if remaining_enemies == 0 and seal_fragments.complete() else "LOCKED - camps and seal fragments required")]
	if boss_spawned:
		legend += " The dragon is at the ruins."
	legend += "\n\nTRAILS\nFrom Tideseal Ruins, follow the woodland trail north past Western Rise to the lantern ruins. The north-east path reaches Ancient Grove (gold ring); its eastern trail returns to the forest camp. Moonleaf Grove remains the optional flower clearing on the south-east trail."
	for index in range(3):
		legend += "\n%s camp: %s" % [["West", "Forest", "Ruins" ][index], "CLEARED" if map.camps_cleared[index] else "WOLVES REMAIN"]
	legend += "\n\nFAST TRAVEL\nVisit a waystone to discover it, then choose a destination below. Enemies within 14 m of either end block travel; an active dragon blocks all travel. Discovered waystones remain saved. Travel does not restore health, stamina or potions."
	_clear_menu("ISLAND MAP", legend)
	pause_menu_open = true
	_menu_button("Return to hunt [Esc]", _resume)
	menu_box.move_child(menu_box.get_child(menu_box.get_child_count() - 1), 1)
	menu_box.add_child(map)
	menu_box.move_child(map, 2)
	for index in range(3):
		var reason: String = exploration.travel_block_reason(index)
		var caption: String = "Travel to " + ["Beach", "Forest", "Ruins"][index]
		if not reason.is_empty():
			caption += " - " + reason
		_menu_button(caption, _travel_waystone.bind(index), not reason.is_empty())
		# Destinations precede the long legend, with Resume always first.
		menu_box.move_child(menu_box.get_child(menu_box.get_child_count() - 1), 3 + index)
	_menu_button("Pause menu", _pause_game)
func _interact_world() -> void:
	if not started or game_finished or get_tree().paused or player.health <= 0:
		return
	if seal_fragments.collect(player.global_position):
		_save_progress()
		_update_objective()
		return
	if herbs.collect(player.global_position):
		potions += 1
		_claim_optional_rewards()
		_save_progress()
		_update_objective()
		return
	_interact_lantern()

func _show_heavy_guide() -> void:
	_clear_menu("HEAVY ATTACK", "Hold the sword button for 0.4 seconds, or press H, for a committed heavy strike. Tap and release the sword button for a normal attack. It costs 40 stamina immediately and hits after a 0.6-second charge, dealing four times blade damage in a 2.6-metre forward arc.\n\nMovement slows during the 1.1-second attack and stamina recovery stops. The orange ground arc shows your strike direction. Ordinary wolves stagger for 0.65 seconds; the dragon does not stagger.\n\nDodge, taking damage, or opening a menu cancels the pending hit. Spent stamina is not refunded. Missing still costs stamina. A connected strike grants 25 spirit and resets the normal combo.")
	_menu_button("Back to camp", _show_camp)

func _travel_waystone(index: int) -> void:
	if not started or game_finished or not pause_menu_open or not get_tree().paused:
		return
	if get_node("IslandExploration").travel_to(index):
		_resume()
	else:
		_show_island_map()

func _accept_scroll_quest() -> void:
	if not journal_open or not started or game_finished:
		return
	keeper.accept()
	_save_progress()
	_show_journal()

func _complete_scroll_quest() -> void:
	if not journal_open or not started or game_finished:
		return
	keeper.report()
	_claim_optional_rewards()
	_save_progress()
	_show_journal()


func _show_art_credits() -> void:
	_clear_menu("ART CREDITS", "Charcoal Black Dark Dragon by Pigcraft (@s8819296)\nCC BY 4.0 - creativecommons.org/licenses/by/4.0\nSource: sketchfab.com/3d-models/charcoal-black-dark-dragon-25c51b198dd54e538f62569d52f61d8e\nModified: mesh reduction, UV consolidation, rig and combat animations.\n\nDire Wolf by Literock Studios.\nHero art by Quaternius (CC0).\nEnvironment textures and scans by Poly Haven (CC0).")
	_menu_button("Back to camp", _show_camp)


func _capture_world() -> void:
	world_data.herbs = herbs.collected_ids.duplicate()
	world_data.seal_fragments = seal_fragments.collected_ids.duplicate()
	world_data.relics = relic_hunt.collected_ids.duplicate()
	var exploration = get_node("IslandExploration")
	world_data.discovered = exploration.discovered.duplicate()
	world_data.checkpoint = exploration.checkpoint_index
	world_data.lantern = lantern_lit
	world_data.position = player.global_position
	world_data.health = int(player.health)
	world_data.potions = potions
	world_data.accepted = keeper.accepted
	world_data.reported = keeper.reported

func _restore_world() -> void:
	herbs.restore(world_data.herbs)
	seal_fragments.restore(world_data.seal_fragments)
	relic_hunt.restore(world_data.relics)
	var exploration = get_node("IslandExploration")
	exploration.discovered.assign(world_data.discovered)
	if world_data.checkpoint >= 0:
		exploration.bind_waystone(world_data.checkpoint)
	keeper.accepted = world_data.accepted
	keeper.reported = world_data.reported
	potions = world_data.potions
	player.health = world_data.health
	player.global_position = world_data.position
	# Relocate old saves that lie beyond the new shallow-water boundary wall.
	var terrain_script = preload("res://scripts/island_terrain.gd")
	var flat := Vector2(player.global_position.x, player.global_position.z)
	if flat.length() > 0.01:
		var angle := atan2(flat.y, flat.x)
		var coast: float = terrain_script.coast_radius(angle, terrain_script.SHALLOW_WATER_BASE)
		# Preserve normal positions, including the capsule's resting contact with the wall.
		if flat.length() > coast - 0.4:
			var safe_radius := coast - 1.0
			player.global_position = Vector3(cos(angle) * safe_radius, 0, sin(angle) * safe_radius)
	# Expanded land and new hills can cover a formerly valid saved beach position.
	var ground_height: float = terrain_script.height_at(Vector2(player.position.x,player.position.z))
	if player.position.y < ground_height - 0.25:
		player.position.y = ground_height + 0.1
	if player.health <= 0:
		player.health = player.max_health
		player.global_position = player.rescue_position
	player._camera_pivot.global_position = player.global_position + Vector3(0,1.2,0)
	_on_health_changed(player.health, player.max_health)
	lantern_lit = world_data.lantern
	if lantern_lit:
		lantern_flame.show()
		lantern_label.text = "LANTERN RESTORED"
		if not completed:
			_spawn_boss()
	elif remaining_enemies == 0:
		lantern_label.text = "LIGHT THE LANTERN" if seal_fragments.complete() else "RECOVER THE LANTERN SEAL"

func _claim_optional_rewards() -> void:
	if herbs.grove_count() >= herbs.GROVE_GOAL and not world_data.grove_reward:
		shards = mini(999999, shards + herbs.GROVE_REWARD)
		world_data.grove_reward = true
	if not completed:
		return
	if relic_hunt.collected == 3 and not world_data.relic_reward:
		shards = mini(999999, shards + 20)
		world_data.relic_reward = true
	if keeper.reported and not world_data.bounty_reward:
		shards = mini(999999, shards + 15)
		world_data.bounty_reward = true

func _world_changed() -> void:
	if _world_ready:
		_claim_optional_rewards()
		_save_progress()

func _quit_world() -> void:
	if _save_progress():
		get_tree().quit()
	else:
		_show_save_failure()
