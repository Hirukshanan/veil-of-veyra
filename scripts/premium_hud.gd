extends Control

const TITLE = preload("res://assets/ui/fonts/Cinzel.ttf")
const QUEST_ICON=preload("res://assets/ui/quest_scroll.svg")
const GOLD := Color("c9b783")
const INK := Color("f2ebd9")
var scene
var controller
var _portrait_image: TextureRect
var _map_image: TextureRect
var _map_overlay: Control
var _title_font: Font
static var _shared_title_font: Font

class MapOverlay extends Control:
	var hud
	func _draw(): hud.map_overlay(self)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if _shared_title_font==null:
		var bold:=FontVariation.new()
		bold.base_font=TITLE
		bold.variation_embolden=0.6
		_shared_title_font=bold
	_title_font=_shared_title_font
	if DisplayServer.get_name()!="headless":
		_make_portrait()
		_make_map()
	call_deferred("_map_labels")
	scene.player.health_changed.connect(func(_value: int,_maximum: int): queue_redraw())
	var timer:=Timer.new()
	timer.wait_time=0.1
	timer.autostart=true
	timer.timeout.connect(func():
		queue_redraw()
		if is_instance_valid(_map_overlay): _map_overlay.queue_redraw())
	add_child(timer)
	resized.connect(_layout_images)
	_layout_images()

func _circle_image(texture: Texture2D) -> TextureRect:
	var image:=TextureRect.new()
	image.texture=texture
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var shader:=Shader.new()
	shader.code="shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); c.a*=1.0-smoothstep(0.485,0.5,length(UV-vec2(0.5))); COLOR=c; }"
	var material:=ShaderMaterial.new()
	material.shader=shader
	image.material=material
	add_child(image)
	return image

func _make_portrait() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(128,128)
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(viewport)
	var actor=scene.player._visual.MODEL.instantiate()
	viewport.add_child(actor)
	actor.rotation.y=PI
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("1d2929")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("c0b6a1")
	environment.environment.ambient_light_energy=0.65
	viewport.add_child(environment)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-25,-35,0)
	light.light_energy=1.5
	viewport.add_child(light)
	var camera:=Camera3D.new()
	viewport.add_child(camera)
	camera.position=Vector3(0.04,1.65,-0.9)
	camera.look_at(Vector3(0,1.65,0))
	camera.fov=22
	camera.make_current()
	_portrait_image=_circle_image(viewport.get_texture())
	_freeze_view(viewport)

func _make_map() -> void:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(256,256)
	viewport.world_3d=scene.get_world_3d()
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	add_child(viewport)
	var camera:=Camera3D.new()
	viewport.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=250
	camera.position=Vector3(0,160,0)
	camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	camera.cull_mask=1
	camera.make_current()
	_map_image=_circle_image(viewport.get_texture())
	_freeze_view(viewport)
	_map_overlay=MapOverlay.new()
	_map_overlay.hud=self
	_map_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(_map_overlay)
	# Combat labels remain in gameplay; redundant environment labels move to HUD guidance.

func _freeze_view(viewport: SubViewport) -> void:
	# Explicitly stop both cached 3D captures after startup, including Compatibility backends.
	for frame in range(2): await RenderingServer.frame_post_draw
	if is_instance_valid(viewport): viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED

func _map_labels() -> void:
	for label in scene.find_children("*","Label3D",true,false):
		label.layers=2
		var owner_node: Node=label.get_parent()
		var combat_label:=false
		while owner_node!=null and owner_node!=scene:
			if owner_node.has_method("take_damage"):
				combat_label=true
				break
			owner_node=owner_node.get_parent()
		# Environmental directions/progress live in the quest panel/map, not across the hero.
		if not combat_label: label.hide()

func quest_content() -> Dictionary:
	var fragments: int=scene.seal_fragments.collected_ids.size() if is_instance_valid(scene.seal_fragments) else 0
	var data: Dictionary={"title":"THE LANTERN'S SEAL","message":"Recover the three seal fragments.","progress":"Seal %d/3   •   Camps %d/5" % [fragments,5-scene.remaining_enemies]}
	if scene.completed: data.message="The island is yours to explore."
	elif scene.boss_spawned: data.message="Defeat the Tidewraith Dragon."
	elif fragments==3 and scene.remaining_enemies==0: data.message="Restore the northern lantern."
	if is_instance_valid(scene.herbs) and scene.player.global_position.distance_to(scene.herbs.GROVE.CENTER)<18 and (not scene.boss_spawned or scene.completed):
		data.title="MOONLEAF GROVE"
		data.message="Gather Moonleaf flowers (%d / 3)." % mini(3,scene.herbs.grove_count())
		data.progress="Optional   •   25 shards reward" if not scene.world_data.grove_reward else "Reward collected   •   Explore the grove"
	return data

func _layout_images() -> void:
	if not is_instance_valid(controller): return
	var f: float=controller.ui_factor(size)
	if is_instance_valid(_portrait_image):
		_portrait_image.position=Vector2(20,18)
		_portrait_image.size=Vector2.ONE*82*f
	if is_instance_valid(_map_image):
		_map_image.size=Vector2.ONE*132*f
		_map_image.position=Vector2(size.x-20-132*f,18)
		_map_overlay.position=_map_image.position
		_map_overlay.size=_map_image.size

func _text(at: Vector2, text: String, pixels: float, color:=INK, title:=false) -> void:
	draw_string(_title_font if title else ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,maxi(12 if title else 11,int(pixels)),color)

func _panel(rect: Rect2) -> void:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.048,0.047,0.76)
	style.border_color=Color(0.69,0.61,0.40,0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	draw_style_box(style,rect)

func _bar(rect: Rect2, value: float, color: Color) -> void:
	var edge:=PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end-Vector2(8,0),rect.position+Vector2(-4,rect.size.y)])
	draw_colored_polygon(edge,Color("131a1b"))
	var fill:=rect.grow(-3)
	fill.size.x*=clampf(value,0,1)
	if fill.size.x>0:
		var cut:=minf(6,fill.size.x*0.3)
		draw_colored_polygon(PackedVector2Array([fill.position,fill.position+Vector2(fill.size.x,0),fill.end-Vector2(cut,0),fill.position+Vector2(-1,fill.size.y)]),color)
		draw_line(fill.position,fill.position+Vector2(fill.size.x,0),color.lightened(0.3),2)
	var outline:=edge.duplicate()
	outline.append(edge[0])
	draw_polyline(outline,GOLD,1.2,true)

func _draw() -> void:
	if not is_instance_valid(scene) or not is_instance_valid(controller): return
	var f: float=controller.ui_factor(size)
	var hero=scene.player
	var diameter:=82*f
	var origin:=Vector2(20,18)
	_panel(Rect2(origin+Vector2(52*f,2),Vector2(275*f,80*f)))
	draw_circle(origin+Vector2.ONE*diameter*0.5,diameter*0.5+3,Color("302b20"))
	draw_arc(origin+Vector2.ONE*diameter*0.5,diameter*0.5+3,0,TAU,64,GOLD,2,true)
	_text(origin+Vector2(94*f,20*f),"Lv. %d" % hero.level,22*f,INK,true)
	_text(origin+Vector2(242*f,19*f),"ARU",12*f,GOLD,true)
	_bar(Rect2(origin+Vector2(92*f,28*f),Vector2(218*f,20*f)),float(hero.health)/hero.max_health,Color("a92c24"))
	_text(origin+Vector2(160*f,43*f),"%d / %d" % [hero.health,hero.max_health],13*f)
	_bar(Rect2(origin+Vector2(92*f,53*f),Vector2(208*f,17*f)),hero.stamina/100.0,Color("16778c"))
	_text(origin+Vector2(166*f,66*f),"%d / 100" % int(hero.stamina),12*f)
	var quest:=Rect2(20,118*f+18,286*f,94*f)
	_panel(quest)
	draw_texture_rect(QUEST_ICON,Rect2(quest.position+Vector2(9*f,8*f),Vector2.ONE*23*f),false,GOLD)
	var content:=quest_content()
	_text(quest.position+Vector2(39*f,24*f),content.title,16*f,GOLD,true)
	draw_rect(Rect2(quest.position+Vector2(13*f,38*f),Vector2.ONE*10*f),GOLD,scene.completed,1)
	_text(quest.position+Vector2(31*f,48*f),content.message,14*f)
	_text(quest.position+Vector2(13*f,73*f),content.progress,12*f,Color("c7c9b8"))
	var utilities: Dictionary=controller.rectangles(size)
	var left:=origin.x+327*f+20
	var right: float=utilities.CampButton.position.x-18
	var middle: float=(left+right)*0.5
	var compass_width:=minf(300*f,right-left)
	if compass_width>100:
		_panel(Rect2(middle-compass_width*0.5,18,compass_width,42*f))
		var heading: float=rad_to_deg(-hero._camera_pivot.global_rotation.y)
		for i in range(-6,7):
			var bearing:=roundi(heading/15.0)*15+i*15
			var offset:=wrapf(float(bearing)-heading,-180,180)/180*compass_width
			if absf(offset)>compass_width*0.46: continue
			var at:=Vector2(middle+offset,18+17*f)
			draw_line(at-Vector2(0,7*f),at,Color(1,0.94,0.75,0.65),1)
			if posmod(bearing,45)==0:
				_text(at+Vector2(-6,16*f),["N","NE","E","SE","S","SW","W","NW"][posmod(bearing/45,8)],11*f)
		draw_colored_polygon(PackedVector2Array([Vector2(middle-4,19),Vector2(middle+4,19),Vector2(middle,25)]),GOLD)
	# Only this compact quick bar appears in gameplay; editing panels live elsewhere.
	for i in range(3):
		var center:=Vector2(size.x*0.5+(i-1)*66*f,size.y-48*f)
		draw_arc(center,29*f,0,TAU,40,Color(0.72,0.66,0.49,0.6),1,true)
		var potion_side: int=2 if (controller.left_handed or controller.profile.preset=="Left-Handed") else 0
		if i!=potion_side: _text(center+Vector2(-5,5),"—",14*f,Color("6c766e"))
	var potion_rect: Rect2=utilities.HealButton
	_text(potion_rect.end-Vector2(8,3),"%d" % scene.potions,14*f,GOLD)

func map_overlay(canvas: Control) -> void:
	if not is_instance_valid(scene): return
	var center:=canvas.size*0.5
	var radius:=canvas.size.x*0.5
	canvas.draw_arc(center,radius,0,TAU,64,GOLD,2,true)
	canvas.draw_arc(center,radius-4,0,TAU,64,Color(0.8,0.75,0.55,0.55),1,true)
	canvas.draw_string(TITLE,Vector2(center.x-5,14),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,INK)
	for enemy in get_tree().get_nodes_in_group("lock_targets"):
		if is_instance_valid(enemy) and enemy.health>0:
			var at:=center+Vector2(enemy.global_position.x,enemy.global_position.z)*radius/125
			if at.distance_to(center)<radius-8: canvas.draw_circle(at,2.4,Color("da674e"))
	if is_instance_valid(scene.seal_fragments) and not scene.seal_fragments.complete():
		var seal:=center+Vector2(-44,54)*radius/125
		canvas.draw_colored_polygon(PackedVector2Array([seal+Vector2(0,-4),seal+Vector2(4,0),seal+Vector2(0,4),seal+Vector2(-4,0)]),Color("e6c55f"))
	var at:=center+Vector2(scene.player.global_position.x,scene.player.global_position.z)*radius/125
	var heading: float=scene.player.global_rotation.y
	var forward:=Vector2(-sin(heading),-cos(heading))
	var right:=Vector2(-forward.y,forward.x)
	canvas.draw_colored_polygon(PackedVector2Array([at+forward*6,at-forward*4+right*4,at-forward*4-right*4]),Color("fff9dc"))
