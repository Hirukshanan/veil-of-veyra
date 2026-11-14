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
}

var voices: Array[AudioStreamPlayer3D] = []
var _hoof_index := 0
var _motion_clip := ""
var _hurt_time := 0.0
var _sparks: Array[MeshInstance3D] = []

func _exit_tree() -> void:
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
	voice.play()
	cue_played.emit(name, channel)

func sync_pose(clip: String, position: float, delta: float, moving: bool, grounded: bool, nearby: bool) -> void:
	_hurt_time = maxf(0.0, _hurt_time - delta)
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
	if interval > 0.0 and ((changed and position < delta) or floori((position + delta) / interval) > floori(position / interval)):
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
