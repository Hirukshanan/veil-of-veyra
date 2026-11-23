extends "res://scripts/bear_audio_review.gd"

func _uses_title_screen() -> bool:
	return true

func _ready() -> void:
	await super._ready()
	_initialize_title()
