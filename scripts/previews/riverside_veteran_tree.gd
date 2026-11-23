extends Node3D

# One fused bole with four incised wounds, two co-dominant stems and terrain-fitted buttresses.
const WOOD := preload("res://assets/environment/polyhaven/island_tree_01/textures/island_tree_01_branches_diff_1k.jpg")
const CROWN := preload("res://assets/environment/new_island/vegetation/refinement/canopy_lod0.res")
const LEAVES := preload("res://assets/environment/new_island/vegetation/refinement/twig_clusters.png")
var bark := SurfaceTool.new()
var heartwood := SurfaceTool.new()
var crowns: Array[Transform3D] = []

func build(land, anchor: Vector3) -> void:
	global_position = anchor
	for s in [bark,heartwood]:
		s.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bole()
	var rng := RandomNumberGenerator.new()
	rng.seed = 92731
	for i in 11:
		var angle := TAU*i/11 + rng.randf_range(-.13,.13)
		var out := Vector3(cos(angle),0,sin(angle))
		var across := Vector3(-out.z,0,out.x)
		var length := rng.randf_range(3.7,6.15)
		var pts: Array[Vector3] = []
		for j in 7:
			var t := j/6.0
			var p := out*(.86+t*length)+across*(sin(t*PI)*sin(angle*3)*.84)
			p.y = land.ground_point(anchor+p).y-anchor.y + 1.46*pow(1-t,5)-.13
			pts.append(p)
		_limb(pts,[.77,.58,.38,.24,.14,.08,.016],8)
	for i in 7:
		var a := i*TAU/7+.24
		var axis := Vector3(cos(a),0,sin(a))
		var side := Vector3(-axis.z,0,axis.x)
		var low := i in [4,5]
		var start := axis*.87 + Vector3.UP*(.05 if low else 3.8+.43*(i%3))
		var tip := axis*(4.1+.6*sin(a)) + Vector3.UP*(7.1+1.3*(i%3)) + side*.68
		var joint := start.lerp(tip,.55)+Vector3.UP*.64-side*.52
		_limb([start,joint,tip],[1.12 if low else .73,.73 if low else .53,.3],13)
		var fork := joint+axis*2.25-side*1.95+Vector3.UP*1.1
		_limb([joint,joint.lerp(fork,.52)+Vector3.UP*.24,fork],[.51,.33,.14],9)
		var basis := Basis(Vector3.UP,a+1.2).scaled(Vector3(1.18,1.1,1.18))
		crowns.append(Transform3D(basis,tip))
		var spray := Basis(Vector3.UP,a-.78).scaled(Vector3(.72,.77,.72))
		crowns.append(Transform3D(spray,fork))
	crowns.append(Transform3D(Basis(Vector3.UP,1.4).scaled(Vector3(1.33,1.53,1.33)),Vector3(-.66,8.3,-.48)))
	for crown in crowns:
		_crown_limbs(crown,rng)
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_texture = WOOD
	bark_mat.vertex_color_use_as_albedo = true
	bark_mat.roughness = .97
	bark_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_finish(bark,bark_mat,"FusedTrunksAndButtresses")
	var raw := ShaderMaterial.new()
	raw.shader = preload("res://scripts/previews/torn_sapwood.gdshader")
	_finish(heartwood,raw,"SplitSapwood")
	var leaf := StandardMaterial3D.new()
	leaf.albedo_texture = LEAVES
	leaf.albedo_color = Color(1.06,1.12,.94)
	leaf.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	leaf.alpha_scissor_threshold = .37
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf.roughness = 1
	_batch(CROWN,leaf,"LeafClusters")
	var body := StaticBody3D.new()
	body.name = "FusedBoleCollision"
	body.collision_layer = 4|8
	body.collision_mask = 0
	add_child(body)
	for origin in [Vector3(0,2.3,0),Vector3(-1.14,1.97,-.6),Vector3(-.62,1.91,1.02)]:
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = 1.49 if origin.x == 0 else .78
		cylinder.height = origin.y*2+.18
		shape.shape = cylinder
		shape.position = origin
		body.add_child(shape)

func _crown_limbs(crown: Transform3D, rng: RandomNumberGenerator) -> void:
	var fork := Vector3(.20,1.74,-.16)
	_limb([crown*Vector3(0,-.035,0),crown*Vector3(.07,.74,.13),crown*fork],
		[.34,.29,.24],9)
	for k in 5:
		var a := TAU*k/5+rng.randf_range(-.28,.28)
		var dir := Vector3(cos(a),0,sin(a))
		var side := Vector3(-dir.z,0,dir.x)
		var joint := fork+dir*1.27+Vector3.UP*rng.randf_range(.86,1.50)
		var twig := joint+dir*1.39+side*.43+Vector3.UP*.88
		_limb([crown*(fork-Vector3.UP*.16),crown*joint,crown*twig,
			crown*(twig+dir*.77+Vector3.UP*.31)],[.23,.16,.067,.016],7)
		_limb([crown*joint,crown*(joint+dir*.54-side*.61+Vector3.UP*.72),
			crown*(joint+dir*.85-side*1.03+Vector3.UP*1.12)],[.12,.065,.012],6)

func _finish(s: SurfaceTool, mat: Material, label: String) -> void:
	s.generate_normals()
	s.index()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = s.commit()
	mesh.material_override = mat
	add_child(mesh)

func _batch(mesh: Mesh, mat: Material, label: String) -> void:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = crowns.size()
	for i in crowns.size():
		batch.set_instance_transform(i,crowns[i])
	var part := MultiMeshInstance3D.new()
	part.name = label
	part.multimesh = batch
	part.material_override = mat
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(part)

func _bole() -> void:
	# The front sector shares the same rings as the bark. Each wound has two
	# raised torn lips and a recessed floor; there is no surface decal.
	var angles := [-PI,-2.78,-2.46,-2.14,-1.82,-1.50,-1.18,-.86,-.63]
	var cut_strips := {}
	for cut in 4:
		var center := -.34+cut*.225
		for offset in [-.099,-.066,-.012,.022,.069,.098]:
			angles.append(center+offset)
		for at in [3,4,5]:
			cut_strips[angles.size()-at] = true
	angles.append_array([.55,.82,1.08,1.4,1.72,2.04,2.36,2.68,PI])
	var heights := [-.25,.24,.58,.85,1.06,1.23,1.43,1.63,1.85,2.10,2.32,2.56,2.79,2.99,3.21,3.44,3.72,4.3,5.35,6.8,8.65,9.7,10.8,11.6]
	for j in heights.size()-1:
		for k in angles.size()-1:
			var y: float = heights[j]
			var outer := k >= 9 and k < 33
			var cut := floori((k-9)/6.0)
			var open := outer and _opening((y+heights[j+1])*.5,cut)>.18
			var wood := open and cut_strips.has(k)
			var s := heartwood if wood else bark
			for idx in [[j,k],[j+1,k],[j+1,k+1],[j,k],[j+1,k+1],[j,k+1]]:
				var h: float = heights[idx[0]]
				var n: int = idx[1]
				var a: float = angles[n]
				var r := 1.72-.091*maxf(h,0)+.53*exp(-maxf(h,0)*1.9)
				var twist := sin(h*.68)*.036+clampf(h-1,0,2.4)*.146
				r += (.082*sin(7*a+h*.41)+.055*sin(13*a-h*.31))*(1+.9*exp(-maxf(h,0)))
				r *= 1.0-.98*smoothstep(7.5,11.6,h)
				if n>=9 and n<33:
					var slot := (n-9)%6
					var g := _opening(h,floori((n-9)/6.0))
					var mid_angle: float = -.34+floori((n-9)/6.0)*.225
					if slot in [1,2,3,4]:
						a = lerpf(mid_angle,a,.055+.945*g)
					r += g*float([0,.082,-.167,-.214,.064,0][slot])
					a += .014*sin(h*14.4+floori((n-9)/6.0)*2.1)*g
				var v := Vector3(sin(a+twist)*r-h*.065,h,cos(a+twist)*r-h*h*.008)
				var tint := Color("e9b87f").lerp(Color("a47751"),.4+.32*sin(h*19+n)) if wood else Color(.76,.78,.69)
				s.set_color(tint)
				s.set_uv(Vector2((a+PI)*.59,h*.34))
				s.add_vertex(v)

func _opening(h: float, cut: int) -> float:
	var base := .95+.14*absf(cut-1.3)
	var top := 3.18+.14*sin(cut*2.2)
	return smoothstep(base,base+.4,h)*(1-smoothstep(top-.38,top,h))

func _limb(pts: Array, radii: Array, sides: int) -> void:
	var previous: Array[Vector3] = []
	var across := Vector3.RIGHT
	var distance := 0.0
	for i in pts.size():
		var tangent: Vector3 = (pts[mini(i+1,pts.size()-1)]-pts[maxi(0,i-1)]).normalized()
		if i == 0 and absf(tangent.dot(across))>.85:
			across = Vector3.FORWARD
		across = (across-tangent*tangent.dot(across)).normalized()
		var other := tangent.cross(across)
		var row: Array[Vector3] = []
		for k in sides+1:
			var a := TAU*k/sides
			row.append(pts[i]+(across*cos(a)+other*sin(a))*float(radii[i])*(1+.093*sin(3*a+i*.44)))
		if i>0:
			var next := distance + (pts[i] as Vector3).distance_to(pts[i-1])
			for k in sides:
				for c in [[previous[k],k,distance],[row[k],k,next],[row[k+1],k+1,next],[previous[k],k,distance],[row[k+1],k+1,next],[previous[k+1],k+1,distance]]:
					bark.set_uv(Vector2(float(c[1])/sides,c[2]*.36))
					bark.set_color(Color(.84,.83,.73))
					bark.add_vertex(c[0])
			distance = next
		previous = row
