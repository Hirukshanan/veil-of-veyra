extends Node3D

const CENTER := Vector3(44,0,28)
const HERBS := [Vector3(41,0,26),Vector3(45,0,25),Vector3(48,0,28),Vector3(45,0,32),Vector3(41,0,31)]

const CANDIDATE_CENTER := Vector3(35,0,29)
const CANDIDATE_HERBS := [Vector3(34,0,25), Vector3(38,0,29), Vector3(36,0,34)]
var candidate := false

func _ready() -> void:
	name = "MoonleafGrove"
	position = CENTER
	if candidate:
		return
	var decor = preload("res://scripts/chapter_environment.gd").new()
	# Leave a broad western entrance aligned with the branching trail.
	for index in range(16):
		var angle := index * TAU / 16.0
		var point := Vector3(cos(angle),0,sin(angle)) * (9.0 + float(index % 3))
		if point.x < -4.0 and absf(point.z) < 5.0:
			continue
		var tree := Node3D.new()
		tree.position = point
		add_child(tree)
		decor._tree(tree, 1.05 + (index % 3) * 0.1)
	for index in range(10):
		var fern := preload("res://assets/environment/fern_02_mobile.scn").instantiate()
		var angle := index * TAU / 10
		fern.position = Vector3(cos(angle)*6.5,0,sin(angle)*6.5)
		fern.rotation.y = angle
		add_child(fern)
		for mesh in fern.find_children("*","MeshInstance3D",true,false):
			mesh.visibility_range_end = 28.0
	var rock_material := preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02",0.7)
	for point in [Vector3(-5,0.3,7),Vector3(6,0.3,5),Vector3(3,0.3,-7)]:
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.8
		mesh.height = 1.6
		mesh.radial_segments = 10
		mesh.rings = 5
		rock.mesh = mesh
		rock.position = point
		rock.scale = Vector3(1.5,0.8,1.1)
		rock.material_override = rock_material
		rock.visibility_range_end = 50.0
		add_child(rock)
		rock.create_convex_collision()
		var body := rock.get_child(0) as StaticBody3D
		body.collision_layer = 4 | 8
		body.collision_mask = 0
	decor.free()
	var signpost := Label3D.new()
	signpost.name = "GroveSign"
	signpost.text = "MOONLEAF GROVE\nCyan flowers • gather 3 for 25 shards"
	signpost.position = Vector3(-8,2.5,0)
	signpost.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	signpost.font_size = 28
	signpost.modulate = Color(0.7,1.0,0.8)
	signpost.visibility_range_end = 24.0
	add_child(signpost)


func populate_candidate(landscape: Node3D) -> void:
	global_position = landscape.ground_point(CANDIDATE_CENTER)
	var scenery := preload("res://scripts/chapter_environment.gd").new()
	# Frame the meadow on three sides and leave the river approach open.
	for offset in [Vector3(-4,0,-8), Vector3(0,0,-9), Vector3(3,0,-7),
			Vector3(4,0,-5), Vector3(5,0,4), Vector3(3,0,9), Vector3(-2,0,9)]:
		var tree := Node3D.new()
		add_child(tree)
		tree.global_position = landscape.ground_point(CANDIDATE_CENTER + offset)
		scenery._tree(tree, .67 + absf(offset.x) * .022)
	scenery.free()
	for offset in [Vector3(-5,0,-4), Vector3(2,0,-5), Vector3(4,0,-3),
			Vector3(4,0,3), Vector3(2,0,7), Vector3(-4,0,6)]:
		var fern := preload("res://assets/environment/fern_02_mobile.scn").instantiate() as Node3D
		add_child(fern)
		fern.global_position = landscape.ground_point(CANDIDATE_CENTER + offset)
		fern.rotation.y = offset.x
	var signpost := _caption("Moonleaf Grove", 1.7)
	add_child(signpost)
	signpost.global_position = landscape.ground_point(CANDIDATE_CENTER + Vector3.LEFT * 6) + Vector3.UP * 1.7

static func build_flower(plant: Node3D, leaves: StandardMaterial3D, bloom: StandardMaterial3D) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = .5
	mesh.height = 1.
	mesh.radial_segments = 8
	mesh.rings = 4
	var stem := CylinderMesh.new()
	stem.bottom_radius = .045
	stem.top_radius = .025
	stem.height = .82
	stem.radial_segments = 6
	_piece(plant, stem, leaves, Vector3.UP * .41, Vector3.ONE)
	for index in 5:
		var angle := index * TAU / 5.
		var radial := Vector3.FORWARD.rotated(Vector3.UP, angle)
		_piece(plant, mesh, leaves, radial * .23 + Vector3.UP * .29, Vector3(.22,.08,.48)).rotation.y = angle
		var petal := _piece(plant, mesh, bloom, radial * .18 + Vector3.UP * .84, Vector3(.20,.10,.33))
		petal.rotation.y = angle
		petal.rotation.x = -.22
	_piece(plant, mesh, bloom, Vector3.UP * .88, Vector3(.21,.18,.21))

	var area := Area3D.new()
	area.name = "HarvestArea"
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitorable = false
	area.position.y = .56
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.22
	collision.shape = sphere
	area.add_child(collision)
	plant.add_child(area)
	var prompt := _caption("Collect Moonleaf", 1.3)
	prompt.name = "Prompt"
	prompt.hide()
	plant.add_child(prompt)

static func _piece(parent: Node3D, mesh: Mesh, material: Material, at: Vector3, shape: Vector3) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = material
	piece.position = at
	piece.scale = shape
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(piece)
	return piece

static func _caption(text: String, height: float) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position.y = height
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("b1ffe4")
	label.font_size = 32
	label.visibility_range_end = 19.
	return label
