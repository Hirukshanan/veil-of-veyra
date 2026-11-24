extends RefCounted

const PREVIEW_ACTOR := preload("res://scripts/armory_preview_actor.gd")
const EQUIPMENT := preload("res://scripts/aru_modular_equipment.gd")
const STONE := preload("res://assets/ui/armory/platform_stone.jpg")
const DEFAULT_YAW := PI + .32
const DEFAULT_ZOOM := 2.66
const MIN_ZOOM := 2.13
const MAX_ZOOM := 3.40

static func build(frame: SubViewportContainer) -> Dictionary:
	var view := SubViewport.new()
	view.own_world_3d = true
	view.transparent_bg = true
	view.msaa_3d = Viewport.MSAA_2X
	view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	frame.add_child(view)
	var room := WorldEnvironment.new()
	room.environment = Environment.new()
	room.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	room.environment.ambient_light_color = Color("d7cbd6")
	room.environment.ambient_light_energy = .64
	view.add_child(room)
	for setup in [[Vector3(-42, -35, 0), Color("ffe2bf"), 1.55],
			[Vector3(-26, 142, 0), Color("ffd099"), 1.16],
			[Vector3(-9, 43, 0), Color("b8c7e9"), .49]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = setup[0]
		light.light_color = setup[1]
		light.light_energy = setup[2]
		view.add_child(light)
	_platform(view)
	var actor := PREVIEW_ACTOR.new()
	actor.relaxed_idle = true
	view.add_child(actor)
	actor.set_physics_process(false)
	actor.set_process_input(false)
	actor.set_process_unhandled_input(false)
	actor.rotation.y = DEFAULT_YAW
	var equipment := EQUIPMENT.new()
	actor.add_child(equipment)
	equipment.bind_hero(actor)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = DEFAULT_ZOOM
	view.add_child(camera)
	camera.position = Vector3(0, 1.53, 4.7)
	camera.look_at(Vector3(0, .83, 0))
	camera.make_current()
	return {"actor": actor, "equipment": equipment, "camera": camera}

static func _platform(view: SubViewport) -> void:
	var slate := StandardMaterial3D.new()
	slate.albedo_color = Color("a8a2a0")
	slate.albedo_texture = STONE
	slate.roughness = .94
	slate.uv1_triplanar = true
	slate.uv1_scale = Vector3.ONE * 1.65
	slate.normal_enabled = true
	slate.normal_texture = preload("res://assets/environment/polyhaven/rocky_terrain_02_nor_gl.jpg")
	slate.normal_scale = .65
	slate.vertex_color_use_as_albedo = true
	slate.cull_mode = BaseMaterial3D.CULL_DISABLED
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color("aa7747")
	bronze.metallic = .6
	bronze.roughness = .51
	_stonework(view, slate)
	# The engraved rim sits in the shallow lip above the masonry.
	bronze.albedo_color = Color("91734c")
	bronze.roughness = .72
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES, bronze)
	for radius in [.64, .98]:
		for index in 72:
			for end in [index, index + 1]:
				var angle: float = TAU * end / 72.0
				lines.surface_add_vertex(Vector3(cos(angle) * radius, .002, sin(angle) * radius))
	for index in 8:
		var angle := TAU * index / 8.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		lines.surface_add_vertex(direction * .64 + Vector3.UP * .002)
		lines.surface_add_vertex(direction * .98 + Vector3.UP * .002)
		var center := direction * .81 + Vector3.UP * .002
		var tangent := Vector3(-direction.z, 0, direction.x)
		var glyph := PackedVector3Array([center + direction * .054, center + tangent * .028,
			center - direction * .054, center - tangent * .028])
		for edge in 4:
			lines.surface_add_vertex(glyph[edge])
			lines.surface_add_vertex(glyph[(edge + 1) % 4])
	lines.surface_end()
	var inlay := MeshInstance3D.new()
	inlay.mesh = lines
	view.add_child(inlay)
	var contact := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.28, .70)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, .43))
	gradient.set_color(1, Color.TRANSPARENT)
	var blur := GradientTexture2D.new()
	blur.gradient = gradient
	blur.fill = GradientTexture2D.FILL_RADIAL
	blur.fill_from = Vector2(.5, .5)
	blur.fill_to = Vector2(1, .5)
	blur.width = 32
	blur.height = 32
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.albedo_texture = blur
	plane.material = ink
	contact.mesh = plane
	contact.position = Vector3(0, .009, .10)
	view.add_child(contact)

static func _stonework(view: SubViewport, material: StandardMaterial3D) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_material(material)
	var rng := RandomNumberGenerator.new()
	rng.seed = 247
	for course in [
		[1.17, .89, -.29, -.214, 0.0],
		[1.10, .89, -.217, -.08, .19],
		[1.14, .98, -.091, -.014, 0.0],
	]:
		for i in 20:
			var a: float = TAU * i / 20.0 + course[4] + .008
			var b: float = TAU * (i + 1) / 20.0 + course[4] - .008
			var outer: float = course[0] + rng.randf_range(-.012, .012)
			var inner: float = course[1]
			var base: float = course[2]
			var top: float = course[3]
			var tint := Color.WHITE * rng.randf_range(.57, .86)
			var low_a := _polar(outer - .014, base, a)
			var low_b := _polar(outer - .014, base, b)
			var mid_a := _polar(outer, top - .025, a)
			var mid_b := _polar(outer, top - .025, b)
			var high_a := _polar(outer - .031, top, a)
			var high_b := _polar(outer - .031, top, b)
			var rim := _polar(1, 0, (a + b) * .5)
			_quad(builder, low_a, low_b, mid_b, mid_a, rim, tint)
			_quad(builder, mid_a, mid_b, high_b, high_a, (rim + Vector3.UP).normalized(), tint)
			_quad(builder, high_a, high_b, _polar(inner, top, b), _polar(inner, top, a), Vector3.UP, tint)
	var center_radius := 1.004
	for i in 48:
		var a := TAU * i / 48.0
		var b := TAU * (i + 1) / 48.0
		builder.set_normal(Vector3.UP)
		builder.set_color(Color(.75, .74, .72))
		builder.add_vertex(Vector3(0, -.004, 0))
		builder.add_vertex(_polar(center_radius, -.004, a))
		builder.add_vertex(_polar(center_radius, -.004, b))
	var dais := MeshInstance3D.new()
	dais.mesh = builder.commit()
	view.add_child(dais)

static func _polar(radius: float, y: float, angle: float) -> Vector3:
	return Vector3(cos(angle) * radius, y, sin(angle) * radius)

static func _quad(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, tint: Color) -> void:
	builder.set_normal(normal)
	builder.set_color(tint)
	var forward := (c - a).cross(b - a).dot(normal) >= 0.0
	var vertices := [a, b, c, a, c, d] if forward else [a, c, b, a, d, c]
	for point in vertices:
		builder.add_vertex(point)
