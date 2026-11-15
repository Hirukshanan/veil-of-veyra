extends "res://scripts/campaign.gd"

var landscape: Node3D
var placement_ready := false
var placement_log: Array[Dictionary] = []

func _restore_world() -> void:
	super._restore_world()
	# The legacy restore samples the old height function; validate this saved point
	# against the new collision instead, including a legitimate cave floor.
	player.global_position = world_data.position

func _build_island() -> void:
	landscape = preload("res://scripts/island_landscape.gd").new()
	add_child(landscape)

func _build_decor() -> void:
	pass

func _create_exploration() -> Node3D:
	return preload("res://scripts/island_candidate_exploration.gd").new()

func _ready() -> void:
	super._ready()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_ground_gameplay()
	landscape.populate_ground_detail()
	var atmosphere := preload("res://scripts/island_atmosphere.gd").new()
	atmosphere.name = "IslandAtmosphere"
	add_child(atmosphere)
	atmosphere.populate(self)
	placement_ready = true

func _ground_node(node: Node3D, safe := false) -> void:
	var before := node.global_position
	node.global_position = landscape.safe_point(before) if safe else landscape.ground_point(before)
	placement_log.append({"node":str(node.name),"before":before,"after":node.global_position})

func _ground_gameplay() -> void:
	for enemy in get_tree().get_nodes_in_group("combat_enemies"):
		_ground_node(enemy,true)
		if "_home" in enemy:
			enemy._home = enemy.global_position
			enemy._patrol_goal = enemy.global_position
	_ground_node(lantern,true)
	for item in herbs.plants:_ground_node(item,true)
	for item in seal_fragments.fragments:_ground_node(item,true)
	for item in relic_hunt.relics:
		if int(item.get_meta("pickup_id")) == 1:item.global_position=Vector3(76,1.58,5)
		else:_ground_node(item,true)
	# Keep the original quest scenery and NPC; only its support height changes.
	_ground_node(seal_fragments.get_node("Scenery"))
	# Western Watch is a journal-only Node, not a physical NPC.
	var exploration = get_node("IslandExploration")
	for index in range(3):
		var point: Vector3 = landscape.safe_point(exploration.CHECKPOINTS[index])
		exploration.grounded_checkpoints.append(point)
		exploration.get_node("Waystone%d"%index).global_position = point
		exploration._waystone_labels[index].global_position = point+Vector3.UP*2
	if exploration.checkpoint_index >= 0:player.rescue_position = exploration.checkpoint_position(exploration.checkpoint_index)+Vector3.UP
	else:player.rescue_position = exploration.checkpoint_position(0)+Vector3.UP
	# All original save IDs/equipment/health are preserved; relocate only unsafe support.
	player.global_position = landscape.supported_saved_point(player.global_position)
	player.velocity = Vector3.ZERO
	player._camera_pivot.global_position = player.global_position+Vector3.UP*1.2

func _spawn_boss() -> void:
	super._spawn_boss()
	var dragon := get_node_or_null("Tidewraith Dragon")
	if dragon != null:dragon.position.y = landscape.height_at(Vector2(dragon.position.x,dragon.position.z))
