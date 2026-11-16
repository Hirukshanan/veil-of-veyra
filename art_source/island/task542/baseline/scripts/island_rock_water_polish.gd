extends Node3D

# Candidate-only visual refinements. Static physics and approved surfaces are immutable.
const ROCK_SHADER=preload("res://assets/environment/new_island/task3/rock.gdshader")
const FALL_SHADER=preload("res://assets/environment/new_island/task3/waterfall.gdshader")
var added_triangles:=0
var material_regions:=0
var smoothed_surfaces:=0

func rock_material(ground:bool=false,inside:bool=false,portal:bool=false)->ShaderMaterial:
	var m:=ShaderMaterial.new();m.shader=ROCK_SHADER
	m.set_shader_parameter("rock",preload("res://assets/environment/new_island/task3/rock_albedo.png"))
	m.set_shader_parameter("rock_normal",preload("res://assets/environment/new_island/task3/rock_normal.png"))
	m.set_shader_parameter("grass",preload("res://assets/environment/polyhaven/leafy_grass_Diffuse.jpg"))
	m.set_shader_parameter("ground_blend",ground);m.set_shader_parameter("interior",inside);m.set_shader_parameter("portal",portal)
	return m

func populate(landscape:Node3D)->void:
	for region in ["WaterfallMountains","EasternCaves"]:
		for visual in landscape.get_node(region).find_children("*","MeshInstance3D",true,false):
			visual.material_override=rock_material(true)
			# Normals only: vertex positions, faces, indices and collider resources stay exact.
			_smooth_normals(visual);material_regions+=1
	var grotto:MeshInstance3D=landscape.get_node("PlayableGrotto")
	grotto.material_override=rock_material(false,true)
	for light in landscape.get_children():
		if light is OmniLight3D and light.position.distance_to(Vector3(76,3.1,2))<0.1:
			light.light_energy=0.33;light.light_color=Color(0.73,0.69,0.58);light.omni_range=8
	_build_fall_support();_build_fall();_build_foam(landscape)

func _smooth_normals(visual:MeshInstance3D)->void:
	var original:Mesh=visual.mesh
	var importer:=ImporterMesh.new()
	for index in range(original.get_surface_count()):
		var arrays:Array=original.surface_get_arrays(index)
		var positions:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var sums:Dictionary={}
		for i in positions.size():
			var key:Vector3=positions[i].snapped(Vector3.ONE*0.0001)
			sums[key]=sums.get(key,Vector3.ZERO)+normals[i]
		for i in positions.size():
			var normal:Vector3=sums[positions[i].snapped(Vector3.ONE*0.0001)].normalized()
			if normal.dot(normals[i])>0.3:normals[i]=normal
		arrays[Mesh.ARRAY_NORMAL]=normals
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays)
	importer.generate_lods(60.0,25.0,[])
	var result:ArrayMesh=importer.get_mesh()
	assert(result.get_faces()==original.get_faces(),"Task 3 normal pass must preserve all triangle positions/order")
	visual.mesh=result;smoothed_surfaces+=1

func _visual(label:String,s:SurfaceTool,material:Material)->MeshInstance3D:
	s.generate_normals();var mesh:=MeshInstance3D.new();mesh.name=label;mesh.mesh=s.commit();mesh.material_override=material
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;mesh.visibility_range_end=165
	add_child(mesh);added_triangles+=mesh.mesh.get_faces().size()/3
	return mesh

func _triangle(s:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
	for p in [a,b,c]:s.set_uv(Vector2(p.x,p.z));s.add_vertex(p)

func _build_fall_support()->void:
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
	var ledge:=_visual("CascadeLedge",stone,rock_material())
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
