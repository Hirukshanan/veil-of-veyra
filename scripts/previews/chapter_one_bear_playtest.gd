extends "res://scripts/chapter_one_economy.gd"

func _create_cave_bear() -> CharacterBody3D:
	var bear := super._create_cave_bear()
	bear.playtest_combat = true
	return bear
