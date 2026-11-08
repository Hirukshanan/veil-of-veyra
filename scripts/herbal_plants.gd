extends Node3D

const LOCATIONS := [Vector3(3,0,25),Vector3(-6,0,18),Vector3(-15,0,9),Vector3(11,0,-2),Vector3(5,0,-17),Vector3(26,0,18),Vector3(-29,0,-12),Vector3(42,0,10)]
var plants: Array[Node3D] = []
var collected := 0

func _ready() -> void:
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.12,0.48,0.24)
	var bloom := StandardMaterial3D.new()
	bloom.albedo_color = Color(0.3,0.9,0.9)
	bloom.emission_enabled = true
	bloom.emission = Color(0.04,0.22,0.18)
	for location in LOCATIONS:
		var plant := Node3D.new()
		plant.position = location
		add_child(plant)
		plants.append(plant)
		for index in range(6):
			var leaf := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = 0.15
			mesh.height = 0.3
			mesh.radial_segments = 8
			mesh.rings = 4
			leaf.mesh = mesh
			leaf.scale = Vector3(1,0.35,2.3)
			var angle := index * TAU / 6
			leaf.position = Vector3(sin(angle)*0.22,0.25,cos(angle)*0.22)
			leaf.rotation.y = angle
			leaf.material_override = leaves
			plant.add_child(leaf)
		var flower := MeshInstance3D.new()
		var bud := SphereMesh.new()
		bud.radius = 0.13
		bud.height = 0.26
		flower.mesh = bud
		flower.position.y = 0.48
		flower.material_override = bloom
		plant.add_child(flower)
		var label := Label3D.new()
		label.text = "MOONLEAF"
		label.position.y = 1.1
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 25
		label.visibility_range_end = 10.0
		plant.add_child(label)

func nearest(point: Vector3) -> Node3D:
	var result: Node3D
	var distance := 2.0
	for plant in plants:
		var candidate := plant.global_position.distance_to(point)
		if candidate < distance:
			distance = candidate
			result = plant
	return result

func collect(point: Vector3) -> bool:
	var plant := nearest(point)
	if plant == null:
		return false
	plants.erase(plant)
	plant.queue_free()
	collected += 1
	return true

func journal_text() -> String:
	return "HERBAL GATHERING: %d/5\nFind cyan-flowered Moonleaf near paths and in the meadows. Approach and press COLLECT / E. Each plant adds one healing potion; use HEAL when injured. Plants and collection progress reset when restarting the hunt." % mini(collected,5)
