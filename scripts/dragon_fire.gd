extends Node3D

# A bounded stream of glowing billows; the boss owns visibility and damage timing.
const COUNT := 48
var _cloud: MultiMeshInstance3D
var _clock := 0.0

func _ready() -> void:
	_cloud = MultiMeshInstance3D.new()
	var spheres := SphereMesh.new()
	spheres.radius = 1.0
	spheres.height = 2.0
	spheres.radial_segments = 8
	spheres.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.no_depth_test = false
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	spheres.material = material
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = spheres
	instances.instance_count = COUNT
	_cloud.multimesh = instances
	_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_cloud)
	animate(0.0)

func animate(delta: float) -> void:
	_clock += delta
	for index in range(COUNT):
		var phase := fmod(float(index) / COUNT + _clock * 1.8, 1.0)
		var angle := index * 2.39996 + _clock * 2.0
		var width := phase * 0.65
		var center := Vector3(cos(angle) * width, sin(angle) * width * 0.55 - phase * 0.6, -phase * 4.15)
		var size := (0.12 + phase * 0.40) * (0.85 + sin(index * 4.0 + _clock * 15.0) * 0.15)
		_cloud.multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3(size, size, size * 1.5)), center))
		var color := Color(1.0, lerpf(0.85, 0.12, phase), lerpf(0.22, 0.01, phase), (1.0 - phase) * 0.60)
		_cloud.multimesh.set_instance_color(index, color)
