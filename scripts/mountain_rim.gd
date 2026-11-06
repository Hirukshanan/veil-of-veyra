extends Node3D

const PEAKS := [
	Vector4(-37, 0, 7, 12), Vector4(-32, -22, 8, 19),
	Vector4(-18, -35, 9, 24), Vector4(0, -40, 10, 27),
	Vector4(20, -34, 9, 21), Vector4(34, -20, 8, 18), Vector4(38, 3, 7, 13)
]

func _ready() -> void:
	name = "MountainRim"
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/environment/mountain_rock.gdshader")
	material.set_shader_parameter("rock", preload("res://assets/environment/polyhaven/rocky_terrain_02_Diffuse.jpg"))
	for index in range(PEAKS.size()):
		var peak: Vector4 = PEAKS[index]
		var mesh := _mountain_mesh(peak.z, peak.w, index)
		_add_rock(mesh, Vector3(peak.x, 0, peak.y), "Peak%d" % index, material)
	for index in range(PEAKS.size() - 1):
		var a := Vector3(PEAKS[index].x, 0, PEAKS[index].y)
		var b := Vector3(PEAKS[index + 1].x, 0, PEAKS[index + 1].y)
		var delta := b - a
		var mesh := _mountain_mesh(1.0, 5.0 + index % 3, index, Vector2(delta.length() * 0.62, 4.5))
		var ridge := _add_rock(mesh, (a + b) * 0.5, "Ridge%d" % index, material)
		ridge.rotation.y = atan2(-delta.z, delta.x)

func _add_rock(mesh: ArrayMesh, point: Vector3, label: String, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = point
	body.collision_layer = 1 | 4
	body.collision_mask = 0
	add_child(body)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)
	return body

static func _point(ring: int, sector: int, radius: float, height: float, seed_index: int) -> Vector3:
	var t := ring / 8.0
	var angle := sector * TAU / 32.0
	var ripple := sin(angle * 5.0 + seed_index) * 0.1 + cos(angle * 9.0 - seed_index) * 0.045
	var spread := radius * t * (1.0 + ripple * sin(t * PI))
	var x := cos(angle) * t
	var z := sin(angle) * t
	var main_peak := exp(-4.0 * (pow(x + 0.2, 2) + z * z))
	var shoulder := 0.85 * exp(-18.0 * (pow(x - 0.43, 2) + pow(z + 0.12, 2)))
	var spur := 0.7 * exp(-22.0 * (pow(x + 0.12, 2) + pow(z - 0.5, 2)))
	var elevation := height * maxf(main_peak, maxf(shoulder, spur)) * (1.0 - smoothstep(0.68, 1.0, t))
	elevation *= 1.0 + (sin(angle * 5.0 + seed_index) * 0.2 + sin(t * 35.0 + angle * 3.0) * 0.08) * sin(t * PI)
	# Offset the summit, break the ridges, and bury the foot in the shore.
	return Vector3(cos(angle) * spread + (1.0 - t) * radius * 0.18, elevation - 0.45, sin(angle) * spread)

static func _mountain_mesh(radius: float, height: float, seed_index: int, stretch := Vector2.ONE) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(8):
		for sector in range(32):
			var a := _point(ring, sector, radius, height, seed_index)
			var b := _point(ring + 1, sector, radius, height, seed_index)
			var c := _point(ring + 1, sector + 1, radius, height, seed_index)
			var d := _point(ring, sector + 1, radius, height, seed_index)
			for point in [a, b, c]:
				surface.add_vertex(point * Vector3(stretch.x, 1, stretch.y))
			if ring > 0:
				for point in [a, c, d]:
					surface.add_vertex(point * Vector3(stretch.x, 1, stretch.y))
	surface.generate_normals()
	return surface.commit()
