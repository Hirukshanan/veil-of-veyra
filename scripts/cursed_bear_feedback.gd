extends Node3D

const ROAR := preload("res://assets/audio/cursed_bear/roar.wav")
const BREATH := preload("res://assets/audio/lantern_awakening/breathing.wav")
const SWIPE := preload("res://assets/audio/demon_boar/sword_swing.wav")
const SLAM := preload("res://assets/audio/demon_boar/charge_impact.wav")
const BITE := preload("res://assets/audio/demon_boar/hit_light.wav")
const ROCK := preload("res://assets/audio/lantern_awakening/fracture.wav")
const STEP := preload("res://assets/audio/demon_boar/hoof_b.wav")
const FALL := preload("res://assets/audio/demon_boar/death_land.wav")
const DUST := Color(.33,.26,.21,.31)
const STEAM := Color(.58,.55,.52,.24)
const CRIMSON := Color(.68,.045,.035,.56)
const POOL_SIZE := 32

@onready var bear = get_parent()
var skeleton: Skeleton3D
var head: int
var paws: Array[int] = []
var pieces: Array[MeshInstance3D] = []
var life := PackedFloat32Array()
var duration := PackedFloat32Array()
var speed := PackedVector3Array()
var gravity := PackedFloat32Array()
var growth := PackedFloat32Array()
var opacity := PackedFloat32Array()
var voices: Array[AudioStreamPlayer3D] = []
var cursor := 0
var puff := SphereMesh.new()
var stone := PrismMesh.new()
var ring := TorusMesh.new()
var glow: ShaderMaterial
var skin: MeshInstance3D
var clock := 0.0
var breath_at := .25
var breath_count := 0
var last_clip := ""
var last_time := -1.0
var last_tip := Vector3.ZERO
var trail_time := 0.0
var shock_played := false
var death_landed := false
var death_time := 0.0
var glow_strength := 0.0
var hit_at := 0.0
var foot_phase := -1
var step_at := 0.0

func _ready() -> void:
	skeleton = bear.get_node("Model").find_children("*","Skeleton3D",true,false)[0]
	skin = bear.get_node("Model").find_children("*","MeshInstance3D",true,false)[0]
	head = skeleton.find_bone("Head")
	for bone in ["ForePaw.L","ForePaw.R","HindPaw.L","HindPaw.R"]:
		paws.append(skeleton.find_bone(bone))
	puff.radial_segments = 8
	puff.rings = 3
	stone.size = Vector3.ONE
	ring.inner_radius = .91
	ring.outer_radius = 1
	ring.rings = 36
	ring.ring_segments = 5
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded,blend_add,depth_draw_never; uniform sampler2D fur : source_color,filter_linear_mipmap; uniform float strength; void fragment(){vec3 c=texture(fur,UV).rgb; float m=smoothstep(0.035,0.23,c.r-max(c.g,c.b)*2.3); ALBEDO=vec3(.85,.018,.006); ALPHA=m*strength;}"
	glow = ShaderMaterial.new()
	glow.shader = shader
	glow.set_shader_parameter("fur",skin.get_active_material(0).albedo_texture)
	for i in POOL_SIZE:
		var node := MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.top_level = true
		node.hide()
		add_child(node)
		pieces.append(node)
	for array in [life,duration,speed,gravity,growth,opacity]:
		array.resize(POOL_SIZE)
	for i in 3:
		var voice := AudioStreamPlayer3D.new()
		voice.max_distance = 24
		voice.unit_size = 3.5
		voice.max_db = -12
		add_child(voice)
		voices.append(voice)
	bear.state_changed.connect(_state)
	bear.bite_connected.connect(_bite)
	bear.health_changed.connect(_hurt)

func _sound(channel: int, stream: AudioStream, db: float, pitch: float, point: Vector3) -> void:
	var voice := voices[channel]
	voice.stop()
	voice.global_position = point
	voice.stream = stream
	voice.volume_db = db
	voice.pitch_scale = pitch
	voice.play()

func _bone(index: int) -> Vector3:
	return skeleton.to_global(skeleton.get_bone_global_pose(index).origin)

func _muzzle() -> Vector3:
	var pose := skeleton.get_bone_global_pose(head)
	var rest := skeleton.get_bone_global_rest(head)
	return skeleton.to_global(pose * (rest.affine_inverse() * Vector3(.48,.081,-.077)))

func _emit(mesh: Mesh, point: Vector3, size: Vector3, tint: Color, seconds: float, velocity := Vector3.ZERO, fall := 0.0, expand := 0.0) -> MeshInstance3D:
	var i := cursor
	cursor = (cursor+1)%POOL_SIZE
	var node := pieces[i]
	node.mesh = mesh
	node.global_transform = Transform3D(Basis.IDENTITY.scaled(size),point)
	node.material_override.albedo_color = tint
	life[i] = seconds
	duration[i] = seconds
	speed[i] = velocity
	gravity[i] = fall
	growth[i] = expand
	opacity[i] = tint.a
	node.show()
	return node

func _dust(point: Vector3, count: int, rocks := false) -> void:
	for i in count:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, TAU*i/count + clock)
		var chip := rocks and i%3==0
		var size := .13 if chip else .34
		_emit(stone if chip else puff, point+dir*.23+Vector3.UP*.12,Vector3(size,size*.67,size),Color(.30,.24,.20,.84) if chip else DUST,.46,dir*(1.8 if chip else 1.2)+Vector3.UP*(1.65 if chip else .5),6.8 if chip else .8,.1 if chip else .9)

func _wave(point: Vector3, radius: float, color: Color) -> void:
	_emit(ring,point+Vector3.UP*.10,Vector3(.55,.12,.55),color,.48,Vector3.ZERO,0,(radius-.55)/.48)

func _state() -> void:
	if bear.state == bear.State.WINDUP:
		shock_played = false
		last_tip = Vector3.ZERO
		if bear.attack == bear.Attack.CHARGE:
			_sound(0,ROAR,-19,.73,_muzzle())
	elif bear.state == bear.State.EXECUTE:
		match bear.attack:
			bear.Attack.CLAWS:
				_sound(1,SWIPE,-14,[.88,1.02,.68][bear._strike],_bone(paws[1 if bear._strike==1 else 0]))
			bear.Attack.ROAR:
				_roar(false)
			bear.Attack.SLAM:
				var point: Vector3 = bear.to_global(Vector3(0,0,-1.1))
				_wave(point,3.2,DUST)
				_dust(point,16,true)
				_sound(1,SLAM,-13,.72,point)
	elif bear.state == bear.State.RECOVER and bear._wall_stagger:
		var point: Vector3 = bear.to_global(Vector3(0,1,-1.9))
		_dust(point,13,true)
		_sound(1,ROCK,-15,.85,point)
	elif bear.state == bear.State.ALERT:
		_sound(0,ROAR,-19,.76,_muzzle())
	elif bear.state == bear.State.RAGE:
		shock_played = false
		skin.material_overlay = glow
	elif bear.state == bear.State.DEAD:
		_sound(0,ROAR,-21,.60,_muzzle())

func _roar(rage: bool) -> void:
	_wave(bear.global_position,3.8,Color(.54,.035,.022,.28))
	_sound(0,ROAR,-13 if rage else -15,.83 if rage else .98,_muzzle())

func _bite(point: Vector3) -> void:
	_emit(puff,point,Vector3(.29,.13,.29),CRIMSON,.14,Vector3.UP*.38)
	_sound(1,BITE,-14,.76,point)

func _hurt(value: int, _maximum: int) -> void:
	if value>0 and clock>=hit_at:
		_sound(1,BITE,-18,.64,bear.global_position+Vector3.UP)
		hit_at = clock+.19

func _physics_process(delta: float) -> void:
	clock += delta
	for i in POOL_SIZE:
		if life[i]<=0: continue
		life[i]-=delta
		var node := pieces[i]
		if life[i]<=0:
			node.hide()
			continue
		var v := speed[i]
		v.y -= gravity[i]*delta
		speed[i]=v
		node.global_position+=v*delta
		var g := growth[i]*delta
		node.scale+=Vector3(g,.12*g if node.mesh==ring else g,g)
		var color: Color=node.material_override.albedo_color
		color.a=opacity[i]*minf(1,life[i]/duration[i]*1.6)
		node.material_override.albedo_color=color
	var clip: String=bear._clip
	var time: float=bear.animator.current_animation_position if bear.animator.is_playing() else last_time
	if clip!=last_clip or time<last_time:
		foot_phase=-1
	if bear.state==bear.State.DEAD:
		death_time+=delta
		if not death_landed and time>=1.85:
			death_landed=true
			_dust(bear.global_position,12,true)
			_sound(1,FALL,-13,.72,bear.global_position)
		if death_time>5:
			skin.material_overlay=null
			set_physics_process(false)
	elif bear.state==bear.State.RAGE and not shock_played and time>=.62:
		shock_played=true
		_roar(true)
	elif clip=="Idle_Breathing_Loop" and clock>=breath_at:
		breath_at=clock+2.93
		breath_count+=1
		for side: float in [-.055,.055]:
			_emit(puff,_muzzle()+bear.global_basis.x*side,Vector3(.13,.10,.15),STEAM,.55,-bear.global_basis.z*.52+Vector3.UP*.22,0,.25)
		_sound(0,ROAR if breath_count%4==0 else BREATH,-25,.64 if breath_count%4==0 else .91,_muzzle())
	elif clip in ["Walk_Loop","Run_Loop","Charge_Loop"]:
		var phase:=floori(time/bear.animator.get_animation(clip).length*4)%4
		if foot_phase!=phase:
			foot_phase=phase
			var point:=_bone(paws[[0,3,1,2][phase]])
			point.y=bear.global_position.y
			if clock >= step_at:
				step_at = clock + .13
				_sound(2,STEP,-17 if clip=="Charge_Loop" else -22,.64+.045*phase,point)
			if clip=="Charge_Loop":
				_dust(point,3)
	if bear.state==bear.State.EXECUTE and bear.attack==bear.Attack.CLAWS:
		var tip: Vector3 =_bone(paws[1 if bear._strike==1 else 0])-bear.global_basis.z*.22
		if last_tip!=Vector3.ZERO and clock>=trail_time and tip.distance_to(last_tip)>.035:
			var trail:=_emit(puff,(tip+last_tip)*.5,Vector3.ONE,CRIMSON,.13)
			trail.look_at(tip,Vector3.RIGHT if absf((tip-last_tip).normalized().y)>.95 else Vector3.UP)
			trail.scale=Vector3(.055,.105,tip.distance_to(last_tip)+.08)
			trail_time=clock+.025
		last_tip=tip
	if skin.material_overlay!=null:
		glow_strength=move_toward(glow_strength,0.0 if bear.health==0 else .52,delta*.45)
		glow.set_shader_parameter("strength",glow_strength)
	last_time=time
	last_clip=clip
