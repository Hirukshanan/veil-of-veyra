extends Node3D

# Original procedural creature art; only visual transforms change during combat.
var kind := 0
var skin: StandardMaterial3D
var _head: Node3D
var _tail: Node3D
var _legs: Array[Node3D] = []
var _clock := 0.0
var _head_rest := Vector3.ZERO
var _armor: StandardMaterial3D
var _ivory: StandardMaterial3D
var _eyes: StandardMaterial3D

func _ready() -> void:
	_armor = _material(Color(0.075, 0.055, 0.12), 0.3)
	_ivory = _material(Color(0.8, 0.7, 0.47))
	_eyes = _material(Color(1.0, 0.32, 0.04))
	_eyes.emission_enabled = true
	_eyes.emission = Color(1.0, 0.12, 0.015)
	if kind == 1:
		_build_serpent()
	else:
		_build_quadruped()
	_head_rest = _head.position

func _material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	material.metallic = metallic
	return material

func _ellipsoid(parent: Node3D, position: Vector3, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = position
	piece.scale = size
	piece.material_override = material
	parent.add_child(piece)
	return piece

func _spike(parent: Node3D, base: Vector3, tip: Vector3, radius: float, material: StandardMaterial3D) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = base.distance_to(tip)
	mesh.radial_segments = 8
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = (base + tip) * 0.5
	piece.quaternion = Quaternion(Vector3.UP, (tip - base).normalized())
	piece.material_override = material
	parent.add_child(piece)

func _pivot(parent: Node3D, position: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = position
	parent.add_child(pivot)
	return pivot

func _build_quadruped() -> void:
	var boar := kind == 2
	var width := 0.56 if boar else 0.29
	var height := 0.83 if boar else 0.64
	_ellipsoid(self, Vector3(0, height, 0.05), Vector3(width, 0.47 if boar else 0.28, 0.7 if boar else 0.55), skin)
	# Layered dark carapace forms a fitted demonic saddle, not humanoid clothing.
	for index in range(3):
		var z := -0.27 + index * 0.29
		_ellipsoid(self, Vector3(0, height + (0.33 if boar else 0.21), z), Vector3(width * 1.04, 0.13, 0.24), _armor)
		_spike(self, Vector3(0, height + 0.38, z), Vector3(0, height + (0.72 if boar else 0.47), z + 0.1), 0.09 if boar else 0.05, _ivory)
	_head = _pivot(self, Vector3(0, height + 0.12, -0.55))
	_ellipsoid(_head, Vector3.ZERO, Vector3(0.43 if boar else 0.27, 0.36 if boar else 0.26, 0.4 if boar else 0.29), skin)
	if boar:
		_ellipsoid(_head, Vector3(0, -0.07, -0.36), Vector3(0.3, 0.2, 0.32), skin)
		_ellipsoid(_head, Vector3(0, -0.06, -0.61), Vector3(0.25, 0.16, 0.065), _armor)
		for side in [-1, 1]:
			_ellipsoid(_head, Vector3(side * 0.1, -0.04, -0.67), Vector3(0.04, 0.045, 0.02), _ivory)
			_tube(_head, [Vector3(side * 0.25, -0.17, -0.35), Vector3(side * 0.42, -0.14, -0.5), Vector3(side * 0.48, 0.09, -0.57), Vector3(side * 0.42, 0.3, -0.55)], [0.1, 0.09, 0.06, 0.005], _ivory)
	else:
		_ellipsoid(_head, Vector3(0, -0.09, -0.25), Vector3(0.19, 0.12, 0.27), _ivory)
		_ellipsoid(_head, Vector3(0, -0.055, -0.48), Vector3(0.085, 0.065, 0.055), _armor)
		for side in [-1, 1]:
			# Tall triangular ears and swept cheek tufts make the fox recognizable.
			_spike(_head, Vector3(side * 0.17, 0.15, 0.02), Vector3(side * 0.24, 0.62, 0.08), 0.17, skin)
			_spike(_head, Vector3(side * 0.17, 0.22, -0.055), Vector3(side * 0.23, 0.52, 0.0), 0.075, _armor)
			_spike(_head, Vector3(side * 0.18, -0.08, -0.02), Vector3(side * 0.43, -0.09, 0.16), 0.14, _ivory)
	for side in [-1, 1]:
		var x := 0.29 if boar else 0.19
		_ellipsoid(_head, Vector3(side * x, 0.09, -0.25), Vector3(0.075, 0.045, 0.055), _eyes)
		_spike(_head, Vector3(side * x, 0.2, -0.04), Vector3(side * (x + 0.1), 0.51 if boar else 0.36, -0.23), 0.1 if boar else 0.055, _armor)
	for front in [true, false]:
		for side in [-1, 1]:
			var leg := _pivot(self, Vector3(side * width * 0.78, height - 0.12, -0.34 if front else 0.43))
			_legs.append(leg)
			var length := height - 0.17
			_ellipsoid(leg, Vector3(0, -length * 0.45, 0), Vector3(0.16 if boar else 0.075, length * 0.55, 0.17 if boar else 0.09), skin)
			_ellipsoid(leg, Vector3(0, -length + 0.02, -0.06), Vector3(0.18 if boar else 0.10, 0.1, 0.21 if boar else 0.15), _armor)
	_tail = _pivot(self, Vector3(0, height, 0.58))
	if boar:
		_tube(_tail, [Vector3.ZERO, Vector3(0, 0.1, 0.25), Vector3(0.16, 0.25, 0.35), Vector3(0.24, 0.14, 0.3)], [0.07, 0.06, 0.04, 0.015], skin)
	else:
		_ellipsoid(_tail, Vector3(0, 0.12, 0.38), Vector3(0.24, 0.24, 0.52), skin).rotation.x = -0.3
		_ellipsoid(_tail, Vector3(0, 0.28, 0.77), Vector3(0.18, 0.18, 0.26), _ivory).rotation.x = -0.4

func _build_serpent() -> void:
	# A continuous tapered mesh gives the body a snake silhouette without bead joints.
	var points: Array[Vector3] = []
	var radii: Array[float] = []
	for index in range(25):
		var t := float(index) / 24.0
		var angle := t * TAU * 1.25
		points.append(Vector3(sin(angle) * 0.48 * (1.0 - t * 0.6), 0.2, 0.25 + cos(angle) * 0.48 * (1.0 - t * 0.6)))
		radii.append(lerpf(0.02, 0.19, t))
	_tube(self, points, radii, skin)
	_head = _pivot(self, points[-1])
	_tube(_head, [Vector3.ZERO, Vector3(0, 0.3, 0.05), Vector3(0, 0.6, -0.04), Vector3(0, 0.82, -0.22)], [0.19, 0.18, 0.15, 0.18], skin)
	for side in [-1, 1]:
		_ellipsoid(_head, Vector3(side * 0.2, 0.58, 0.02), Vector3(0.2, 0.37, 0.075), _armor).rotation.z = -side * 0.2
		_ellipsoid(_head, Vector3(side * 0.22, 0.62, -0.055), Vector3(0.07, 0.19, 0.025), _ivory)
	_ellipsoid(_head, Vector3(0, 0.84, -0.27), Vector3(0.26, 0.16, 0.33), skin)
	_ellipsoid(_head, Vector3(0, 0.74, -0.37), Vector3(0.21, 0.055, 0.25), _armor)
	for side in [-1, 1]:
		_ellipsoid(_head, Vector3(side * 0.18, 0.9, -0.46), Vector3(0.065, 0.045, 0.05), _eyes)
		_spike(_head, Vector3(side * 0.14, 0.77, -0.52), Vector3(side * 0.12, 0.57, -0.57), 0.045, _ivory)
		_spike(_head, Vector3(side * 0.18, 0.96, -0.18), Vector3(side * 0.25, 1.23, -0.1), 0.075, _armor)
	_tail = _pivot(self, Vector3.ZERO)

func _tube(parent: Node3D, points: Array[Vector3], radii: Array[float], material: StandardMaterial3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[Vector3] = []
	for index in range(points.size()):
		var tangent := (points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]).normalized()
		var axis := Vector3.RIGHT if absf(tangent.dot(Vector3.UP)) > 0.95 else Vector3.UP
		var right := tangent.cross(axis).normalized()
		var up := right.cross(tangent).normalized()
		for side in range(10):
			var angle := TAU * side / 10.0
			rings.append(points[index] + radii[index] * (cos(angle) * right + sin(angle) * up))
	for index in range(points.size() - 1):
		for side in range(10):
			var a := index * 10 + side
			var b := index * 10 + (side + 1) % 10
			for vertex in [a, b, a + 10, b, b + 10, a + 10]:
				surface.add_vertex(rings[vertex])
	surface.generate_normals()
	var piece := MeshInstance3D.new()
	piece.mesh = surface.commit()
	piece.material_override = material
	parent.add_child(piece)

func animate(delta: float, speed: float, anticipation: float, strike: float, hurt: float) -> void:
	_clock += delta * (2.0 + speed * 3.0)
	var stride := sin(_clock) * minf(speed, 1.0) * 0.55
	for index in range(_legs.size()):
		_legs[index].rotation.x = stride * (1.0 if index == 0 or index == 3 else -1.0) if anticipation == 0.0 and strike == 0.0 and hurt == 0.0 else 0.0
	_head.rotation.x = anticipation * 0.3 - strike * 0.5 + hurt * 0.2
	_head.position = _head_rest
	_head.position.z -= strike * 0.22
	if kind == 1:
		_head.rotation.z = sin(_clock * 0.6) * 0.12 * (1.0 - anticipation)
	_tail.rotation.y = sin(_clock * 0.6) * 0.25
