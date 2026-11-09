extends Control

signal play_requested
signal blade_requested
signal armor_requested
signal quests_requested
signal guides_requested
signal settings_requested
signal reset_requested
signal quit_requested

const TITLE_FONT = preload("res://assets/ui/fonts/Cinzel.ttf")
const ART = preload("res://assets/ui/brand/dragon_lantern.png")
const INK := Color("f2e6ce")
const MUTED := Color("98aba8")
const GOLD := Color("c6a56b")
var buttons := {}
var _stats: Array[Panel] = []
var _eyebrow: Label
var _title: Label
var _subtitle: Label
var _footer: Label
var _art: Panel
var _art_image: TextureRect
var _art_heading: Label
var _art_caption: Label
var _art_tag: Label
var _blade_detail: Label
var _armor_detail: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_eyebrow = _label("A WARDEN'S JOURNEY", 12, GOLD)
	_title = _label("VEIL OF\nVEYRA", 50, INK, true)
	_subtitle = _label("An island in shadow. A light worth reclaiming.", 18, MUTED)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for caption in ["TIDE SHARDS", "BLADE", "ARMOR"]:
		var stat := Panel.new()
		stat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stat.add_theme_stylebox_override("panel", _style(Color("101f25"), Color("2a3b3c"), 10))
		add_child(stat)
		var value := _label("0", 23, INK, false, stat)
		value.name = "Value"
		var title := _label(caption, 10, MUTED, false, stat)
		title.name = "Caption"
		_stats.append(stat)
	_button("play", "CONTINUE JOURNEY    >", play_requested, true)
	_button("blade", "UPGRADE BLADE", blade_requested)
	_button("armor", "UPGRADE ARMOR", armor_requested)
	_blade_detail = _label("", 13, MUTED)
	_armor_detail = _label("", 13, MUTED)
	for entry in [["quests","Quest journal",quests_requested],["guides","Field guide",guides_requested],["settings","Settings",settings_requested],["reset","New journey",reset_requested],["quit","Quit",quit_requested]]:
		_button(entry[0],entry[1],entry[2])
	_footer = _label("Your journey is saved on this device.",12,MUTED)
	_footer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_art = Panel.new()
	_art.clip_contents = true
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.add_theme_stylebox_override("panel",_style(Color("07141c"),Color("6c593e"),18))
	add_child(_art)
	_art_image = TextureRect.new()
	_art_image.texture = ART
	_art_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.add_child(_art_image)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
 vec4 art = texture(TEXTURE, UV);
 float vignette = (1.0 - smoothstep(0.0, 0.65, length(UV - vec2(0.5))));
 float shade = smoothstep(0.58, 1.0, UV.y);
 COLOR = vec4(art.rgb * (0.7 + 0.3 * vignette) * (1.0 - shade * 0.9), art.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	_art_image.material = material
	_art_tag = _label("VEYRA  /  ISLAND CHRONICLES",11,INK,false,_art)
	_art_tag.add_theme_color_override("font_color",GOLD)
	_art_heading = _label("THE TIDEWRAITH",23,INK,true,_art)
	_art_caption = _label("Clear the camps. Restore the lantern.\nFace the darkness beyond the reef.",15,Color("b5c7c4"),false,_art)
	_art_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resized.connect(_layout)
	_layout()

func configure(shards: int, blade: int, armor: int, blade_cost: int, armor_cost: int, completed: bool, notice: String, stage: String) -> void:
	_stats[0].get_node("Value").text = str(shards)
	_stats[1].get_node("Value").text = "%d / 5" % (blade + 1)
	_stats[2].get_node("Value").text = "%d / 5" % (armor + 1)
	buttons.blade.disabled = blade >= 4 or shards < blade_cost
	buttons.armor.disabled = armor >= 4 or shards < armor_cost
	_blade_detail.text = "Fully upgraded" if blade >= 4 else "%d shards  /  +1 sword damage" % blade_cost
	_armor_detail.text = "Fully upgraded" if armor >= 4 else "%d shards  /  +25 vitality" % armor_cost
	_footer.text = notice if not notice.is_empty() else "Your journey is saved on this device."
	_footer.tooltip_text = _footer.text
	if "unreadable" in notice.to_lower():
		_footer.text = "Save unreadable. Start a New journey to enable saving."
	elif "fail" in notice.to_lower():
		_footer.text = "Save failed. Keep the game open; return to camp to retry."
	_footer.modulate = Color("ffba91") if "fail" in notice.to_lower() or "unreadable" in notice.to_lower() else Color.WHITE
	_art_heading.text = "LIGHT RETURNS" if completed else "THE TIDEWRAITH"
	_art_caption.text = "The island endures. Explore the grove\nand complete your remaining quests." if completed else stage
	_eyebrow.text = "THE ISLAND REMEMBERS" if completed else "A WARDEN'S JOURNEY"
	_layout()

func _button(id: String, text: String, event: Signal, primary := false) -> void:
	var button := Button.new()
	button.name = id.capitalize() + "Button"
	button.text = text
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font",TITLE_FONT if primary else ThemeDB.fallback_font)
	button.add_theme_color_override("font_color",INK)
	button.add_theme_color_override("font_disabled_color",Color("677f7b"))
	button.add_theme_stylebox_override("normal",_style(Color("174e4e") if primary else Color("10252b"),GOLD if primary else Color("355153"),10))
	button.add_theme_stylebox_override("hover",_style(Color("236968") if primary else Color("1c393f"),GOLD,10))
	button.add_theme_stylebox_override("pressed",_style(Color("123536"),Color("e4c085"),10))
	button.add_theme_stylebox_override("disabled",_style(Color("101b20"),Color("263738"),10))
	var focus := _style(Color(0,0,0,0),Color("edd29d"),10)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus",focus)
	button.pressed.connect(func(): event.emit())
	buttons[id] = button
	add_child(button)

func _label(text: String, font_size: int, color: Color, title := false, parent: Node = null) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	if title: label.add_theme_font_override("font",TITLE_FONT)
	if parent == null:
		add_child(label)
	else:
		parent.add_child(label)
	return label

func _style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _layout() -> void:
	if _title == null: return
	var unit := clampf((size.y - 40.0) / 548.0,0.62,1.35)
	var margin := 24.0 * unit
	var gap := 20.0 * unit
	var width := size.x - margin * 2
	var left := (width - gap) * 0.55
	var right := width - left - gap
	_place(_eyebrow,Rect2(margin,margin,left,20))
	_place(_title,Rect2(margin,margin+24*unit,left,112*unit))
	_title.add_theme_font_size_override("font_size",roundi(46*unit))
	_place(_subtitle,Rect2(margin,margin+142*unit,left,44*unit))
	_subtitle.add_theme_font_size_override("font_size",maxi(14,roundi(18*unit)))
	for index in range(3):
		var cell := (left - gap) / 3
		_place(_stats[index],Rect2(margin+index*(cell+gap*0.5),margin+200*unit,cell,54*unit))
		var value: Label = _stats[index].get_node("Value")
		var caption: Label = _stats[index].get_node("Caption")
		value.add_theme_font_size_override("font_size",maxi(18,roundi(23*unit)))
		_place(value,Rect2(12,20*unit,cell-24,32*unit))
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		value.vertical_alignment=VERTICAL_ALIGNMENT_TOP
		caption.add_theme_font_size_override("font_size",maxi(9,roundi(10*unit)))
		_place(caption,Rect2(12,5*unit,cell-24,15*unit))
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		caption.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	_place(buttons.play,Rect2(margin,margin+272*unit,left,maxf(48,60*unit)))
	buttons.play.add_theme_font_size_override("font_size",maxi(16,roundi(20*unit)))
	var card_width := (left-gap*0.5)*0.5
	for index in range(2):
		var button: Button = buttons.blade if index==0 else buttons.armor
		_place(button,Rect2(margin+index*(card_width+gap*0.5),margin+346*unit,card_width,maxf(44,48*unit)))
		button.add_theme_font_size_override("font_size",maxi(12,roundi(14*unit)))
		var detail := _blade_detail if index==0 else _armor_detail
		_place(detail,Rect2(button.position.x,button.position.y+button.size.y+6,card_width,26))
		detail.add_theme_font_size_override("font_size",maxi(11,roundi(13*unit)))
		detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text=detail.text
	var nav_width := (width-gap*2)/5
	for index in range(5):
		var id: String = ["quests","guides","settings","reset","quit"][index]
		var button: Button = buttons[id]
		_place(button,Rect2(margin+index*(nav_width+gap*0.5),size.y-margin-62,nav_width,42))
		button.add_theme_font_size_override("font_size",maxi(13,roundi(15*unit)))
	_place(_footer,Rect2(margin,size.y-margin-16,width,20))
	_place(_art,Rect2(margin+left+gap,margin,right,maxf(80,size.y-margin*2-85)))
	_art_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_place(_art_tag,Rect2(18,18,right-36,18))
	_place(_art_heading,Rect2(18,_art.size.y-90*unit,right-36,32*unit))
	_art_heading.add_theme_font_size_override("font_size",maxi(15,roundi(23*unit)))
	_place(_art_caption,Rect2(18,_art.size.y-54*unit,right-36,48*unit))
	_art_caption.add_theme_font_size_override("font_size",maxi(12,roundi(15*unit)))
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("071218"))
	var unit := clampf((size.y-40)/548,0.62,1.35)
	var start := Vector2(24,191)*unit
	draw_line(start,start+Vector2(52,0),GOLD,2)
	draw_line(start+Vector2(60,0),Vector2(size.x*0.52,start.y),Color("263d41"),1)
