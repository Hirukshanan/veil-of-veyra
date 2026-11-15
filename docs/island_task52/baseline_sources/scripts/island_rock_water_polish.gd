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
	grotto.material_override=rock_material(false,true);_smooth_normals(grotto)
	for light in landscape.get_children():
		if light is OmniLight3D and light.position.distance_to(Vector3(76,3.1,2))<0.1:
			light.light_energy=0.33;light.light_color=Color(0.73,0.69,0.58);light.omni_range=8
	_build_entrance();_build_cave_finish(landscape);_build_fall();_build_foam(landscape)

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

func _arch(side:int,ring:int)->Vector3:
	var angle:float=side*PI/24.0
	if ring==0:
		# Coincides with the existing twelve-sided vault at every second vertex.
		var k:float=side/2.0;var lo:int=floori(k);var hi:int=mini(12,lo+1)
		var a:=Vector3(76+cos(lo*PI/12)*(2.6+sin(lo*3.1)*.1),1.5+sin(lo*PI/12)*(3.8+sin(lo*3.1)*.1),-6)
		var b:=Vector3(76+cos(hi*PI/12)*(2.6+sin(hi*3.1)*.1),1.5+sin(hi*PI/12)*(3.8+sin(hi*3.1)*.1),-6)
		return a.lerp(b,k-lo)
	var radius:float=7.9 if ring==2 else 6.1
	var height:float=5.8 if ring==2 else 5.9
	var rough:float=sin(side*1.73+ring)*.23+sin(side*.91)*.16
	return Vector3(76+cos(angle)*(radius+rough),1.22+sin(angle)*(height+rough),(-.3 if ring==1 else 7.8)+sin(angle*3.0)*.55)

func _build_entrance()->void:
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(2):
		for side in range(24):
			var a:=_arch(side,ring);var b:=_arch(side+1,ring);var c:=_arch(side,ring+1);var d:=_arch(side+1,ring+1)
			_triangle(s,a,b,c);_triangle(s,c,b,d)
	_visual("FittedCaveRockMantle",s,rock_material(false,false,true))

func _fall_point(u:float,t:float)->Vector3:
	var center:float=0.12+sin(t*3.2)*.15
	var width:float=1.16+sin(t*PI)*.20+t*.28+sin(t*19.0)*.09+sin(t*43.0)*.035
	var side:float=u*2.0-1.0
	var y:float=lerpf(5.35,1.64,t)
	var z:float=lerpf(-70.55,-67.72,t)+sin(t*PI)*.29
	return Vector3(center+side*width,y+sin(u*19+t*6)*.10*sin(t*PI)+sin(u*23.0)*.075*(1.0-t),z+sin(u*18+t*11)*.075+side*side*.12)

func _build_cave_finish(landscape:Node3D)->void:
	var s:=SurfaceTool.new();s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(24):
		for col in range(8):
			var corners:Array[Vector3]=[]
			for pair in [Vector2i(col,row),Vector2i(col+1,row),Vector2i(col,row+1),Vector2i(col+1,row+1)]:
				var x:float=73.28+pair.x*5.44/8.0;var z:float=-5.99+pair.y*15.97/24.0
				corners.append(Vector3(x,maxf(1.5,landscape.SURFACE.sample(Vector2(x,z)))+.014,z))
			_triangle(s,corners[0],corners[1],corners[2]);_triangle(s,corners[2],corners[1],corners[3])
	# Close only the tiny visual slit between the rough vault and its old flat end cap.
	for side in range(12):
		var vertices:Array[Vector3]=[]
		for index in [side,side+1]:
			var rough:float=sin(8*2.3+index*3.1)*.1
			vertices.append(Vector3(76+cos(index*PI/12)*(2.6+rough),1.5+sin(index*PI/12)*(3.8+rough),9.98))
		_triangle(s,Vector3(76,1.5,9.98),vertices[0],vertices[1])
	_visual("CaveRockFloorAndEndFinish",s,rock_material(false,true))

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
