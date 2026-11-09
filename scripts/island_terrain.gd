extends RefCounted

# Keep combat ground level and slope only the beach.
static func coast_radius(angle: float, base: float) -> float:
	return base + 1.5 * sin(angle * 3.0) + 0.8 * sin(angle * 5.0) + 0.5 * sin(angle * 7.0)

static func ground() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(128):
		var a := index * TAU / 128.0
		var b := (index + 1) * TAU / 128.0
		var base := 76.0
		var p := Vector3(cos(a), 0, sin(a)) * coast_radius(a, base)
		var q := Vector3(cos(b), 0, sin(b)) * coast_radius(b, base)
		p.y = 1.0
		q.y = p.y
		for vertex in [Vector3(0, p.y, 0), p, q]:
			surface.add_vertex(vertex)
		var outer_p := Vector3(cos(a), 0, sin(a)) * coast_radius(a, 96.0)
		var outer_q := Vector3(cos(b), 0, sin(b)) * coast_radius(b, 96.0)
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
		[Vector3(2, 0, -4), Vector3(9, 0, -1), Vector3(16, 0, -4)],
		[Vector3(0,0,27), Vector3(12,0,29), Vector3(24,0,29), Vector3(36,0,28), Vector3(44,0,28)]
	]:
		var curve := Curve3D.new()
		curve.bake_interval = 0.8
		for index in range(points.size()):
			var tangent: Vector3 = (points[mini(index + 1, points.size() - 1)] - points[maxi(index - 1, 0)]) / 6.0
			curve.add_point(points[index], -tangent, tangent)
		routes.append(curve.get_baked_points())
	return routes

# Rasterized once and shared across chapter reloads; no per-frame route loop.
static var _trail_mask: ImageTexture

static func trail_mask() -> ImageTexture:
	if _trail_mask != null:
		return _trail_mask
	var image := Image.create(256, 256, false, Image.FORMAT_R8)
	image.fill(Color.BLACK)
	var routes := trails()
	for route_index in range(routes.size()):
		var radius := 3.0 if route_index == 0 else 2.3
		for point in routes[route_index]:
			var center := (Vector2(point.x, point.z) / 104.0 + Vector2.ONE * 0.5) * 256.0
			var pixels := ceili(radius * 256.0 / 104.0)
			for y in range(maxi(0, int(center.y) - pixels), mini(256, int(center.y) + pixels + 1)):
				for x in range(maxi(0, int(center.x) - pixels), mini(256, int(center.x) + pixels + 1)):
					var distance := (Vector2(x + 0.5, y + 0.5) - center).length() * 104.0 / 256.0
					var weight := 1.0 - smoothstep(radius * 0.4, radius, distance)
					if weight > image.get_pixel(x, y).r:
						image.set_pixel(x, y, Color(weight, 0, 0))
	_trail_mask = ImageTexture.create_from_image(image)
	return _trail_mask

static func material(chapter: int) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = preload("res://assets/environment/island_ground.gdshader")
	var ids := ["coast_sand_01", "leafy_grass", "forest_ground_04"]
	var layers := ["sand", "grass", "soil"]
	for index in range(ids.size()):
		var path: String = "res://assets/environment/polyhaven/" + ids[index]
		result.set_shader_parameter(layers[index] + "_color", load(path + "_Diffuse.jpg"))
		result.set_shader_parameter(layers[index] + "_normal", load(path + "_nor_gl.jpg"))
	result.set_shader_parameter("trail_mask", trail_mask())
	result.set_shader_parameter("chapter_tint", [Color(1, 0.97, 0.9), Color(0.85, 1, 0.85), Color(0.85, 0.85, 0.95)][chapter])
	return result