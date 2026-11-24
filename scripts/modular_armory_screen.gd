extends CanvasLayer

signal closed

const STORE := preload("res://scripts/chapter_store_screen.gd")
const STAGE := preload("res://scripts/armory_preview_stage.gd")
const CURRENCIES := preload("res://scripts/currency_display.gd")
const PLAYER := preload("res://scripts/player.gd")
const HALL := preload("res://assets/ui/armory/temple.jpg")
const SLOTS := ["blade", "shield", "armor"]
const ITEMS := [
	[
		{"name":"Aru's Curved Blade", "art":preload("res://assets/ui/armory/curved_blade.png"), "description":"Aru’s starter blade. Powers sword attacks and Spirit Burst."},
		{"name":"Embersteel Sword", "art":preload("res://assets/ui/armory/embersteel.png"), "description":"A forged embersteel blade. Shares your weapon upgrades."},
	],
	[{"name":"Thornward Shield", "art":preload("res://assets/ui/armory/thornward.png"), "description":"Bronze-bound oak. Uses your existing guard and parry."}],
	[
		{"name":"Ranger Outfit", "art":preload("res://assets/ui/armory/ranger_outfit.png"), "description":"Aru’s starter outfit. Armor upgrades increase maximum health."},
		{"name":"Reinforced Ranger Armor", "art":preload("res://assets/ui/armory/reinforced.png"), "description":"Fitted plates for the Ranger Outfit. Shares your armor upgrades."},
	],
]

var game
var section := 0
var option := 0
var inspecting := false
var yaw := STAGE.DEFAULT_YAW
var zoom := STAGE.DEFAULT_ZOOM
var fingers := {}
var mouse_drag := false
var upgrade_after := 0
var preview: CharacterBody3D
var modular_preview: Node
var camera: Camera3D
var canvas: SubViewportContainer
var balance: HBoxContainer
var tabs: Array[Button] = []
var choices: Array[Button] = []
var cards: HBoxContainer
var item: Label
var detail: Label
var stats: Label
var levels: Label
var next_stats: RichTextLabel
var next_level: Label
var cost_row: HBoxContainer
var cost_text: Label
var detail_art: TextureRect
var status: Label
var equip_button: Button
var upgrade_button: Button
var audio: AudioStreamPlayer
var upgrade_ok: AudioStreamWAV
var upgrade_error: AudioStreamWAV
var safe_area: Control
var screen_margin: MarginContainer
var layout_stack: VBoxContainer
var header_panel: PanelContainer
var item_column: VBoxContainer
var card_strip: ScrollContainer
var reset_button: Button
var compact_cards := false
var card_extent := Vector2(166, 138)

func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	var background := ColorRect.new()
	background.color = Color("0e0b10")
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area = preload("res://scripts/safe_area.gd").new()
	background.add_child(safe_area)
	screen_margin = MarginContainer.new()
	safe_area.add_child(screen_margin)
	screen_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_stack = VBoxContainer.new()
	screen_margin.add_child(layout_stack)
	_build_header(layout_stack)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	layout_stack.add_child(columns)
	_build_preview(columns)
	_build_items(columns)
	safe_area.resized.connect(_layout_armory)
	_layout_armory()
	audio = AudioStreamPlayer.new()
	audio.volume_db = -20
	add_child(audio)
	upgrade_ok = _chime(523.25, 783.99)
	upgrade_error = _chime(233.08, 174.61)
	_choose(0)

func _build_header(root: VBoxContainer) -> void:
	header_panel = _panel(root, 11)
	var layer_control := Control.new()
	header_panel.add_child(layer_control)
	var castle := _image(layer_control, STORE.CASTLE)
	castle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	castle.anchor_left = .48
	castle.anchor_right = .91
	castle.offset_top = -9
	castle.offset_bottom = 9
	var header_row := HBoxContainer.new()
	layer_control.add_child(header_row)
	header_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_row.add_theme_constant_override("separation", 18)
	_button(header_row, "Back to menu", _close)
	_label(header_row, "Armory", 35, STORE.GOLD, true)
	var brand := _label(header_row, "VEIL OF VERA", 23, STORE.GOLD, true)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	balance = CURRENCIES.new()
	balance.icon_size = 42
	balance.currency_divider = true
	header_row.add_child(balance)

func _build_preview(parent: HBoxContainer) -> void:
	var panel := _panel(parent, 7)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = .77
	var stack := VBoxContainer.new()
	panel.add_child(stack)
	var frame := Control.new()
	frame.clip_contents = true
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(frame)
	var background := _image(frame, HALL)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(.88, .85, .87)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas = SubViewportContainer.new()
	canvas.stretch = true
	canvas.gui_input.connect(_preview_press)
	frame.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stage := STAGE.build(canvas)
	preview = stage.actor
	modular_preview = stage.equipment
	camera = stage.camera
	_trim(frame)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	stack.add_child(controls)
	var hint := _label(controls, "Drag to rotate  ·  Pinch to zoom", 19, STORE.INK)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_button = _button(controls, "Reset view", _reset_view)

func _build_items(parent: HBoxContainer) -> void:
	var panel := _panel(parent, 11)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.23
	var background := _image(panel, STORE.SURFACE)
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.modulate = Color(.76, .7, .75)
	item_column = VBoxContainer.new()
	var column := item_column
	panel.add_child(column)
	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 8)
	column.add_child(categories)
	for index in SLOTS.size():
		var button := _button(categories, ["Weapons", "Shields", "Body Armor"][index], _choose.bind(index))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.append(button)
	card_strip = ScrollContainer.new()
	var strip := card_strip
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.follow_focus = true
	column.add_child(strip)
	cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 10)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip.add_child(cards)
	_divider(column)
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 12)
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(details)
	detail_art = _image(details, null)
	detail_art.custom_minimum_size.x = 145
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 4)
	details.add_child(text)
	item = _label(text, "", 27, STORE.GOLD, true)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail = _label(text, "", 19, STORE.INK)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_divider(text)
	var comparison := HBoxContainer.new()
	comparison.add_theme_constant_override("separation", 12)
	text.add_child(comparison)
	var current := VBoxContainer.new()
	current.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison.add_child(current)
	levels = _label(current, "", 19, STORE.GOLD)
	stats = _label(current, "", 18, STORE.INK)
	var next := VBoxContainer.new()
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comparison.add_child(next)
	next_level = _label(next, "", 19, STORE.GOLD)
	next_stats = RichTextLabel.new()
	next_stats.bbcode_enabled = true
	next_stats.fit_content = true
	next_stats.scroll_active = false
	next_stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_stats.add_theme_font_override("normal_font", STORE.BODY)
	next_stats.add_theme_font_size_override("normal_font_size", 18)
	next_stats.add_theme_color_override("default_color", STORE.INK)
	next_stats.add_theme_constant_override("line_separation", 2)
	next.add_child(next_stats)
	_divider(column)
	cost_row = HBoxContainer.new()
	cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(cost_row)
	var icon := _image(cost_row, CURRENCIES.SHARD)
	icon.custom_minimum_size = Vector2(33, 28)
	cost_text = _label(cost_row, "", 21, STORE.GOLD)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	equip_button = _button(actions, "", _change.bind(false))
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_button = _button(actions, "Upgrade", _change.bind(true), true)
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status = _label(column, "", 20, STORE.GOLD)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size.y = 27

func _layout_armory() -> void:
	var usable := safe_area.size
	var compact := usable.y < 744.0
	var tight := usable.y < 682.0
	var outer_margin := 8 if tight else 12 if compact else 16
	for side in ["left", "top", "right", "bottom"]:
		screen_margin.add_theme_constant_override("margin_" + side, outer_margin)
	layout_stack.add_theme_constant_override("separation", 7 if tight else 10 if compact else 13)
	header_panel.custom_minimum_size.y = 60 if tight else 66 if compact else 70
	item_column.add_theme_constant_override("separation", 3 if tight else 5 if compact else 8)
	detail_art.custom_minimum_size.x = 100 if usable.x < 1180 else 123 if compact else 145
	compact_cards = compact
	card_extent = Vector2(149 if usable.x < 1120 else 166, 120 if tight else 126 if compact else 138)
	card_strip.custom_minimum_size.y = card_extent.y + 4
	# The two existing cards fit in the phone layout. Keep native horizontal
	# browsing available if a future equipment category exceeds this width.
	for card: Button in choices:
		card.custom_minimum_size = card_extent
		var thumbnail := card.find_child("Thumbnail", true, false) as TextureRect
		thumbnail.custom_minimum_size.y = 45 if compact_cards else 55

func _choose(index: int) -> void:
	section = index
	option = maxi(0, game.gear_selection()[SLOTS[section]])
	inspecting = false
	status.text = ""
	for node in cards.get_children():
		cards.remove_child(node)
		node.queue_free()
	choices.clear()
	for index_in_slot in ITEMS[section].size():
		_item_card(index_in_slot, ITEMS[section][index_in_slot])
	_refresh()

func _item_card(index: int, data: Dictionary) -> void:
	var button := _button(cards, "", _inspect.bind(index))
	button.custom_minimum_size = card_extent
	button.toggle_mode = true
	button.accessibility_name = data.name
	var surface := _image(button, STORE.SURFACE)
	surface.stretch_mode = TextureRect.STRETCH_SCALE
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.offset_left = 5
	surface.offset_right = -5
	surface.offset_top = 5
	surface.offset_bottom = -5
	_trim(button)
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(contents)
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left = 7
	contents.offset_right = -7
	contents.offset_top = 6
	contents.offset_bottom = -6
	contents.add_theme_constant_override("separation", 1)
	var art := _image(contents, data.art)
	art.name = "Thumbnail"
	art.custom_minimum_size.y = 45 if compact_cards else 55
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var caption := _label(contents, data.name, 16, STORE.GOLD, true)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size.y = 36
	var tag := _label(contents, "", 16, STORE.MUTED)
	tag.name = "Ownership"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choices.append(button)

func _inspect(index: int) -> void:
	option = index
	inspecting = true
	status.text = ""
	_refresh()

func _refresh() -> void:
	var slot: String = SLOTS[section]
	var equipped: Dictionary = game.gear_selection()
	var owned: bool = game.owns_gear(slot, option)
	var active: bool = equipped[slot] == option
	var previewing := inspecting and not active
	var display := equipped.duplicate()
	if previewing:
		display[slot] = option
	preview.set_equipment_visuals(display.blade >= 0, display.armor >= 0)
	# Appearance preview is separate from live equipment and is never a save write.
	modular_preview.apply(display)
	balance.update_balances(game.shards, game.veil_gems)
	for i in tabs.size():
		tabs[i].set_pressed_no_signal(i == section)
	var has_level := slot != "shield"
	var level: int = game.gear_level(slot) if has_level else 0
	for i in choices.size():
		choices[i].set_pressed_no_signal(i == option)
		var tag := choices[i].find_child("Ownership", true, false) as Label
		var state := "Equipped" if equipped[slot] == i else "Owned" if game.owns_gear(slot, i) else "In Store"
		if previewing and i == option:
			state = "Preview · " + state
		tag.text = ("%s · Lv %d" % [state, level]) if has_level and not (previewing and i == option) else state
	var entry: Dictionary = ITEMS[section][option]
	item.text = entry.name
	detail.text = entry.description + ("  ·  Preview only" if previewing else "")
	detail_art.texture = entry.art
	equip_button.text = "Unequip" if active else "Equip"
	equip_button.disabled = not owned or game.equipment_locked()
	levels.text = "Current · Level %d / %d" % [level, game.LEVEL_CAP] if has_level else "Current"
	levels.add_theme_color_override("font_color", STORE.GOLD)
	var attack: int = game.player.attack_damage
	var health: int = game.player.max_health
	stats.text = _stat_lines(attack, health)
	var available: bool = has_level and level < game.LEVEL_CAP
	cost_row.visible = available
	upgrade_button.visible = has_level
	upgrade_button.disabled = not available or not owned or game.equipment_locked()
	upgrade_button.text = "Upgrade" if available else "Maximum level reached"
	if available:
		var after_attack := PLAYER.blade_power(level + 1) if slot == "blade" and equipped.blade >= 0 else attack
		var after_health := PLAYER.armor_vitality(level + 1) if slot == "armor" and equipped.armor >= 0 else health
		next_level.text = "Next · Level %d / %d" % [level + 1, game.LEVEL_CAP]
		next_stats.text = _stat_lines(after_attack, after_health, after_attack > attack, after_health > health)
		if equipped[slot] < 0:
			next_stats.text += "
Bonus applies when equipped."
		cost_text.text = "Required  ·  %d Tide Shards" % game._cost(level)
	else:
		next_level.text = "Maximum level" if has_level else "Shield"
		next_stats.text = "Upgrade complete" if has_level else "Uses existing guard stats.
No upgrades available."

func _stat_lines(attack: int, health: int, attack_improved := false, health_improved := false) -> String:
	var attack_line := "Attack  %d" % attack
	var health_line := "Max Health  %d" % health
	if attack_improved:
		attack_line = "[color=#a3c89b]%s[/color]" % attack_line
	if health_improved:
		health_line = "[color=#a3c89b]%s[/color]" % health_line
	return "%s\n%s\nStamina  %d\nGuard Defense  %d%%" % [
		attack_line, health_line, PLAYER.MAX_STAMINA, roundi((1.0 - PLAYER.GUARD_DAMAGE_FACTOR) * 100)]

func _change(upgrade: bool) -> void:
	var slot: String = SLOTS[section]
	if not game.owns_gear(slot, option) or game.equipment_locked():
		return
	if upgrade:
		var level: int = game.gear_level(slot)
		if slot == "shield" or level >= game.LEVEL_CAP:
			return
		var cost: int = game._cost(level)
		# Ignore a rapid second charge, but let an unaffordable attempt replace
		# feedback from the preceding upgrade with the current validation result.
		if Time.get_ticks_msec() < upgrade_after and game.shards >= cost:
			return
		var result: String = game.change_gear(slot, true)
		var ok := result == "Upgrade saved."
		if ok:
			upgrade_after = Time.get_ticks_msec() + 425
			status.text = "Upgrade Successful · Level %d · %d Tide Shards spent" % [level + 1, cost]
		else:
			status.text = "Insufficient Tide Shards" if result == "You need more Tide Shards." else result
		status.add_theme_color_override("font_color", STORE.GOLD if ok else Color("e4a092"))
		audio.stream = upgrade_ok if ok else upgrade_error
		audio.play()
	else:
		status.add_theme_color_override("font_color", STORE.GOLD)
		status.text = game.select_gear(slot, -1 if game.gear_selection()[slot] == option else option)
		inspecting = false
	_refresh()

func _reset_view() -> void:
	yaw = STAGE.DEFAULT_YAW
	zoom = STAGE.DEFAULT_ZOOM

func _preview_press(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not event.canceled and fingers.size() < 2:
		fingers[event.index] = canvas.get_global_transform_with_canvas() * event.position
		canvas.accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and fingers.is_empty():
		mouse_drag = event.pressed
		canvas.accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and fingers.has(event.index):
		if fingers.size() == 1:
			yaw = wrapf(yaw + event.relative.x * .012, -PI, PI)
		else:
			var indices := fingers.keys()
			var other: Vector2 = fingers[indices[0] if indices[1] == event.index else indices[1]]
			var previous: Vector2 = fingers[event.index]
			var old_distance := other.distance_to(previous)
			var new_distance := other.distance_to(event.position)
			if minf(old_distance, new_distance) > 16.0:
				zoom = clampf(zoom * old_distance / new_distance, STAGE.MIN_ZOOM, STAGE.MAX_ZOOM)
		fingers[event.index] = event.position
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and (not event.pressed or event.canceled) and fingers.erase(event.index):
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_drag and fingers.is_empty():
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			yaw = wrapf(yaw + event.relative.x * .012, -PI, PI)
		else:
			mouse_drag = false
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _process(delta: float) -> void:
	var smoothing := 1.0 - exp(-delta * 14.0)
	preview.rotation.y = lerp_angle(preview.rotation.y, yaw, smoothing)
	camera.size = lerpf(camera.size, zoom, smoothing)

func _close() -> void:
	if not visible:
		return
	hide()
	closed.emit()
	queue_free()

func _panel(parent: Control, inset: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("19141a"), Color("9c704b"), 1, inset))
	parent.add_child(panel)
	return panel

func _button(parent: Control, copy: String, action: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = copy
	button.custom_minimum_size.y = 43
	button.add_theme_font_override("font", STORE.TITLE)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", STORE.INK)
	button.add_theme_color_override("font_disabled_color", STORE.MUTED)
	button.add_theme_stylebox_override("normal", _box(Color("50301e") if primary else Color("20171d"), Color("ad8057") if primary else Color("806044"), 1, 8))
	button.add_theme_stylebox_override("hover", _box(Color("342328"), STORE.GOLD, 1, 8))
	var active := _box(Color("291c21"), Color("f4c780"), 2, 8)
	active.shadow_color = Color("c7904d7a")
	active.shadow_size = 5
	button.add_theme_stylebox_override("pressed", active)
	button.add_theme_stylebox_override("hover_pressed", active)
	button.add_theme_stylebox_override("disabled", _box(Color("1c161c"), Color("574438"), 1, 8))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, STORE.GOLD, 1, 0))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _box(fill: Color, border: Color, width: int, inset: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(5)
	box.set_content_margin_all(inset)
	return box

func _label(parent: Control, value: String, pixels: int, tint: Color, display := false) -> Label:
	var text := Label.new()
	text.text = value
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("font_size", pixels)
	text.add_theme_font_override("font", STORE.TITLE if display else STORE.BODY)
	text.add_theme_color_override("font_color", tint)
	parent.add_child(text)
	return text

func _image(parent: Control, texture: Texture2D) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func _trim(parent: Control) -> void:
	var trim := STORE.CornerTrim.new()
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(trim)
	trim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _divider(parent: Control) -> void:
	var divider := STORE.GiltDivider.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.custom_minimum_size.y = 8
	parent.add_child(divider)

func _chime(first: float, second: float) -> AudioStreamWAV:
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(10584)
	for i in bytes.size() / 2:
		var seconds := float(i) / wave.mix_rate
		var note := first if seconds < .067 else second
		var age := seconds if seconds < .067 else seconds - .067
		var envelope := minf(age * 200.0, 1.0) * exp(-age * 38.0)
		bytes.encode_s16(i * 2, roundi(sin(TAU * note * age) * envelope * 5600.0))
	wave.data = bytes
	return wave
