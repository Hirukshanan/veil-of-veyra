extends Node3D

signal cue_played(cue: StringName)

const CLIPS := {
	&"alert": preload("res://assets/audio/demon_fox/alert.ogg"),
	&"bite_growl": preload("res://assets/audio/demon_fox/bite_growl.ogg"),
	&"bite_hit": preload("res://assets/audio/demon_fox/bite_hit.ogg"),
	&"bite_snap": preload("res://assets/audio/demon_fox/bite_snap.ogg"),
	&"breath_approach": preload("res://assets/audio/demon_fox/breath_approach.ogg"),
	&"breath_stalk": preload("res://assets/audio/demon_fox/breath_stalk.ogg"),
	&"death_body": preload("res://assets/audio/demon_fox/death_body.ogg"),
	&"death_decay": preload("res://assets/audio/demon_fox/death_decay.ogg"),
	&"death_roar": preload("res://assets/audio/demon_fox/death_roar.ogg"),
	&"dodge_air": preload("res://assets/audio/demon_fox/dodge_air.ogg"),
	&"dodge_paw": preload("res://assets/audio/demon_fox/dodge_paw.ogg"),
	&"leap_air": preload("res://assets/audio/demon_fox/leap_air.ogg"),
	&"leap_hit": preload("res://assets/audio/demon_fox/leap_hit.ogg"),
	&"leap_land": preload("res://assets/audio/demon_fox/leap_land.ogg"),
	&"leap_roar": preload("res://assets/audio/demon_fox/leap_roar.ogg"),
	&"pain_a": preload("res://assets/audio/demon_fox/pain_a.ogg"),
	&"pain_b": preload("res://assets/audio/demon_fox/pain_b.ogg"),
	&"pain_c": preload("res://assets/audio/demon_fox/pain_c.ogg"),
	&"paw_brake": preload("res://assets/audio/demon_fox/paw_brake.ogg"),
	&"paw_forest_a": preload("res://assets/audio/demon_fox/paw_forest_a.ogg"),
	&"paw_forest_b": preload("res://assets/audio/demon_fox/paw_forest_b.ogg"),
	&"paw_forest_c": preload("res://assets/audio/demon_fox/paw_forest_c.ogg"),
	&"paw_stone_a": preload("res://assets/audio/demon_fox/paw_stone_a.ogg"),
	&"paw_stone_b": preload("res://assets/audio/demon_fox/paw_stone_b.ogg"),
	&"paw_stone_c": preload("res://assets/audio/demon_fox/paw_stone_c.ogg"),
	&"stagger": preload("res://assets/audio/demon_fox/stagger.ogg"),
	&"veil_buildup": preload("res://assets/audio/demon_fox/veil_buildup.ogg"),
	&"veil_hum": preload("res://assets/audio/demon_fox/veil_hum.ogg"),
	&"veil_reveal": preload("res://assets/audio/demon_fox/veil_reveal.ogg"),
	&"veil_vanish": preload("res://assets/audio/demon_fox/veil_vanish.ogg"),
	&"veil_warning": preload("res://assets/audio/demon_fox/veil_warning.ogg"),
}

const WALK_CONTACTS := [0.0, .36, .50, .86]
const RUN_CONTACTS := [.44, .52, .88, .97]
const FOREST_PAWS := [&"paw_forest_a", &"paw_forest_b", &"paw_forest_c"]
const STONE_PAWS := [&"paw_stone_a", &"paw_stone_b", &"paw_stone_c"]
const PAIN := [&"pain_a", &"pain_b", &"pain_c"]
const DEATH_CONTACT := .97
const DEATH_RESONANCE := 1.13

var _voice: AudioStreamPlayer3D
var _feet: AudioStreamPlayer3D
var _magic: AudioStreamPlayer3D
var _impact: AudioStreamPlayer3D
var _veil_bed: AudioStreamPlayer3D
var _step_delay := 0.0
var _breath_delay := 0.7
var _moving_fast := false
var _step_index := 0
var _pain_index := 0
var _veiled := false
var _dead := false
var _death_step := 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_voice = _make_player(.58)
	_feet = _make_player(.08)
	_magic = _make_player(.46)
	_impact = _make_player(.20)
	_veil_bed = _make_player(.48)
	var loop := CLIPS[&"veil_hum"].duplicate() as AudioStreamOggVorbis
	loop.loop = true
	_veil_bed.stream = loop

func _exit_tree() -> void:
	_stop_all()
	for emitter in [_voice, _feet, _magic, _impact, _veil_bed]:
		emitter.stream = null

func _make_player(height: float) -> AudioStreamPlayer3D:
	var emitter := AudioStreamPlayer3D.new()
	emitter.position.y = height
	emitter.max_polyphony = 1
	emitter.unit_size = 3.5
	emitter.max_distance = 17.0
	add_child(emitter)
	return emitter

func _near_listener() -> bool:
	var camera := get_viewport().get_camera_3d()
	return camera != null and global_position.distance_squared_to(camera.global_position) < 289.0

func _play(emitter: AudioStreamPlayer3D, cue: StringName, gain: float, variation := .05) -> void:
	if not _near_listener():
		return
	emitter.stream = CLIPS[cue]
	emitter.volume_db = gain + _rng.randf_range(-.65, .65)
	emitter.pitch_scale = 1.0 + _rng.randf_range(-variation, variation)
	emitter.play()
	cue_played.emit(cue)

func update_movement(delta: float, speed: float, grounded: bool, stalking: bool, approaching: bool) -> void:
	_step_delay -= delta
	_breath_delay -= delta
	if grounded and speed > 1.15 and not _veiled:
		_moving_fast = true
	if grounded and not _veiled and _moving_fast and speed < .24 and _step_delay <= .02:
		_play(_feet, &"paw_brake", -17.0)
		_step_delay = .13
		_moving_fast = false
	if not _veiled and (stalking or approaching) and _breath_delay <= 0.0 and not _voice.playing and _near_listener():
		_play(_voice, &"breath_stalk" if stalking else &"breath_approach", -18.0 if stalking else -16.0)
		_breath_delay = _rng.randf_range(1.5, 2.45)
	if _veiled and _near_listener():
		if not _veil_bed.playing:
			_veil_bed.volume_db = -30.0
			_veil_bed.play()
			cue_played.emit(&"veil_hum")
		var level := lerpf(-30.0, -23.0, clampf(speed / 2.35, 0.0, 1.0))
		_veil_bed.volume_db = move_toward(_veil_bed.volume_db, level, delta * 38.0)
	elif _veil_bed.playing:
		_veil_bed.stop()

func steps(clip: String, before: float, after: float, length: float) -> void:
	if _veiled or _step_delay > 0.0 or length <= 0.0 or clip not in ["Walk", "Run"] or not _near_listener():
		return
	for contact in WALK_CONTACTS if clip == "Walk" else RUN_CONTACTS:
		var time: float = contact * length
		var crossed := before <= time and time < after
		if after < before:
			crossed = time >= before or time < after
		if crossed:
			var paws := STONE_PAWS if _stone_underfoot() else FOREST_PAWS
			_play(_feet, paws[_step_index % paws.size()], -19.0 if clip == "Walk" else -13.0, .10)
			_step_index += 1
			_step_delay = .11 if clip == "Run" else .15
			return

func _stone_underfoot() -> bool:
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * .28,
		global_position - Vector3.UP * .62, 1 | 4 | 8 | 16)
	var ground := get_world_3d().direct_space_state.intersect_ray(ray)
	if ground.is_empty():
		return false
	var surface := ground.collider as Node3D
	return surface.get_parent().name != &"ConnectedTerrain" or ground.normal.y < .75

func alert() -> void:
	_play(_voice, &"alert", -9.0)

func veil_started() -> void:
	_veiled = true
	_moving_fast = false
	_voice.stop()
	_feet.stop()
	_play(_magic, &"veil_vanish", -8.0, .02)

func veil_warning() -> void:
	_play(_voice, &"veil_warning", -6.5, .02)
	_play(_magic, &"veil_buildup", -17.0, 0.0)

func veil_ended() -> void:
	_veiled = false
	_veil_bed.stop()
	_play(_magic, &"veil_reveal", -8.0, .02)

func windup(bite: bool) -> void:
	_play(_voice, &"bite_growl" if bite else &"leap_roar", -9.0 if bite else -6.5)

func bite_snap() -> void:
	_play(_magic, &"bite_snap", -13.0)

func takeoff() -> void:
	_play(_magic, &"leap_air", -10.0)

func land() -> void:
	_moving_fast = false
	_step_delay = .16
	_play(_feet, &"leap_land", -8.0)

func impact(bite: bool) -> void:
	_play(_impact, &"bite_hit" if bite else &"leap_hit", -9.0 if bite else -7.5)

func dodge() -> void:
	_play(_magic, &"dodge_air", -13.0)
	_play(_feet, &"dodge_paw", -17.0)
	_step_delay = .17
	_moving_fast = false

func hurt() -> void:
	_play(_voice, PAIN[_pain_index % PAIN.size()], -9.0)
	_pain_index += 1

func stagger() -> void:
	_play(_voice, &"stagger", -9.0)

func death_begin() -> void:
	_dead = true
	_veiled = false
	_stop_all()
	_play(_voice, &"death_roar", -7.0, 0.0)

func death_pose(position: float) -> void:
	if not _dead:
		return
	if _death_step == 0 and position >= DEATH_CONTACT:
		_death_step = 1
		_play(_feet, &"death_body", -7.5, 0.0)
	if _death_step == 1 and position >= DEATH_RESONANCE:
		_death_step = 2
		_play(_magic, &"death_decay", -11.0, 0.0)

func _stop_all() -> void:
	for emitter in [_voice, _feet, _magic, _impact, _veil_bed]:
		emitter.stop()
