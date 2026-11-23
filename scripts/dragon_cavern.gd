extends Node3D

const REVEAL_LAYER := 1 << 19
const AXIS := 2.7
const EYE := Vector3(AXIS,37.9,80.6)
var eye: Node3D


static func passage_stone(rock: StandardMaterial3D, tint: Color, cavern_surface := true) -> ShaderMaterial:
	var skin := ShaderMaterial.new()
	skin.shader = preload("res://assets/environment/buried_shrine/masonry.gdshader")
	skin.set_shader_parameter("rock",rock.albedo_texture)
	skin.set_shader_parameter("normal_tex",rock.normal_texture)
	skin.set_shader_parameter("tint",tint)
	skin.set_shader_parameter("passage_shadow",2 if cavern_surface else 1)
	return skin

func build(shrine: Node3D, rock: StandardMaterial3D, atlas: Texture2D) -> void:
	var lining := passage_stone(rock,Color(.31,.32,.35))
	var masonry := passage_stone(rock,Color(.41,.37,.32))
	for i in 7:
		var z := 47.2+i*.78
		_block(shrine,Vector3(AXIS,33.84,z),Vector3(4.55,.32,.83),masonry)
		for side in [-1,1]:
			_block(shrine,Vector3(AXIS+side*2.30,36.2,z),Vector3(.64,4.4,.79),masonry)
		_block(shrine,Vector3(AXIS,38.57,z),Vector3(5.2,.65,.79),masonry)
	# One irregular collision shell expands from the masonry throat into the cavern.
	var positions := [51.7,54.1,58.5,64.,70.,77.5,83.6,86.]
	var widths := [2.5,3.2,8.,14.,16.,14.5,10.,2.]
	var heights := [4.7,6.3,11.8,17.,19.4,17.6,12.4,5.]
	var depths := [.3,1.7,5.7,11.4,15.7,15.2,11.3,2.]
	var rings: Array[PackedVector3Array] = []
	const RING_SAMPLES := 36
	for i in positions.size():
		var ring := PackedVector3Array()
		for sample in RING_SAMPLES:
			var angle := TAU*sample/RING_SAMPLES
			var rough := 1.+.055*sin(i*2.7+angle*7.)+.055*sin(angle*13.+i*.83)
			var y: float = sin(angle)
			var height: float = heights[i] if y>=0 else depths[i]
			ring.append(Vector3(AXIS+cos(angle)*widths[i]*rough,34.+y*height*rough,positions[i]+sin(angle*3.+i)*.62))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(1,rings.size()):
		for i in RING_SAMPLES:
			var j := (i+1)%RING_SAMPLES
			for point in [rings[row-1][i],rings[row][j],rings[row][i],rings[row-1][i],rings[row-1][j],rings[row][j]]:
				surface.add_vertex(point)
	surface.index()
	surface.generate_normals()
	var hollow := MeshInstance3D.new()
	hollow.mesh = surface.commit()
	hollow.material_override = lining
	add_child(hollow)
	hollow.create_trimesh_collision()
	var shell_body := hollow.get_child(0) as StaticBody3D
	shell_body.collision_layer = 29
	shell_body.collision_mask = 0
	shell_body.get_child(0).shape.backface_collision = true
	# Close the far rock silhouette behind the eye, including the lower chasm.
	var recess := StandardMaterial3D.new()
	recess.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	recess.albedo_color = Color(.020,.022,.026)
	_block(shrine,Vector3(AXIS,36.5,85.65),Vector3(25,27,.86),recess)
	# A fallen causeway and stone parapets carry the player over the chasm.
	_block(shrine,Vector3(AXIS,33.71,66.5),Vector3(4.25,.58,30.2),masonry)
	for i in 19:
		var z := 52.2+i*1.52
		for side in [-1,1]:
			var h := 1.22 if i%4 else 1.55
			_block(shrine,Vector3(AXIS+side*2.08,34+h*.5,z),Vector3(.44,h,1.53),lining)
	_block(shrine,Vector3(AXIS,34.84,81.4),Vector3(4.7,1.68,.88),lining)
	for point in [Vector3(3.55,36.95,49.4),Vector3(.6,39.2,55.1),Vector3(-6.5,43.1,62.6),Vector3(11,44.8,69.4)]:
		var lamp := OmniLight3D.new()
		add_child(lamp)
		lamp.position = point
		lamp.omni_range = 10. if point.z<58. else 15.
		lamp.light_color = Color(.47,.56,.70)
		lamp.light_energy = .84 if point.z<58. else .62
	_add_depth(rock)
	eye = preload("res://scripts/dragon_eye_socket.gd").new()
	add_child(eye)
	eye.position = EYE
	eye.scale = Vector3.ONE*.66
	eye.build(atlas,rock.albedo_texture)
	for feature in eye.get_children():
		feature.layers = REVEAL_LAYER

func _block(shrine: Node3D, at: Vector3, size: Vector3, material: Material) -> void:
	var box := BoxMesh.new()
	box.size = size
	var piece := MeshInstance3D.new()
	piece.mesh = box
	piece.material_override = material
	add_child(piece)
	piece.position = at
	shrine.solid(at,size,self)

func close_bridge_parapet_ends(shrine: Node3D, rock: StandardMaterial3D) -> void:
	var lining := passage_stone(rock,Color(.31,.32,.35))
	# Join the last stones to the end wall, using the same visible/solid builder.
	for side in [-1, 1]:
		_block(shrine, Vector3(AXIS + side*2.08, 34.61, 80.64), Vector3(.44, 1.22, .70), lining)

# A few layered rock curtains give scale without filling the walkable route.
func _add_depth(source: StandardMaterial3D) -> void:
	var stone := passage_stone(source,Color(.28,.29,.33))
	var work := SurfaceTool.new()
	work.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 505
	for side in [-1,1]:
		for i in 9:
			var z := 56.3+i*2.83
			var x: float = AXIS+side*rng.randf_range(4.2,minf(9.,4.4+i*.77))
			var height := rng.randf_range(3.4,10.8)
			var crown := Vector3(x,46.6+minf(i*.88,6.),z)
			var span := rng.randf_range(.45,1.24)
			var tip := crown-Vector3(side*.6,height,.14)
			for band in 5:
				var t := band/5.
				var n := (band+1)/5.
				for segment in 8:
					var a := TAU*segment/8.
					var b := TAU*(segment+1)/8.
					for uv in [Vector2(a,t),Vector2(b,t),Vector2(b,n),Vector2(a,t),Vector2(b,n),Vector2(a,n)]:
						var radius := span*(.09+.91*pow(1.-uv.y,.76))*(1.+.17*sin(5.*uv.x+i))
						work.add_vertex(crown.lerp(tip,uv.y)+Vector3(cos(uv.x)*radius,0,sin(uv.x)*radius))
	work.index()
	work.generate_normals()
	var curtains := MeshInstance3D.new()
	curtains.mesh = work.commit()
	curtains.material_override = stone
	curtains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(curtains)

func sample(time: float) -> void:
	eye.sample(time)
