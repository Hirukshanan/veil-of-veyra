extends Node3D

signal passage_opened

const PEDESTAL := Vector3(62.5,2.4,25)
const WALL := Vector3(67,2.6,32)
const DURATION := 18.0
const FLAG := "lantern_awakening"
const EYE_ATLAS = preload("res://assets/environment/lantern_awakening/approved_eye/eye_atlas.png")
const EYE_FRAME_SECONDS := 0.2
var game
var active := false
var clock := 0.0
var stage := "dormant"
var events:Array[Dictionary] = []
var pedestal:Node3D
var lantern_prop:Node3D
var glow:OmniLight3D
var gate:StaticBody3D
var chunks:Array[MeshInstance3D] = []
var cracks:Node3D
var dust:CPUParticles3D
var camera:Camera3D
var eye:TextureRect
var eye_frames:Array[AtlasTexture]=[]
var eye_frame := -1
var overlay:CanvasLayer
var fade:ColorRect
var skip_button:Button
var hint:Label3D
var music:AudioStreamPlayer
var rumble:AudioStreamPlayer3D
var roar:AudioStreamPlayer3D
var breath:AudioStreamPlayer3D
var old_camera:Camera3D
var hidden_layers:Array[CanvasLayer] = []
var old_invulnerability := 0.0
var old_hero_physics := true
var old_hero_input := true
var actor_physics:Dictionary = {}
var environment:Environment
var cinematic_fill:OmniLight3D
var starting_lantern := Vector3.ZERO
var last_eye_open := 0.0
const FRACTURE = preload("res://assets/audio/lantern_awakening/fracture.wav")
var owns_audio_bus := false
var trace_enabled := OS.get_environment("VEYRA_PROFILE_CINEMATIC")=="1"
var trace:Array=[]
func mark(label:String,begin:int):
	if not trace_enabled:return
	trace.append({"label":label,"us":Time.get_ticks_usec()-begin,"host_us":Time.get_ticks_usec(),"frame":Engine.get_process_frames(),"clock":clock})


func eligible() -> bool:
	return (game.completed or game.world_data.get("cursed_bear_defeated", false)) and game.lantern_lit and game.seal_fragments.complete() and 1 in game.relic_hunt.collected_ids

func finished() -> bool:
	return game.world_data.get(FLAG,false)

func near_pedestal() -> bool:
	return to_local(game.player.global_position).distance_to(PEDESTAL)<2.7

func quest() -> Dictionary:
	var count := int(game.completed or game.world_data.get("cursed_bear_defeated", false))+int(game.lantern_lit)+int(game.seal_fragments.complete())+int(1 in game.relic_hunt.collected_ids)
	return {"title":"The Lantern Awakening","description":"The cave relic names a stone altar in the inner chamber. Bring the restored lantern's light to its ancient platform.","objective":"Guardian overcome · restored lantern · whole seal · cave relic","value":5 if finished() else count,"total":5,"reward":"The hidden passage remains open.","next":"The crimson eye watches from the depths." if finished() else "Approach the inner chamber altar and use Interact." if eligible() else "Resolve the island's curse, restore the northern lantern and find the cave relic.","done":finished()}

func _ready():
	name="LanternAwakening"
	_build_pedestal()
	_build_wall()
	_build_camera_and_eye()
	_build_audio()
	_build_overlay()
	# The enclosed camera needs the approved cave shell and event props only.
	# Keep their normal gameplay layer; add a dedicated cinematic visibility bit.
	game.landscape.get_node("PlayableGrotto").layers |= 1<<18
	for item in game.player.find_children("*","GeometryInstance3D",true,false):item.layers |= 1<<18
	for item in find_children("*","GeometryInstance3D",true,false):
		item.layers |= 1<<18

	if finished():apply_open_state()
	set_process(true)
func stone() -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_texture=preload("res://assets/environment/new_island/task3/rock_albedo.png")
	material.normal_enabled=true
	material.normal_texture=preload("res://assets/environment/new_island/task3/rock_normal.png")
	material.albedo_color=Color(.48,.43,.36)
	material.roughness=.95
	material.uv1_triplanar=true
	material.uv1_scale=Vector3.ONE*.8
	return material

func mesh(parent:Node,shape:Mesh,at:Vector3,material:Material) -> MeshInstance3D:
	var item:=MeshInstance3D.new()
	item.mesh=shape
	item.position=at
	item.material_override=material
	item.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	item.visibility_range_end=100
	parent.add_child(item)
	return item

func cylinder(parent:Node,radius:float,height:float,at:Vector3,material:Material):
	var shape:=CylinderMesh.new()
	shape.top_radius=radius
	shape.bottom_radius=radius*1.08
	shape.height=height
	shape.radial_segments=16
	return mesh(parent,shape,at,material)

func _build_pedestal():
	pedestal=Node3D.new()
	pedestal.name="DescendingStoneAltar"
	pedestal.position=PEDESTAL
	add_child(pedestal)
	var rock:=stone()
	cylinder(pedestal,1.05,.25,Vector3(0,.12,0),rock)
	cylinder(pedestal,.63,1.25,Vector3(0,.85,0),rock)
	cylinder(pedestal,.91,.22,Vector3(0,1.58,0),rock)
	for height in [.34,1.38]:
		cylinder(pedestal,.71,.09,Vector3(0,height,0),rock)
	var body:=StaticBody3D.new()
	body.collision_layer=1|4|8
	pedestal.add_child(body)
	var collision:=CollisionShape3D.new()
	var shape:=CylinderShape3D.new()
	shape.radius=.95;shape.height=1.7
	collision.shape=shape;collision.position.y=.85
	body.add_child(collision)
	lantern_prop=Node3D.new()
	lantern_prop.position=PEDESTAL+Vector3.UP*1.75
	add_child(lantern_prop)
	var brass:=StandardMaterial3D.new()
	brass.albedo_color=Color(.23,.14,.055)
	brass.metallic=.5;brass.roughness=.55
	cylinder(lantern_prop,.23,.08,Vector3.ZERO,brass)
	cylinder(lantern_prop,.25,.10,Vector3.UP*.56,brass)
	for corner in range(4):
		var angle:=corner*TAU/4+PI/4
		cylinder(lantern_prop,.026,.5,Vector3(cos(angle)*.18,.28,sin(angle)*.18),brass)
	var flame:=StandardMaterial3D.new()
	flame.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.albedo_color=Color(1,.56,.16)
	# Unshaded color already supplies the accepted flame brightness.
	var core:=SphereMesh.new();core.radius=.12;core.height=.32
	mesh(lantern_prop,core,Vector3.UP*.27,flame)
	glow=OmniLight3D.new();glow.light_cull_mask=1<<18;glow.omni_range=9;glow.light_color=Color(1,.63,.25)
	glow.light_energy=0;glow.shadow_enabled=false
	lantern_prop.add_child(glow)
	lantern_prop.hide()
	hint=Label3D.new();hint.position=PEDESTAL+Vector3.UP*2.55
	hint.font_size=28;hint.pixel_size=.008
	hint.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(hint)

func _build_wall():
	var rock:=stone()
	var rng:=RandomNumberGenerator.new();rng.seed=6202
	# A removable stone seal fills the existing reserved-hall arch, with no edits
	# to the approved cave mesh, relic route or collision source.
	var cells:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/lantern_awakening/seal_cells.json"))
	for cell in cells:
		var center:=Vector2.ZERO
		for point in cell:center+=Vector2(point[0],point[1])
		center/=cell.size()
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var points:Array[Vector3]=[]
		for point in cell:points.append(Vector3((point[0]-center.x)*.997,(point[1]-center.y)*.997,0))
		for index in range(points.size()):
			var a:=points[index];var b:=points[(index+1)%points.size()]
			var front:=Vector3(0,0,-.65-rng.randf()*.10)
			for vertex in [a+Vector3(0,0,-.63),b+Vector3(0,0,-.63),front,b+Vector3(0,0,.6),a+Vector3(0,0,.6),Vector3(0,0,.6),a+Vector3(0,0,-.63),a+Vector3(0,0,.6),b+Vector3(0,0,-.63),b+Vector3(0,0,-.63),a+Vector3(0,0,.6),b+Vector3(0,0,.6)]:surface.add_vertex(vertex)
		surface.generate_normals()
		var piece:=mesh(self,surface.commit(),WALL+Vector3(center.x,center.y,0),rock)
		piece.name="SealFracture%d"%chunks.size()
		piece.set_meta("rest",piece.position)
		piece.set_meta("velocity",Vector3(center.x*.4,1.3+center.y*.3,1.3+rng.randf()))
		chunks.append(piece)
	gate=StaticBody3D.new();gate.name="HiddenPassageSeal";gate.position=WALL+Vector3.UP*2.7
	gate.collision_layer=1|4|8;gate.collision_mask=0
	add_child(gate)
	var collision:=CollisionShape3D.new();collision.name="SealCollision"
	var shape:=BoxShape3D.new();shape.size=Vector3(9.4,5.5,1.4)
	collision.shape=shape;gate.add_child(collision)
	cracks=Node3D.new();add_child(cracks)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color(.48,.25,.09)
	for branch in range(8):
		for segment in range(4):
			var a:=crack_point(branch,segment)
			var b:=crack_point(branch,segment+1)
			var line:=CylinderMesh.new();line.top_radius=.012;line.bottom_radius=.023;line.height=a.distance_to(b);line.radial_segments=5
			var visible:=mesh(cracks,line,(a+b)*.5,material)
			visible.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
			visible.hide()
	dust=CPUParticles3D.new();dust.name="StoneDust";dust.amount=32
	dust.position=WALL+Vector3.UP*2
	dust.lifetime=2.5;dust.one_shot=true;dust.explosiveness=.55
	dust.direction=Vector3(0,.4,-1);dust.spread=65
	dust.initial_velocity_min=.3;dust.initial_velocity_max=1.8
	dust.gravity=Vector3(0,-.25,0);dust.scale_amount_min=.05;dust.scale_amount_max=.24
	var particle:=SphereMesh.new();particle.radius=.18;particle.height=.36;particle.radial_segments=6;particle.rings=3
	var dust_material:=StandardMaterial3D.new();dust_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;dust_material.albedo_color=Color(.30,.26,.21,.32)
	dust_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	particle.material=dust_material;dust.mesh=particle;dust.emitting=false
	dust.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)

func _build_camera_and_eye():
	camera=Camera3D.new();camera.far=50;camera.name="AwakeningCinematicCamera";camera.near=.08;camera.fov=58
	add_child(camera)
	environment=Environment.new();environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color.BLACK;environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color(.72,.65,.54);environment.ambient_light_energy=.8
	environment.ambient_light_sky_contribution=0
	environment.fog_enabled=false;environment.fog_mode=Environment.FOG_MODE_DEPTH
	environment.fog_light_color=Color.BLACK;environment.fog_depth_begin=5;environment.fog_depth_end=22
	camera.environment=null
	cinematic_fill=OmniLight3D.new();cinematic_fill.light_cull_mask=1<<18
	cinematic_fill.position=Vector3(66,5.7,27)
	cinematic_fill.light_color=Color(.85,.70,.48)
	cinematic_fill.omni_range=16;cinematic_fill.light_energy=0;cinematic_fill.shadow_enabled=false
	add_child(cinematic_fill)

func _build_audio():
	var bus:=AudioServer.get_bus_index("LanternCave")
	if bus<0:
		bus=AudioServer.bus_count;AudioServer.add_bus();AudioServer.set_bus_name(bus,"LanternCave")
		owns_audio_bus=true
		var reverb:=AudioEffectReverb.new();reverb.room_size=.85;reverb.wet=.28;reverb.dry=.8
		AudioServer.add_bus_effect(bus,reverb)
	rumble=audio_3d("stone.wav",PEDESTAL,-15)
	roar=audio_3d("dragon_roar.wav",Vector3(64,6,45),-9)
	breath=audio_3d("breathing.wav",Vector3(64,5.5,48),-14)
	music=AudioStreamPlayer.new();music.stream=load("res://assets/audio/lantern_awakening/tension.wav")
	music.volume_db=-15;add_child(music)

func audio_3d(file:String,at:Vector3,gain:float) -> AudioStreamPlayer3D:
	var sound:=AudioStreamPlayer3D.new();sound.stream=load("res://assets/audio/lantern_awakening/"+file)
	sound.position=at;sound.volume_db=gain;sound.bus="LanternCave"
	sound.unit_size=12;sound.max_distance=70
	add_child(sound)
	return sound

func _build_overlay():
	overlay=CanvasLayer.new();overlay.layer=40;add_child(overlay)
	eye=TextureRect.new();eye.name="ApprovedDragonEye"
	eye.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	eye.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	eye.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	eye.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for index in range(6):
		var frame:=AtlasTexture.new();frame.atlas=EYE_ATLAS
		frame.region=Rect2((index%3)*1280,(index/3)*720,1280,720)
		frame.filter_clip=true;eye_frames.append(frame)
	eye.texture=eye_frames[0];eye.hide();overlay.add_child(eye)
	fade=ColorRect.new();fade.color=Color(0,0,0,0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(fade)
	var safe:=preload("res://scripts/safe_area.gd").new();overlay.add_child(safe)
	skip_button=Button.new();skip_button.text="Skip";skip_button.custom_minimum_size=Vector2(120,52)
	safe.add_child(skip_button)
	skip_button.anchor_left=1;skip_button.anchor_right=1
	skip_button.offset_left=-144;skip_button.offset_right=-24
	skip_button.offset_top=20;skip_button.offset_bottom=72
	skip_button.pressed.connect(skip)
	overlay.hide()

func start() -> bool:
	if active or finished() or not eligible() or not near_pedestal() or not game.started or game.game_finished or game.player.health<=0 or get_tree().paused:return false
	var measured_save:=Time.get_ticks_usec()
	game._save_progress()
	mark("start_save",measured_save)
	var measured_start:=Time.get_ticks_usec()
	game.player.set_move_input(Vector2.ZERO)
	game.player.cancel_touch_camera()
	game.player.cancel_swing()
	game.player.end_guard()
	get_tree().call_group("movement_joysticks","reset")
	get_tree().call_group("attack_gestures","cancel_hold")
	get_tree().call_group("gameplay_buttons","cancel_touch")
	old_camera=get_viewport().get_camera_3d()
	old_invulnerability=game.player._invulnerability_time
	old_hero_physics=game.player.is_physics_processing()
	old_hero_input=game.player.is_processing_input()
	game.player._invulnerability_time=100000
	game.player.set_physics_process(false)
	game.player.set_process_input(false)
	for actor in get_tree().get_nodes_in_group("combat_enemies"):
		actor_physics[actor]=actor.is_physics_processing()
		actor.set_physics_process(false)
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer!=overlay and layer.visible:
			hidden_layers.append(layer);layer.hide()
	process_mode=Node.PROCESS_MODE_ALWAYS
	active=true;clock=0;stage="placement";events.clear()
	camera.fov=58;camera.environment=null
	starting_lantern=to_local(game.player.global_position)+Vector3(.25,1.1,0)
	lantern_prop.show();hint.hide();overlay.show();fade.color.a=0
	camera.cull_mask=1<<18;camera.make_current()
	mark("start_before_audio",measured_start)
	var measured_audio:=Time.get_ticks_usec()
	music.play();_event("lantern_placement")
	mark("start_audio",measured_audio)
	cinematic_fill.light_energy=2.0
	var measured_sample:=Time.get_ticks_usec()
	_sample(0)
	mark("start_sample",measured_sample)
	return true

func _event(value:String):
	stage=value
	events.append({"stage":value,"seconds":snappedf(clock,.01)})
	print("AWAKENING ",value," @ ",snappedf(clock,.01))

func _gate_cues() -> Array:
	return [[4.2,"spreading_fractures"],[5.8,"wall_break"]]

func _on_gate_motion() -> void:
	gate.get_child(0).set_deferred("disabled",true)
	dust.position=WALL+Vector3.UP*2
	dust.restart();dust.emitting=true
	rumble.position=WALL+Vector3.UP*2
	rumble.stream=FRACTURE;rumble.play()

func _darkness_cue() -> float:
	return 12.4

func _eye_cue() -> float:
	return 13.3

func _on_darkness() -> void:
	pass

func _on_eye_opening() -> void:
	breath.play()

func _process(delta:float):
	if not active:
		hint.visible=not finished() and to_local(game.player.global_position).distance_to(PEDESTAL)<10
		hint.text="Interact · Place lantern" if eligible() else "Ancient altar · dormant"
		return
	var measured_process:=Time.get_ticks_usec()
	var previous:=clock
	clock=minf(DURATION,clock+delta)
	for cue in ([[1.2,"stone_descent"]]+_gate_cues()+[[7.2,"distant_dragon_roar"],[8.0,"passage_camera"],[_darkness_cue(),"complete_darkness"],[_eye_cue(),"crimson_eye_opening"],[15.7,"music_cut"],[18.0,"return_to_hero"]]):
		if previous<float(cue[0]) and clock>=float(cue[0]):
			var measured_cue:=Time.get_ticks_usec()
			_event(cue[1])
			match cue[1]:
				"stone_descent":
					rumble.play()
					dust.position=PEDESTAL+Vector3.UP*.3
					dust.restart();dust.emitting=true
				"wall_break","seal_retraction": _on_gate_motion()
				"distant_dragon_roar":roar.play()
				"complete_darkness":_on_darkness()
				"crimson_eye_opening":_on_eye_opening()
				"music_cut":music.stop()
			mark("cue_"+str(cue[1]),measured_cue)
	var measured_sample:=Time.get_ticks_usec()
	_sample(clock)
	mark("sample",measured_sample)
	mark("process",measured_process)
	if clock>=DURATION:_finish(false)

func _sample(time:float):
	lantern_prop.position=starting_lantern.lerp(PEDESTAL+Vector3.UP*1.75,smoothstep(0,1.0,time))
	glow.light_energy=smoothstep(.7,1.5,time)*1.4
	var descent:=smoothstep(1.2,4.1,time)
	pedestal.position=PEDESTAL-Vector3.UP*descent*2.8
	lantern_prop.position-=Vector3.UP*descent*2.8
	for index in range(cracks.get_child_count()):cracks.get_child(index).visible=time>=4.2+index*.045 and time<5.8
	if time>=5.8:
		var falling:=minf(time-5.8,2.8)
		for index in range(chunks.size()):
			var piece:=chunks[index]
			var rest:Vector3=piece.get_meta("rest")
			var velocity:Vector3=piece.get_meta("velocity")
			piece.position=rest+velocity*falling+Vector3.DOWN*3*falling*falling
			piece.position.y=maxf(2.55,piece.position.y)
			piece.rotation=Vector3(falling*(index%3+.3),falling*.6,falling*.3)
			piece.visible=time<9.3
			if time>=9.3:_settled_piece(index)
	if time<7.2:
		var framing:=smoothstep(3.25,4.3,time)
		camera.position=Vector3(66,4.8,21.5).lerp(Vector3(66,4.5,26),framing)
		var altar_target:=PEDESTAL+Vector3.UP*lerpf(1.4,.3,descent)
		camera.look_at(to_global(altar_target.lerp(WALL+Vector3.UP*2.5,framing)))
	else:
		var travel:=smoothstep(7.2,12.4,time)
		camera.position=Vector3(66,4.5,26).lerp(Vector3(64,5.5,44.5),travel)
		camera.look_at(to_global((WALL+Vector3.UP*2.5).lerp(Vector3(64,5.5,48),travel)))
		camera.fov=lerpf(58,45,travel)
		cinematic_fill.light_energy=2.0*(1-travel)
	if time>=12.4:
		camera.environment=environment
		camera.cull_mask=1<<19
		eye.visible=time>=13.3 and time<17.3
		last_eye_open=clampf((time-13.3)/1.2,0,1)
		var index:=clampi(int(floor((time-13.3)/EYE_FRAME_SECONDS)),0,5)
		if index!=eye_frame:
			eye.texture=eye_frames[index];eye_frame=index
	var path_darkness:=.9*smoothstep(8.5,12.4,time) if time<12.4 else 0.0
	fade.color.a=maxf(path_darkness,smoothstep(15.7,16.2,time)*(1-smoothstep(17.3,18,time)))
	if time>=17.3:
		glow.light_energy=0
		eye.hide()
		if is_instance_valid(old_camera):old_camera.make_current()

func apply_open_state():
	pedestal.position=PEDESTAL-Vector3.UP*2.8
	lantern_prop.position=PEDESTAL+Vector3.UP*(1.75-2.8)
	lantern_prop.hide()
	for index in range(chunks.size()):_settled_piece(index)
	cracks.hide()
	gate.get_child(0).set_deferred("disabled",true)
	hint.hide()

func crack_point(branch:int,step:int) -> Vector3:
	return WALL+Vector3(sin(branch*1.4)*step*.55+sin(step*2+branch)*step*.045,2.1+cos(branch)*step*.45+sin(step*1.7+branch)*step*.025,-.76)

func _settled_piece(index:int):
	var piece:=chunks[index]
	piece.visible=index in [0,4,15,19]
	if not piece.visible:return
	var rest:Vector3=piece.get_meta("rest")
	piece.scale=Vector3.ONE*.4
	piece.position=WALL+Vector3(signf(rest.x-WALL.x)*4.15,.20,.6+float(index%3)*.5)
	piece.rotation=Vector3(.7,index*.7,.4)

func skip():
	if active:_finish(true)

func _finish(skipped:bool):
	if not active:return
	_event("skipped" if skipped else "completed")
	apply_open_state()
	for sound in [music,rumble,roar,breath]:sound.stop()
	cinematic_fill.light_energy=0;glow.light_energy=0
	eye.hide();overlay.hide();camera.clear_current()
	if is_instance_valid(old_camera):old_camera.make_current()
	for layer in hidden_layers:
		if is_instance_valid(layer):layer.show()
	hidden_layers.clear()
	game.player._invulnerability_time=old_invulnerability
	game.player.set_physics_process(old_hero_physics)
	game.player.set_process_input(old_hero_input)
	game.player.set_move_input(Vector2.ZERO)
	for actor in actor_physics:
		if is_instance_valid(actor):actor.set_physics_process(actor_physics[actor])
	actor_physics.clear()
	game.world_data[FLAG]=true
	passage_opened.emit()
	active=false
	var measured_save:=Time.get_ticks_usec()
	var saved:bool=game._save_progress()
	mark("finish_save",measured_save)
	game._resume()
	game.quest_feedback={"title":"BEYOND THE SEAL","message":"The hidden passage is open." if saved else "Passage open. Save pending.","until":Time.get_ticks_msec()+6000}

func _unhandled_input(event:InputEvent):
	if active and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		skip();get_viewport().set_input_as_handled()

func _exit_tree():
	for sound in [music,rumble,roar,breath]:
		if is_instance_valid(sound):sound.stop()
	if owns_audio_bus:
		var bus:=AudioServer.get_bus_index("LanternCave")
		if bus>=0:AudioServer.remove_bus(bus)
