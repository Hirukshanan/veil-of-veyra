extends MeshInstance3D

# A single static, two-surface landmark. Roots taper into the bank and curl back
# around a splintered heart. Only the exposed seams carry the lantern's warmth.
class RootSurface extends SurfaceTool:
	var vertices := 0

func _ready() -> void:
	var wood := RootSurface.new()
	var seams := RootSurface.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	seams.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bark := StandardMaterial3D.new()
	bark.albedo_texture = preload("res://assets/environment/polyhaven/island_tree_01/textures/island_tree_01_diff_1k.jpg")
	bark.albedo_color = Color("baa68c")
	bark.roughness = 0.93
	wood.set_material(bark)
	var sap := StandardMaterial3D.new()
	sap.albedo_color = Color("ca6542")
	sap.emission_enabled = true
	sap.emission = Color("e67335")
	seams.set_material(sap)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6187
	for i in 9:
		var along := Vector3.RIGHT.rotated(Vector3.UP, (i + rng.randf_range(-0.18, 0.18)) * TAU / 9)
		var across := along.cross(Vector3.UP)
		var reach := rng.randf_range(1.75, 2.6)
		var path := PackedVector3Array([Vector3.UP * rng.randf_range(0.7, 1.1) - along * 0.16,
			along * 0.38 + Vector3.UP * 0.72, along * 0.9 + across * 0.24 + Vector3.UP * rng.randf_range(0.29, 0.57),
			along * 1.47 + across * 0.28 + Vector3.UP * 0.17, along * reach - across * 0.15 - Vector3.UP * 0.12])
		_strand(wood, path, [0.34, 0.29, 0.19, 0.10, 0.012])
		_strand(wood, [path[2], path[2] + across * 0.42 + along * 0.18 - Vector3.UP * 0.12,
			path[3] + across * 0.76 - Vector3.UP * 0.23], [0.13, 0.067, 0.008])
		if i % 2 == 0:
			_strand(seams, [path[1] + Vector3.UP * 0.27, path[2] + Vector3.UP * 0.18,
				path[3] + Vector3.UP * 0.092], [0.024, 0.031, 0.006])
	for i in 5:
		var along := Vector3.RIGHT.rotated(Vector3.UP, i * TAU / 5)
		var across := along.cross(Vector3.UP)
		var top := rng.randf_range(1.45, 2.05)
		var bend := along * 0.43 + Vector3.UP * top * 0.76
		_strand(wood, [along * 0.35 - Vector3.UP * 0.1, across * 0.13 + Vector3.UP * 0.65,
			bend, along * 0.72 - across * 0.18 + Vector3.UP * top,
			along * 0.62 - across * 0.29 + Vector3.UP * (top + 0.25)], [0.4, 0.31, 0.19, 0.078, 0.008])
		_strand(wood, [bend, bend + across * 0.27 + Vector3.UP * 0.28,
			bend + across * 0.46 + Vector3.UP * 0.32], [0.12, 0.054, 0.008])
	mesh = wood.commit()
	seams.commit(mesh)

static func _strand(surface: RootSurface, path: PackedVector3Array, radii: Array, sides := 10) -> void:
	var curve := Curve3D.new()
	for i in path.size():
		var handle := (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]) / 6.0
		curve.add_point(path[i], -handle, handle)
	var last_ring := -1
	var previous_side := Vector3.ZERO
	for step in (path.size() - 1) * 4 + 1:
		var offset := step / 4.0
		var center := curve.samplef(offset)
		var tangent := (curve.samplef(minf(offset + .02, path.size() - 1)) - curve.samplef(maxf(0, offset - .02))).normalized()
		if step == 0:
			previous_side = Vector3.UP if absf(tangent.y) < .85 else Vector3.RIGHT
		var side := previous_side.slide(tangent).normalized()
		var across := tangent.cross(side)
		previous_side = side
		var lower := floori(offset)
		var radius := lerpf(radii[lower], radii[mini(lower + 1, radii.size() - 1)], offset - lower)
		var ring := surface.vertices
		surface.vertices += sides + 1
		for j in sides + 1:
			var angle := TAU * j / sides
			var normal := cos(angle) * side + sin(angle) * across
			surface.set_normal(normal)
			surface.set_uv(Vector2(float(j) / sides, offset * 0.48))
			surface.add_vertex(center + normal * radius * (1.0 + 0.10 * cos(3.0 * angle + offset)))
		if last_ring >= 0:
			for j in sides:
				for index in [last_ring+j, ring+j, ring+j+1, last_ring+j, ring+j+1, last_ring+j+1]:
					surface.add_index(index)
		last_ring = ring
