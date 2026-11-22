extends Node3D

const FOX_AUDIO := preload("res://scripts/fox_combat_audio.gd")
const VEIL_SHADER := preload("res://scripts/fox_veil.gdshader")

const RIPPLE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never;
uniform float progress : hint_range(0.0, 1.0);
void fragment() {
	vec2 point = UV * 2.0 - 1.0;
	float radius = mix(0.17, 0.92, progress);
	float distance_to_edge = abs(length(point) - radius);
	float band = 1.0 - smoothstep(0.012, 0.074, distance_to_edge);
	float arc = 0.62 + 0.38 * sin(atan(point.y, point.x) * 5.0 - progress * 7.0);
	ALBEDO = vec3(0.97, 0.045, 0.115);
	ALPHA = band * arc * smoothstep(0.0, 0.15, progress) * pow(1.0 - progress, 1.35) * 0.82;
}
"""
const VEIL_WARNING_SECONDS := .48
const RIPPLE_START := .30
const RIPPLE_SECONDS := .34

class VeilSurface:
	var mesh: MeshInstance3D
	var index: int
	var original: Material
	var effect: ShaderMaterial

var _veil_surfaces: Array[VeilSurface] = []
var _trail: GPUParticles3D
var _burst: GPUParticles3D
var _ripple: MeshInstance3D
var _ripple_material: ShaderMaterial
var _ripple_time := 0.0
var _veil_amount := 0.0
var _tell_amount := 0.0
var _veiled := false
var _telling := false
var _materials_swapped := false

var audio: Node3D
var _warning: MeshInstance3D
var _warning_material: StandardMaterial3D
var _dust: CPUParticles3D
var _label: Label3D
var _maximum := 0

func _ready() -> void:
	audio = FOX_AUDIO.new()
	audio.name = "FoxAudio"
	add_child(audio)
	_label = Label3D.new()
	_label.position.y = 1.23
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 32
	_label.outline_size = 8
	_label.pixel_size = .0044
	add_child(_label)
	_warning = MeshInstance3D.new()
	_warning.top_level = true
	_warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_warning_material = StandardMaterial3D.new()
	_warning_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warning_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_warning_material.albedo_color = Color(.93, .52, .21, .48)
	_warning.material_override = _warning_material
	_warning.hide()
	add_child(_warning)
	_build_dust()

func _build_dust() -> void:
	_dust = CPUParticles3D.new()
	_dust.top_level = true
	_dust.emitting = false
	_dust.one_shot = true
	_dust.amount = 8
	_dust.lifetime = .28
	_dust.explosiveness = 1.0
	_dust.direction = Vector3.UP
	_dust.spread = 77.0
	_dust.gravity = Vector3(0, -2.0, 0)
	_dust.initial_velocity_min = .42
	_dust.initial_velocity_max = 1.4
	_dust.scale_amount_min = .68
	_dust.scale_amount_max = 1.14
	_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var puff := SphereMesh.new()
	puff.radius = .068
	puff.height = .09
	puff.radial_segments = 5
	puff.rings = 3
	var dust_material := StandardMaterial3D.new()
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.vertex_color_use_as_albedo = true
	puff.material = dust_material
	_dust.mesh = puff
	var fade := Gradient.new()
	fade.set_color(0, Color(.55, .43, .32, .43))
	fade.set_color(1, Color(.55, .43, .32, 0.0))
	_dust.color_ramp = fade
	add_child(_dust)

func warn_landing(point: Vector3, radius: float) -> void:
	var ring := SurfaceTool.new()
	ring.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 18
	var inner := PackedVector3Array()
	var outer := PackedVector3Array()
	for index in range(SEGMENTS):
		var angle := TAU * float(index) / SEGMENTS
		var direction := Vector3(cos(angle), 0, sin(angle))
		inner.append(_ground(point + direction * (radius - .085)) - point)
		outer.append(_ground(point + direction * radius) - point)
	for index in range(SEGMENTS):
		var next := (index + 1) % SEGMENTS
		for vertex in [inner[index], outer[index], outer[next], inner[index], outer[next], inner[next]]:
			ring.add_vertex(vertex)
	_warning.global_position = point
	_warning.mesh = ring.commit()
	_warning.show()

func _ground(point: Vector3) -> Vector3:
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.6, point - Vector3.UP * 1.6, 16)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		point.y = hit.position.y
	return point + Vector3.UP * .043

func hide_warning() -> void:
	_warning.hide()

func update_health(value: int) -> void:
	_maximum = maxi(_maximum, value)
	_label.text = "DEMON FOX  %d / %d" % [value, _maximum]

func defeat() -> void:
	_veiled = false
	_telling = false
	_veil_amount = 0.0
	_restore_materials()
	for particles in [_trail, _burst, _dust]:
		particles.emitting = false
		particles.hide()
	_ripple.hide()
	_label.hide()
	audio.death_begin()

func alert() -> void:
	audio.alert()

func hurt() -> void:
	audio.hurt()

func impact(bite: bool) -> void:
	audio.impact(bite)

func land(at: Vector3) -> void:
	audio.land()
	_dust.global_position = at + Vector3.UP * .10 - global_basis.z * .34
	_dust.restart()
	_dust.emitting = true

func prepare_veil(model: Node3D) -> void:
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh.mesh == null:
			continue
		for index in mesh.mesh.get_surface_count():
			var coat := mesh.get_active_material(index) as BaseMaterial3D
			if coat == null:
				continue
			var surface := VeilSurface.new()
			surface.mesh = mesh
			surface.index = index
			surface.original = mesh.get_surface_override_material(index)
			surface.effect = ShaderMaterial.new()
			surface.effect.shader = VEIL_SHADER
			surface.effect.render_priority = -2
			if coat.normal_enabled:
				surface.effect.set_shader_parameter("coat_normal", coat.normal_texture)
				surface.effect.set_shader_parameter("normal_strength", coat.normal_scale)
			surface.effect.set_shader_parameter("coat", coat.albedo_texture)
			surface.effect.set_shader_parameter("coat_color", coat.albedo_color)
			surface.effect.set_shader_parameter("coat_roughness", coat.roughness)
			_veil_surfaces.append(surface)
	_trail = _build_spectral_particles(false)
	_burst = _build_spectral_particles(true)
	_build_ripple()

func _build_spectral_particles(burst: bool) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = burst
	particles.amount = 8 if burst else 6
	particles.lifetime = .28 if burst else .23
	particles.explosiveness = 1.0 if burst else 0.0
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 3, 4))
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3.UP if burst else Vector3(0, .10, -1)
	process_material.spread = 85.0 if burst else 12.0
	process_material.particle_flag_align_y = not burst
	process_material.gravity = Vector3(0, -.8, 0)
	process_material.initial_velocity_min = .75 if burst else .13
	process_material.initial_velocity_max = 2.0 if burst else .64
	process_material.scale_min = .7
	process_material.scale_max = 1.3
	var taper := Curve.new()
	taper.add_point(Vector2(0, .85))
	taper.add_point(Vector2(.20, 1))
	taper.add_point(Vector2(1, .10))
	var taper_texture := CurveTexture.new()
	taper_texture.curve = taper
	process_material.scale_curve = taper_texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color(.87, .13, .22, .72 if burst else .60))
	gradient.set_color(1, Color(.46, .07, .13, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process_material.color_ramp = ramp
	particles.process_material = process_material
	var fleck := SphereMesh.new()
	fleck.radius = .032 if burst else .016
	fleck.height = .064 if burst else .21
	fleck.radial_segments = 4
	fleck.rings = 2
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fleck.material = material
	particles.draw_pass_1 = fleck
	add_child(particles)
	return particles

func _build_ripple() -> void:
	_ripple = MeshInstance3D.new()
	_ripple.top_level = true
	_ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.5, 2.5)
	_ripple.mesh = plane
	var shader := Shader.new()
	shader.code = RIPPLE_SHADER
	_ripple_material = ShaderMaterial.new()
	_ripple_material.shader = shader
	_ripple.material_override = _ripple_material
	_ripple.hide()
	add_child(_ripple)

func _start_ripple() -> void:
	_ripple_time = 0.0
	_ripple.global_position = global_position + Vector3.UP * .21
	_ripple_material.set_shader_parameter("progress", 0.0)
	_ripple.show()

func spectral_burst(point: Vector3) -> void:
	_burst.global_position = point
	_burst.restart()
	_burst.emitting = true

func set_veil(active: bool) -> void:
	_veiled = active
	_telling = false
	_label.hide()
	if active:
		_tell_amount = 0.0
		if not _materials_swapped:
			for surface in _veil_surfaces:
				surface.mesh.set_surface_override_material(surface.index, surface.effect)
			_materials_swapped = true
		audio.veil_started()
	else:
		if not _ripple.visible:
			_start_ripple()
		spectral_burst(global_position + Vector3.UP * .38)
		audio.veil_ended()

func _restore_materials() -> void:
	if not _materials_swapped:
		return
	for surface in _veil_surfaces:
		surface.mesh.set_surface_override_material(surface.index, surface.original)
	_materials_swapped = false

func update_motion(delta: float, movement: Vector3, attack_trail: bool) -> void:
	var speed := movement.length()
	_trail.position = Vector3(0, .37, .83) if attack_trail else Vector3(0, .33, .31)
	_trail.emitting = speed > .4 and (_veiled or attack_trail)
	if _trail.emitting:
		_trail.global_basis = Basis.looking_at(-movement, Vector3.UP)
	if _ripple.visible:
		_ripple_time += delta
		_ripple_material.set_shader_parameter("progress", minf(_ripple_time / RIPPLE_SECONDS, 1.0))
		if _ripple_time >= RIPPLE_SECONDS:
			_ripple.hide()
	if not _materials_swapped:
		return
	if _telling:
		var before := _tell_amount
		_tell_amount = minf(_tell_amount + delta / VEIL_WARNING_SECONDS, 1.0)
		if before < RIPPLE_START / VEIL_WARNING_SECONDS and _tell_amount >= RIPPLE_START / VEIL_WARNING_SECONDS:
			_start_ripple()
	var materializing := _telling and _tell_amount >= .86
	var target_veil := 1.0 if _veiled and not materializing else 0.0
	var duration := .25 if target_veil > 0.0 else .22
	_veil_amount = move_toward(_veil_amount, target_veil, delta / duration)
	if not _veiled and is_zero_approx(_veil_amount):
		_restore_materials()
		_label.show()
		return
	for surface in _veil_surfaces:
		surface.effect.set_shader_parameter("veil", smoothstep(0.0, 1.0, _veil_amount))
		surface.effect.set_shader_parameter("tell", _tell_amount)
		surface.effect.set_shader_parameter("motion", clampf(speed / 2.35, 0.0, 1.0))

func veil_tell() -> void:
	if _telling:
		return
	_telling = true
	audio.veil_warning()