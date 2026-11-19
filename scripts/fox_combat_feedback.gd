extends Node3D

const GROWL := preload("res://assets/audio/demon_boar/warning.wav")
const IMPACT := preload("res://assets/audio/demon_boar/hit_light.wav")
const LAND := preload("res://assets/audio/demon_boar/death_land.wav")
const HURT := preload("res://assets/audio/demon_boar/hurt.wav")
const STEPS := [preload("res://assets/audio/demon_boar/hoof_a.wav"),
	preload("res://assets/audio/demon_boar/hoof_b.wav"), preload("res://assets/audio/demon_boar/hoof_c.wav")]
const WALK_CONTACTS := [0.0, .36, .50, .86]
const RUN_CONTACTS := [.44, .52, .88, .97]

var _voice: AudioStreamPlayer3D
var _feet: AudioStreamPlayer3D
var _warning: MeshInstance3D
var _warning_material: StandardMaterial3D
var _dust: CPUParticles3D
var _step_index := 0
var _label: Label3D
var _maximum := 0

func _ready() -> void:
	_voice = _make_voice(.56)
	_feet = _make_voice(.10)
	_label = Label3D.new()
	_label.position.y = 1.23
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 32
	_label.outline_size = 8
	_label.pixel_size = .0044
	add_child(_label)
	_warning = MeshInstance3D.new()
	_warning.top_level = true
	_warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_warning_material = StandardMaterial3D.new()
	_warning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warning_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_warning_material.albedo_color = Color(.93, .52, .21, .48)
	_warning.material_override = _warning_material
	_warning.hide()
	add_child(_warning)
	_build_dust()

func _exit_tree() -> void:
	for voice in [_voice, _feet]:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null

func _make_voice(height: float) -> AudioStreamPlayer3D:
	var voice := AudioStreamPlayer3D.new()
	voice.position.y = height
	voice.max_polyphony = 1
	voice.max_distance = 16.0
	voice.unit_size = 3.0
	add_child(voice)
	return voice

func _build_dust() -> void:
	_dust = CPUParticles3D.new()
	_dust.top_level = true
	_dust.emitting = false
	_dust.one_shot = true
	_dust.amount = 6
	_dust.lifetime = .24
	_dust.explosiveness = 1.0
	_dust.direction = Vector3.UP
	_dust.spread = 77.0
	_dust.gravity = Vector3(0, -2.0, 0)
	_dust.initial_velocity_min = .42
	_dust.initial_velocity_max = 1.4
	_dust.scale_amount_min = .68
	_dust.scale_amount_max = 1.14
	_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var puff := SphereMesh.new()
	puff.radius = .055
	puff.height = .09
	puff.radial_segments = 5
	puff.rings = 3
	var dust_material := StandardMaterial3D.new()
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.vertex_color_use_as_albedo = true
	puff.material = dust_material
	_dust.mesh = puff
	var fade := Gradient.new()
	fade.set_color(0, Color(.55, .43, .32, .43))
	fade.set_color(1, Color(.55, .43, .32, 0.0))
	_dust.color_ramp = fade
	add_child(_dust)

func warn_landing(point: Vector3, radius: float) -> void:
	var ring := SurfaceTool.new()
	ring.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 18
	var inner := PackedVector3Array()
	var outer := PackedVector3Array()
	for index in range(SEGMENTS):
		var angle := TAU * float(index) / SEGMENTS
		var direction := Vector3(cos(angle), 0, sin(angle))
		inner.append(_ground(point + direction * (radius - .085)) - point)
		outer.append(_ground(point + direction * radius) - point)
	for index in range(SEGMENTS):
		var next := (index + 1) % SEGMENTS
		for vertex in [inner[index], outer[index], outer[next], inner[index], outer[next], inner[next]]:
			ring.add_vertex(vertex)
	_warning.global_position = point
	_warning.mesh = ring.commit()
	_warning.show()

func _ground(point: Vector3) -> Vector3:
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.6, point - Vector3.UP * 1.6, 16)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		point.y = hit.position.y
	return point + Vector3.UP * .043

func hide_warning() -> void:
	_warning.hide()

func update_health(value: int) -> void:
	_maximum = maxi(_maximum, value)
	_label.text = "DEMON FOX  %d / %d" % [value, _maximum]

func defeat() -> void:
	_label.hide()

func alert() -> void:
	_play(_voice, GROWL, -14.0, 1.28)

func hurt() -> void:
	_play(_voice, HURT, -20.0, 1.23)

func impact() -> void:
	_play(_voice, IMPACT, -13.0, 1.16)

func land(at: Vector3) -> void:
	_play(_feet, LAND, -19.0, 1.17)
	_dust.global_position = at + Vector3.UP * .10 - global_basis.z * .34
	_dust.restart()
	_dust.emitting = true

func steps(clip: String, before: float, after: float, length: float) -> void:
	if _feet.playing or length <= 0.0 or clip not in ["Walk", "Run"]:
		return
	for contact in WALK_CONTACTS if clip == "Walk" else RUN_CONTACTS:
		var time: float = contact * length
		var crossed := before <= time and time < after
		if after < before:
			crossed = time >= before or time < after
		if crossed:
			_play(_feet, STEPS[_step_index % STEPS.size()], -23.0, 1.18 + .09 * (_step_index % 3))
			_step_index += 1
			return

func _play(voice: AudioStreamPlayer3D, stream: AudioStream, gain: float, pitch: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_squared_to(global_position) < 256.0:
		voice.stream = stream
		voice.volume_db = gain
		voice.pitch_scale = pitch
		voice.play()
