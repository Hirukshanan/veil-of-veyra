extends Control

signal closed
const DISPLAY := preload("res://assets/ui/fonts/Cinzel.ttf")
const BODY := preload("res://assets/ui/fonts/CrimsonText-Regular.ttf")
const ART := preload("res://assets/ui/brand/about_tidewraith.png")
const CREATOR := "Logachandran Hirukshanan"
const SOUNDTRACK := "Original Soundtrack & Music Direction — " + CREATOR

var scroll := ScrollContainer.new()
var closing := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base := ColorRect.new()
	base.color = Color("100e11")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe := preload("res://scripts/safe_area.gd").new()
	add_child(safe)
	var panel := PanelContainer.new()
	safe.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_right = .53
	panel.offset_left = 16
	panel.offset_top = 16
	panel.offset_bottom = -16
	var stone := StyleBoxFlat.new()
	stone.bg_color = Color("100c0be6")
	stone.border_color = Color("936f43")
	stone.set_border_width_all(1)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
		stone.set_content_margin(side,22)
	panel.add_theme_stylebox_override("panel",stone)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var bar := HBoxContainer.new()
	column.add_child(bar)
	var heading := label(bar,"About",26,true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := Button.new()
	back.text = "Back to menu"
	back.custom_minimum_size = Vector2(150,52)
	back.add_theme_font_override("font",DISPLAY)
	back.add_theme_color_override("font_color", Color("f3d89f"))
	back.add_theme_stylebox_override("normal", bronze_box("241810","89643f"))
	back.add_theme_stylebox_override("hover", bronze_box("37241a","bd945b"))
	back.add_theme_stylebox_override("pressed", bronze_box("4a3020","d1a76b"))
	back.add_theme_stylebox_override("focus", bronze_box("00000000","d8ad70"))
	bar.add_child(back)
	back.pressed.connect(close)
	back.grab_focus()
	column.add_theme_constant_override("separation",14)
	column.add_child(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 8
	var scrollbar := scroll.get_v_scroll_bar()
	scrollbar.add_theme_stylebox_override("scroll", bronze_box("1c1410","493423", 10))
	scrollbar.add_theme_stylebox_override("grabber", bronze_box("8c613c","b68752", 10))
	scrollbar.add_theme_stylebox_override("grabber_highlight", bronze_box("a87746","c39862", 10))
	scrollbar.add_theme_stylebox_override("grabber_pressed", bronze_box("b78953","dbb780", 10))
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation",10)
	scroll.add_child(page)
	label(page,"VEIL OF VERA",40,true)
	label(page,"The Curse Awakens",25,true)
	label(page,"An ancient darkness stirs beneath a forgotten island. As Aru, a lone warrior, restore a mysterious lantern and follow the traces of a curse buried deep within the land.",24)
	label(page,"Created & developed by",22,true)
	label(page,CREATOR,30,true)
	label(page,"Game Design · Story & Worldbuilding · Creative Direction\nProgramming & Development · Music & Soundtrack Creation",23)
	label(page,"An Independent Game Project",22)
	label(page,"Game information",27,true)
	label(page,"Chapter I · Dark Fantasy Action RPG · Single Player\nPlatform  Android   ·   Engine  Godot\nDeveloper  " + CREATOR + "\nVersion  " + str(ProjectSettings.get_setting("application/config/version")),23)
	label(page,"Mobile controls",27,true)
	label(page,"Movement — Drag the virtual joystick.\nCamera — Drag open space to turn the view.\nSword attack — Tap the sword button. Hold it for a heavy attack.\nDodge — Tap Dodge to evade.\nGuard — Hold the shield button to block.\nSpirit Burst — Tap Burst when your Spirit is full.\nInteract — Tap Pick / Interact when prompted.\nHealing potion — Tap the potion slot to heal.\nQuest Journal — Tap the journal icon to track objectives.\nCircular minimap — Follow your heading and nearby quest markers.\nPause — Tap the pause icon.",23)
	label(page,"Custom characters & world",27,true)
	label(page,"Creative design & development — " + CREATOR,24)
	label(page,"Cursed Bear (Demon Bear), Demon Boar and Demon Fox · Custom weapons, shields and armor · Island and environments, including Tidewarden Shrine and quest locations · Custom animation, visual effects and combat design.",23)
	label(page,"The Island and Demon Boar source models used Tripo3D. The Cursed Bear was developed from a project-supplied original with a custom Blender rig and animations. Demon Fox uses a project-specific mobile model with custom animations and combat integration. Modular Aru equipment was modeled in Blender.",23)
	label(page,"Original music",27,true)
	label(page,SOUNDTRACK,24)
	label(page,"Custom-generated game soundtracks were created under the developer’s direction using AI-assisted music tools.",23)
	label(page,"Asset credits & licenses",27,true)
	label(page,"Aru’s base character, outfit and animation library — Quaternius (CC0). Environment textures and scans — Poly Haven contributors (CC0). Dire Wolf Lite — Literock Studios / Literock Ventures.",23)
	link(page,"Dire Wolf Lite — Literock Studios","https://literock-studios.itch.io/direwolf-lite")
	link(page,"Ranger outfit — Quaternius","https://quaternius.com/packs/modularcharacteroutfitsfantasy.html")
	link(page,"Poly Haven license","https://polyhaven.com/license")
	label(page,"Charcoal Black Dark Dragon — Pigcraft (@s8819296), CC BY 4.0. Mesh reduced, UVs consolidated, orientation and scale normalized, rig and animations added. Custom adaptation and gameplay integration by " + CREATOR + ".",23)
	link(page,"Dragon model source","https://sketchfab.com/3d-models/charcoal-black-dark-dragon-25c51b198dd54e538f62569d52f61d8e")
	link(page,"Creative Commons Attribution 4.0","https://creativecommons.org/licenses/by/4.0/legalcode")
	label(page,"Music & sound",26,true)
	label(page,"Bear vocals include edited, pitched and layered recordings by the U.S. Fish & Wildlife Service (packaged by AntumDeluge, CC0) and Shizhao (CC BY 3.0). Boar and Dragon vocals use fvcalderan’s Boar (CC0). Impact Sounds and RPG Audio by Kenney (CC0).",23)
	link(page,"Bear Growls — recording","https://opengameart.org/content/bear-growls")
	link(page,"Bear growl.ogg — Shizhao","https://commons.wikimedia.org/wiki/File:Bear_growl.ogg")
	link(page,"Creative Commons Attribution 3.0","https://creativecommons.org/licenses/by/3.0/")
	link(page,"Boar — fvcalderan","https://opengameart.org/content/boar-0")
	link(page,"Kenney Impact Sounds","https://kenney.nl/assets/impact-sounds")
	link(page,"Kenney RPG Audio","https://kenney.nl/assets/rpg-audio")
	link(page,"CC0 public domain dedication","https://creativecommons.org/publicdomain/zero/1.0/")
	label(page,"Type & technology",26,true)
	label(page,"Cinzel © 2020 The Cinzel Project Authors. Crimson Text © 2010 The Crimson Text Project Authors. Both typefaces use the SIL Open Font License 1.1. Built with Godot Engine, distributed under the MIT license.",23)
	link(page,"Cinzel license","https://github.com/google/fonts/tree/main/ofl/cinzel")
	link(page,"Crimson Text license","https://github.com/google/fonts/tree/main/ofl/crimsontext")
	link(page,"Godot Engine license","https://godotengine.org/license/")
	modulate.a = 0
	create_tween().tween_property(self,"modulate:a",1.0,.20)

func bronze_box(fill: String, edge: String, width := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill)
	box.border_color = Color(edge)
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	box.content_margin_left = width * .5
	box.content_margin_right = width * .5
	return box

func label(parent: Control, copy: String, pixels: int, title := false) -> Label:
	var item := Label.new()
	item.text = copy
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_override("font",DISPLAY if title else BODY)
	item.add_theme_font_size_override("font_size",pixels)
	item.add_theme_color_override("font_color",Color("ebc890") if title else Color("e3dcd1"))
	parent.add_child(item)
	return item

func link(parent: Control, caption: String, url: String) -> void:
	var item := LinkButton.new()
	item.text = caption
	item.uri = url
	item.custom_minimum_size.y = 44
	item.add_theme_color_override("font_color", Color("dfbc82"))
	parent.add_child(item)

func close() -> void:
	if closing:
		return
	closing = true
	var fade := create_tween()
	fade.tween_property(self,"modulate:a",0.0,.15)
	fade.tween_callback(closed.emit)
	fade.tween_callback(queue_free)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
