extends Node3D

const ROOM_BUS := "BearTempleVoices"
const SUSPENSE := preload("res://assets/audio/bear_encounter/suspense.ogg")
const BATTLE := preload("res://assets/audio/bear_encounter/battle.ogg")
const RAGE := preload("res://assets/audio/bear_encounter/rage.ogg")
const EYE := preload("res://assets/audio/bear_encounter/eye_cue.wav")
const ACCENT := preload("res://assets/audio/bear_encounter/roar_cue.wav")
const ROAR := preload("res://assets/audio/bear_encounter/roar.wav")
const COMBAT_ROAR := preload("res://assets/audio/bear_encounter/combat_roar.wav")
const RAGE_ROAR := preload("res://assets/audio/bear_encounter/rage_roar.wav")
const GROWLS := [preload("res://assets/audio/bear_encounter/growl_a.wav"),preload("res://assets/audio/bear_encounter/growl_b.wav")]
const BREATHS := [preload("res://assets/audio/bear_encounter/breath_a.wav"),preload("res://assets/audio/bear_encounter/breath_b.wav")]

var game: Node3D
var bed: AudioStreamPlayer
var battle: AudioStreamPlayer
var rage: AudioStreamPlayer
var accent: AudioStreamPlayer
var breath_voice: AudioStreamPlayer3D
var growl_voice: AudioStreamPlayer3D
var roar_voice: AudioStreamPlayer3D
var music_gain := Vector3.ZERO
var duck := 0.
var duck_hold := 0.
var variation := 0
var eye_cued := false
var defeated := false
var retreat_time := 0.
var owns_bus := false

func _ready() -> void:
	if AudioServer.get_bus_index(ROOM_BUS)<0:
		var index := AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(index,ROOM_BUS)
		var room := AudioEffectReverb.new()
		room.room_size = .74
		room.damping = .64
		room.predelay_msec = 31.
		room.predelay_feedback = .21
		room.wet = .20
		room.dry = .87
		AudioServer.add_bus_effect(index,room)
		owns_bus = true
	bed = _track(SUSPENSE)
	battle = _track(_loop(BATTLE))
	rage = _track(_loop(RAGE))
	accent = _track()
	breath_voice = _voice()
	growl_voice = _voice()
	roar_voice = _voice()

func _track(stream: AudioStream = null) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.stream = stream
	audio.volume_db = -80.
	add_child(audio)
	return audio

func _loop(stream: AudioStreamOggVorbis) -> AudioStreamOggVorbis:
	var instance := stream.duplicate() as AudioStreamOggVorbis
	instance.loop = true
	return instance

func _voice() -> AudioStreamPlayer3D:
	var audio := AudioStreamPlayer3D.new()
	audio.bus = ROOM_BUS
	audio.unit_size = 6.
	audio.max_distance = 33.
	audio.max_db = -5.
	add_child(audio)
	return audio

func vocal(cue: StringName, muzzle: Vector3, cinematic := false) -> void:
	var is_roar := cue in [&"roar", &"combat_roar", &"rage_roar"]
	if not is_roar and roar_voice.playing: return
	var voice := growl_voice
	var recording: AudioStream
	var level := -11.
	match cue:
		&"roar", &"combat_roar", &"rage_roar":
			voice = roar_voice
			recording = ROAR
			if cue == &"combat_roar": recording = COMBAT_ROAR
			if cue == &"rage_roar": recording = RAGE_ROAR
			level = -3. if cinematic else -5.
			breath_voice.stop()
			growl_voice.stop()
			duck_hold = 1.35
			if cinematic: _accent(ACCENT,-17.)
		&"breath":
			if growl_voice.playing: return
			voice = breath_voice
			recording = BREATHS[variation%2]
			level = -14.
		_:
			recording = GROWLS[variation%2]
	var pitches := [1.,.91,1.034,.96]
	voice.stop()
	voice.stream = recording
	voice.pitch_scale = 1. if is_roar else pitches[variation%4]
	voice.global_position = muzzle
	voice.volume_db = level
	voice.play()
	variation += 1

func _accent(stream: AudioStream, volume: float) -> void:
	accent.stream = stream
	accent.volume_db = volume
	accent.play()

func _process(delta: float) -> void:
	if not game.placement_ready: return
	var boss: Node3D = game.cave_bear
	var intro: bool = game.bear_intro.active
	var living: bool = is_instance_valid(boss) and boss.health>0
	var fighting: bool = living and not defeated and game.introduced and game.shrine.in_cell and game.player.position.z>=-9.
	if intro and not bed.playing and not eye_cued:
		bed.play()
	if intro and not eye_cued and game.bear_intro.elapsed>=2.82:
		eye_cued = true
		_accent(EYE,-15.)
	if fighting and not battle.playing:
		battle.play()
		rage.play()
	if fighting:
		retreat_time = 0.
	else:
		retreat_time += delta
	var target := Vector3(float(intro),float(fighting),float(fighting and boss.enraged))
	music_gain.x = move_toward(music_gain.x,target.x,delta*(1.8 if intro else .86))
	var fade := .40 if defeated else .86
	music_gain.y = move_toward(music_gain.y,target.y,delta*(1.12 if fighting else fade))
	music_gain.z = move_toward(music_gain.z,target.z,delta*(.96 if target.z>0. else fade))
	duck_hold = maxf(0.,duck_hold-delta)
	duck = move_toward(duck,float(duck_hold>0.),delta*(10. if duck_hold>0. else 1.28))
	var dip := duck*8.
	bed.volume_db = linear_to_db(maxf(.0001,music_gain.x)) - 18. - dip
	battle.volume_db = linear_to_db(maxf(.0001,music_gain.y)) - 14. - dip
	rage.volume_db = linear_to_db(maxf(.0001,music_gain.z)) - 17. - dip
	if not intro and music_gain.x<=0.: bed.stop()
	if not fighting and music_gain.y<=0. and (retreat_time>3.1 or defeated):
		if battle.playing: battle.stop()
		if rage.playing: rage.stop()

func _exit_tree() -> void:
	if owns_bus:
		var index := AudioServer.get_bus_index(ROOM_BUS)
		if index>=0: AudioServer.remove_bus(index)
