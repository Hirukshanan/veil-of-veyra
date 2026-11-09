extends Node3D

const CENTER := Vector3(44,0,28)
const HERBS := [Vector3(41,0,26),Vector3(45,0,25),Vector3(48,0,28),Vector3(45,0,32),Vector3(41,0,31)]

func _ready() -> void:
	name = "MoonleafGrove"
	position = CENTER
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
