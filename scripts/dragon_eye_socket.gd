extends Node3D

# Anatomical eye aperture in the approved texture's source coordinates. The
# texture follows a convex lens bounded by physical upper and lower eyelids.
const CENTER := Vector2(.548,.535)
const STEP := 56
var eye: MeshInstance3D
var lens: ShaderMaterial
var scales: ShaderMaterial

func build(atlas: Texture2D, mineral: Texture2D) -> void:
	lens = ShaderMaterial.new()
	lens.shader = preload("res://assets/environment/buried_shrine/cavern_eye.gdshader")
	lens.set_shader_parameter("atlas",atlas)
	scales = ShaderMaterial.new()
	scales.shader = preload("res://assets/environment/buried_shrine/dragon_scales.gdshader")
	scales.set_shader_parameter("mineral",mineral)
	var shape := SurfaceTool.new()
	shape.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in STEP:
		var a := TAU*i/STEP
		var b := TAU*(i+1)/STEP
		for band in 8:
			var outer := (band+1)/8.
			var inner := band/8.
			for point in [Vector2(a,inner),Vector2(a,outer),Vector2(b,outer),Vector2(a,inner),Vector2(b,outer),Vector2(b,inner)]:
				var uv := _aperture(point.x,point.y)
				shape.set_uv(uv)
				shape.set_color(Color(1.-point.y,0,0))
				shape.add_vertex(_point(uv,-.48*(1.-point.y*point.y)))
	eye = _finish_mesh(shape,lens)
	var face := SurfaceTool.new()
	face.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in STEP:
		var a := TAU*i/STEP
		var b := TAU*(i+1)/STEP
		for band in 6:
			for v in [Vector2(a,band),Vector2(a,band+1),Vector2(b,band+1),Vector2(a,band),Vector2(b,band+1),Vector2(b,band)]:
				var ring := int(v.y)
				var radius: float = [1.,1.045,1.12,1.29,1.54,1.9,2.26][ring]
				var depth: float = [-.10,-.41,-.52,-.47,-.33,.22,1.13][ring]
				var brow := maxf(0.,-sin(v.x))*sin(float(ring)*PI/6.)*.49
				var uv := _aperture(v.x,radius)
				var edge_weight: float = [1.,.96,.61,.24,.0,.0,.0][ring]
				face.set_color(Color(edge_weight,0. if sin(v.x)<0 else 1.,.5+.24*sin(v.x*7.+ring),1.-smoothstep(3.7,6.,float(ring))))
				face.add_vertex(_point(uv,depth-brow))
	# Individual overlapping scutes add relief beyond the lid folds in one mesh.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2505
	for row in 4:
		for column in 19:
			var a := TAU*(column+.48*(row%2))/19.
			var uv := _aperture(a,1.33+row*.19)
			var depth := -.55+row*.29+maxf(0.,sin(a))*.19
			var origin := _point(uv,depth)
			var spread := rng.randf_range(.48,.80)+row*.057
			var tilt := .36*sin(a)
			var tip := origin+Vector3(spread*.29,-.14,-rng.randf_range(.12,.32))
			for side in 6:
				var t := TAU*side/6.
				var n := TAU*(side+1)/6.
				for pt in [tip,origin+Vector3(cos(t)*spread,sin(t)*spread*.6,cos(t)*tilt),origin+Vector3(cos(n)*spread,sin(n)*spread*.6,cos(n)*tilt)]:
					face.set_color(Color(0,.5,rng.randf_range(.36,.68),1.-smoothstep(1.4,4.2,float(row))))
					face.add_vertex(pt)
	_finish_mesh(face,scales)
	hide()

func _aperture(angle: float, radius: float) -> Vector2:
	var x := cos(angle)
	var y := sin(angle)
	return CENTER+Vector2(.325*x, .251*y-.10*x)*radius

func _point(uv: Vector2, depth: float) -> Vector3:
	return Vector3(-(uv.x-CENTER.x)*13.6,-(uv.y-CENTER.y)*7.65,depth)

func _finish_mesh(surface: SurfaceTool, material: Material) -> MeshInstance3D:
	surface.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = surface.commit()
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(visual)
	return visual

func sample(time: float) -> void:
	visible = time>=14.06 and time<17.3
	if not visible: return
	var reveal := smoothstep(14.18,15.72,time)
	var opening := smoothstep(14.22,15.58,time)
	scales.set_shader_parameter("relief_light",reveal)
	scales.set_shader_parameter("lid_open",opening)
	lens.set_shader_parameter("frame_index",clampi(int(floor((time-14.22)/.264)),0,5))
	lens.set_shader_parameter("exposure",.14*smoothstep(14.06,14.22,time)+.86*smoothstep(14.22,15.12,time))
