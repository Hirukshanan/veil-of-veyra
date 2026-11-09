extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")
const BOSS_SCRIPT = preload("res://scripts/boss.gd")
const ENVIRONMENT_SCRIPT = preload("res://scripts/chapter_environment.gd")
var environment_chapter := 0

var player: CharacterBody3D
var status_label: Label
var health_label: Label
var boss_name_label: Label
var boss_health_bar: ProgressBar
var remaining_enemies := 0
var boss_spawned := false
var game_finished := false


class IslandJoystick extends Control:
	signal value_changed(value: Vector2)

	var _touch_index := -1
	var _value := Vector2.ZERO

	func _ready() -> void:
		add_to_group("movement_joysticks")
		mouse_filter = Control.MOUSE_FILTER_STOP
		queue_redraw()

	func reset() -> void:
		_touch_index = -1
		_set_value(Vector2.ZERO)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and _touch_index == -1:
				_touch_index = event.index
				_update_value(event.position)
				accept_event()
			elif not event.pressed and event.index == _touch_index:
				_touch_index = -1
				_set_value(Vector2.ZERO)
				accept_event()
		elif event is InputEventScreenDrag and event.index == _touch_index:
			_update_value(event.position)
			accept_event()

	func _update_value(point: Vector2) -> void:
		var radius := minf(size.x, size.y) * 0.34
		_set_value(((point - size * 0.5) / radius).limit_length(1.0))

	func _set_value(value: Vector2) -> void:
		_value = value
		value_changed.emit(value)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, minf(size.x, size.y) * 0.44, Color(0.04, 0.12, 0.16, 0.46))
		draw_circle(center, minf(size.x, size.y) * 0.34, Color(0.4, 0.78, 0.72, 0.23))
		draw_circle(center + _value * minf(size.x, size.y) * 0.29, minf(size.x, size.y) * 0.17, Color(0.78, 0.93, 0.83, 0.8))


func _ready() -> void:
	_setup_input()
	_build_island()
	_build_lighting()
	_build_decor()
	_build_player()
	_build_enemies()
	_build_hud()


func _setup_input() -> void:
	_bind_keys(&"move_left", [KEY_A, KEY_LEFT])
	_bind_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_bind_keys(&"move_forward", [KEY_W, KEY_UP])
	_bind_keys(&"move_back", [KEY_S, KEY_DOWN])
	_bind_keys(&"attack", [KEY_J])
	_bind_keys(&"heavy_attack", [KEY_H])
	_bind_keys(&"sprint", [KEY_SHIFT])
	_bind_keys(&"dodge", [KEY_K, KEY_SPACE])
	_bind_keys(&"target_lock", [KEY_TAB])
	_bind_keys(&"spirit_burst", [KEY_L])


func _bind_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


func _build_island() -> void:
	var water := MeshInstance3D.new()
	water.name = "Sea"
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(2000, 2000)
	water.mesh = water_mesh
	water.position.y = -1.45
	var sea_material := ShaderMaterial.new()
	sea_material.shader = preload("res://assets/environment/coastal_water.gdshader")
	water.material_override = sea_material
	add_child(water)

	var island := StaticBody3D.new()
	island.name = "Island"
	island.position.y = -1.0
	add_child(island)

	var island_mesh := MeshInstance3D.new()
	island_mesh.name = "Surface"
	var terrain := preload("res://scripts/island_terrain.gd").ground()
	island_mesh.mesh = terrain
	island_mesh.material_override = preload("res://scripts/island_terrain.gd").material(environment_chapter)
	island.add_child(island_mesh)

	var island_collision := CollisionShape3D.new()
	island_collision.shape = terrain.create_trimesh_shape()
	island.add_child(island_collision)


func _build_lighting() -> void:
	var environment := Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = [Color(0.12, 0.34, 0.58), Color(0.10, 0.22, 0.28), Color(0.12, 0.07, 0.22)][environment_chapter]
	sky_material.sky_horizon_color = [Color(0.76, 0.83, 0.78), Color(0.55, 0.68, 0.59), Color(0.68, 0.36, 0.29)][environment_chapter]
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	sky_material.ground_bottom_color = ENVIRONMENT_SCRIPT.SEA_COLORS[environment_chapter]
	sky_material.sky_curve = 0.2
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	environment.background_color = Color(0.035, 0.075, 0.12)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.52, 0.65, 0.72)
	environment.ambient_light_energy = 0.45
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 28, 0)
	sun.light_color = [Color(1.0, 0.88, 0.7), Color(0.75, 0.9, 0.83), Color(1.0, 0.67, 0.48)][environment_chapter]
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)


func _build_decor() -> void:
	var decor := ENVIRONMENT_SCRIPT.new()
	decor.name = "ChapterEnvironment"
	decor.set("chapter", environment_chapter)
	add_child(decor)


func _build_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Aru"
	player.position = Vector3(0, 0, 27)
	player.rescue_position = Vector3(0, 1, 27)
	add_child(player)
	player.connect("health_changed", Callable(self, "_on_health_changed"))
	player.connect("defeated", Callable(self, "_on_player_defeated"))


func _build_enemies() -> void:
	var spawn_points := [Vector3(-4, 0, -3), Vector3(0, 0, -6), Vector3(4, 0, -3)]
	remaining_enemies = spawn_points.size()
	for index in range(spawn_points.size()):
		var enemy: CharacterBody3D = ENEMY_SCRIPT.new()
		enemy.name = "Shore Demon %d" % (index + 1)
		enemy.position = spawn_points[index]
		enemy.set("target", player)
		add_child(enemy)
		enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := preload("res://scripts/safe_area.gd").new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	status_label = Label.new()
	status_label.text = "THE VEILED ISLE  •  Hunt the shore demons"
	status_label.position = Vector2(28, 22)
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.94, 0.83))
	root.add_child(status_label)

	health_label = Label.new()
	health_label.text = "VITALITY  100"
	health_label.position = Vector2(30, 60)
	health_label.add_theme_font_size_override("font_size", 20)
	health_label.add_theme_color_override("font_color", Color(0.75, 0.91, 0.81))
	root.add_child(health_label)

	boss_name_label = Label.new()
	boss_name_label.text = "TIDEWRAITH DRAGON"
	boss_name_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_name_label.offset_left = -180
	boss_name_label.offset_top = 132
	boss_name_label.offset_right = 180
	boss_name_label.offset_bottom = 160
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 20)
	boss_name_label.add_theme_color_override("font_color", Color(0.97, 0.75, 0.56))
	boss_name_label.visible = false
	root.add_child(boss_name_label)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	boss_health_bar.offset_left = -180
	boss_health_bar.offset_top = 163
	boss_health_bar.offset_right = 180
	boss_health_bar.offset_bottom = 185
	boss_health_bar.max_value = 28
	boss_health_bar.value = 28
	boss_health_bar.show_percentage = false
	boss_health_bar.add_theme_stylebox_override("background", _button_style(Color(0.08, 0.08, 0.09, 0.92)))
	boss_health_bar.add_theme_stylebox_override("fill", _button_style(Color(0.63, 0.17, 0.11, 0.94)))
	boss_health_bar.visible = false
	root.add_child(boss_health_bar)

	var joystick := IslandJoystick.new()
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.offset_left = 24
	joystick.offset_right = 214
	joystick.offset_top = -225
	joystick.offset_bottom = -35
	joystick.value_changed.connect(Callable(player, "set_move_input"))
	root.add_child(joystick)

	var attack_button := _make_button("", Vector2(-116,-116),Vector2(-20,-20))
	attack_button.set_script(preload("res://scripts/attack_button.gd"))
	attack_button.name = "AttackButton"
	_set_action_icon(attack_button,"attack","Attack; hold for heavy attack")
	attack_button.tap_requested.connect(Callable(player,"attack"))
	attack_button.heavy_requested.connect(Callable(player,"heavy_attack"))
	root.add_child(attack_button)
	var dodge_button := _make_button("",Vector2(-204,-100),Vector2(-124,-20))
	dodge_button.name = "DodgeButton"
	_set_action_icon(dodge_button,"dodge","Dodge")
	dodge_button.pressed.connect(Callable(player,"dodge"))
	root.add_child(dodge_button)
	var burst_button := _make_button("",Vector2(-116,-204),Vector2(-36,-124))
	burst_button.name = "SpiritBurstButton"
	_set_action_icon(burst_button,"burst","Spirit burst")
	burst_button.disabled = true
	burst_button.pressed.connect(Callable(player,"spirit_burst"))
	root.add_child(burst_button)
	var sprint_button := _make_button("",Vector2(-292,-100),Vector2(-212,-20))
	sprint_button.name = "SprintButton"
	_set_action_icon(sprint_button,"sprint","Sprint")
	sprint_button.pressed.connect(Callable(player,"toggle_sprint"))
	root.add_child(sprint_button)
	var combat_hud_timer := Timer.new()
	combat_hud_timer.wait_time = 0.05
	combat_hud_timer.autostart = true
	combat_hud_timer.timeout.connect(func():
		sprint_button.disabled = not player.sprint_enabled and player.stamina < 20.0
		sprint_button.meter = player.stamina/100.0
		sprint_button.self_modulate = Color(1.0,0.8,0.4) if player.sprint_enabled else Color.WHITE
		dodge_button.meter = clampf(float(player.get("_dodge_cooldown")),0.0,1.0)
		burst_button.meter = float(player.spirit)/100.0
		burst_button.disabled = player.spirit < 100 or float(player.get("_attack_cooldown")) > 0.0
	)
	root.add_child(combat_hud_timer)

	var hint := Label.new()
	hint.name = "ControlsHint"
	hint.text = "Drag open space to turn the camera" if OS.has_feature("mobile") else "WASD: Move   J: Attack   K: Dodge   Esc: Pause"
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 28
	hint.offset_right = -210
	hint.offset_top = 104
	hint.offset_bottom = 128
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.75, 0.83, 0.79, 0.9))
	root.add_child(hint)
	for label in [status_label, health_label, boss_name_label, hint]:
		label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.05, 0.95))
		label.add_theme_constant_override("outline_size", 4)


func _make_button(label: String, top_left: Vector2, bottom_right: Vector2) -> Button:
	var button := preload("res://scripts/round_button.gd").new()
	button.text = label
	button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	button.offset_left = top_left.x
	button.offset_top = top_left.y
	button.offset_right = bottom_right.x
	button.offset_bottom = bottom_right.y
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color(0.94, 0.97, 0.87))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.06, 0.2, 0.22, 0.82)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.1, 0.34, 0.33, 0.94)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.3, 0.48, 0.34, 0.95)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.06, 0.11, 0.13, 0.8)))
	button.add_theme_color_override("font_disabled_color", Color(0.61, 0.68, 0.65))
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_NONE
	return button


func _set_action_icon(button: Button, id: String, accessible_name: String) -> void:
	button.text = ""
	button.icon = load("res://assets/ui/controls/"+id+".svg")
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",38)
	button.accessibility_name = accessible_name
	button.tooltip_text = ""


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 200
	style.corner_radius_top_right = 200
	style.corner_radius_bottom_left = 200
	style.corner_radius_bottom_right = 200
	style.border_color = Color(0.65, 0.84, 0.72, 0.8)
	style.set_border_width_all(2)
	return style


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _on_health_changed(value: int, maximum: int) -> void:
	if is_instance_valid(health_label):
		health_label.text = "VITALITY  %d / %d" % [value, maximum]


func _on_enemy_defeated() -> void:
	remaining_enemies -= 1
	if remaining_enemies <= 0 and not boss_spawned and not game_finished:
		_spawn_boss()


func _spawn_boss() -> void:
	boss_spawned = true
	status_label.text = "THE TIDEWRAITH DRAGON RISES FROM THE REEF"
	boss_name_label.visible = true
	boss_health_bar.visible = true
	var boss: CharacterBody3D = BOSS_SCRIPT.new()
	boss.name = "Tidewraith Dragon"
	boss.position = Vector3(0, 0, -25)
	boss.set("target", player)
	boss.connect("health_changed", Callable(self, "_on_boss_health_changed"))
	boss.connect("defeated", Callable(self, "_on_boss_defeated"))
	boss.connect("enraged_started", Callable(self, "_on_boss_enraged"))
	add_child(boss)


func _on_boss_enraged() -> void:
	boss_name_label.text = "TIDEWRAITH DRAGON — ENRAGED"
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.2))


func _on_boss_health_changed(value: int, maximum: int) -> void:
	boss_health_bar.max_value = maximum
	boss_health_bar.value = value


func _on_boss_defeated() -> void:
	game_finished = true
	boss_name_label.visible = false
	boss_health_bar.visible = false
	status_label.text = "TIDEWRAITH DRAGON DEFEATED  •  Chapter complete"


func _on_player_defeated() -> void:
	if not game_finished:
		game_finished = true
		status_label.text = "Aru has fallen  •  Press R to return to the shore"


func _unhandled_key_input(event: InputEvent) -> void:
	if game_finished and event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
