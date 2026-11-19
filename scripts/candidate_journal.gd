extends Control

const Q = preload("res://scripts/chapter_one_quests.gd")
const PAPER = preload("res://assets/ui/quest_parchment.jpg")
const TITLE = preload("res://assets/ui/fonts/Cinzel.ttf")
const BODY = preload("res://assets/ui/fonts/CrimsonText-Regular.ttf")
const INK = Color("3b281b")
const LINE = Color("946b3c")
var game
var section := "Main"
var selected := "main"
var mobile_prompts := OS.has_feature("android") or OS.has_feature("ios")
var page: VBoxContainer
var sheet: Control
var paper_body: TextureRect
var upper_roller: TextureRect
var lower_roller: TextureRect
var reveal: Control
var detail_scroll: ScrollContainer
var motion: Tween
var content_motion: Tween
var closing := false
var unroll := 0.0
var last_layout_size := Vector2.ZERO

static func entry(g, id: String) -> Dictionary:
	if id=="awakening":
		return g.awakening_quest()
	var s := Q.snapshot(g)
	var goal := Q.current(g)
	match id:
		"watch":
			return row("Western Watch","Two wolves still haunt the western forest trails.","Western wolves",2-s.watch_remaining,2,"15 Tide Shards after reporting and victory.","Accept the bounty." if not s.accepted else ("Clear the western pair." if s.watch_remaining else ("Report your success." if not s.reported else "Claimed." if s.bounty_reward else "Defeat the Tidewraith.")),s.bounty_reward)
		"relic":
			return row("Keeper's Relics","Search the grassland trail, mountain foothills and eastern cave.","Golden relics",s.relics,3,"20 Tide Shards after victory.","Approach a golden relic." if s.relics<3 else "Defeat the Tidewraith." if not s.completed else "Claimed.",s.relic_reward)
		"grove":
			return row("Moonleaf Grove","Follow the meadow paths to the grove beyond the river.","Grove flowers",mini(3,s.grove),3,"One potion per flower and 25 Tide Shards for three.","Gather Moonleaf in the grove." if not s.grove_reward else "Claimed.",s.grove_reward)
	var intro: Dictionary = g.opening_journal() if g.has_method("opening_journal") else {}
	var description: String = intro.get("guide", goal.guide)
	var finding: String = intro.get("finding", "")
	if not finding.is_empty() and not description.contains(finding):
		description += "\n\n" + finding
	var progress: String = intro.get("progress", "Seal %d/3   ·   Camps %d/5" % [s.seals,5-s.camps])
	return row(intro.get("title", goal.title),description,progress,s.seals+5-s.camps+int(s.lantern)+int(s.completed),10,goal.reward,intro.get("next", goal.next),s.completed)

static func row(title,description,objective,value,total,reward,next,done) -> Dictionary:
	return {"title":title,"description":description,"objective":objective,"value":value,"total":total,"reward":reward,"next":next,"done":done}



class Ornament extends Control:
	func _ready():
		custom_minimum_size = Vector2(14,12)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw():
		var center := size * .5
		draw_line(Vector2(0,center.y),center-Vector2(12,0),LINE,1,true)
		draw_line(center+Vector2(12,0),Vector2(size.x,center.y),LINE,1,true)
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-4),center+Vector2(4,0),center+Vector2(0,4),center+Vector2(-4,0)]),LINE)

class Stamp extends Control:
	func _ready():
		custom_minimum_size = Vector2(50,50)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw():
		var color := Color(.38,.22,.14,.7)
		draw_arc(Vector2(25,25),22,0,TAU,40,color,1.5,true)
		draw_arc(Vector2(25,25),18,0,TAU,40,color,1,true)
		draw_polyline(PackedVector2Array([Vector2(14,25),Vector2(22,33),Vector2(36,17)]),color,3,true)

class Shard extends Control:
	func _ready():
		custom_minimum_size = Vector2(24,28)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw():
		draw_colored_polygon(PackedVector2Array([Vector2(12,2),Vector2(22,13),Vector2(12,26),Vector2(2,13)]),Color("826234"))
		draw_polyline(PackedVector2Array([Vector2(12,4),Vector2(6,13),Vector2(12,23)]),Color("c2a06a"),1.5,true)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	sheet = Control.new()
	add_child(sheet)
	paper_body = artwork(Rect2(65,140,665,525))
	upper_roller = artwork(Rect2(0,36,794,112))
	lower_roller = artwork(Rect2(0,655,794,120))
	reveal = Control.new()
	reveal.clip_contents = true
	sheet.add_child(reveal)
	page = VBoxContainer.new()
	reveal.add_child(page)
	page.add_theme_constant_override("separation",9)
	resized.connect(_layout)
	render()
	_layout()
	page.modulate.a = 0
	motion = create_tween().set_parallel(true)
	motion.tween_method(_set_unroll,0.0,1.0,.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(page,"modulate:a",1.0,.13).set_delay(.12)

func artwork(region:Rect2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = PAPER
	atlas.region = region
	var image := TextureRect.new()
	image.texture = atlas
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Reuse the original artwork's inexpensive white-background key.
	image.material = game.quest_parchment.material
	sheet.add_child(image)
	return image

func _layout():
	if not is_instance_valid(sheet):
		return
	var width := minf(size.x-12,1500)
	sheet.position = Vector2((size.x-width)*.5,6)
	sheet.size = Vector2(width,size.y-12)
	_set_unroll(unroll)
	if page.get_child_count()>0 and last_layout_size != size:
		last_layout_size = size
		# Width changes update wrapping and touch typography without moving gameplay.
		page.add_theme_constant_override("separation",7 if size.y<500 else 9)

func _set_unroll(value:float):
	unroll = value
	var roller_height := clampf(sheet.size.y*.115,35,82)
	var full_height := sheet.size.y-roller_height*1.5
	var height := maxf(1,full_height*value)
	var top := (sheet.size.y-height)*.5
	paper_body.position = Vector2(0,top)
	paper_body.size = Vector2(sheet.size.x,height)
	upper_roller.position = Vector2(0,top-roller_height*.7)
	upper_roller.size = Vector2(sheet.size.x,roller_height)
	lower_roller.position = Vector2(0,top+height-roller_height*.3)
	lower_roller.size = Vector2(sheet.size.x,roller_height)
	var inset := sheet.size.x*.125
	var content_top := roller_height*1.25+8
	var content_height := maxf(1,sheet.size.y-2*content_top)
	var visible_height := content_height*value
	reveal.position = Vector2(inset,(sheet.size.y-visible_height)*.5)
	reveal.size = Vector2(sheet.size.x-2*inset,visible_height)
	page.position = Vector2(0,-(content_height-visible_height)*.5)
	page.size = Vector2(reveal.size.x,content_height)

func close(finished:Callable):
	if closing:
		return
	closing = true
	for action in page.find_children("*","Button",true,false):
		action.disabled = true
	if motion and motion.is_valid():
		motion.kill()
	motion = create_tween().set_parallel(true)
	motion.tween_property(page,"modulate:a",0.0,.09)
	motion.tween_method(_set_unroll,unroll,0.0,.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	motion.chain().tween_callback(finished)

func prompt_text(value:String) -> String:
	if mobile_prompts:
		return value.replace("COLLECT / E","Pick / Interact").replace("LIGHT / E","Interact")
	return value

func label(parent:Node,value:String,font_size:int,heading:=false) -> Label:
	var item := Label.new()
	item.text = prompt_text(value)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_color_override("font_color",INK)
	item.add_theme_font_override("font",TITLE if heading else BODY)
	item.add_theme_font_size_override("font_size",font_size)
	parent.add_child(item)
	return item

func button(parent:Node,caption:String,action:Callable,active:=false) -> Button:
	var item := Button.new()
	item.text = caption
	item.custom_minimum_size = Vector2(130,48)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("65462e") if active else Color(.83,.69,.46,.45)
	normal.border_color = Color("a2814e")
	normal.set_border_width_all(1)
	normal.border_width_bottom = 2
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hover := normal.duplicate()
	hover.bg_color = Color("947047")
	var focus := normal.duplicate()
	focus.bg_color.a = 0
	focus.border_color = Color("5c3822")
	focus.set_border_width_all(2)
	item.add_theme_stylebox_override("normal",normal)
	item.add_theme_stylebox_override("hover",hover)
	item.add_theme_stylebox_override("pressed",hover)
	item.add_theme_stylebox_override("focus",focus)
	item.add_theme_color_override("font_color",Color("f8e9c7") if active else INK)
	item.add_theme_font_override("font",TITLE)
	item.add_theme_font_size_override("font_size",16)
	parent.add_child(item)
	item.pressed.connect(action)
	return item

func choose(group:String,id:String):
	if closing:
		return
	section = group
	selected = id
	render()

func render():
	if content_motion and content_motion.is_valid():
		content_motion.kill()
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	var compact := size.x<1000
	var top := HBoxContainer.new()
	page.add_child(top)
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	label(title,"CHAPTER I",12,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label(title,"Quests of Veyra",22 if compact else 28,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button(top,"Return to hunt",game._close_journal_animated).custom_minimum_size.x = 170
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation",6)
	page.add_child(tabs)
	for group in ["Main","Side","Completed"]:
		button(tabs,group,choose.bind(group,""),section==group)
	page.add_child(Ornament.new())
	var spread := HBoxContainer.new()
	spread.add_theme_constant_override("separation",16)
	page.add_child(spread)
	spread.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var index_scroll := preload("res://scripts/mobile_settings.gd").TouchScroll.new()
	index_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	index_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	index_scroll.size_flags_stretch_ratio = 1
	spread.add_child(index_scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation",10)
	index_scroll.add_child(stack)
	var ids:Array = []
	for id in ["main","awakening","watch","relic","grove"]:
		var quest := entry(game,id)
		if section==("Completed" if quest.done else "Main" if id in ["main","awakening"] else "Side"):
			ids.append(id)
	if selected not in ids:
		selected = "" if ids.is_empty() else ids[0]
	for id in ids:
		var quest := entry(game,id)
		var item := button(stack,str(quest.title).capitalize(),choose.bind(section,id),selected==id)
		item.custom_minimum_size.y = 58
		match id:
			"watch": item.icon = preload("res://assets/ui/controls/attack.svg")
			"relic": item.icon = preload("res://assets/ui/controls/collect.svg")
			"grove": item.icon = preload("res://assets/ui/controls/potion.svg")
			_: item.icon = preload("res://assets/ui/quest_scroll.svg")
		item.expand_icon = true
		item.add_theme_constant_override("icon_max_width",18)
	var divider := VSeparator.new()
	var separator_style := StyleBoxLine.new()
	separator_style.color = Color(.46,.31,.17,.35)
	separator_style.vertical = true
	divider.add_theme_stylebox_override("separator",separator_style)
	spread.add_child(divider)
	detail_scroll = preload("res://scripts/mobile_settings.gd").TouchScroll.new()
	spread.add_child(detail_scroll)
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_stretch_ratio = 2.35
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var detail := VBoxContainer.new()
	detail_scroll.add_child(detail)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",8)
	if selected=="":
		label(detail,"Your deeds will be recorded here.",24)
		return
	var quest := entry(game,selected)
	var heading := HBoxContainer.new()
	detail.add_child(heading)
	label(heading,str(quest.title).capitalize(),22 if compact else 27,true).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if quest.done:
		heading.add_child(Stamp.new())
		label(detail,"COMPLETED",14,true)
	label(detail,quest.description,21 if compact else 23)
	label(detail,quest.objective if selected=="main" else quest.objective+"   %d / %d" % [quest.value,quest.total],16 if compact else 18,true)
	var bar := ProgressBar.new()
	bar.max_value = quest.total
	bar.value = quest.value
	bar.show_percentage = false
	bar.custom_minimum_size.y = 10
	var background := StyleBoxFlat.new()
	background.bg_color = Color(.29,.19,.1,.2)
	background.border_color = LINE
	background.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("8b6939")
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
	detail.add_child(bar)
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation",12)
	detail.add_child(rewards)
	var icon := TextureRect.new()
	icon.texture = preload("res://assets/ui/controls/potion.svg") if selected=="grove" else preload("res://assets/ui/controls/lantern.svg")
	icon.custom_minimum_size = Vector2(27,27)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.self_modulate = Color("6d4b26")
	rewards.add_child(icon)
	if selected not in ["main","awakening"]:
		rewards.add_child(Shard.new())
		if selected!="grove":
			icon.hide()
	label(rewards,quest.reward,21).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(detail,"Next step",13,true)
	label(detail,quest.next,21)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation",8)
	detail.add_child(actions)
	if selected=="watch" and not game.keeper.reported:
		if not game.keeper.accepted:
			button(actions,"Accept bounty",game._accept_scroll_quest)
		elif game.keeper.remaining()==0:
			button(actions,"Report bounty",game._complete_scroll_quest)
	if not quest.done:
		button(actions,"Tracked" if game.tracked_quest==selected else "Track quest",track,game.tracked_quest==selected)
	detail.modulate.a = .7
	content_motion = create_tween()
	content_motion.tween_property(detail,"modulate:a",1,.1)

func track():
	game.set_tracked_quest(selected)
	render()
