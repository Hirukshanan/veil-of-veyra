extends Node3D

const CENTER := Vector3(-44,0,54)
const LOCATIONS := [Vector3(-40,0,52),Vector3(-47,0,55),Vector3(-43,0,59)]
const REQUIRED := 3
var collected_ids: Array[int] = []
var fragments: Array[Node3D] = []

func _ready() -> void:
	name = "BeachSealRuins"
	var ruins := Node3D.new()
	ruins.name = "Scenery"
	ruins.position = CENTER
	add_child(ruins)
	var decor = preload("res://scripts/chapter_environment.gd").new()
	# Pillars sit outside the approach and each fragment's reach circle.
	for index in range(7):
		var pillar := Node3D.new()
		pillar.position = Vector3(cos(index*TAU/7)*9.5,0,sin(index*TAU/7)*9.5)
		if pillar.position.x > 3 and pillar.position.z < -2:
			pillar.free()
			continue
		ruins.add_child(pillar)
		decor._column(pillar,0.55,1.7+index%3,Color("807461"))
		if index%2==0:
			var cap := BoxMesh.new()
			cap.size = Vector3(1.7,0.35,1.2)
			decor._piece(pillar,cap,Vector3(0,1.9+index%3,0),Color("807461"))
	for index in range(3):
		var fallen := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.45
		mesh.bottom_radius = 0.6
		mesh.height = 2.7
		mesh.radial_segments = 10
		fallen.mesh = mesh
		fallen.position = Vector3(-7+index*4,0.5,7.5)
		fallen.rotation = Vector3(0,0.4*index,PI/2)
		fallen.material_override = preload("res://scripts/environment_materials.gd").surface("rocky_terrain_02",0.8)
		ruins.add_child(fallen)
		fallen.create_convex_collision()
		var blocker := fallen.get_child(0) as StaticBody3D
		blocker.collision_layer = 4|8
		blocker.collision_mask = 0
	decor.free()
	var sign := Label3D.new()
	sign.text = "TIDESEAL RUINS\nRecover the lantern's three seal fragments"
	sign.position = CENTER+Vector3(3,3,-5)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 28
	sign.modulate = Color("9bdde0")
	sign.visibility_range_end = 26
	add_child(sign)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("6cf0e2")
	material.emission_enabled = true
	material.emission = Color("207b81")
	for index in range(LOCATIONS.size()):
		var fragment := Node3D.new()
		fragment.name = "SealFragment%d"%index
		fragment.set_meta("pickup_id",index)
		fragment.position = LOCATIONS[index]
		add_child(fragment)
		fragments.append(fragment)
		var shard := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.5,0.7,0.22)
		shard.mesh = mesh
		shard.material_override = material
		shard.position.y = 0.9
		shard.rotation.z = 0.3+index*0.2
		fragment.add_child(shard)
		var label := Label3D.new()
		label.text = "SEAL FRAGMENT"
		label.position.y = 1.65
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 26
		label.visibility_range_end = 14.0
		fragment.add_child(label)

func nearest(point: Vector3, max_distance: float = 2.0) -> Node3D:
	var result: Node3D
	var distance := max_distance
	for fragment in fragments:
		var candidate := point.distance_to(fragment.global_position)
		if candidate < distance:
			distance = candidate
			result = fragment
	return result

func collect(point: Vector3) -> bool:
	var fragment := nearest(point)
	if fragment == null: return false
	collected_ids.append(int(fragment.get_meta("pickup_id")))
	fragments.erase(fragment)
	fragment.queue_free()
	return true

func complete() -> bool:
	return collected_ids.size() == REQUIRED

func restore(ids: Array) -> void:
	collected_ids.assign(ids)
	for fragment in fragments.duplicate():
		if int(fragment.get_meta("pickup_id")) in ids:
			fragments.erase(fragment)
			fragment.queue_free()

func journal_text() -> String:
	var state := "COMPLETE - lantern seal recovered" if complete() else "%d/3 recovered"%collected_ids.size()
	return "LANTERN SEAL: %s\nFollow the south-west trail from Beach waystone to Tideseal Ruins. The cyan diamond on MAP marks the ruins. Approach each fragment and tap the hand icon / E. Recover all three fragments and clear the demon camps to light the northern lantern. The fragments are quest items; they do not consume potions or reset when reopening."%state
