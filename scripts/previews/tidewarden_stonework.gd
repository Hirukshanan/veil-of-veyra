extends RefCounted

const MATERIALS := preload("res://scripts/environment_materials.gd")
const RIM := [Vector2(-.74,-1), Vector2(.72,-1), Vector2(1,-.70), Vector2(1,.71),
	Vector2(.74,1), Vector2(-.72,1), Vector2(-1,.70), Vector2(-1,-.72)]
const STONE_COLORS := [Color("86a563"), Color("92b8d7"), Color("dbaf7c")]
const TRIM_COLORS := [Color("556d43"), Color("587790"), Color("9b6d3e")]
const MAGIC := [Color("a5d864"), Color("58cfeb"), Color("efa451")]
const HEIGHTS := [2.25,3.25,2.79]

var stone: Array[StandardMaterial3D] = []
var trim: Array[StandardMaterial3D] = []
var bronze: StandardMaterial3D
var shadow_stone: StandardMaterial3D
var bark: StandardMaterial3D

func _init() -> void:
	for color in STONE_COLORS:
		stone.append(_stone(color,.63,.14))
	for color in TRIM_COLORS:
		trim.append(_stone(color,.74,.095))
	bronze = _flat(Color("8e6137"), .51)
	bronze.metallic = .57
	shadow_stone = _flat(Color("262d29"), .95)
	bark = MATERIALS.surface("forest_ground_04",.87,Color("69543b"))

func build_pillar(pillar: Node3D, index: int) -> Dictionary:
	# Profiles are height, half-width and half-depth. Broader courses are solid bases
	# and crowns. Narrower courses shape each surviving shaft and its bevels.
	var profiles: Array
	match index:
		0:
			profiles = [Vector3(-.14,.71,.56),Vector3(.08,.73,.58),Vector3(.15,.67,.52),
				Vector3(.26,.55,.45),Vector3(.36,.52,.43),Vector3(.74,.56,.44),
				Vector3(1.35,.51,.405),Vector3(1.76,.42,.35),Vector3(2.11,.30,.27),
				Vector3(2.25,.17,.18)]
		1:
			profiles = [Vector3(-.12,.71,.60),Vector3(.08,.74,.62),Vector3(.16,.66,.53),
				Vector3(.27,.64,.51),Vector3(.34,.49,.38),Vector3(2.36,.49,.38),
				Vector3(2.44,.55,.43),Vector3(2.55,.62,.50),Vector3(2.68,.63,.49),
				Vector3(2.81,.54,.43),Vector3(3.19,.43,.37),Vector3(3.25,.28,.25)]
		_:
			profiles = [Vector3(-.12,.82,.58),Vector3(.08,.82,.58),Vector3(.16,.72,.55),
				Vector3(.27,.66,.49),Vector3(.38,.64,.45),Vector3(.67,.62,.44),
				Vector3(1.72,.56,.43),Vector3(1.93,.49,.40),Vector3(2.09,.61,.46),
				Vector3(2.23,.67,.49),Vector3(2.40,.55,.44),Vector3(2.61,.38,.30),
				Vector3(2.79,.20,.22)]
	_mesh(pillar,_profile(profiles,index+101),stone[index])
	_trim_courses(pillar,index)
	var y: float = [1.16,1.61,1.50][index]
	var face: float = [.46,.42,.47][index]
	var center := Vector3(0,y,face)
	var shape := _socket_outline(index)
	var lit := _flat(MAGIC[index].darkened(.52), .42)
	lit.metallic = .29
	lit.emission_enabled = true
	lit.emission = MAGIC[index].darkened(.25)
	lit.emission_energy_multiplier = .05
	_mesh(pillar,_inset(shape,1.15,.81,-.015,.074),trim[index],center)
	_mesh(pillar,_inset(shape,.86,.70,.054,.083),bronze if index == 2 else stone[index],center)
	_mesh(pillar,_jewel(shape,.68,.018,.038),shadow_stone,center)
	_mesh(pillar,_inset(shape,.74,.64,.074,.078),lit,center)
	var insert := _mesh(pillar,_jewel(shape,.60,.008,.064),lit,center+Vector3.BACK*.04)
	insert.name = "SealFragmentInlay"
	_engrave(pillar,index,face,center)
	_add_body(pillar,Vector3(0,HEIGHTS[index]*.49,0),Vector3([1.07,1.02,1.24][index],
		HEIGHTS[index]*.98,[.91,.84,.95][index]))
	return {"insert":insert,"glow":lit}

func build_beacon(parent: Node3D, center: Vector3, facing: float) -> Dictionary:
	var monument := Node3D.new()
	monument.name = "TidewardenBeacon"
	monument.position = center
	monument.rotation.y = facing
	parent.add_child(monument)
	# The lantern-shaped head is supported by a continuous buttressed stone plinth.
	var footing := [Vector3(-.17,1.24,.95),Vector3(.095,1.24,.95),Vector3(.18,1.13,.84),
		Vector3(.25,1.04,.77),Vector3(.38,.96,.72),Vector3(.49,.81,.59),
		Vector3(.66,.57,.46),Vector3(1.11,.49,.39),Vector3(1.25,.56,.43),
		Vector3(1.33,.66,.50),Vector3(1.42,.64,.47),Vector3(2.11,.56,.44),
		Vector3(2.22,.66,.49),Vector3(2.33,.71,.53),Vector3(2.44,.59,.45),
		Vector3(2.59,.36,.37),Vector3(2.69,.19,.20)]
	_mesh(monument,_profile(footing,71),_stone(Color("b7aa89"),.71,.14))
	_mesh(monument,_profile([Vector3(.235,1.06,.789),Vector3(.29,1.04,.778),Vector3(.34,.985,.752)],42),trim[2])
	for side in [-1.0,1.0]:
		var buttress := _mesh(monument,_profile([Vector3(.11,.27,.57),Vector3(.36,.26,.54),
			Vector3(.54,.20,.41),Vector3(1.16,.13,.26),Vector3(1.35,.095,.19)],82),trim[2],
			Vector3(side*.74,0,.025))
		buttress.rotation.y = side*.12
	var crest := _socket_outline(2)
	var face := Vector3(0,1.76,.465)
	_mesh(monument,_inset(crest,1.2,.93,-.025,.075),trim[2],face)
	_mesh(monument,_inset(crest,.96,.71,.057,.106),bronze,face)
	_mesh(monument,_jewel(crest,.72,.034,.051),shadow_stone,face)
	var light := _flat(Color("95744c"),.33)
	light.emission_enabled = true
	light.emission = Color("c49655")
	light.emission_energy_multiplier = .025
	var luminous := _mesh(monument,_inset(crest,.73,.64,.064,.078),light,face)
	var lens := _mesh(monument,_jewel(crest,.39,.07,.145),light,face)
	lens.name = "BeaconLens"
	var rays: Array = []
	for index in 8:
		var ray := Vector2.from_angle(index*TAU/8.0)
		var center_ray := Vector2(0,1.76)
		rays.append([center_ray+ray*.385,center_ray+ray*(.49 if index%2 == 0 else .44)])
	_mesh(monument,_lines(rays,.029,.513),bronze)
	_mesh(monument,_lines(rays,.012,.516),light)
	for side in [-1,1]:
		var relief := [[Vector2(side*.18,.83),Vector2(side*.34,.88),Vector2(side*.43,1.09)],
			[Vector2(side*.26,2.35),Vector2(side*.37,2.31),Vector2(side*.46,2.21)]]
		_mesh(monument,_lines(relief,.018,.531),bronze)
	_add_body(monument,Vector3(0,.36,0),Vector3(2.34,.80,1.78))
	_add_body(monument,Vector3(0,1.67,0),Vector3(1.24,1.9,.91))
	return {"mesh":luminous,"light":light}

func _trim_courses(pillar: Node3D, index: int) -> void:
	var profiles: Array
	match index:
		0:
			profiles = [Vector3(.10,.715,.561),Vector3(.145,.69,.552),Vector3(.205,.633,.51)]
		1:
			profiles = [Vector3(2.47,.58,.456),Vector3(2.52,.61,.494),Vector3(2.575,.63,.506),Vector3(2.62,.637,.503)]
		_:
			profiles = [Vector3(2.10,.624,.476),Vector3(2.16,.657,.501),Vector3(2.225,.68,.506),Vector3(2.27,.645,.495)]
	_mesh(pillar,_profile(profiles,65+index),trim[index])
	# Cored pilasters and retaining roots give the shafts different side silhouettes.
	for side in [-1.0,1.0]:
		var at := Vector3(side*[.39,.43,.49][index],0,.07)
		match index:
			0:
				var path := [at+Vector3(side*.23,.05,.58),at+Vector3(.01,.20,.31),
					at+Vector3(-side*.16,.50,.19),at+Vector3(-side*.08,.82,.13),
					at+Vector3(-side*.15,1.02,.06)]
				_mesh(pillar,_vine(path,.091),bark)
			1:
				_mesh(pillar,_profile([Vector3(.24,.16,.32),Vector3(.36,.16,.32),
					Vector3(2.43,.105,.29),Vector3(2.58,.155,.35)],25),trim[index],at)
			_:
				_mesh(pillar,_profile([Vector3(.11,.24,.43),Vector3(.31,.235,.40),
					Vector3(.52,.19,.34),Vector3(1.14,.11,.22)],31),trim[index],at)

func _engrave(pillar: Node3D, index: int, face: float, center: Vector3) -> void:
	var lines: Array = []
	var z: float
	match index:
		0:
			for side in [-1.0,1.0]:
				lines.append([Vector2(side*.10,.39),Vector2(side*.27,.53),Vector2(side*.36,.70),
					Vector2(side*.29,1.02),Vector2(side*.35,1.31),Vector2(side*.25,1.58)])
				lines.append([Vector2(side*.29,.91),Vector2(side*.40,1.07),Vector2(side*.41,1.22)])
				lines.append([Vector2(side*.27,.53),Vector2(side*.41,.57),Vector2(side*.43,.69)])
			z = face+.009
		1:
			for band in [.66,.81,2.13,2.26]:
				var wave: Array[Vector2] = []
				for step in 13:
					var u := float(step)/12.0
					wave.append(Vector2(-.40+.80*u,band+.056*sin(u*TAU*1.5)))
				lines.append(wave)
			z = face+.012
		_:
			for side in [-1.0,1.0]:
				lines.append([Vector2(side*.14,.65),Vector2(side*.36,.78),Vector2(side*.47,.99),
					Vector2(side*.48,1.55),Vector2(side*.39,1.77)])
			for ray in 7:
				var angle := (float(ray)/6.0)*PI
				var dir := Vector2.from_angle(angle)
				var sun := Vector2(0,1.965)
				lines.append([sun+dir*.14,sun+dir*.23])
			z = face+.013
	_mesh(pillar,_lines(lines,.032,z-.008),shadow_stone)
	_mesh(pillar,_lines(lines,.015,z+.003),bronze if index == 2 else trim[index])
	# A shallow center petal identifies the fragment even before restoration.
	if index == 0:
		_mesh(pillar,_jewel(_socket_outline(0),.22,.0,.03),trim[index],center+Vector3(0,.63,-.055))
	elif index == 2:
		_mesh(pillar,_jewel(_socket_outline(2),.22,.0,.026),bronze,center+Vector3(0,.44,-.02))

func _socket_outline(index: int) -> PackedVector2Array:
	match index:
		0: # A pointed leaf with an asymmetrical lower fork.
			return PackedVector2Array([Vector2(0,.42),Vector2(.225,.20),Vector2(.252,-.055),
				Vector2(.12,-.216),Vector2(.018,-.34),Vector2(-.158,-.226),Vector2(-.255,-.061),Vector2(-.20,.18)])
		1: # A rounded, scalloped tide medallion.
			var outline := PackedVector2Array()
			for i in 16:
				var angle := PI*.5-float(i)*TAU/16.0
				var scallop := 1.0 + (.038 if i%2 == 0 else -.03)
				outline.append(Vector2(cos(angle)*.28,sin(angle)*.295)*scallop)
			return outline
		_: # A broad chamfered sun key.
			return PackedVector2Array([Vector2(-.13,.32),Vector2(.13,.32),Vector2(.30,.12),
				Vector2(.30,-.11),Vector2(.13,-.30),Vector2(-.13,-.30),Vector2(-.30,-.11),Vector2(-.30,.12)])

func _profile(sections: Array, seed: int) -> ArrayMesh:
	var s := _surface()
	var rows: Array[PackedVector3Array] = []
	for tier in sections.size():
		var profile: Vector3 = sections[tier]
		var ring := PackedVector3Array()
		for corner in RIM.size():
			var p: Vector2 = RIM[corner]
			var irregular := sin(float(corner*13+tier*3+seed))*.018
			ring.append(Vector3(p.x*(profile.y+irregular),profile.x+(irregular if tier > 0 else 0),
				p.y*(profile.z+irregular)))
		rows.append(ring)
	for i in RIM.size():
		var next := (i+1)%RIM.size()
		_triangle(s,Vector3.UP*sections[0].x,rows[0][next],rows[0][i])
		for step in range(1,rows.size()):
			_quad(s,rows[step-1][i],rows[step-1][next],rows[step][next],rows[step][i])
		_triangle(s,Vector3.UP*sections[-1].x,rows[-1][i],rows[-1][next])
	s.generate_normals()
	s.index()
	return s.commit()

func _inset(outline: PackedVector2Array, outer: float, inner: float, lip: float, rim: float) -> ArrayMesh:
	var s := _surface()
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i+1)%outline.size()]
		_quad(s,Vector3(a.x,a.y,0)*outer+Vector3.BACK*lip,Vector3(b.x,b.y,0)*outer+Vector3.BACK*lip,
			Vector3(b.x,b.y,0)*inner+Vector3.BACK*rim,Vector3(a.x,a.y,0)*inner+Vector3.BACK*rim)
	s.generate_normals()
	return s.commit()

func _jewel(outline: PackedVector2Array, scale: float, edge: float, tip: float) -> ArrayMesh:
	var s := _surface()
	for i in outline.size():
		var a := outline[i]*scale
		var b := outline[(i+1)%outline.size()]*scale
		_triangle(s,Vector3(0,.027,tip),Vector3(a.x,a.y,edge),Vector3(b.x,b.y,edge))
	s.generate_normals()
	return s.commit()

func _lines(paths: Array, width: float, z: float) -> ArrayMesh:
	var s := _surface()
	for path in paths:
		for i in range(1,path.size()):
			var a: Vector2 = path[i-1]
			var b: Vector2 = path[i]
			var normal := (b-a).orthogonal().normalized()*width*.5
			_quad(s,Vector3(a.x-normal.x,a.y-normal.y,z),Vector3(b.x-normal.x,b.y-normal.y,z),
				Vector3(b.x+normal.x,b.y+normal.y,z),Vector3(a.x+normal.x,a.y+normal.y,z))
	s.generate_normals()
	return s.commit()

func _vine(path: Array, radius: float) -> ArrayMesh:
	var s := _surface()
	for segment in range(1,path.size()):
		var a: Vector3 = path[segment-1]
		var b: Vector3 = path[segment]
		var tangent := (b-a).normalized()
		var side := tangent.cross(Vector3.FORWARD).normalized()
		var up := side.cross(tangent)
		var ra := radius*(1.0-.76*float(segment-1)/(path.size()-1))
		var rb := radius*(1.0-.76*float(segment)/(path.size()-1))
		for i in 6:
			var p := TAU*i/6
			var q := TAU*(i+1)/6
			var u := side*cos(p)+up*sin(p)
			var v := side*cos(q)+up*sin(q)
			_quad(s,a+u*ra,a+v*ra,b+v*rb,b+u*rb)
	s.generate_normals()
	return s.commit()

func _surface() -> SurfaceTool:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	return s

func _triangle(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	s.add_vertex(a)
	s.add_vertex(b)
	s.add_vertex(c)

func _quad(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(s,a,b,c)
	_triangle(s,a,c,d)

func _stone(tint: Color, scale: float, bounce: float) -> StandardMaterial3D:
	var mat := MATERIALS.surface("rocky_terrain_02",scale,tint)
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	# Lift the stone's local color in shadow without adding scene lights.
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = bounce
	return mat
func _flat(tint: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = rough
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func _mesh(parent: Node3D, mesh: Mesh, material: Material, at := Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.visibility_range_end = 90.0
	parent.add_child(instance)
	return instance

func _add_body(parent: Node3D, at: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 4 | 8
	body.collision_mask = 0
	parent.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collider.shape = shape
	collider.position = at
	body.add_child(collider)
