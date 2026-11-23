extends "res://scripts/previews/chapter_one_tidewarden_playtest.gd"

func _create_tidewarden() -> Tidewarden:
	return preload("res://scripts/previews/tidewarden_visual_shrine.gd").new()
