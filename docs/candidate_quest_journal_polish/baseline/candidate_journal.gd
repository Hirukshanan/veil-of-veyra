extends TextureRect

const Q = preload("res://scripts/chapter_one_quests.gd")
const PAPER = preload("res://assets/ui/quest_parchment.jpg")
const TITLE = preload("res://assets/ui/fonts/Cinzel.ttf")
const BODY = preload("res://assets/ui/fonts/CrimsonText-Regular.ttf")
var game
var section := "Main"
var selected := "main"
var page: VBoxContainer

static func entry(g, id: String) -> Dictionary:
	var s := Q.snapshot(g)
	var goal := Q.current(g)
	match id:
		"watch":
			return row("Western Watch","Two wolves still haunt the western forest trails.","Western wolves",2-s.watch_remaining,2,"15 Tide Shards after reporting and victory.","Accept the bounty." if not s.accepted else ("Clear the western pair." if s.watch_remaining else ("Report your success." if not s.reported else "Claimed." if s.bounty_reward else "Defeat the Tidewraith.")),s.bounty_reward)
		"relic":
			return row("Keeper's Relics","Search the grassland trail, mountain foothills and eastern cave.","Golden relics",s.relics,3,"20 Tide Shards after victory.","Approach a golden relic." if s.relics<3 else "Defeat the Tidewraith." if not s.completed else "Claimed.",s.relic_reward)
		"grove":
			return row("Moonleaf Grove","Follow the meadow paths to the grove beyond the river.","Grove flowers",mini(3,s.grove),3,"One potion per flower and 25 Tide Shards for three.","Gather Moonleaf in the grove." if not s.grove_reward else "Claimed.",s.grove_reward)
	return row(goal.title,goal.guide,"Seal %d/3   ·   Camps %d/5" % [s.seals,5-s.camps],s.seals+5-s.camps+int(s.lantern)+int(s.completed),10,goal.reward,goal.next,s.completed)

static func row(title,description,objective,value,total,reward,next,done) -> Dictionary:
	return {"title":title,"description":description,"objective":objective,"value":value,"total":total,"reward":reward,"next":next,"done":done}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var paper := AtlasTexture.new()
	paper.atlas = PAPER
	var extent := PAPER.get_size()
	paper.region = Rect2(extent*Vector2(.32,.3),extent*Vector2(.36,.38))
	texture = paper
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	page = VBoxContainer.new()
	add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.offset_left=30
	page.offset_right=-30
	page.offset_top=16
	page.offset_bottom=-16
	page.add_theme_constant_override("separation",10)
	render()
	pivot_offset=size*.5
	scale=Vector2(.92,.82)
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(self,"scale",Vector2.ONE,.2)

func label(parent, value, font_size, heading=false):
	var l:=Label.new()
	l.text=value
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color",Color("392418"))
	l.add_theme_font_override("font",TITLE if heading else BODY)
	l.add_theme_font_size_override("font_size",font_size)
	parent.add_child(l)
	return l

func button(parent,caption,action,active=false):
	var b:=Button.new()
	b.text=caption
	b.custom_minimum_size=Vector2(0,48)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("663f2e") if active else Color("e3c496")
	style.border_color=Color("87623d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left=16
	style.content_margin_right=16
	b.add_theme_stylebox_override("normal",style)
	b.add_theme_color_override("font_color",Color("fff2d6") if active else Color("462b1c"))
	b.add_theme_font_override("font",TITLE)
	parent.add_child(b)
	b.pressed.connect(action)
	return b

func choose(group:String,id:String):
	section=group
	selected=id
	render()

func render():
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()
	var top:=HBoxContainer.new()
	page.add_child(top)
	label(top,"Chapter I   /   Quest Journal",32,true).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(top,"Return to hunt",game._resume)
	var tabs:=HBoxContainer.new()
	page.add_child(tabs)
	for group in ["Main","Side","Completed"]:
		button(tabs,group,choose.bind(group,""),section==group)
	page.add_child(HSeparator.new())
	var spread:=HBoxContainer.new()
	spread.add_theme_constant_override("separation",24)
	page.add_child(spread)
	spread.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var stack:=VBoxContainer.new()
	spread.add_child(stack)
	stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var ids: Array=[]
	for id in ["main","watch","relic","grove"]:
		var q:=entry(game,id)
		if section==("Completed" if q.done else "Main" if id=="main" else "Side"):
			ids.append(id)
	if selected not in ids: selected="" if ids.is_empty() else ids[0]
	for id in ids:
		var q:=entry(game,id)
		button(stack,("✓ " if q.done else "")+str(q.title).capitalize(),choose.bind(section,id),selected==id)
	spread.add_child(VSeparator.new())
	var scroll:=preload("res://scripts/mobile_settings.gd").TouchScroll.new()
	spread.add_child(scroll)
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio=2.4
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var detail:=VBoxContainer.new()
	scroll.add_child(detail)
	detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",12)
	if selected=="":
		label(detail,"Completed quests will appear here.",24)
		return
	var q:=entry(game,selected)
	label(detail,q.title.capitalize(),30,true)
	label(detail,q.description,24)
	label(detail,q.objective if selected=="main" else q.objective+"   %d / %d" % [q.value,q.total],20,true)
	var bar:=ProgressBar.new()
	bar.max_value=q.total
	bar.value=q.value
	bar.show_percentage=false
	bar.custom_minimum_size.y=9
	detail.add_child(bar)
	label(detail,"◆  "+q.reward,22)
	label(detail,"Next   "+q.next,22)
	var actions:=HBoxContainer.new()
	detail.add_child(actions)
	if selected=="watch" and not game.keeper.reported:
		if not game.keeper.accepted: button(actions,"Accept bounty",game._accept_scroll_quest)
		elif game.keeper.remaining()==0: button(actions,"Report bounty",game._complete_scroll_quest)
	if not q.done:
		button(actions,"Tracked" if game.tracked_quest==selected else "Track quest",track,game.tracked_quest==selected)
	detail.modulate.a=.65
	create_tween().tween_property(detail,"modulate:a",1,.12)

func track():
	game.set_tracked_quest(selected)
	render()
