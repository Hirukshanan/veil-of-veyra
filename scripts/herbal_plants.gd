extends Node3D

var collected_ids: Array[int] = []

const LOCATIONS := [Vector3(3,0,25),Vector3(-6,0,18),Vector3(-15,0,9),Vector3(11,0,-2),Vector3(5,0,-17),Vector3(26,0,18),Vector3(-29,0,-12),Vector3(42,0,10)]
const GROVE = preload("res://scripts/moonleaf_grove.gd")
const GROVE_START := 8
const EAST_MEADOW_HERB_ID := 7
const EAST_MEADOW_HERB := Vector3(34,0,7)
const GROVE_GOAL := 3
const GROVE_REWARD := 25
var plants: Array[Node3D] = []
var collected := 0
var candidate_grove := false
var collector: CharacterBody3D
var prompt_plant: Node3D

func _ready() -> void:
	var leaves := StandardMaterial3D.new()
	leaves.albedo_color = Color(0.12,0.48,0.24)
	var bloom := StandardMaterial3D.new()
	bloom.albedo_color = Color(0.3,0.9,0.9)
	bloom.emission_enabled = true
	bloom.emission = Color(0.04,0.22,0.18)
	var locations := LOCATIONS + (GROVE.CANDIDATE_HERBS if candidate_grove else GROVE.HERBS)
	for id in locations.size():
		var plant := Node3D.new()
		plant.set_meta("pickup_id", id)
		plant.position = EAST_MEADOW_HERB if candidate_grove and id == EAST_MEADOW_HERB_ID else locations[id]
		add_child(plant)
		plants.append(plant)
		if candidate_grove and id >= GROVE_START:
			GROVE.build_flower(plant, leaves, bloom)
			continue
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
		if candidate_grove and plant.has_node("HarvestArea"):
			if not is_instance_valid(collector) or not plant.get_node("HarvestArea").overlaps_body(collector):
				continue
		if candidate < distance and plant.visible and not plant.is_queued_for_deletion():
			distance = candidate
			result = plant
	return result

func collect(point: Vector3) -> bool:
	var plant := nearest(point)
	if plant == null:
		return false
	collected_ids.append(int(plant.get_meta("pickup_id")))
	plants.erase(plant)
	if plant.has_node("HarvestArea"):
		set_prompt(null)
		var tween := plant.create_tween()
		tween.tween_property(plant, "scale", Vector3.ONE * .05, .22).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(plant.queue_free)
	else:
		plant.queue_free()
	collected += 1
	return true

func journal_text() -> String:
	return "HERBAL GATHERING: %d/5\nFind cyan-flowered Moonleaf near paths and in the meadows. Approach and press COLLECT / E. Each plant adds one healing potion; use HEAL when injured. Plants and collection progress remain saved." % mini(collected,5)

func restore(ids: Array) -> void:
	collected_ids.assign(ids)
	collected = ids.size()
	# Legacy saves could gather two extra flowers. Retain those IDs and
	# expose only the outstanding number of quest pickups.
	var remaining := maxi(0, GROVE_GOAL - grove_count())
	for item in plants.duplicate():
		var id: int = item.get_meta("pickup_id")
		if id in ids or (candidate_grove and id >= GROVE_START and remaining == 0):
			plants.erase(item)
			item.hide()
			item.queue_free()
		elif candidate_grove and id >= GROVE_START:
			remaining -= 1

func set_prompt(plant: Node3D) -> void:
	if prompt_plant == plant:
		return
	if is_instance_valid(prompt_plant):
		prompt_plant.get_node("Prompt").hide()
	prompt_plant = plant
	if plant != null:
		plant.get_node("Prompt").show()

func grove_center() -> Vector3:
	return GROVE.CANDIDATE_CENTER if candidate_grove else GROVE.CENTER

func grove_count() -> int:
	var count := 0
	for id in collected_ids:
		if id >= GROVE_START:
			count += 1
	return count

func grove_journal(rewarded: bool) -> String:
	var stage := "COMPLETE - 25 shards received" if rewarded else ("%d/3 flowers gathered" % mini(grove_count(), GROVE_GOAL))
	return "MOONLEAF GROVE: %s\nFollow the eastern trail from the beach into the south-east meadow. The grove marker on the minimap marks the grove. Gather 3 cyan-flowered plants inside the grove for 25 shards, paid once automatically. Each flower also adds one healing potion. Ordinary Moonleaf elsewhere does not count for this quest." % stage
