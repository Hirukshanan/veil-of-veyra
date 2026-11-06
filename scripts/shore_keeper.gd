extends Node3D

const HOME := Vector3(4, 0, 25)
const CAMP := Vector3(-18, 0, 12)
const BONUS := 15
var accepted := false
var reported := false
var marker: Label3D

func _ready() -> void:
	name = "ShoreKeeper"
	position = HOME
	var visual := preload("res://scripts/hero_visual.gd").new()
	add_child(visual)
	var spirit := StandardMaterial3D.new()
	spirit.albedo_color = Color(0.22, 0.62, 0.74)
	spirit.emission_enabled = true
	spirit.emission = Color(0.03, 0.16, 0.2)
	spirit.roughness = 0.85
	for mesh in visual._meshes:
		mesh.material_override = spirit
	var ring := MeshInstance3D.new()
	var shape := TorusMesh.new()
	shape.inner_radius = 0.75
	shape.outer_radius = 0.85
	shape.rings = 24
	shape.ring_segments = 8
	ring.mesh = shape
	ring.position.y = 0.06
	ring.material_override = spirit
	add_child(ring)
	marker = Label3D.new()
	marker.position.y = 2.4
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 32
	marker.visibility_range_end = 18.0
	add_child(marker)
	update_marker()

func remaining() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("lock_targets"):
		if enemy.get_script() != preload("res://scripts/enemy.gd"):
			continue
		if not enemy.is_queued_for_deletion() and enemy.health > 0 and enemy._home.distance_to(CAMP) < 6.0:
			count += 1
	return count

func update_marker() -> void:
	marker.text = "SHORE KEEPER\n" + ("WATCH RESTORED" if reported else ("REPORT BACK [E]" if accepted and remaining() == 0 else ("WESTERN WATCH" if accepted else "TALK [E]")))

func accept() -> void:
	accepted = true
	update_marker()

func report() -> bool:
	if not accepted or reported or remaining() > 0:
		return false
	reported = true
	update_marker()
	return true

func reward() -> int:
	return BONUS if reported else 0

func journal_text() -> String:
	if reported:
		return "WESTERN WATCH - REPORTED\nDefeat the dragon to receive 15 bonus shards."
	if not accepted:
		return "WESTERN WATCH - AVAILABLE\nSpeak with the Shore Keeper beside the beach waystone to accept an optional bounty."
	if remaining() > 0:
		return "WESTERN WATCH - ACTIVE\nClear the western camp: %d wolves remaining. Then return to the Shore Keeper." % remaining()
	return "WESTERN WATCH - RETURN\nThe western camp is clear. Speak with the Shore Keeper at the beach to secure your bonus."

func hint(origin: Vector3, camera_basis: Basis) -> String:
	if not accepted:
		return "Shore Keeper at beach: optional bounty"
	if reported:
		return "Western Watch: +15 shards on victory"
	var target := CAMP if remaining() > 0 else HOME
	return ("Western camp | " if remaining() > 0 else "Return to Keeper | ") + preload("res://scripts/island_exploration.gd").direction_hint(origin, target, camera_basis)