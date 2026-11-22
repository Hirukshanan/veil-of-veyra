extends "res://scripts/cursed_bear_feedback.gd"

const CLAW_CLIPS := [
	preload("res://assets/audio/bear_encounter/claw_left.wav"),
	preload("res://assets/audio/bear_encounter/claw_right.wav"),
	preload("res://assets/audio/bear_encounter/claw_heavy.wav")
]
const EARTHBREAKER := preload("res://assets/audio/bear_encounter/earthbreaker.wav")
const LAUNCH := preload("res://assets/audio/bear_encounter/charge_launch.wav")
const SNAP := preload("res://assets/audio/bear_encounter/bite_snap.wav")

var score: Node3D

func _sound(channel: int, stream: AudioStream, db: float, pitch: float, point: Vector3) -> void:
	if channel == 0 and (stream == ROAR or stream == BREATH):
		if stream == ROAR and score.game.bear_intro.active and bear._clip == "Roar":
			score.vocal(&"roar", point, true)
		elif bear.state == bear.State.WINDUP and bear.attack == bear.Attack.CHARGE:
			return
		elif bear._clip != "Roar" and bear.state != bear.State.RAGE:
			var resting: bool = stream == BREATH or bear._clip == "Idle_Breathing_Loop"
			score.vocal(&"breath" if resting else &"growl", point)
		return
	if stream == SWIPE:
		super._sound(channel, CLAW_CLIPS[bear._strike], db, 1., point)
	elif stream == SLAM:
		super._sound(channel, EARTHBREAKER, db, 1., point)
	else:
		super._sound(channel, stream, db, pitch, point)

func _state() -> void:
	super._state()
	if bear.state == bear.State.WINDUP and bear.attack == bear.Attack.ROAR:
		score.vocal(&"combat_roar", _muzzle())
	elif bear.state == bear.State.RAGE:
		score.vocal(&"rage_roar", _muzzle())
	elif bear.state == bear.State.EXECUTE:
		if bear.attack == bear.Attack.BITE:
			super._sound(0, SNAP, -12., 1., _muzzle())
		elif bear.attack == bear.Attack.CHARGE:
			super._sound(0, LAUNCH, -12., 1., _muzzle())
