extends "res://scripts/bear_awakening_review.gd"

const AUDIO := preload("res://scripts/bear_encounter_audio.gd")
const FEEDBACK := preload("res://scripts/bear_audio_feedback.gd")
var score: AUDIO

func _ready() -> void:
	score = AUDIO.new()
	score.name = "BearEncounterAudio"
	score.game = self
	add_child(score)
	await super._ready()

func _create_cave_bear() -> CharacterBody3D:
	var boss := super._create_cave_bear()
	var feedback := boss.get_node("Feedback")
	feedback.set_script(FEEDBACK)
	feedback.score = score
	return boss

func _bear_victory() -> void:
	score.defeated = true
	super._bear_victory()
