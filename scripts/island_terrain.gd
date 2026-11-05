extends RefCounted

# Keep combat ground level and slope only the beach.
static func coast_radius(angle: float, base: float) -> float:
	return base + 1.5 * sin(angle * 3.0) + 0.8 * sin(angle * 5.0) + 0.5 * sin(angle * 7.0)

static func ground(interior: bool = false) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(128):
		var a := index * TAU / 128.0
		var b := (index + 1) * TAU / 128.0
		var base := 33.0 if interior else 38.0
		var p := Vector3(cos(a), 0, sin(a)) * coast_radius(a, base)
		var q := Vector3(cos(b), 0, sin(b)) * coast_radius(b, base)
		p.y = 1.015 if interior else 1.0
		q.y = p.y
		for vertex in [Vector3(0, p.y, 0), p, q]:
			surface.add_vertex(vertex)
		if not interior:
			var outer_p := Vector3(cos(a), 0, sin(a)) * coast_radius(a, 48.0)
			var outer_q := Vector3(cos(b), 0, sin(b)) * coast_radius(b, 48.0)
			outer_p.y = -1.0
			outer_q.y = -1.0
			for vertex in [p, outer_p, q, q, outer_p, outer_q]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

static func trails() -> Array[PackedVector3Array]:
	var routes: Array[PackedVector3Array] = []
	for points in [
		[Vector3(0, 0, 29), Vector3(0, 0, 27), Vector3(-3, 0, 18), Vector3(0, 0, 12), Vector3(0, 0, 2), Vector3(2, 0, -4), Vector3(-2, 0, -13), Vector3(0, 0, -20), Vector3(0, 0, -25)],
		[Vector3(0, 0, 12), Vector3(-8, 0, 9), Vector3(-18, 0, 12)],
		[Vector3(2, 0, -4), Vector3(9, 0, -1), Vector3(16, 0, -4)]
	]:
		var curve := Curve3D.new()
		curve.bake_interval = 0.8
		for index in range(points.size()):
			var tangent: Vector3 = (points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]) / 6.0
			curve.add_point(points[index], -tangent, tangent)
		routes.append(curve.get_baked_points())
	return routes

static func trail_mesh(points: PackedVector3Array, width: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(points.size() - 1):
		var sides: Array[Vector3] = []
		for sample in [index, index + 1]:
			var tangent := (points[mini(sample + 1, points.size() - 1)] - points[maxi(sample - 1, 0)]).normalized()
			var side := tangent.cross(Vector3.UP) * width * (0.5 + 0.055 * sin(sample * 0.7))
			sides.append(points[sample] + side + Vector3.UP * 0.035)
			sides.append(points[sample] - side + Vector3.UP * 0.035)
		for corner in [0, 1, 2, 2, 1, 3]:
			surface.add_vertex(sides[corner])
	surface.generate_normals()
	return surface.commit()