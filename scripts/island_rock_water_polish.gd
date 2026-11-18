extends Node3D

# Candidate rock surfaces and waterfall detailing share the existing static collision layers.
const ROCK_SHADER=preload("res://assets/environment/new_island/task3/rock.gdshader")
const FALL_SHADER=preload("res://assets/environment/new_island/task3/waterfall.gdshader")
var added_triangles:=0

func rock_material(ground:bool=false,inside:bool=false,portal:bool=false)->ShaderMaterial:
	var m:=ShaderMaterial.new();m.shader=ROCK_SHADER
	m.set_shader_parameter("rock",preload("res://assets/environment/new_island/task3/rock_albedo.png"))
	m.set_shader_parameter("rock_normal",preload("res://assets/environment/new_island/task3/rock_normal.png"))
	m.set_shader_parameter("grass",preload("res://assets/environment/polyhaven/leafy_grass_Diffuse.jpg"))
	m.set_shader_parameter("ground_blend",ground);m.set_shader_parameter("interior",inside);m.set_shader_parameter("portal",portal)
	return m

func populate(landscape:Node3D)->void:
	var grotto:MeshInstance3D=landscape.get_node("PlayableGrotto")
	var ridge_material := rock_material(false, true)
	ridge_material.shader = preload("res://assets/environment/new_island/task542/rock_transition.gdshader")
	ridge_material.set_shader_parameter("ridge_surface", true)
	ridge_material.set_shader_parameter("sand", preload("res://assets/environment/polyhaven/coast_sand_01_Diffuse.jpg"))
	grotto.material_override = ridge_material
	for light in landscape.get_children():
		if light is OmniLight3D and light.position.distance_to(Vector3(76,3.1,2))<0.1:
			light.light_energy=0.33;light.light_color=Color(0.73,0.69,0.58);light.omni_range=8
	var ground: MeshInstance3D = landscape.get_node("ConnectedTerrain")
	_build_fall_support(ground.material_override)
	_build_fall()
	_build_foam(landscape)

func _visual(label:String,s:SurfaceTool,material:Material)->MeshInstance3D:
	s.generate_normals();var mesh:=MeshInstance3D.new();mesh.name=label;mesh.mesh=s.commit();mesh.material_override=material
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;mesh.visibility_range_end=165
	add_child(mesh);added_triangles+=mesh.mesh.get_faces().size()/3
	return mesh

func _triangle(s:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
	for p in [a,b,c]:s.set_uv(Vector2(p.x,p.z));s.add_vertex(p)

func _build_fall_support(material: Material) -> void:
	var stone:=SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var last:Array[Vector3]=[]
	for row in range(16):
		var t:=row/15.0
		var ring:Array[Vector3]=[]
		for side in range(32):
			var angle:=TAU*side/32
			var width:=lerpf(5.1,2.8,t)+.26*sin(angle*5+t*3)
			var nose:=lerpf(-67.85,-70.63,t)-.2*sin(t*PI)
			var z:=nose-2.7+2.7*cos(angle)
			var x:=sin(angle)*width
			var y:=lerpf(.05,8.94,t)+.24*sin(angle*3)*t
			ring.append(Vector3(x,y,z))
		if row>0:
			for i in range(32):
				var j:=(i+1)%32
				_triangle(stone,last[i],ring[i],last[j])
				_triangle(stone,last[j],ring[i],ring[j])
		last=ring
	for i in range(32):
		_triangle(stone,last[i],Vector3(0,9,-73.4),last[(i+1)%32])
	var ledge:=_visual("CascadeLedge",stone,material)
	ledge.create_trimesh_collision()
	var body:StaticBody3D=ledge.get_child(0)
	body.collision_layer=1|4|8
	body.get_child(0).shape.backface_collision=true

func _fall_point(u:float,t:float)->Vector3:
	var center:float=0.12+sin(t*3.2)*.15
	var width:float=1.16+sin(t*PI)*.20+t*.28+sin(t*19.0)*.09+sin(t*43.0)*.035
	var side:float=u*2.0-1.0
	var y:float=lerpf(9.02,1.59,t)
	var z:float=lerpf(-70.55,-67.72,t)+sin(t*PI)*.29
	var point:=Vector3(center+side*width,y+sin(u*19+t*6)*.10*sin(t*PI)+sin(u*23.0)*.075*(1.0-t),z+sin(u*18+t*11)*.075+side*side*.12)

	return point

func _build_fall()->void:
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_spillway(s)
	for row in range(28):
		for col in range(12):
			for pair in [Vector2i(col,row),Vector2i(col+1,row),Vector2i(col,row+1),Vector2i(col+1,row),Vector2i(col+1,row+1),Vector2i(col,row+1)]:
				var u:float=pair.x/12.0;var t:float=pair.y/28.0
				# Three turbulent filaments separate slightly below the common rocky crest.
				var band:int=col/4;var local:float=(pair.x-band*4)/4.0
				var gap:float=sin(t*PI*.88)*.020
				var split_u:float=(band+lerpf(gap,1.0-gap,local))/3.0
				s.set_uv(Vector2(u,t));s.add_vertex(_fall_point(split_u,t))
	var m:=ShaderMaterial.new();m.shader=FALL_SHADER
	_visual("CliffFollowingWaterfall",s,m)

func _add_spillway(surface: SurfaceTool) -> void:
	# Use the same flowing surface and join the existing curtain at its first row.
	for column in range(12):
		for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
			var u: float = (column + corner.x) / 12.0
			var lip := _fall_point(u, 0.0)
			var source := Vector3(0.12 + (u * 2.0 - 1.0) * 0.72, 9.24, -73.4)
			surface.set_uv(Vector2(u, 0.0 if corner.y == 1 else -0.19))
			surface.add_vertex(lip if corner.y == 1 else source)

func _build_foam(landscape:Node3D)->void:
	# Duplicate only existing river-top faces; original water geometry is never edited.
	var faces:PackedVector3Array=landscape.get_node("FlowingRiver").mesh.get_faces()
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,faces.size(),3):
		var center:Vector3=(faces[i]+faces[i+1]+faces[i+2])/3.0
		if center.z < -68 or center.z > -63:continue
		_triangle(s,faces[i]+Vector3.UP*.014,faces[i+1]+Vector3.UP*.014,faces[i+2]+Vector3.UP*.014)
	var m:=ShaderMaterial.new();m.shader=FALL_SHADER;m.set_shader_parameter("foam",true)
	_visual("WaterfallImpactFoam",s,m)
