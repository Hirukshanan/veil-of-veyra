extends Node3D

# Interior cell. Its paired thresholds leave the original cave and cinematic
# shell intact. Y stays in the existing save format's supported range.
const TOP := Vector3(0, 40, -20)
const DEN := Vector3(0, 34, 9)
const OUTER := Vector3(67.8, 2.35, 20)
const INNER := Vector3(67, 2.5, 22)
var chamber: Node3D
var veil: MeshInstance3D
var door: MeshInstance3D
var stone := StandardMaterial3D.new()
var trim: StandardMaterial3D
var open := false
var exposed_steps: Node3D

func _ready() -> void:
	stone.albedo_texture = preload("res://assets/environment/new_island/task3/rock_albedo.png")
	stone.normal_enabled = true
	stone.normal_texture = preload("res://assets/environment/new_island/task3/rock_normal.png")
	stone.uv1_triplanar = true
	stone.uv1_world_triplanar = true
	stone.uv1_scale = Vector3.ONE * .65
	stone.albedo_color = Color(.65,.58,.51)
	trim = stone.duplicate()
	trim.albedo_color = Color(.42,.48,.49)
	# The original passage beyond this partition becomes the inner sanctum.
	block(self, OUTER + Vector3(-6,2.6,.8), Vector3(8,6,1.2))
	block(self, OUTER + Vector3(6,2.6,.8), Vector3(8,6,1.2))
	block(self, OUTER + Vector3(0,4.7,.8), Vector3(5,2,1.2))
	block(self, OUTER + Vector3(0,1.7,1), Vector3(4.2,4,.45))
	veil = block(self, OUTER + Vector3(0,1.6,-.55), Vector3(4.3,4,.8))
	exposed_steps = Node3D.new()
	add_child(exposed_steps)
	exposed_steps.hide()
	for i in 4:
		block(exposed_steps, OUTER + Vector3(0,-.36-i*.09,-1.4+i*.38),Vector3(4,.5,.4),false)

func unlock(immediate: bool) -> void:
	if open: return
	open = true
	exposed_steps.show()
	var end := veil.position.y - 4.6
	if immediate: veil.position.y = end
	else: create_tween().set_trans(Tween.TRANS_SINE).tween_property(veil,"position:y",end,1.45)

func block(parent: Node3D, at: Vector3, size: Vector3, solid := true, accent := false) -> MeshInstance3D:
	var mesh_node := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_node.mesh = box
	mesh_node.material_override = trim if accent else stone
	parent.add_child(mesh_node)
	mesh_node.position = at
	if solid:
		var body := StaticBody3D.new()
		body.collision_layer = 29
		body.collision_mask = 0
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
		mesh_node.add_child(body)
	return mesh_node

static func inside(p: Vector3) -> bool:
	return p.y >= 33 and p.y < 48 and absf(p.x)<17 and p.z >= -25 and p.z <= 24

func populate(defeated: bool) -> void:
	if is_instance_valid(chamber): return
	chamber = Node3D.new()
	chamber.name = "BuriedTemple"
	add_child(chamber)
	# Six metres of descent. One smooth physics ramp under dressed stone treads.
	block(chamber,Vector3(0,39.75,-22),Vector3(6,.5,4))
	var ramp := block(chamber,Vector3(0,36.74,-13),Vector3(6,.5,sqrt(232.0)))
	ramp.rotation.x = atan2(6.,14.)
	for i in 35:
		var f := (i+.5)/35.
		block(chamber,Vector3(0,39.87-6*f,-20+14*f),Vector3(5.96,.27,.404),false,i%5==0)
	for side in [-1,1]:
		block(chamber,Vector3(side*3.5,39,-15),Vector3(1,12,18))
		block(chamber,Vector3(side*15,38.9,7.5),Vector3(1,11,29))
		block(chamber,Vector3(side*9,38.9,-6.5),Vector3(12,11,1))
		block(chamber,Vector3(side*9,38.9,21.5),Vector3(12,11,1))
		for i in 4:
			var z := -3.+7.*i
			var h := 3.3+fmod(i*2.7+float(side+1),4.8)
			pillar(side*12.7,z,h)
			block(chamber,Vector3(side*14.25,41.9,z),Vector3(1.4,.8,3),false,true)
	block(chamber,Vector3(0,44.6,0),Vector3(31,1,49))
	block(chamber,Vector3(0,42,-24.3),Vector3(7,6,1))
	block(chamber,Vector3(0,33.7,7.5),Vector3(30,.6,29))
	# Broad cracked flags have recessed seams above a continuous combat floor.
	for x in 7:
		for z in 6:
			var tile := block(chamber,Vector3((x-3)*4.1,33.97,-3.8+z*4.55),Vector3(4.07,.08,4.51),false,(x+2*z)%7==0)
			tile.rotation.y = sin(x*8.+z)*.004
	block(chamber,Vector3(0,33.7,22.6),Vector3(7,.6,3))
	door = block(chamber,Vector3(0,38,21.5),Vector3(6,8,.9),true,true)
	for at in [Vector3(-9,39,1),Vector3(9,39,14),Vector3(0,41,-17)]:
		var light := OmniLight3D.new()
		chamber.add_child(light)
		light.position = at
		light.light_color = Color(.98,.68,.40) if at.x<0 else Color(.54,.72,.85)
		light.light_energy = 2.1
		light.omni_range = 18
	# A broken processional arcade frames the altar door. All overhanging
	# decoration stays above the charge lane and the spring arm.
	block(chamber,Vector3(0,43,21.5),Vector3(7,2.4,1.3),true,true)
	for side in [-1,1]:
		for tier in 3:
			block(chamber,Vector3(side*(3.7-tier*.38),40.4+tier*.65,20.8),Vector3(1.2,.74,1.5),false,true)
		for bay in 3:
			var z := .5+bay*7.
			block(chamber,Vector3(side*13.7,42.4,z),Vector3(2,.6,6.9),false,true)
			var rock := SphereMesh.new()
			rock.radial_segments = 7
			rock.rings = 3
			var outcrop := MeshInstance3D.new()
			outcrop.mesh = rock
			outcrop.material_override = trim
			chamber.add_child(outcrop)
			outcrop.position = Vector3(side*14.55,39.3,z)
			outcrop.scale = Vector3(1.4,4.+bay,4.2)
			outcrop.rotation.x = .3*sin(z)
	# Concentric weathered stone voussoirs over the sealed threshold.
	for i in 11:
		var angle := PI*i/10.
		var brick := block(chamber,Vector3(3.9*cos(angle),38.5+3.9*sin(angle),20.45),Vector3(.85,1.12,.72),false,true)
		brick.rotation.z = angle
	for i in 3:
		var scar := block(door,Vector3((i-1)*.6,.15,.0)+Vector3.FORWARD*.48,Vector3(.12,2.1,.08),false,true)
		scar.rotation.z = -.21
	_dress_ruins()
	_batch_masonry()
	_weather_stone()
	if defeated: unseal(true)

func pillar(x: float,z: float,h: float) -> void:
	block(chamber,Vector3(x,34.3,z),Vector3(2.2,.6,2.2),true,true)
	var pillar_mesh := CylinderMesh.new()
	pillar_mesh.radial_segments = 8
	pillar_mesh.rings = 1
	pillar_mesh.top_radius = .71
	pillar_mesh.bottom_radius = .92
	pillar_mesh.height = h
	var shaft := MeshInstance3D.new()
	shaft.mesh = pillar_mesh
	shaft.material_override = stone
	chamber.add_child(shaft)
	shaft.position = Vector3(x,34.6+h/2,z)
	shaft.create_convex_collision()
	shaft.get_child(0).collision_layer = 29
	var cap := block(chamber,Vector3(x,34.7+h,z),Vector3(1.48,.34,1.56),false,true)
	cap.rotation.z = .15*sin(z)

func unseal(immediate := false) -> void:
	if not is_instance_valid(door): return
	if immediate: door.position.y = 28.8
	else: create_tween().set_trans(Tween.TRANS_SINE).tween_property(door,"position:y",28.8,1.3)

func leave() -> void:
	if is_instance_valid(chamber):
		remove_child(chamber)
		chamber.queue_free()
		chamber = null

# Shared unit boxes keep the many static flags and stairs to two draw calls.
func _batch_masonry() -> void:
	for material in [stone,trim]:
		var blocks: Array[MeshInstance3D] = []
		for node in chamber.get_children():
			if node is MeshInstance3D and node != door and node.mesh is BoxMesh and node.material_override == material:
				blocks.append(node)
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = BoxMesh.new()
		batch.instance_count = blocks.size()
		for i in blocks.size():
			var piece := blocks[i]
			var pose := piece.transform
			pose.basis = pose.basis.scaled_local(piece.mesh.size)
			batch.set_instance_transform(i,pose)
			piece.mesh = null
		var visual := MultiMeshInstance3D.new()
		visual.multimesh = batch
		visual.material_override = material
		chamber.add_child(visual)

func _weather_stone() -> void:
	var weather := ShaderMaterial.new()
	weather.shader = preload("res://scripts/temple_moss.gdshader")
	weather.set_shader_parameter("rock", stone.albedo_texture)
	weather.set_shader_parameter("relief",stone.normal_texture)
	weather.set_shader_parameter("moss",preload("res://assets/environment/polyhaven/leafy_grass_Diffuse.jpg"))
	var dark: ShaderMaterial = weather.duplicate()
	dark.set_shader_parameter("patina",.71)
	for node in chamber.find_children("*","GeometryInstance3D",true,false):
		if node.material_override == stone: node.material_override = weather
		elif node.material_override == trim: node.material_override = dark

func _dress_ruins() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 62107
	var foliage: Array[Transform3D] = []
	var vines := SurfaceTool.new()
	vines.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Broken side galleries: surviving springers, banded piers and fallen blocks.
	for side in [-1,1]:
		for bay in 3:
			var z := .5+bay*7.
			for j in 13:
				if (bay+side)%2==0 and j>4 and j<8: continue
				var a := PI*j/12.
				var voussoir := block(chamber,Vector3(side*12.7,37.9+3.1*sin(a),z+3.5*cos(a)),Vector3(1.45,.74,.97),false,true)
				voussoir.rotation.x = a
			for j in 6:
				var base := Vector3(side*rng.randf_range(11.1,14.0),34.07,z+rng.randf_range(-2.7,2.7))
				var rubble := block(chamber,base,Vector3(rng.randf_range(.45,1.6),rng.randf_range(.25,.69),rng.randf_range(.6,1.5)),false)
				rubble.rotation = Vector3(rng.randf_range(-.19,.19),rng.randf_range(-1.,1.),rng.randf_range(-.23,.23))
				foliage.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*rng.randf_range(.7,1.45)),base+Vector3.UP*.19))
			for strand in 7:
				_vine(vines,rng,Vector3(side*12.1,40.9,z+rng.randf_range(-2.1,2.1)),rng.randf_range(1.3,4.8))
		for pier in 4:
			for band in [0.6,.84,2.9]:
				block(chamber,Vector3(side*12.7,34.3+band,-3.+pier*7.),Vector3(2.03,.19,2.03),false,true)
	# Overlapping rough voussoirs break up the lip of the daylight shaft.
	for i in 32:
		var a := TAU*i/32.
		var lip := Vector3(-1.+5.*cos(a),43.76+rng.randf_range(-.25,.2),5.8+3.8*sin(a))
		var rock := block(chamber,lip,Vector3(rng.randf_range(1.2,2.3),rng.randf_range(.6,1.4),rng.randf_range(1.,1.8)),false)
		rock.rotation = Vector3(rng.randf_range(-.32,.32),-a,rng.randf_range(-.35,.35))
		_vine(vines,rng,lip-Vector3.UP*.28,rng.randf_range(1.1,4.4))
	var leaves := StandardMaterial3D.new()
	leaves.vertex_color_use_as_albedo = true
	leaves.cull_mode = BaseMaterial3D.CULL_DISABLED
	vines.set_material(leaves)
	vines.generate_normals()
	var hanging := MeshInstance3D.new()
	hanging.mesh = vines.commit()
	chamber.add_child(hanging)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = preload("res://assets/environment/new_island/vegetation/fern.res")
	batch.instance_count = foliage.size()
	for i in foliage.size(): batch.set_instance_transform(i,foliage[i])
	var ferns := MultiMeshInstance3D.new()
	ferns.multimesh = batch
	chamber.add_child(ferns)
	var shaft := SpotLight3D.new()
	chamber.add_child(shaft)
	shaft.position = Vector3(-1,43.7,5.8)
	shaft.look_at(Vector3(.7,34,8),Vector3.UP)
	shaft.spot_range = 17
	shaft.spot_angle = 37
	shaft.light_color = Color(.95,1.,.77)
	shaft.light_energy = 5.

func _vine(surface: SurfaceTool,rng: RandomNumberGenerator,anchor: Vector3,length_m: float) -> void:
	var last := anchor
	var phase := rng.randf()*TAU
	var edge := Vector3(.032,0,.018)
	for i in range(1,10):
		var t := i/9.
		var tip := anchor+Vector3(.21*sin(phase+t*5.)*t,-length_m*t,.19*cos(phase+t*4.)*t)
		var bark := Color(.32,.37,.14)
		for pt in [last-edge,last+edge,tip-edge,tip-edge,last+edge,tip+edge]:
			surface.set_color(bark)
			surface.add_vertex(pt)
		var leaf := Vector3((1 if i%2==0 else -1)*rng.randf_range(.12,.28),-.22,rng.randf_range(-.14,.14))
		var mid := tip+leaf*.52
		var width := Vector3(.015,.065,.045)
		var green := Color(.40,.52,.16).lerp(Color(.19,.34,.12),rng.randf())
		for pt in [tip,mid+width,tip+leaf,tip,tip+leaf,mid-width]:
			surface.set_color(green)
			surface.add_vertex(pt)
		last = tip
