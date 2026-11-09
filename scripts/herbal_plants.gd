extends Node3D

var collected_ids: Array[int] = []

const LOCATIONS := [Vector3(3,0,25),Vector3(-6,0,18),Vector3(-15,0,9),Vector3(11,0,-2),Vector3(5,0,-17),Vector3(26,0,18),Vector3(-29,0,-12),Vector3(42,0,10)]
const GROVE = preload("res://scripts/moonleaf_grove.gd")
const GROVE_START := 8
const GROVE_GOAL := 3
const GROVE_REWARD := 25
var plants: Array[Node3D] = []
var collected := 0

func _ready() -> void:
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.12,0.48,0.24)
	var bloom := StandardMaterial3D.new()
	bloom.albedo_color = Color(0.3,0.9,0.9)
	bloom.emission_enabled = true
	bloom.emission = Color(0.04,0.22,0.18)
	for location in LOCATIONS + GROVE.HERBS:
		var plant := Node3D.new()
		plant.set_meta("pickup_id", plants.size())
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
		label.text = "GROVE MOONLEAF" if int(plant.get_meta("pickup_id")) >= GROVE_START else "MOONLEAF"
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
	collected_ids.append(int(plant.get_meta("pickup_id")))
	plants.erase(plant)
	plant.queue_free()
	collected += 1
	return true

func journal_text() -> String:
	return "HERBAL GATHERING: %d/5\nFind cyan-flowered Moonleaf near paths and in the meadows. Approach and press COLLECT / E. Each plant adds one healing potion; use HEAL when injured. Plants and collection progress remain saved." % mini(collected,5)

func restore(ids: Array) -> void:
	collected_ids.assign(ids)
	collected = ids.size()
	for item in plants.duplicate():
		if int(item.get_meta("pickup_id")) in ids:
			plants.erase(item)
			item.queue_free()

func grove_count() -> int:
	var count := 0
	for id in collected_ids:
		if id >= GROVE_START:
			count += 1
	return count

func grove_journal(rewarded: bool) -> String:
	var stage := "COMPLETE - 25 shards received" if rewarded else ("%d/3 flowers gathered" % mini(grove_count(), GROVE_GOAL))
	return "MOONLEAF GROVE: %s\nFollow the eastern trail from the Beach waystone into the south-east meadow. The green leaf on MAP marks the grove. Gather 3 cyan-flowered plants inside the grove for 25 shards, paid once automatically. Each flower also adds one healing potion. Ordinary Moonleaf elsewhere does not count for this quest." % stage
