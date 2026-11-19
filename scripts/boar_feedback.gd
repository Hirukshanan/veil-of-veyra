extends Node3D

# Three bounded spatial voices. The existing Master volume/mute applies to all.
signal cue_played(cue: String, channel: int)

const CUES := {
	"warning": [preload("res://assets/audio/demon_boar/warning.wav"), 0, -5.0],
	"charge": [preload("res://assets/audio/demon_boar/charge.wav"), 0, -5.0],
	"hurt": [preload("res://assets/audio/demon_boar/hurt.wav"), 0, -9.0],
	"death": [preload("res://assets/audio/demon_boar/death.wav"), 0, -5.0],
	"hoof_a": [preload("res://assets/audio/demon_boar/hoof_a.wav"), 1, -12.0],
	"hoof_b": [preload("res://assets/audio/demon_boar/hoof_b.wav"), 1, -12.0],
	"hoof_c": [preload("res://assets/audio/demon_boar/hoof_c.wav"), 1, -12.0],
	"scrape": [preload("res://assets/audio/demon_boar/scrape.wav"), 1, -10.0],
	"hit_light": [preload("res://assets/audio/demon_boar/hit_light.wav"), 2, -7.0],
	"hit_heavy": [preload("res://assets/audio/demon_boar/hit_heavy.wav"), 2, -4.0],
	"charge_impact": [preload("res://assets/audio/demon_boar/charge_impact.wav"), 2, -4.0],
	"death_land": [preload("res://assets/audio/demon_boar/death_land.wav"), 2, -6.0],
	"sweep_prepare": [preload("res://assets/audio/demon_boar/scrape.wav"), 0, -7.0, 1.18],
	"sweep_swing": [preload("res://assets/audio/demon_boar/charge.wav"), 0, -12.0, 1.2],
	"sweep_impact": [preload("res://assets/audio/demon_boar/hit_light.wav"), 2, -4.0, .85],
	"stomp_prepare": [preload("res://assets/audio/demon_boar/warning.wav"), 0, -8.0, .84],
	"stomp_impact": [preload("res://assets/audio/demon_boar/charge_impact.wav"), 2, -3.0, .78],
}

var voices: Array[AudioStreamPlayer3D] = []
var _hoof_index := 0
var _motion_clip := ""
var _hurt_time := 0.0
var _sparks: Array[MeshInstance3D] = []
var _dust: CPUParticles3D
var _camera: Camera3D
var _camera_base := 0.0
var _camera_tween: Tween

func _exit_tree() -> void:
	_reset_camera()
	for voice in voices:
		voice.stop()
		voice.stream = null

func _ready() -> void:
	for index in range(3):
		var voice := AudioStreamPlayer3D.new()
		voice.position.y = 0.8 if index == 0 else 0.15
		voice.max_polyphony = 1
		voice.max_distance = 18.0 if index == 1 else 26.0
		voice.unit_size = 6.0
		voice.max_db = 0.0
		voice.bus = &"Master"
		voice.finished.connect(func(): voice.stream = null)
		add_child(voice)
		voices.append(voice)

func cue(name: String) -> void:
	if name == "hurt":
		# Multiple targets/fast hits must not restart the vocal every physics tick.
		if _hurt_time > 0.0:return
		_hurt_time = 0.28
	var entry: Array = CUES[name]
	var channel: int = entry[1]
	var voice := voices[channel]
	voice.stream = entry[0]
	voice.volume_db = entry[2]
	voice.pitch_scale = entry[3] if entry.size() > 3 else 1.0
	voice.play()
	cue_played.emit(name, channel)

func prepare_elite_dust() -> void:
	_dust = CPUParticles3D.new()
	_dust.name = "HoofDust"
	_dust.emitting = false
	_dust.one_shot = true
	_dust.amount = 7
	_dust.lifetime = .38
	_dust.explosiveness = 1.0
	_dust.direction = Vector3.UP
	_dust.spread = 77.0
	_dust.gravity = Vector3(0, -2.1, 0)
	_dust.initial_velocity_min = 1.1
	_dust.initial_velocity_max = 2.3
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_dust.emission_sphere_radius = .28
	_dust.scale_amount_min = .55
	_dust.scale_amount_max = 1.25
	_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := SphereMesh.new()
	mesh.radius = .12
	mesh.height = .24
	mesh.radial_segments = 5
	mesh.rings = 2
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	mesh.material = material
	_dust.mesh = mesh
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(.65, .51, .34, .51), Color(.53, .44, .31, 0)])
	_dust.color_ramp = fade
	add_child(_dust)
	_dust.top_level = true

func dust_at(point: Vector3, scatter: float) -> void:
	if not is_instance_valid(_dust):
		return
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point - Vector3.UP * 1.5, 16)
	var floor_hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not floor_hit.is_empty():
		point.y = floor_hit.position.y
	_dust.global_position = point + Vector3.UP * .15
	_dust.emission_sphere_radius = .33 * scatter
	_dust.restart()
	_dust.emitting = true

func camera_impact(body: Node3D, magnitude: float) -> void:
	var arm := body.get("_camera_arm") as SpringArm3D
	if not is_instance_valid(arm) or arm.get_child_count() == 0:
		return
	var camera := arm.get_child(0) as Camera3D
	if not is_instance_valid(camera) or not camera.current:
		return
	_reset_camera()
	_camera = camera
	_camera_base = camera.v_offset
	_camera_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_camera_tween.tween_property(camera, "v_offset", _camera_base - magnitude, .045)
	_camera_tween.tween_property(camera, "v_offset", _camera_base, .125).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_callback(_reset_camera)

func _reset_camera() -> void:
	if _camera_tween and _camera_tween.is_running():
		_camera_tween.kill()
	if is_instance_valid(_camera):
		_camera.v_offset = _camera_base
	_camera = null

func sync_pose(clip: String, position: float, delta: float, moving: bool, grounded: bool, nearby: bool, advance: float = -1.0) -> void:
	_hurt_time = maxf(0.0, _hurt_time - delta)
	var step := advance if advance >= 0.0 else delta
	var changed := clip != _motion_clip
	_motion_clip = clip
	if not nearby:return
	if clip == "charge_warning" and position < 0.65 and position + delta >= 0.65:
		cue("scrape")
	elif clip == "death" and position < 1.25 and position + delta >= 1.25:
		cue("death_land")
	if not moving or not grounded:return
	# Authored contacts: four walk feet per 1.2 s, paired run/charge feet per loop.
	var interval := 0.3 if clip in ["walk", "run"] else (0.25 if clip == "charge_attack" else 0.0)
	if interval > 0.0 and ((changed and position < step) or floori((position + step) / interval) > floori(position / interval)):
		cue(["hoof_a", "hoof_b", "hoof_c"][_hoof_index % 3])
		_hoof_index += 1

func strike(origin: Vector3, heavy: bool) -> void:
	cue("hit_heavy" if heavy else "hit_light")
	# Two brief crossed contact strokes; no particles, light, camera shake or hit stop.
	_sparks = _sparks.filter(func(spark): return is_instance_valid(spark))
	if _sparks.size() >= 2:
		_sparks.pop_front().queue_free()
	var spark := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [-0.65, 0.65]:
		var length := 0.22 if heavy else 0.14
		var along := Vector2(cos(angle), sin(angle)) * length
		var across := Vector2(-sin(angle), cos(angle)) * 0.018
		for vertex in [-along, across, along, -along, along, -across]:
			mesh.surface_add_vertex(Vector3(vertex.x, vertex.y, 0))
	mesh.surface_end()
	spark.mesh = mesh
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = Color(1.0, 0.78, 0.38)
	spark.material_override = material
	var direction := to_local(origin)
	direction.y = 0
	direction = direction.normalized() if direction.length_squared() > 0.01 else Vector3.FORWARD
	spark.position = Vector3(direction.x * 0.62, 0.95, direction.z * 1.3)
	add_child(spark)
	_sparks.append(spark)
	var tween := create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.16 if heavy else 0.10)
	tween.tween_callback(spark.queue_free)
