extends Node3D

signal completed

const DURATION := 9.2
const ALERT_AT := 2.65
const ROAR_AT := 4.35
const STANCE_AT := 6.85
var active := false
var elapsed := 0.
var stage := 0
var player: CharacterBody3D
var bear: CharacterBody3D
var feedback: Node3D
var gameplay_camera: Camera3D
var camera: Camera3D
var overlay: CanvasLayer
var title: Label
var skip_button: Button
var shown_layers: Array[CanvasLayer] = []
var eye_fill: OmniLight3D
var entry: Vector3
var player_physics: bool
var player_input: bool
var player_unhandled_input: bool
var player_invulnerability: float

func _ready() -> void:
	set_physics_process(false)
	camera = Camera3D.new()
	camera.near = .09
	camera.far = 65.
	add_child(camera)
	eye_fill = OmniLight3D.new()
	eye_fill.light_color = Color(1.,.13,.07)
	eye_fill.omni_range = 1.8
	eye_fill.light_energy = 0.
	add_child(eye_fill)
	overlay = CanvasLayer.new()
	overlay.layer = 40
	add_child(overlay)
	var safe := preload("res://scripts/safe_area.gd").new()
	overlay.add_child(safe)
	skip_button = Button.new()
	skip_button.text = "Skip"
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	skip_button.offset_left = -150
	skip_button.offset_right = -24
	skip_button.offset_top = 20
	skip_button.offset_bottom = 72
	skip_button.pressed.connect(skip)
	safe.add_child(skip_button)
	title = Label.new()
	title.text = "CURSED BEAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",35)
	title.add_theme_color_override("font_color",Color(.95,.82,.59))
	title.add_theme_constant_override("outline_size",5)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	title.offset_left = -220
	title.offset_right = 220
	title.offset_top = -124
	title.offset_bottom = -62
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(title)
	overlay.hide()

func start(hero: CharacterBody3D, boss: CharacterBody3D) -> void:
	player = hero
	bear = boss
	feedback = bear.get_node("Feedback")
	entry = player.global_position
	gameplay_camera = get_viewport().get_camera_3d()
	camera.cull_mask = gameplay_camera.cull_mask
	camera.environment = gameplay_camera.environment
	player_physics = player.is_physics_processing()
	player_input = player.is_processing_input()
	player_unhandled_input = player.is_processing_unhandled_input()
	player_invulnerability = player._invulnerability_time
	player.set_move_input(Vector2.ZERO)
	player.cancel_touch_camera()
	player.cancel_swing()
	player.end_guard()
	get_tree().call_group("movement_joysticks","reset")
	get_tree().call_group("attack_gestures","cancel_hold")
	get_tree().call_group("gameplay_buttons","cancel_touch")
	player._invulnerability_time = 999.
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)
	bear.target = null
	bear.set_physics_process(false)
	for layer in get_parent().find_children("*","CanvasLayer",true,false):
		if layer!=overlay and layer.visible:
			shown_layers.append(layer)
			layer.hide()
	bear._play("Idle_Breathing_Loop",.86)
	title.modulate.a = 0.
	overlay.show()
	active = true
	_sample_camera()
	camera.make_current()
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	elapsed = minf(elapsed+delta,DURATION)
	if stage==0 and elapsed>=ALERT_AT:
		stage = 1
		bear._play("Alert_Aggro",.66)
	if stage==1 and elapsed>=ROAR_AT:
		stage = 2
		bear._play("Roar",.98)
		feedback._sound(0,feedback.ROAR,-14,.92,feedback._muzzle())
		for paw in feedback.paws.slice(0,2):
			feedback._dust(feedback._bone(paw),4)
	if stage==2 and elapsed>=STANCE_AT:
		stage = 3
		bear._play("Idle_Breathing_Loop",1.)
		feedback._sound(1,feedback.ROCK,-22,.89,feedback._bone(feedback.paws[0]))
		for paw in feedback.paws.slice(0,2):
			feedback._dust(feedback._bone(paw),3)
	bear.animator.advance(delta*bear._pace)
	if stage==0:
		var skeleton: Skeleton3D = feedback.skeleton
		var head: int = feedback.head
		var neck := skeleton.find_bone("Neck")
		# Lower the head slightly over the existing breathing pose.
		var amount := .12*(1.-smoothstep(1.9,ALERT_AT,elapsed))
		skeleton.set_bone_pose_rotation(neck,skeleton.get_bone_pose_rotation(neck)*Quaternion(Vector3.RIGHT,-amount))
		skeleton.set_bone_pose_rotation(head,skeleton.get_bone_pose_rotation(head)*Quaternion(Vector3.RIGHT,-amount*.5))
	elif stage==3:
		var heading: Vector3 = player.global_position-bear.global_position
		heading.y = 0.
		bear._face(heading.normalized(),delta*.7)
	eye_fill.global_position = feedback._muzzle()+Vector3(0,.35,-.63)
	eye_fill.light_energy = .55*smoothstep(ALERT_AT,ROAR_AT,elapsed)*(1.-smoothstep(7.0,DURATION,elapsed))
	_sample_camera()
	if elapsed>=DURATION: skip()

func _sample_camera() -> void:
	var wide_start := entry+Vector3(.65,2.3,-3.1)
	wide_start.x = clampf(wide_start.x,-2.3,2.3)
	var wide_end := Vector3(1.0,36.55,1.9)
	var low := Vector3(2.8,35.28,10.95)
	var roar_view := Vector3(2.55,35.24,11.25)
	var stance := Vector3(-1.18,35.9,9.4)
	var point := wide_start.lerp(wide_end,smoothstep(0.,2.72,elapsed))
	point = point.lerp(low,smoothstep(2.0,3.96,elapsed))
	point = point.lerp(roar_view,smoothstep(4.05,4.52,elapsed))
	point = point.lerp(stance,smoothstep(6.22,7.62,elapsed))
	var shake := smoothstep(4.45,4.57,elapsed)*(1.-smoothstep(4.62,5.16,elapsed))
	point += Vector3(sin(elapsed*64.),cos(elapsed*51.),0)*shake*.045
	var body_target := bear.global_position+Vector3.UP*1.88
	var muzzle: Vector3 = feedback._muzzle()
	var face_mix := smoothstep(2.06,3.84,elapsed)*(1.-smoothstep(6.2,7.42,elapsed))
	var focus := body_target.lerp(muzzle+Vector3.UP*.28,face_mix)
	var basis := Basis.looking_at(focus-point)
	var handoff := smoothstep(7.76,DURATION,elapsed)
	camera.global_transform = Transform3D(basis,point).interpolate_with(gameplay_camera.global_transform,handoff)
	camera.fov = lerpf(lerpf(66.,49.,face_mix),gameplay_camera.fov,handoff)
	title.modulate.a = smoothstep(7.05,7.57,elapsed)*(1.-smoothstep(8.77,DURATION,elapsed))

func _input(event: InputEvent) -> void:
	if active and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_SPACE]:
		get_viewport().set_input_as_handled()
		skip()

func skip() -> void:
	if not active: return
	active = false
	set_physics_process(false)
	eye_fill.light_energy = 0.
	overlay.hide()
	gameplay_camera.make_current()
	for layer in shown_layers:
		if is_instance_valid(layer): layer.show()
	shown_layers.clear()
	player.set_move_input(Vector2.ZERO)
	player._invulnerability_time = maxf(player_invulnerability,.9)
	player.set_physics_process(player_physics)
	player.set_process_input(player_input)
	player.set_process_unhandled_input(player_unhandled_input)
	completed.emit()
