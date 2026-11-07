extends Node

const CAMP := Vector3(-18, 0, 12)
const BONUS := 15
var accepted := false
var reported := false
func _ready() -> void:
	name = "WesternWatchQuest"

func remaining() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("lock_targets"):
		if enemy.get_script() != preload("res://scripts/enemy.gd"):
			continue
		if not enemy.is_queued_for_deletion() and enemy.health > 0 and enemy._home.distance_to(CAMP) < 6.0:
			count += 1
	return count

func accept() -> void:
	accepted = true

func report() -> bool:
	if not accepted or reported or remaining() > 0:
		return false
	reported = true
	return true

func reward() -> int:
	return BONUS if reported else 0

func journal_text() -> String:
	if reported:
		return "WESTERN WATCH - REPORTED\nDefeat the dragon to receive 15 bonus shards."
	if not accepted:
		return "WESTERN WATCH - AVAILABLE\nAccept this bounty using the button in this quest scroll. No conversation is required."
	if remaining() > 0:
		return "WESTERN WATCH - ACTIVE\nClear the western camp: %d wolves remaining. Then complete the bounty in QUEST." % remaining()
	return "WESTERN WATCH - RETURN\nThe western camp is clear. Use Complete in QUEST to secure your bonus."

func hint(origin: Vector3, camera_basis: Basis) -> String:
	if not accepted:
		return "QUEST: optional Western Watch bounty"
	if reported:
		return "Western Watch: +15 shards on victory"
	if remaining() == 0:
		return "QUEST: Western Watch ready to complete"
	var target := CAMP
	return ("Western camp | " if remaining() > 0 else "Return to Keeper | ") + preload("res://scripts/island_exploration.gd").direction_hint(origin, target, camera_basis)