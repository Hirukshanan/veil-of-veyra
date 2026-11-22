extends "res://scripts/lantern_awakening.gd"

const SEAL := Vector3(2.7,34,38.65)
const ALTAR := Vector3(-1.8,34,32)
var leaves: Array[Node3D] = []
var gold: Array[MeshInstance3D] = []
var fissures: Array[MeshInstance3D] = []
var amber := StandardMaterial3D.new()
var crimson := StandardMaterial3D.new()
var seal_lights: Array[OmniLight3D] = []
var passage: Node3D
var extend_passage := false
var cavern: Node3D
var corridor_environment: Environment
const GATE_POWER_TIME := 4.4
const RETRACT_TIME := 5.85
const CLEAR_TIME := 8.05
var seal_materials: Array[ShaderMaterial] = []

func _build_wall():
	super._build_wall()
	for piece in chunks:
		piece.hide()
	cracks.hide()

func attach_sanctum(shrine: Node3D) -> void:
	if is_instance_valid(passage): return
	passage = Node3D.new()
	passage.name = "SanctumPassage"
	shrine.chamber.add_child(passage)
	for direction in [-1,1]:
		var leaf := Node3D.new()
		passage.add_child(leaf)
		leaves.append(leaf)
		for source in shrine.sanctum_seal:
			if _static_seal_frame(source): continue
			var face := MeshInstance3D.new()
			face.mesh = source.mesh
			leaf.add_child(face)
			face.global_transform = source.global_transform
			for surface in face.mesh.get_surface_count():
				var skin: ShaderMaterial = source.get_active_material(surface).duplicate()
				skin.set_shader_parameter("seal_half",direction)
				face.set_surface_override_material(surface,skin)
				seal_materials.append(skin)
	for source in shrine.sanctum_seal:
		if not _static_seal_frame(source): source.hide()
	amber.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amber.albedo_color = Color(1,.61,.14)
	crimson.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crimson.albedo_color = Color(1,.095,.04)
	var path := [ALTAR+Vector3(0,.225,.75),Vector3(-1.45,34.225,33.2),Vector3(-.7,34.12,34.8),Vector3(2.7,34.025,36.7),SEAL+Vector3(0,.025,-.4)]
	for i in range(1,path.size()):
		for j in 7:
			var a: Vector3 = path[i-1].lerp(path[i],j/7.)
			var b: Vector3 = path[i-1].lerp(path[i],(j+1)/7.)
			gold.append(_line(passage,a,b,.042,amber))
			if j%2==0:
				var spur := Vector3(.27 if j%4==0 else -.27,0,.19)
				gold.append(_line(passage,a,a+spur,.035,amber))
	for x in [-4.7,1.1]:
		var lamp := OmniLight3D.new()
		passage.add_child(lamp)
		lamp.position = Vector3(x,36.6,33.55)
		lamp.light_color = Color(1,.64,.24)
		lamp.omni_range = 2.8
		lamp.light_energy = 0
		seal_lights.append(lamp)
	if not extend_passage: _build_fissures()
	# The recess continues behind the actual seal on the existing sanctum floor.
	# Its lining stays at the edges of the walkable passage.
	var lining: Material = stone()
	if extend_passage:
		lining = preload("res://scripts/dragon_cavern.gd").passage_stone(stone(),Color(.40,.38,.35),false)
		var jamb := stone()
		jamb.albedo_color = Color(.48,.42,.34)
		# Meet the baked left wall at x=-2.6 instead of overlapping it.
		_panel(shrine,Vector3(-.975,37.7,39.19),Vector3(3.25,7.4,.86),jamb)
		_panel(shrine,Vector3(6.04,37.7,39.19),Vector3(2.52,7.4,.86),jamb)
		_panel(shrine,Vector3(2.7,41.02,39.19),Vector3(4.28,1.12,.86),jamb)
	for side in [-1,1]:
		for i in 5:
			var width := .66+float(i%2)*.14
			_panel(shrine,Vector3(2.7+side*2.35,36.75,40.55+i*1.43),Vector3(width,5.5,1.42),lining)
	_panel(shrine,Vector3(2.7,39.6,43.5),Vector3(5.2,.65,8.1),lining)
	if extend_passage:
		cavern = preload("res://scripts/dragon_cavern.gd").new()
		passage.add_child(cavern)
		cavern.build(shrine,stone(),EYE_ATLAS)
	if finished(): apply_open_state()

func _static_seal_frame(part: MeshInstance3D) -> bool:
	# The pale voussoirs and piers belong to the frame, outside the sliding leaves.
	return extend_passage and str(part.name).begins_with("SanctumSeal_Pale_cut_stone")

func _build_fissures() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 484
	for branch in 9:
		var angle := TAU*branch/9.
		var direction := Vector3(cos(angle),sin(angle),0)
		var tangent := Vector3(-direction.y,direction.x,0)
		var point := SEAL+Vector3(0,2.82,-.19)
		for i in 6:
			var next := SEAL+Vector3(0,2.82,-.19)+direction*(i+1)*.33+tangent*rng.randf_range(-.16,.16)
			fissures.append(_line(passage,point,next,.036-i*.003,crimson))
			point = next

func _panel(shrine: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	mesh(passage,shape,at,material)
	shrine.solid(at,size,passage)

func _line(parent: Node3D, a: Vector3, b: Vector3, width: float, material: Material) -> MeshInstance3D:
	var beam := BoxMesh.new()
	beam.size = Vector3(width,width,a.distance_to(b))
	var piece := mesh(parent,beam,(a+b)*.5,material)
	piece.look_at(b)
	piece.hide()
	return piece

func start() -> bool:
	skip_button.modulate.a = 1.
	if not super.start(): return false
	camera.cull_mask = old_camera.cull_mask
	if extend_passage:
		var source := get_world_3d().environment
		corridor_environment = source.duplicate() if source else Environment.new()
		corridor_environment.background_mode = Environment.BG_COLOR
		corridor_environment.background_color = Color(.022,.027,.034)
		corridor_environment.fog_enabled = true
		corridor_environment.fog_mode = Environment.FOG_MODE_DEPTH
		corridor_environment.fog_light_color = Color(.022,.027,.034)
		corridor_environment.fog_density = 1.
		corridor_environment.fog_light_energy = .17
		corridor_environment.fog_sun_scatter = 0.
		corridor_environment.fog_aerial_perspective = 0.
		corridor_environment.fog_depth_begin = 4.5
		corridor_environment.fog_depth_end = 18.
		corridor_environment.fog_depth_curve = .8
	roar.global_position = cavern.EYE if extend_passage else Vector3(2.7,36.8,46.6)
	breath.global_position = roar.global_position
	return true

func _gate_cues() -> Array:
	return [[GATE_POWER_TIME,"seal_engravings"],[RETRACT_TIME,"seal_retraction"]] if extend_passage else super._gate_cues()

func _on_gate_motion() -> void:
	if not extend_passage:
		super._on_gate_motion()
		return
	rumble.global_position = SEAL+Vector3.UP*2.
	rumble.stream = preload("res://assets/audio/lantern_awakening/stone.wav")
	rumble.volume_db = -14.
	rumble.play()

func _darkness_cue() -> float:
	return 13.47 if extend_passage else super._darkness_cue()

func _eye_cue() -> float:
	return 14.22 if extend_passage else super._eye_cue()

func _on_darkness() -> void:
	if not extend_passage: return
	breath.play()
	rumble.stream = preload("res://assets/audio/lantern_awakening/stone.wav")
	rumble.global_position = Vector3(2.7,35.0,65.5)
	rumble.volume_db = -27.
	rumble.play()

func _on_eye_opening() -> void:
	if not extend_passage: super._on_eye_opening()

func _sample(time: float):
	lantern_prop.position = starting_lantern.lerp(PEDESTAL+Vector3.UP*1.75,smoothstep(0.,1.0,time))
	glow.light_cull_mask = 1
	glow.light_energy = 1.8*smoothstep(.55,1.5,time)*(1.-smoothstep(7.4,11.5,time))
	for i in gold.size():
		var arrival := lerpf(1.03,GATE_POWER_TIME-.04,float(i)/maxf(1.,gold.size()-1.)) if extend_passage else 1.02+i*.058
		gold[i].visible = time >= arrival and time < 11.8
	for lamp in seal_lights:
		lamp.light_energy = 2.2*smoothstep(2.4,3.6,time)*(1.-smoothstep(5.6,8.,time))
	for i in fissures.size():
		fissures[i].visible = time >= 4.2+(i%6)*.19 and time<6.53
	var charge := smoothstep(4.2,5.8,time)*(1.-smoothstep(6.3,7.3,time))
	if extend_passage:
		var pulse := .66+.34*cos((time-GATE_POWER_TIME)*TAU*1.65)
		charge = smoothstep(GATE_POWER_TIME,GATE_POWER_TIME+.34,time)*pulse*(1.-smoothstep(6.12,7.75,time))
		var collision := gate.get_child(0) as CollisionShape3D
		if time>=CLEAR_TIME and not collision.disabled:
			collision.set_deferred("disabled",true)
	for skin in seal_materials:
		skin.set_shader_parameter("seal_charge",charge)
	_open_leaves(smoothstep(RETRACT_TIME if extend_passage else 5.8,CLEAR_TIME,time))
	if time<8.1:
		var sweep := smoothstep(1.0,7.9,time)
		camera.global_position = Vector3(3.35,37.3,28.8).lerp(Vector3(2.7,36.3,36.55),sweep)
		var floor_focus := Vector3(.65,34.23,35.32)
		var focus := (ALTAR+Vector3.UP*1.36).lerp(floor_focus,smoothstep(1.3,2.7,time))
		focus = focus.lerp(SEAL+Vector3.UP*2.35,smoothstep(3.55,5.1,time))
		camera.look_at(focus.lerp(Vector3(2.7,36.45,48.7),smoothstep(7.,8.1,time)))
	elif extend_passage:
		_sample_cavern(time)
	else:
		var travel := smoothstep(8.1,12.4,time)
		camera.global_position = Vector3(2.7,36.3,lerpf(36.55,46.28,travel))
		camera.look_at(Vector3(2.7,36.45,48.7))
		camera.fov = lerpf(58.,45.,travel)
	if not extend_passage and time>=12.4:
		camera.environment = environment
		camera.cull_mask = 1 << 19
		eye.visible = time>=13.3 and time<17.3
		last_eye_open = clampf((time-13.3)/1.2,0,1)
		var index := clampi(int(floor((time-13.3)/EYE_FRAME_SECONDS)),0,5)
		if eye_frame!=index:
			eye.texture = eye_frames[index]
			eye_frame = index
	fade.color.a = .98*smoothstep(9.4,12.4,time) if time<12.4 else smoothstep(16.9,17.3,time)*(1.-smoothstep(17.3,18.,time))
	if extend_passage:
		var entrance_black := smoothstep(12.64,13.47,time)*(1.-smoothstep(14.06,14.40,time))
		var return_black := smoothstep(17.07,17.3,time)*(1.-smoothstep(17.3,18.,time))
		fade.color.a = maxf(entrance_black,return_black)
		skip_button.modulate.a = 1.-fade.color.a
	if time>=17.3 and is_instance_valid(old_camera):
		old_camera.make_current()

func _sample_cavern(time: float) -> void:
	var approach := smoothstep(8.1,17.22,time)
	var progress := lerpf(approach,1.,smoothstep(14.3,16.52,time))
	if time >= _darkness_cue():
		# Leave the camera in place. Swap visibility only while the screen is black.
		camera.environment = environment
		camera.cull_mask = cavern.REVEAL_LAYER
	var rise := smoothstep(11.1,14.4,time)
	camera.global_position = Vector3(2.7,36.3+rise*1.6,lerpf(36.55,72.0,progress))
	if camera.global_position.z>39.6 and time<_darkness_cue():
		camera.environment = corridor_environment
	camera.look_at(Vector3(2.7,lerpf(36.45,37.9,rise),80.6))
	camera.fov = lerpf(58.,48.,progress)
	cavern.sample(time)

func _open_leaves(amount: float) -> void:
	for i in leaves.size():
		leaves[i].position = Vector3((2*i-1)*3.3*amount,0,.75*amount)

func apply_open_state():
	if is_instance_valid(cavern): cavern.eye.hide()
	lantern_prop.position = PEDESTAL+Vector3.UP*1.75
	lantern_prop.show()
	glow.light_energy = 0
	_open_leaves(1.)
	for leaf in leaves: leaf.hide()
	for mark in gold+fissures: mark.hide()
	for lamp in seal_lights: lamp.light_energy = 0
	gate.get_child(0).set_deferred("disabled",true)
	hint.hide()
