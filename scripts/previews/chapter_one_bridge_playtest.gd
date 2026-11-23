extends "res://scripts/previews/chapter_one_bear_playtest.gd"

const NEAR_BRIDGE := Vector3(2.7, 34.08, 49.0)
const FAR_BRIDGE := Vector3(2.7, 34.08, 79.0)
const BELOW_DECK := 33.55

func _create_awakening() -> Node3D:
	var event := super._create_awakening()
	event.bridge_recovery_review = true
	return event

func _under_bridge(point: Vector3) -> bool:
	return point.z >= 46.5 and point.z <= 86.0 and point.y < BELOW_DECK

func _bridge_checkpoint(point: Vector3) -> Vector3:
	return NEAR_BRIDGE if point.distance_squared_to(NEAR_BRIDGE) <= point.distance_squared_to(FAR_BRIDGE) else FAR_BRIDGE

func _ground_gameplay() -> void:
	var saved: Vector3 = player.position
	# Legacy fallen saves within the underground cell can be loaded directly.
	if world_data.get(awakening.FLAG, false) and saved.y >= 12.0 and absf(saved.x - NEAR_BRIDGE.x) < 19.0 and _under_bridge(saved):
		player.position = _bridge_checkpoint(saved)
	super._ground_gameplay()

func _capture_world() -> void:
	super._capture_world()
	if shrine.in_cell and awakening.finished() and _under_bridge(world_data.position):
		world_data.position = _bridge_checkpoint(world_data.position)

func _update_temple_thresholds() -> void:
	var point: Vector3 = player.position
	if shrine.in_cell and not awakening.active and awakening.finished() and _under_bridge(point):
		get_tree().call_group("movement_joysticks", "reset")
		player.set_move_input(Vector2.ZERO)
		player.sprint_enabled = false
		player._dodge_time = 0.0
		player._charge_knockback = Vector3.ZERO
		player.cancel_swing()
		_cross_threshold(_bridge_checkpoint(point))
		_save_progress()
		return
	super._update_temple_thresholds()
