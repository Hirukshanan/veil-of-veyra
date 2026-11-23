extends CanvasLayer

signal closed

const PLAYER := preload("res://scripts/player.gd")
const DISPLAY_FONT := preload("res://assets/ui/fonts/Cinzel.ttf")
const GOLD := Color("f1c686")
const INK := Color("ded4c3")
const SLOTS := ["blade", "shield", "armor"]
const NAMES := ["Aru's Curved Blade", "Shield", "Ranger Outfit"]
const NOTES := [
	"Aru's curved blade powers sword strikes and Spirit Burst.",
	"Aru can guard and parry with his current kit. No shield is available.",
	"Improve the outfit's protection to raise maximum health. Aru keeps his ranger clothing when protection is unequipped."
]

var game
var section := 0
var preview: PlayerPreview
var canvas: Control
var balance: Label
var stats: Label
var item: Label
var detail: Label
var levels: Label
var status: Label
var equip_button: Button
var upgrade_button: Button
var tabs: Array[Button] = []
var yaw := PI + .34
var drag_finger := -1
var dragging := false

class PlayerPreview extends "res://scripts/player.gd":
	func _ready() -> void:
		_visual = preload("res://scripts/hero_visual.gd").new()
		_visual.idle_only = true
		add_child(_visual)
		_build_weapon()

func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	var backdrop := ColorRect.new()
	backdrop.color = Color("110f16")
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	backdrop.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]:
		margin.add_theme_constant_override("margin_"+side, 28)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	margin.add_child(body)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	body.add_child(header)
	_button(header, "Back to menu", _close)
	var title := _label(header, "Armory", 32, GOLD, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	balance = _label(header, "", 22, GOLD)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(layout)
	_build_preview(layout)
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.08
	right.add_theme_stylebox_override("panel", _panel(Color("1b1720"),Color("5d4532"),18))
	layout.add_child(right)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	right.add_child(column)
	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 9)
	column.add_child(categories)
	for index in SLOTS.size():
		var tab := _button(categories, ["Weapons","Shields","Body Armor"][index], _choose.bind(index))
		tab.toggle_mode = true
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.append(tab)
	_add_equipment_selector(column)
	stats = _label(column, "", 19, GOLD)
	var scroll := preload("res://scripts/mobile_settings.gd").TouchScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 10)
	scroll.add_child(copy)
	item = _label(copy, "", 27, GOLD, true)
	detail = _label(copy, "", 20, INK)
	levels = _label(copy, "", 20, INK)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	equip_button = _button(actions, "", _change.bind(false))
	upgrade_button = _button(actions, "Upgrade", _change.bind(true))
	status = _label(column, "", 17, GOLD)
	_refresh()

func _add_equipment_selector(_column: VBoxContainer) -> void:
	pass

func _build_preview(parent: Control) -> void:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", _panel(Color("16141d"),Color("5d4532"),8))
	parent.add_child(box)
	var stack := VBoxContainer.new()
	box.add_child(stack)
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.stretch_shrink = 2
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.gui_input.connect(_rotate_input)
	stack.add_child(frame)
	canvas = frame
	var view := SubViewport.new()
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	frame.add_child(view)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("201b27")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c9bcd0")
	world.environment.ambient_light_energy = .65
	view.add_child(world)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-37, -28, 0)
	key.light_color = Color("ffd398")
	key.light_energy = 1.3
	view.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-22, 148, 0)
	rim.light_color = Color("92a9f0")
	rim.light_energy = .75
	view.add_child(rim)
	var pedestal := MeshInstance3D.new()
	var stone := CylinderMesh.new()
	stone.top_radius = .88
	stone.bottom_radius = .96
	stone.height = .16
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("47353d")
	stone.material = material
	pedestal.mesh = stone
	pedestal.position.y = -.09
	view.add_child(pedestal)
	preview = PlayerPreview.new()
	# This is the shared hero model and held blade, with only its display idle.
	view.add_child(preview)
	preview.set_physics_process(false)
	preview.set_process_input(false)
	preview.set_process_unhandled_input(false)
	preview.rotation.y = yaw
	var camera := Camera3D.new()
	view.add_child(camera)
	camera.position = Vector3(0,1.17,3.75)
	camera.look_at(Vector3(0,.88,0))
	camera.fov = 36
	camera.make_current()
	var turn := HBoxContainer.new()
	turn.alignment = BoxContainer.ALIGNMENT_CENTER
	turn.add_theme_constant_override("separation", 12)
	stack.add_child(turn)
	_button(turn,"Rotate left",_turn.bind(-.65))
	_button(turn,"Rotate right",_turn.bind(.65))

func _rotate_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and drag_finger == -1:
			drag_finger = event.index
		elif event.index == drag_finger:
			drag_finger = -1
	elif event is InputEventScreenDrag and event.index == drag_finger:
		yaw += event.relative.x * .012
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and drag_finger == -1:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging and drag_finger == -1:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			yaw += event.relative.x * .012
		else:
			dragging = false

func _process(delta: float) -> void:
	preview.rotation.y = lerp_angle(preview.rotation.y, yaw, 1.0-exp(-delta*14))

func _turn(radians: float) -> void:
	yaw += radians

func _choose(index: int) -> void:
	section = index
	status.text = ""
	_refresh()

func _change(upgrade: bool) -> void:
	status.text = game.change_gear(SLOTS[section],upgrade)
	_refresh()

func _refresh() -> void:
	preview.set_equipment_visuals(game.equipped("blade"), game.equipped("armor"))
	balance.text = "%d Tide Shards" % game.shards
	stats.text = "Attack  %d     Health  %d     Stamina  %d\nGuard defense  %d%% damage reduction" % [
		game.player.attack_damage,game.player.max_health,PLAYER.MAX_STAMINA,roundi((1.0-PLAYER.GUARD_DAMAGE_FACTOR)*100)]
	for i in tabs.size():
		tabs[i].button_pressed = section == i
	var slot: String = SLOTS[section]
	item.text = NAMES[section]
	detail.text = NOTES[section]
	var supported := slot != "shield"
	equip_button.visible = supported
	upgrade_button.visible = supported
	if not supported:
		levels.text = "No shield owned"
		return
	var equipped: bool = game.equipped(slot)
	var level: int = game.gear_level(slot)
	var cost: int = game._cost(level)
	var next_stats := "%d → %d attack" % [PLAYER.blade_power(level), PLAYER.blade_power(level+1)] if slot == "blade" else (
		"%d → %d max health" % [PLAYER.armor_vitality(level), PLAYER.armor_vitality(level+1)])
	levels.text = "%s  ·  Level %d / %d" % ["Equipped" if equipped else "Owned",level,game.LEVEL_CAP]
	levels.text += "\nNext level  ·  %s\nRequired  ·  %d Tide Shards" % [next_stats,cost] if level < game.LEVEL_CAP else "\nMaximum level reached"
	equip_button.text = "Unequip" if equipped else "Equip"
	equip_button.disabled = game.equipment_locked()
	upgrade_button.disabled = level >= game.LEVEL_CAP or game.shards < cost or game.equipment_locked()
	if game.equipment_locked():
		status.text = "This save could not be read."
	elif status.text.is_empty() and upgrade_button.disabled and game.gear_level(SLOTS[section]) < game.LEVEL_CAP:
		status.text = "More Tide Shards needed."

func _close() -> void:
	hide()
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _button(parent: Control, caption: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(98,48)
	button.add_theme_font_size_override("font_size",18)
	button.add_theme_color_override("font_color",INK)
	button.add_theme_color_override("font_hover_color",GOLD)
	button.add_theme_stylebox_override("normal",_panel(Color("261f29"),Color("67503c"),9))
	button.add_theme_stylebox_override("hover",_panel(Color("37272e"),GOLD,9))
	button.add_theme_stylebox_override("pressed",_panel(Color("4a3032"),GOLD,9))
	button.add_theme_stylebox_override("disabled",_panel(Color("201b22"),Color("3a2e35"),9))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _label(parent: Control, value: String, pixels: int, color: Color, display := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",pixels)
	label.add_theme_color_override("font_color",color)
	if display:
		label.add_theme_font_override("font",DISPLAY_FONT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if parent is VBoxContainer else TextServer.AUTOWRAP_OFF
	parent.add_child(label)
	return label

func _panel(fill: Color, border: Color, inset: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		box.set_content_margin(side,inset)
	return box
