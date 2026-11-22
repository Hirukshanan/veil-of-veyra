extends "res://scripts/buried_temple.gd"

const ALTAR := Vector3(-1.8,34,32)
const STAIR_TOP := Vector3(0,44.9,-30.1)
const LAIR := Vector3(0,34.08,15.4)
var in_cell := false
var dragon_cavern := false
var polish_model: PackedScene
var sanctum_seal: Array[MeshInstance3D] = []
var altar_trim: Array[MeshInstance3D] = []

static func owns(p: Vector3) -> bool:
	return p.y >= 33 and p.y <= 49 and absf(p.x)<15 and p.z >= -33 and p.z < 48

func solid(at: Vector3, size: Vector3, parent: Node3D = null) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 29
	body.collision_mask = 0
	(parent if parent else chamber).add_child(body)
	body.position = at
	var collider := CollisionShape3D.new()
	var hull := BoxShape3D.new()
	hull.size = size
	collider.shape = hull
	body.add_child(collider)
	return body

func populate(defeated: bool) -> void:
	in_cell = true
	if is_instance_valid(chamber):
		chamber.show()
		chamber.process_mode = Node.PROCESS_MODE_INHERIT
		return
	chamber = Node3D.new()
	chamber.name = "HallOfTheBuriedSun"
	add_child(chamber)
	var model := polish_model if polish_model else preload("res://assets/environment/buried_shrine/hall.glb")
	var shell := model.instantiate()
	chamber.add_child(shell)
	shell.position.y = 34
	door = MeshInstance3D.new()
	chamber.add_child(door)
	door.position = Vector3(0,34,0)
	var materials := {}
	for piece in shell.find_children("*","MeshInstance3D",true,false):
		var mesh_node := piece as MeshInstance3D
		var part_name := str(mesh_node.name)
		# The passage owns the full right jamb and its collider.
		if part_name.begins_with("SanctumRightReturn") or (dragon_cavern and part_name.begins_with("SanctumRightBackdrop")):
			mesh_node.free()
			continue
		for i in mesh_node.mesh.get_surface_count():
			var original := mesh_node.mesh.surface_get_material(i) as StandardMaterial3D
			if not materials.has(original):
				materials[original] = _surface(original)
			mesh_node.set_surface_override_material(i,materials[original])
		if str(piece.name).begins_with("Portcullis"):
			mesh_node.reparent(door,true)
		elif str(piece.name).begins_with("AltarTrim"):
			altar_trim.append(mesh_node)
		elif str(piece.name).begins_with("SanctumSeal"):
			sanctum_seal.append(mesh_node)
	solid(Vector3(0,3.95,20),Vector3(6.3,7.9,.68),door)
	solid(Vector3(0,33.8,7.4),Vector3(26,.4,26))
	solid(Vector3(0,44.59,-30.72),Vector3(8,.44,3.4))
	var ramp := solid(Vector3(0,39.23,-17),Vector3(8,.31,26.35))
	ramp.rotation.x = atan2(10.8,24.)
	for side in [-1,1]:
		solid(Vector3(side*4.43,43,-17),Vector3(1,19,27))
		solid(Vector3(side*12.85,38.8,7.5),Vector3(.8,9.6,26))
		solid(Vector3(side*8.75,38.9,-5.4),Vector3(9.5,10,.8))
		solid(Vector3(side*8,38.8,20),Vector3(9.7,9.8,1))
		for z in [-4.6,1.5,7.6,13.7,19.8]:
			solid(Vector3(side*10,37,z),Vector3(1.9,6,1.9))
		solid(Vector3(side*5.55,36.9,18.5),Vector3(3,5.8,2.4))
		solid(Vector3(side*7.15,38,34),Vector3(.9,8,28))
	solid(Vector3(0,43.95,7.5),Vector3(26,.3,26))
	solid(Vector3(0,33.8,34),Vector3(15,.4,28))
	solid(Vector3(0,42.5,34),Vector3(15,.7,29))
	if dragon_cavern:
		solid(Vector3(-3.56,38,47.5),Vector3(7.88,8,.8))
		solid(Vector3(6.24,38,47.5),Vector3(2.52,8,.8))
	else:
		solid(Vector3(0,38,47.5),Vector3(15,8,.8))
	solid(Vector3(-4.82,37,39.1),Vector3(4.6,6.2,.8))
	solid(Vector3(0,48,-32.5),Vector3(9,7,.8))
	_lighting()
	if defeated: unseal(true)

func _surface(original: StandardMaterial3D) -> Material:
	if original.resource_name.contains("Daylight"):
		var sky := StandardMaterial3D.new()
		sky.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sky.albedo_color = Color(.63,.69,.71)
		return sky
	var surface := ShaderMaterial.new()
	surface.shader = preload("res://assets/environment/buried_shrine/masonry.gdshader")
	surface.set_shader_parameter("tint",original.albedo_color)
	surface.set_shader_parameter("weathered",polish_model != null)
	surface.set_shader_parameter("cavern_portal",dragon_cavern)
	surface.set_shader_parameter("passage_shadow",1 if dragon_cavern else 0)
	surface.set_shader_parameter("rock",stone.albedo_texture)
	surface.set_shader_parameter("normal_tex",stone.normal_texture)
	if original.resource_name.contains("bronze") or original.resource_name.contains("Inlay"):
		surface.set_shader_parameter("metalness",.75)
	return surface

func _lighting() -> void:
	for z in [.9,12.2]:
		var aperture := Vector3(-2.4,44,z)
		var landing := Vector3(1.5,34,z+1.5)
		var beam := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.radial_segments = 16
		cone.rings = 1
		cone.cap_top = false
		cone.cap_bottom = false
		cone.top_radius = .70
		cone.bottom_radius = 2.65
		cone.height = aperture.distance_to(landing)
		beam.mesh = cone
		var mist := ShaderMaterial.new()
		mist.shader = preload("res://assets/environment/buried_shrine/shaft.gdshader")
		if polish_model: mist.set_shader_parameter("density",.135)
		beam.material_override = mist
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chamber.add_child(beam)
		beam.position = (landing+aperture)*.5
		beam.quaternion = Quaternion(Vector3.UP,(aperture-landing).normalized())
		var sun := SpotLight3D.new()
		chamber.add_child(sun)
		sun.position = aperture
		sun.look_at(landing)
		sun.spot_range = 18
		sun.spot_angle = 31
		sun.light_color = Color(.79,.86,1.)
		sun.light_energy = 4.7 if polish_model else 4.
	for spec in [[Vector3(1,38,16),Color(.69,.11,.085),1.9,8.],[Vector3(-1.8,37.7,32),Color(1.,.68,.32),3.7,12.],[Vector3(-1,42,-18),Color(.55,.67,.83),2.5,13.]]:
		var lamp := OmniLight3D.new()
		chamber.add_child(lamp)
		lamp.position = spec[0]
		lamp.light_color = spec[1]
		lamp.light_energy = spec[2]
		lamp.omni_range = spec[3]

	if polish_model:
		var seal_fill := OmniLight3D.new()
		seal_fill.position = Vector3(0,39,43)
		seal_fill.light_color = Color(.97,.78,.56)
		seal_fill.omni_range = 6.5 if dragon_cavern else 10.
		seal_fill.light_energy = 1.35 if dragon_cavern else 2.1
		chamber.add_child(seal_fill)

func decorate_altar(pedestal: Node3D) -> void:
	if altar_trim.is_empty(): return
	for part in pedestal.get_children():
		if part is MeshInstance3D: part.layers = 1 << 18
	for part in altar_trim:
		part.reparent(pedestal,true)
		if pedestal.global_position.y < ALTAR.y - 1:
			part.position.y += pedestal.global_position.y - ALTAR.y
	altar_trim.clear()

func unseal(immediate := false) -> void:
	if not is_instance_valid(door): return
	if immediate: door.position.y = 25.6
	else: create_tween().set_trans(Tween.TRANS_SINE).tween_property(door,"position:y",25.6,2.)

func suspend_cell() -> void:
	in_cell = false
	chamber.hide()
	chamber.process_mode = Node.PROCESS_MODE_DISABLED
