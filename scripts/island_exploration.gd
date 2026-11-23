extends Node3D

const CAMPS := [Vector3(-18, 0, 12), Vector3(16, 0, -4), Vector3(0, 0, -25)]
const BEACH_SPAWN := Vector3(0, 0, 27)
var player: Node3D
func _ready() -> void:
	add_child(preload("res://scripts/chapter_one_region.gd").new())
	add_child(preload("res://scripts/island_grass.gd").new())
	add_child(preload("res://scripts/moonleaf_grove.gd").new())
	var forest:=preload("res://scripts/island_forest.gd").new()
	for camp in CAMPS: forest.clearings.append(Vector4(camp.x,camp.y,camp.z,6.5))
	# Retain the authored clearings in the legacy forest layout.
	for point in [BEACH_SPAWN, Vector3(0,0,2), Vector3(0,0,-20)]:
		forest.clearings.append(Vector4(point.x, point.y, point.z, 4.0))
	add_child(forest)
	var decor = preload("res://scripts/chapter_environment.gd").new()
	for index in range(12):
		var fern := preload("res://assets/environment/fern_02_mobile.scn").instantiate()
		fern.position = Vector3((-1 if index % 2 == 0 else 1) * (6 + index % 4), 0, 18 - index * 3.5)
		fern.rotation.y = index * 2.1
		add_child(fern)
		for mesh in fern.find_children("*", "MeshInstance3D", true, false):
			mesh.visibility_range_end = 28.0
	var rock_material := preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02", 0.7)
	for index in range(16):
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 2.0
		mesh.radial_segments = 10
		mesh.rings = 5
		rock.mesh = mesh
		var angle := index * TAU / 16
		rock.position = Vector3(cos(angle) * 34.0, 0.3, sin(angle) * 34.0)
		rock.scale = Vector3(1.2 + absf(sin(index * 3.1)), 0.7 + absf(cos(index * 2.1)), 1.0 + absf(cos(index)))
		rock.rotation = Vector3(0.2 * sin(index), angle, 0.2 * cos(index))
		rock.material_override = rock_material
		rock.visibility_range_end = 65.0
		add_child(rock)
		rock.create_convex_collision()
		var blocker := rock.get_child(0) as StaticBody3D
		blocker.collision_layer = 4 | 8
		blocker.collision_mask = 0
	for index in range(8):
		var ruin := Node3D.new()
		ruin.position = Vector3(cos(index * TAU / 8) * 9, 0, -25 + sin(index * TAU / 8) * 8)
		add_child(ruin)
		decor._ruin(ruin, index)
	for index in range(CAMPS.size()):
		_label(["WESTERN HUNTING CAMP", "FOREST HUNTING CAMP", "LANTERN RUINS"][index], CAMPS[index] + Vector3(0, 3.5, 0))
	decor.free()


func _label(text: String, point: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = point
	label.font_size = 30
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.visibility_range_end = 25
	add_child(label)
	return label

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player) or player.health <= 0:
		return
	# Emergency rescue for genuine falls through geometry.
	# Normal sea entry is blocked by the shallow-water boundary wall;
	# this only fires for positions well below the water surface.
	if player.global_position.y < -4.0:
		player.global_position = player.rescue_position
		player.velocity = Vector3.ZERO
		player.take_damage(20)

static func direction_hint(origin: Vector3, destination: Vector3, camera_basis: Basis) -> String:
	var offset := destination - origin
	offset.y = 0
	if offset.length() < 2.0:
		return "Nearby"
	var forward := -camera_basis.z
	forward.y = 0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	var angle := atan2(offset.dot(right), offset.dot(forward))
	var sector := posmod(roundi(angle / (PI / 4.0)), 8)
	return "%s %.0fm" % [["Ahead", "Ahead-R", "Right", "Back-R", "Behind", "Back-L", "Left", "Ahead-L"][sector], offset.length()]
