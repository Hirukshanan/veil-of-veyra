extends "res://scripts/armory_screen.gd"

const EQUIPMENT := preload("res://scripts/aru_modular_equipment.gd")
const ITEMS := [["Aru's Curved Blade","Embersteel Sword"],["Thornward Shield"],["Ranger Outfit","Reinforced Ranger Armor"]]
var selector: HBoxContainer
var choices: Array[Button] = []
var option := 0
var inspecting := false
var modular_preview: EQUIPMENT

func _ready() -> void:
	option = maxi(0,game.gear_selection().blade)
	super._ready()

func _build_preview(parent: Control) -> void:
	super._build_preview(parent)
	var frame := canvas as SubViewportContainer
	frame.stretch_shrink = 1 if get_window().size.x >= 1050 else 2
	var view := frame.get_child(0) as SubViewport
	var environment := view.find_children("*", "WorldEnvironment", false, false)[0] as WorldEnvironment
	environment.environment.background_color = Color("181621")
	environment.environment.ambient_light_color = Color("d6c6bb")
	environment.environment.ambient_light_energy = .78
	var lights := view.find_children("*", "DirectionalLight3D", false, false)
	var key := lights[0] as DirectionalLight3D
	key.rotation_degrees = Vector3(-29, -24, 0)
	key.light_color = Color("ffe3c4")
	key.light_energy = 1.46
	var rim := lights[1] as DirectionalLight3D
	rim.rotation_degrees = Vector3(-32, 141, 0)
	rim.light_color = Color("a4bdff")
	rim.light_energy = .89
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-17, 56, 0)
	fill.light_color = Color("d6dfff")
	fill.light_energy = .43
	view.add_child(fill)

func _add_equipment_selector(column: VBoxContainer) -> void:
	selector = HBoxContainer.new()
	selector.add_theme_constant_override("separation", 8)
	column.add_child(selector)
	for index in 2:
		var button := _button(selector,"",_inspect.bind(index))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choices.append(button)

func _choose(index: int) -> void:
	option = maxi(0,game.gear_selection()[SLOTS[index]])
	inspecting = false
	super._choose(index)

func _inspect(index: int) -> void:
	option = index
	inspecting = true
	status.text = ""
	_refresh()

func _change(upgrade: bool) -> void:
	if upgrade:
		super._change(true)
		return
	var slot: String = SLOTS[section]
	status.text = game.select_gear(slot,-1 if game.gear_selection()[slot] == option else option)
	inspecting = false
	_refresh()

func _refresh() -> void:
	super._refresh()
	if not is_instance_valid(modular_preview):
		modular_preview = EQUIPMENT.new()
		preview.add_child(modular_preview)
		modular_preview.bind_hero(preview)
	var slot: String = SLOTS[section]
	var saved: Dictionary = game.gear_selection()
	var active: bool = saved[slot] == option
	var locked: bool = not game.owns_gear(slot, option)
	for i in choices.size():
		choices[i].visible = i < ITEMS[section].size()
		if choices[i].visible:
			choices[i].text = ITEMS[section][i]
			choices[i].set_pressed_no_signal(i == option)
	var display := saved.duplicate()
	# Inspection is temporary. Selecting the equipped entry shows the actual loadout.
	if inspecting:
		display[slot] = option
	modular_preview.apply(display)
	item.text = ITEMS[section][option]
	equip_button.show()
	equip_button.text = "Unequip" if active else "Equip"
	equip_button.disabled = locked or game.equipment_locked()
	var owned := "Available in the Store" if locked else "Equipped" if active else "Owned"
	if slot == "shield":
		detail.text = "Reinforced oak with a bronze thorn engraving. Guard uses the existing combat rules."
		levels.text = owned + "\nNo stat change"
		upgrade_button.hide()
		return
	var stats_note := "Shares blade damage and upgrades." if slot == "blade" else "Shares Ranger health and upgrades."
	detail.text = stats_note + ("\nInspecting this option" if display[slot] != saved[slot] else "")
	var existing := levels.text.split("\n",true,1)
	levels.text = owned + "  ·  Level %d / %d" % [game.gear_level(slot),game.LEVEL_CAP]
	if existing.size() > 1:
		levels.text += "\n" + existing[1]
