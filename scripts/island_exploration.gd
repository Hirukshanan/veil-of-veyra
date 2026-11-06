extends Node3D

const CAMPS := [Vector3(-18, 0, 12), Vector3(16, 0, -4), Vector3(0, 0, -25)]
const CHECKPOINTS := [Vector3(0, 0, 27), Vector3(0, 0, 2), Vector3(0, 0, -20)]
var player: Node3D
var checkpoint_index := -1
var _waystone_labels: Array[Label3D] = []

func _ready() -> void:
	add_child(preload("res://scripts/mountain_rim.gd").new())
	var decor = preload("res://scripts/chapter_environment.gd").new()
	for index in range(20):
		var tree := Node3D.new()
		tree.position = Vector3((-1 if index % 2 == 0 else 1) * (8 + (index % 4) * 3), 0, 22 - (index / 2) * 4.3)
		tree.position.x += sin(index * 5.3) * 1.8
		tree.position.z += cos(index * 3.7) * 1.4
		add_child(tree)
		if tree.position.z > 10:
			decor._palm(tree)
		else:
			decor._grove_tree(tree, index)
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
	for index in range(8):
		var ruin := Node3D.new()
		ruin.position = Vector3(cos(index * TAU / 8) * 9, 0, -25 + sin(index * TAU / 8) * 8)
		add_child(ruin)
		decor._ruin(ruin, index)
	for index in range(CAMPS.size()):
		_label(["WESTERN HUNTING CAMP", "FOREST HUNTING CAMP", "LANTERN RUINS"][index], CAMPS[index] + Vector3(0, 3.5, 0))
	for index in range(CHECKPOINTS.size()):
		var stone := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1.2
		mesh.bottom_radius = 1.2
		mesh.height = 0.06
		stone.mesh = mesh
		stone.position = CHECKPOINTS[index] + Vector3(0, 0.04, 0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.7, 0.6, 0.3)
		stone.material_override = material
		add_child(stone)
		_waystone_labels.append(_label("WAYSTONE • approach to bind", CHECKPOINTS[index] + Vector3(0, 2, 0)))
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
	for index in range(CHECKPOINTS.size()):
		if player.global_position.distance_to(CHECKPOINTS[index]) < 2.0:
			checkpoint_index = index
			for label_index in range(_waystone_labels.size()):
				_waystone_labels[label_index].text = "WAYSTONE • BOUND" if label_index == index else "WAYSTONE • approach to bind"
			player.rescue_position = CHECKPOINTS[index] + Vector3.UP
	# Water is a boundary, not a swimming mechanic. Rescue has the existing fall penalty.
	if player.global_position.y < -1.2:
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

func rescue_name() -> String:
	return ["Beach", "Forest", "Ruins"][checkpoint_index] if checkpoint_index >= 0 else "Beach"