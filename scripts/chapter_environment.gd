extends Node3D

const GROUND_COLORS := [Color(0.58, 0.48, 0.29), Color(0.19, 0.31, 0.21), Color(0.21, 0.2, 0.25)]
const SEA_COLORS := [Color(0.03, 0.28, 0.34), Color(0.025, 0.17, 0.19), Color(0.09, 0.1, 0.17)]
var chapter := 0
var landmarks: Array[Node3D] = []

func _ready() -> void:
	var count: int = [10, 14, 8][chapter]
	for index in range(count):
		var angle := TAU * float(index) / count + 0.17
		var landmark := Node3D.new()
		landmark.name = ["ShorePalm", "GroveTree", "RuinPillar"][chapter] + str(index + 1)
		landmark.position = Vector3(cos(angle) * 12.8, 0, sin(angle) * 12.8)
		add_child(landmark)
		landmarks.append(landmark)
		match chapter:
			0: _palm(landmark)
			1: _grove_tree(landmark, index)
			2: _ruin(landmark, index)

func _piece(parent: Node3D, mesh: Mesh, location: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = location
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _column(parent: Node3D, radius: float, height: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.8
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	_piece(parent, mesh, Vector3(0, height * 0.5, 0), color)
	# Camera-only blockers keep direct-pursuit enemies from getting trapped.
	var blocker := StaticBody3D.new()
	blocker.collision_layer = 4
	blocker.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	collision.position.y = height * 0.5
	blocker.add_child(collision)
	parent.add_child(blocker)

func _palm(parent: Node3D) -> void:
	_column(parent, 0.25, 3.6, Color(0.43, 0.3, 0.18))
	for index in range(5):
		var angle := TAU * index / 5.0
		var frond := PrismMesh.new()
		frond.size = Vector3(0.8, 0.25, 2.6)
		var leaf := _piece(parent, frond, Vector3(sin(angle) * 1.1, 3.55, cos(angle) * 1.1), Color(0.2, 0.43, 0.25))
		leaf.rotation = Vector3(0.15, angle, 0)

func _grove_tree(parent: Node3D, index: int) -> void:
	var height := 3.0 + (index % 3) * 0.4
	_column(parent, 0.38, height, Color(0.22, 0.17, 0.16))
	var crown := SphereMesh.new()
	crown.radius = 1.5
	crown.height = 2.7
	crown.radial_segments = 8
	crown.rings = 4
	_piece(parent, crown, Vector3(0, height, 0), Color(0.12, 0.3, 0.24))
	var fungus := SphereMesh.new()
	fungus.radius = 0.25
	fungus.height = 0.2
	fungus.radial_segments = 8
	fungus.rings = 4
	_piece(parent, fungus, Vector3(0.6, 0.2, 0.3), Color(0.3, 0.65, 0.65))

func _ruin(parent: Node3D, index: int) -> void:
	var height := 2.3 if index % 2 == 0 else 3.7
	_column(parent, 0.6, height, Color(0.33, 0.3, 0.38))
	var plinth := BoxMesh.new()
	plinth.size = Vector3(1.5, 0.3, 1.5)
	_piece(parent, plinth, Vector3(0, 0.15, 0), Color(0.29, 0.26, 0.32))
	var cap := BoxMesh.new()
	cap.size = Vector3(1.3, 0.3, 1.1)
	var broken_cap := _piece(parent, cap, Vector3(0.1, height, 0), Color(0.43, 0.38, 0.46))
	broken_cap.rotation.z = 0.12 if index % 2 == 0 else -0.08
