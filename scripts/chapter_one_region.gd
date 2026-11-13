extends Node3D

# Shared geography only. Boss/reveal triggers and progression belong to Phase 5.
const GROVE_CENTER := Vector3(9, 0, -45)
const GROVE_RADIUS := 9.0
const GROVE_CLEARANCE := 10.5
const DRAGON_PERCH := Vector3(39, 10, -55)
const DRAGON_CAMERA := Vector3(9, 2.8, -45)
const DRAGON_LOOK_AT := Vector3(39, 12, -55)
const VISTA_CLEARANCE := 5.0

# Append to the original five routes; their indices and quest locations stay stable.
const TRAILS := [
	[Vector3(-44,0,54), Vector3(-44,0,36), Vector3(-40,0,26), Vector3(-40,0,12), Vector3(-39,0,-7), Vector3(-35,0,-19), Vector3(-27,0,-18), Vector3(-12,0,-16), Vector3(-4,0,-17), Vector3(0,0,-13)],
	[Vector3(0,0,-25), Vector3(4.5,0,-31), Vector3(4.5,0,-37), GROVE_CENTER],
	[GROVE_CENTER, Vector3(18,0,-39), Vector3(29,0,-31), Vector3(30,0,-19), Vector3(16,0,-4)]
]
const WAYMARKS := [
	{"name": "WoodlandTrail", "position": Vector3(-37,0,27), "text": "WOODLAND TRAIL\nNorth: forest & lantern ruins\nSouth: Tideseal Ruins"},
	{"name": "WesternRise", "position": Vector3(-43,0,7), "text": "WESTERN RISE\nWest: open hillside\nNorth: woodland trail"},
	{"name": "GroveTrail", "position": Vector3(-2,0,-40), "text": "ANCIENT GROVE\nNorth-east: woodland clearing\nSouth: lantern ruins"},
	{"name": "ForestReturn", "position": Vector3(31,0,-16), "text": "FOREST TRAIL\nNorth: Ancient Grove\nSouth: forest camp & beach"}
]

func _ready() -> void:
	name = "ChapterOneRegion"
	_anchor("AncientGrove", GROVE_CENTER).set_meta("clear_radius", GROVE_RADIUS)
	_anchor("DragonPerch", DRAGON_PERCH).look_at(Vector3(DRAGON_CAMERA.x, DRAGON_PERCH.y, DRAGON_CAMERA.z))
	_anchor("DragonLookAt", DRAGON_LOOK_AT)
	var camera_anchor := _anchor("DragonCamera", DRAGON_CAMERA)
	camera_anchor.look_at(DRAGON_LOOK_AT)
	camera_anchor.set_meta("fov", 42.0)
	var stone_mesh := CylinderMesh.new()
	stone_mesh.top_radius = 0.18
	stone_mesh.bottom_radius = 0.32
	stone_mesh.height = 0.7
	stone_mesh.radial_segments = 6
	stone_mesh.rings = 1
	stone_mesh.material = preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02", 0.7)
	for entry in WAYMARKS:
		var stone := StaticBody3D.new()
		stone.name = entry.name
		stone.position = entry.position
		stone.collision_layer = 4 | 8
		stone.collision_mask = 0
		add_child(stone)
		var visual := MeshInstance3D.new()
		visual.mesh = stone_mesh
		visual.position.y = 0.35
		visual.visibility_range_end = 35.0
		stone.add_child(visual)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.32
		shape.height = 0.7
		collision.shape = shape
		collision.position.y = 0.35
		stone.add_child(collision)
		_label(stone, entry.text, Vector3(0, 2.1, 0), 18.0)
	_label(self, "ANCIENT GROVE", GROVE_CENTER + Vector3(0, 2.6, 0), 22.0)

func _anchor(anchor_name: String, point: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = anchor_name
	marker.position = point
	add_child(marker)
	return marker

func _label(parent: Node3D, text: String, point: Vector3, distance: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = point
	label.font_size = 25
	label.modulate = Color(0.9, 0.86, 0.67)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = distance
	parent.add_child(label)

static func reserves_forest(point: Vector2) -> bool:
	if point.distance_to(Vector2(GROVE_CENTER.x, GROVE_CENTER.z)) < GROVE_CLEARANCE:
		return true
	var nearest := Geometry2D.get_closest_point_to_segment(point, Vector2(DRAGON_CAMERA.x, DRAGON_CAMERA.z), Vector2(DRAGON_PERCH.x, DRAGON_PERCH.z))
	return point.distance_to(nearest) < VISTA_CLEARANCE
