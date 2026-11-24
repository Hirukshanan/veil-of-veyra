extends "res://scripts/player.gd"

var relaxed_idle := false

func _ready() -> void:
	_visual = preload("res://scripts/hero_visual.gd").new()
	_visual.idle_only = true
	_visual.relaxed_preview_idle = relaxed_idle
	add_child(_visual)
	_build_weapon()
