extends CanvasLayer

signal closed

const CURRENCIES := preload("res://scripts/currency_display.gd")
const TITLE := preload("res://assets/ui/fonts/Cinzel.ttf")
const BODY := preload("res://assets/ui/fonts/CrimsonText-Regular.ttf")
const CASTLE := preload("res://assets/ui/store/castle.png")
const SURFACE := preload("res://assets/ui/store/bronze_surface.png")
const CARD_GAP := 12
const ART := {
	"potion": preload("res://assets/ui/store/potion.png"),
	"blade": preload("res://assets/ui/store/blade.png"),
	"shield": preload("res://assets/ui/store/shield.png"),
	"armor": preload("res://assets/ui/store/armor.png"),
}
const GOLD := Color("e8bd85")
const INK := Color("f3e4cf")
const MUTED := Color("baaa98")

class CornerTrim extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var edge := Color("b78757b8")
		for corner in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
			var corner_at: Vector2 = corner * size
			var inward: Vector2 = Vector2.ONE - corner * 2.0
			var a := corner_at + Vector2(2, 18) * inward
			var b := corner_at + Vector2(2, 9) * inward
			var c := corner_at + Vector2(9, 2) * inward
			var d := corner_at + Vector2(18, 2) * inward
			draw_polyline(PackedVector2Array([a, b, c, d]), edge, 1.0, true)

class GiltDivider extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var middle := size * .5
		var edge := Color("936844")
		draw_line(Vector2(6, middle.y), middle - Vector2(10, 0), edge, 1)
		draw_line(middle + Vector2(10, 0), Vector2(size.x - 6, middle.y), edge, 1)
		draw_colored_polygon(PackedVector2Array([middle - Vector2(5, 0),
			middle - Vector2(0, 3), middle + Vector2(5, 0), middle + Vector2(0, 3)]), GOLD)

var game
var category := 0
var selected := 0
var category_buttons: Array[Button] = []
var cards: HBoxContainer
var card_scroll: ScrollContainer
var card_buttons: Dictionary = {}
var empty_note: Label
var item_name: Label
var header_balances: HBoxContainer
var detail_balances: HBoxContainer
var price: Label
var price_icon: TextureRect
var quantity: Label
var feedback: Label
var purchase: Button
var buy_after := 0
var cue: AudioStreamPlayer
var success_sound: AudioStreamWAV
var failure_sound: AudioStreamWAV

func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	var backdrop := ColorRect.new()
	backdrop.color = Color("0e0c11")
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ambience := _surface(backdrop)
	ambience.modulate = Color(.53, .49, .54)
	ambience.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe := preload("res://scripts/safe_area.gd").new()
	backdrop.add_child(safe)
	var margin := MarginContainer.new()
	safe.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	_build_header(content)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(columns)
	var browse := VBoxContainer.new()
	browse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	browse.size_flags_stretch_ratio = 2.6
	browse.add_theme_constant_override("separation", 13)
	columns.add_child(browse)
	var categories := HBoxContainer.new()
	categories.add_theme_constant_override("separation", 10)
	browse.add_child(categories)
	for i in 3:
		var tab := _button(categories, ["Consumables", "Equipment", "Cosmetics"][i], _choose_category.bind(i))
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.toggle_mode = true
		category_buttons.append(tab)
	var stock := _panel(browse, Color("151015"), Color("654b39"), 12)
	stock.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var stock_content := VBoxContainer.new()
	stock.add_child(stock_content)
	card_scroll = ScrollContainer.new()
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.follow_focus = true
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stock_content.add_child(card_scroll)
	cards = HBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", CARD_GAP)
	card_scroll.add_child(cards)
	card_scroll.resized.connect(_size_cards)
	empty_note = _label(stock_content, "Cosmetic appearances will be available in a future update.", 26, MUTED)
	empty_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_details(columns)
	cue = AudioStreamPlayer.new()
	cue.volume_db = -20
	add_child(cue)
	success_sound = _make_cue(523.25, 783.99)
	failure_sound = _make_cue(233.08, 174.61)
	_choose_category(0)

func _build_header(parent: Control) -> void:
	var header := _panel(parent, Color("171218"), Color("956a46"), 12)
	header.custom_minimum_size.y = 86
	var frame := Control.new()
	header.add_child(frame)
	var art := _image(frame, CASTLE)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.anchor_left = .35
	art.anchor_right = .99
	art.offset_top = -11
	art.offset_bottom = 11
	_trim(frame)
	var row := HBoxContainer.new()
	frame.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 19)
	_button(row, "Back to menu", close)
	var heading := _label(row, "Store", 36, GOLD, true)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var brand := _label(row, "VEIL OF VERA", 23, GOLD, true)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_balances = CURRENCIES.new()
	header_balances.icon_size = 44
	header_balances.currency_divider = true
	row.add_child(header_balances)

func _build_details(parent: Control) -> void:
	var panel := _panel(parent, Color("191319"), Color("b5895c"), 17)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(292, 394)
	_trim(panel)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 12)
	var detail_surface := _surface(panel)
	detail_surface.modulate = Color(.76, .72, .76)
	panel.add_child(detail)
	item_name = _label(detail, "", 28, GOLD, true)
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_name.custom_minimum_size.y = 67
	_divider(detail)
	detail_balances = CURRENCIES.new()
	detail_balances.icon_size = 37
	detail_balances.currency_divider = true
	detail.add_child(detail_balances)
	detail_balances.alignment = BoxContainer.ALIGNMENT_CENTER
	var cost := HBoxContainer.new()
	cost.alignment = BoxContainer.ALIGNMENT_CENTER
	detail.add_child(cost)
	price_icon = _image(cost, CURRENCIES.SHARD)
	price_icon.custom_minimum_size = Vector2(36, 36)
	price = _label(cost, "", 23, GOLD)
	quantity = _label(detail, "", 22, INK)
	quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity.custom_minimum_size.y = 29
	feedback = _label(detail, "", 22, GOLD)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.custom_minimum_size.y = 39
	purchase = _button(detail, "Buy", _purchase)
	purchase.custom_minimum_size.y = 54
	_style_button(purchase, true)
	_trim(purchase)

func _choose_category(index: int) -> void:
	category = index
	selected = -1
	feedback.text = ""
	cards.hide()
	for old in cards.get_children():
		cards.remove_child(old)
		old.queue_free()
	card_buttons.clear()
	for i in game.STORE_ITEMS.size():
		var item: Dictionary = game.STORE_ITEMS[i]
		if item.category == category:
			if selected < 0:
				selected = i
			_add_card(i, item)
	for i in category_buttons.size():
		category_buttons[i].set_pressed_no_signal(i == category)
	card_scroll.visible = selected >= 0
	cards.show()
	card_scroll.scroll_horizontal = 0
	empty_note.visible = selected < 0
	_size_cards()
	_refresh()

func _size_cards() -> void:
	if not is_instance_valid(cards):
		return
	var card_width := clampf(floorf((card_scroll.size.x - 2.0 * CARD_GAP - 6.0) / 3.0), 208.0, 274.0)
	for card: Button in card_buttons.values():
		card.custom_minimum_size.x = card_width

func _add_card(index: int, item: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(200, 320)
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.toggle_mode = true
	button.accessibility_name = item.name
	button.pressed.connect(_select.bind(index))
	_style_card(button)
	cards.add_child(button)
	var surface := _surface(button)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.offset_left = 6
	surface.offset_top = 6
	surface.offset_right = -6
	surface.offset_bottom = -6
	_trim(button)
	card_buttons[index] = button
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 8)
	margin.add_child(contents)
	var art := _image(contents, ART[item.art])
	art.custom_minimum_size.y = 115
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var caption := _label(contents, item.name, 22, GOLD, true)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.custom_minimum_size.y = 67
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_divider(contents)
	var copy := _label(contents, item.copy, 20, INK)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.custom_minimum_size.y = 92
	if item.category == 0:
		copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cost := HBoxContainer.new()
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost.alignment = BoxContainer.ALIGNMENT_CENTER
	contents.add_child(cost)
	var icon := _image(cost, CURRENCIES.SHARD)
	icon.custom_minimum_size = Vector2(32, 32)
	var tag := _label(cost, "", 21, GOLD)
	tag.name = "CardPrice"

func _select(index: int) -> void:
	selected = index
	feedback.text = ""
	_refresh()

func _refresh() -> void:
	header_balances.update_balances(game.shards, game.veil_gems)
	detail_balances.update_balances(game.shards, game.veil_gems)
	for index in card_buttons:
		var card: Button = card_buttons[index]
		var card_item: Dictionary = game.STORE_ITEMS[index]
		card.set_pressed_no_signal(index == selected)
		var tag := card.find_child("CardPrice", true, false) as Label
		tag.text = "Owned" if game.store_owns(card_item) else "%d Tide Shards" % card_item.price
		(tag.get_parent().get_child(0) as TextureRect).visible = not game.store_owns(card_item)

	price_icon.visible = selected >= 0
	purchase.visible = selected >= 0
	quantity.text = ""
	if selected < 0:
		item_name.text = "Cosmetics"
		price.text = "2 Veil Gems per appearance"
		price_icon.texture = CURRENCIES.GEM
		price_icon.show()
		return

	var item: Dictionary = game.STORE_ITEMS[selected]
	var owned: bool = game.store_owns(item)
	item_name.text = item.name
	price.text = "Owned" if owned else "%d Tide Shards" % item.price
	price_icon.texture = CURRENCIES.SHARD
	price_icon.visible = not owned
	if item.bit == 0:
		quantity.text = "Carried  %d / %d" % [game.potions, game.STORE_POTION_LIMIT]
	purchase.text = "Owned" if owned else "Buy"
	purchase.disabled = owned

func _purchase() -> void:
	if selected < 0 or Time.get_ticks_msec() < buy_after:
		return
	var result: String = game.buy_store_item(selected)
	buy_after = Time.get_ticks_msec() + 425
	var successful := result == "Purchase Successful"
	feedback.text = result
	feedback.add_theme_color_override("font_color", GOLD if successful else Color("e4a092"))
	cue.stream = success_sound if successful else failure_sound
	cue.play()
	_refresh()

func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()

func _panel(parent: Control, fill: Color, edge: Color, inset: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(fill, edge, 1, inset))
	parent.add_child(panel)
	return panel

func _button(parent: Control, copy: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = copy
	button.custom_minimum_size = Vector2(0, 47)
	button.add_theme_font_override("font", TITLE)
	button.add_theme_font_size_override("font_size", 19)
	button.pressed.connect(action)
	_style_button(button, false)
	parent.add_child(button)
	return button

func _style_button(button: Button, prominent: bool) -> void:
	button.add_theme_stylebox_override("normal", _box(Color("50321f") if prominent else Color("221a20"), Color("a87546") if prominent else Color("77543a"), 1, 8))
	button.add_theme_stylebox_override("hover", _box(Color("3b2825"), GOLD, 1, 8))
	var active := _box(Color("38251e"), Color("f0bf79"), 2, 8)
	active.shadow_color = Color("ad6a3d65")
	active.shadow_size = 5
	button.add_theme_stylebox_override("pressed", active)
	button.add_theme_stylebox_override("hover_pressed", active)
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, Color("d3a76f"), 1, 0))
	button.add_theme_stylebox_override("disabled", _box(Color("1d181b"), Color("5d4a3d"), 1, 8))
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_disabled_color", MUTED)

func _style_card(button: Button) -> void:
	var normal := _box(Color("141016"), Color("866043"), 1, 8)
	var hover := _box(Color("1d151a"), Color("d4a476"), 1, 8)
	var selected_style := _box(Color("181118"), Color("f2c274"), 2, 8)
	selected_style.shadow_color = Color("bf843b80")
	selected_style.shadow_size = 5
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", selected_style)
	button.add_theme_stylebox_override("hover_pressed", selected_style)
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, Color("bc9166"), 1, 0))

func _surface(parent: Control) -> TextureRect:
	var surface := _image(parent, SURFACE)
	surface.stretch_mode = TextureRect.STRETCH_SCALE
	return surface

func _trim(parent: Control) -> void:
	var trim := CornerTrim.new()
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(trim)
	trim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _divider(parent: Control) -> void:
	var divider := GiltDivider.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.custom_minimum_size.y = 9
	parent.add_child(divider)

func _box(fill: Color, edge: Color, border: int, inset: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(border)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(inset)
	return box

func _image(parent: Control, texture: Texture2D) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image

func _label(parent: Control, copy: String, pixels: int, tint: Color, heading := false) -> Label:
	var label := Label.new()
	label.text = copy
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", TITLE if heading else BODY)
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label

func _make_cue(first: float, second: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	var samples := roundi(stream.mix_rate * .24)
	data.resize(samples * 2)
	for i in samples:
		var seconds := float(i) / stream.mix_rate
		var signal_value := 0.0
		for note in [Vector2(first, 0.0), Vector2(second, .065)]:
			var age: float = seconds - note.y
			if age >= 0.0:
				var envelope := minf(1.0, age * 160.0) * exp(-age * 24.0)
				signal_value += sin(TAU * note.x * age) * envelope
		data.encode_s16(i * 2, roundi(signal_value * 6900.0))
	stream.data = data
	return stream
