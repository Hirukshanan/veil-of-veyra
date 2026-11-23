extends Node3D

var dust: CPUParticles3D
var sparks: CPUParticles3D
var swipe: MeshInstance3D
var swipe_material: StandardMaterial3D
var swipe_tween: Tween
static var _particle_mask: GradientTexture2D

func _ready() -> void:
	if _particle_mask == null:
		_particle_mask = GradientTexture2D.new()
		_particle_mask.width = 16
		_particle_mask.height = 16
		_particle_mask.fill = GradientTexture2D.FILL_RADIAL
		_particle_mask.fill_from = Vector2(.5, .5)
		_particle_mask.fill_to = Vector2(1.0, .5)
		_particle_mask.gradient = Gradient.new()
		_particle_mask.gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	dust = _particles(Color("99836b9e"), 8, .33, .13)
	sparks = _particles(Color("f6ac69"), 5, .19, .038)
	swipe_material = _material(Color("ffbd7a"))
	_build_swipe()

func _particles(tint: Color, count: int, life: float, size: float) -> CPUParticles3D:
	var emitter := CPUParticles3D.new()
	emitter.emitting = false
	emitter.one_shot = true
	emitter.amount = count
	emitter.lifetime = life
	emitter.explosiveness = 1.0
	emitter.local_coords = false
	emitter.direction = Vector3.FORWARD
	emitter.spread = 52.0
	emitter.initial_velocity_min = .7
	emitter.initial_velocity_max = 1.8
	emitter.gravity = Vector3.DOWN * 2.2
	emitter.scale_amount_min = .5
	emitter.scale_amount_max = 1.35
	emitter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE * size
	var material := _material(tint)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = _particle_mask
	mesh.material = material
	emitter.mesh = mesh
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	emitter.color_ramp = ramp
	material.vertex_color_use_as_albedo = true
	add_child(emitter)
	return emitter

func _material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = tint
	return material

func _build_swipe() -> void:
	var ribbon := SurfaceTool.new()
	ribbon.begin(Mesh.PRIMITIVE_TRIANGLES)
	for mark in [-.07, .07]:
		for segment in 7:
			var a := float(segment) / 7.0
			var b := float(segment+1) / 7.0
			var start := Vector3(lerpf(-.32,.32,a), mark+a*.16, -.18*sin(a*PI))
			var end := Vector3(lerpf(-.32,.32,b), mark+b*.16, -.18*sin(b*PI))
			var edge_a := Vector3.UP * (.035*sin(a*PI))
			var edge_b := Vector3.UP * (.035*sin(b*PI))
			for point in [start-edge_a,start+edge_a,end+edge_b,start-edge_a,end+edge_b,end-edge_b]:
				ribbon.add_vertex(point)
	swipe = MeshInstance3D.new()
	swipe.mesh = ribbon.commit()
	swipe.material_override = swipe_material
	swipe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	swipe.top_level = true
	add_child(swipe)
	swipe.hide()

func kick(at: Vector3, heading: Vector3) -> void:
	var point := at + Vector3.UP * .13
	_emit(dust, point, heading + Vector3.UP * .38)

func impact(at: Vector3, heading: Vector3) -> void:
	_emit(sparks, at, heading + Vector3.UP * .3)

func _emit(emitter: CPUParticles3D, at: Vector3, heading: Vector3) -> void:
	emitter.look_at_from_position(at, at+heading)
	emitter.restart()
	emitter.emitting = true

func slash(at: Vector3, heading: Vector3) -> void:
	if swipe_tween:
		swipe_tween.kill()
	swipe.look_at_from_position(at, at+heading)
	swipe.show()
	swipe_tween = create_tween()
	swipe_tween.tween_method(_fade_swipe, .73, 0.0, .13)
	swipe_tween.tween_callback(swipe.hide)

func _fade_swipe(alpha: float) -> void:
	swipe_material.albedo_color.a = alpha
