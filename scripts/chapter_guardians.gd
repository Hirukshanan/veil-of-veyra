extends RefCounted

const SAVE_KEY := "guardian_quest"
const BEAR_FLAG := "cursed_bear_defeated"
const GROVE_FLAG := "ancient_grove_investigated"
const GROVE_CENTER := preload("res://scripts/chapter_one_region.gd").GROVE_CENTER
const TITLE := "The Three Cursed Guardians"
const DESCRIPTION := "The broken seal's three fragments have been absorbed by powerful cursed creatures. Defeat the guardians and recover the fragments to restore the Northern Lantern."
const LANTERN := "restore_lantern"
const WARG_INDEX := 2
const WARG_HOME := Vector3(37, 0, -47)
const BOAR_HOME := Vector3(-20, 0, -34)
const GUARDIANS := [
	{"id": "guardian_warg", "name": "Dire Warg", "actor": "CampDemon2", "region": "Northern Foothills",
		"center": Vector3(35, 0, -45), "radius": 13.0, "color": Color("ef9e64"),
		"trail": "Follow the trail from the Northern Lantern toward Ancient Grove, then skirt east below the mountain ridge."},
	{"id": "guardian_fox", "name": "Demon Fox", "actor": "DemonFox", "region": "Eastern Terrace",
		"center": Vector3(44, 0, -22), "radius": 12.0, "color": Color("ec81b2"),
		"trail": "Follow the east-bank trail north, then search the open terrace below the eastern cliffs."},
	{"id": "guardian_boar", "name": "Demon Boar", "actor": "DemonBoar", "region": "Central Shelf",
		"center": Vector3(-22, 0, -33), "radius": 12.0, "color": Color("e4ce70"),
		"trail": "Follow the trail north from the Northern Lantern, then skirt the ridge west to the low shelf."},
]

var game
var grove_roots: MeshInstance3D
var grove_point: Vector3:
	get:
		return grove_roots.global_position

func _init(scene) -> void:
	game = scene

func restore() -> void:
	var world: Dictionary = game.world_data
	if not world.has(SAVE_KEY):
		world[SAVE_KEY] = {"investigated": not world.seal_fragments.is_empty(), "regions": [], "fox_defeated": false}
		# Credit guardians already cleared before this quest was added.
		if WARG_INDEX in world.cleared and 0 not in world.seal_fragments:
			world.seal_fragments.append(0)
		if world.get("boar_defeated", false) and 2 not in world.seal_fragments:
			world.seal_fragments.append(2)
	var progress: Dictionary = world[SAVE_KEY]
	if not progress.get("foothill_marker", false):
		# Discover the relocated Warg's region independently of the old woodland.
		progress.regions.erase(0)
		progress.foothill_marker = true
	if not progress.get("central_east_markers", false):
		# The old search areas do not count as discovery of the new homes.
		progress.regions.erase(1)
		progress.regions.erase(2)
		progress.central_east_markers = true

func revealed() -> bool:
	return game.world_data[SAVE_KEY].investigated or game.seal_fragments.complete()

func fox_defeated() -> bool:
	return game.world_data[SAVE_KEY].fox_defeated

func can_investigate() -> bool:
	return not revealed() and game.player.global_position.distance_to(game.seal_fragments.get_node("Scenery").global_position) <= 2.6

func investigate() -> void:
	game.world_data[SAVE_KEY].investigated = true
	discover_regions()
	game.opening.seal_investigated()
	refresh_tracking(true)
	game._save_progress()

func grove_pending() -> bool:
	return is_instance_valid(grove_roots) and grove_roots.is_visible_in_tree() and game.lantern_lit and not game.completed and not game.world_data.get(GROVE_FLAG, false)

func can_investigate_grove() -> bool:
	return grove_pending() and game.player.global_position.distance_to(grove_point) <= 2.8

func investigate_grove() -> void:
	if not can_investigate_grove():
		return
	game.world_data[GROVE_FLAG] = true
	game._award_shards(game._grove_shard_reward())
	game._save_progress()

func grove_objective() -> Dictionary:
	if game.world_data.get(BEAR_FLAG, false):
		return game.awakening_quest()
	if game.world_data.get(GROVE_FLAG, false):
		return _row("The Cursed Bear", "Warm ash winds around the roots at Ancient Grove. A great beast has scored the stones.",
			"Defeat the Cursed Bear", 0, 1, "Unseal the cave altar.",
			"Enter the eastern cave. Beyond the relic, follow the bend and descend the hidden stone steps.", false)
	return _row("Investigate Ancient Grove", "The restored lantern reveals a trail of ash leading northeast into Ancient Grove.",
		"Search the roots", 0, 1, "Learn what feeds the curse.", "Follow the northeast trail to the ember-veined roots by the river.", false)

func recover(fragment: int) -> void:
	if fragment == 1:
		game.world_data[SAVE_KEY].fox_defeated = true
	if game.seal_fragments.recover(fragment):
		if game.seal_fragments.complete() and not game.lantern_lit:
			game.set_tracked_quest(LANTERN)
		else:
			refresh_tracking(false)

func discover_regions() -> bool:
	var regions: Array = game.world_data[SAVE_KEY].regions
	var position: Vector3 = game.player.global_position
	var changed := false
	for index in range(GUARDIANS.size()):
		var guardian: Dictionary = GUARDIANS[index]
		if index not in regions and not collected(index) and _distance(position, guardian.center) <= guardian.radius:
			regions.append(index)
			changed = true
	return changed

func collected(index: int) -> bool:
	return index in game.seal_fragments.collected_ids

func index_for(id: String) -> int:
	for index in range(GUARDIANS.size()):
		if GUARDIANS[index].id == id:
			return index
	return -1

func ids() -> Array[String]:
	var entries: Array[String] = []
	if revealed():
		for guardian in GUARDIANS:
			entries.append(guardian.id)
		entries.append(LANTERN)
	return entries

func can_track(id: String) -> bool:
	if id == LANTERN:
		return game.seal_fragments.complete() and not game.lantern_lit
	var index := index_for(id)
	return index >= 0 and revealed() and not collected(index)

func refresh_tracking(choose_guardian: bool) -> void:
	var current: String = game.tracked_quest
	if game.lantern_lit:
		if current == LANTERN or index_for(current) >= 0:
			game.set_tracked_quest("main")
	elif game.seal_fragments.complete():
		if current in ["", "main"] or index_for(current) >= 0:
			game.set_tracked_quest(LANTERN)
	elif revealed() and ((index_for(current) >= 0 and not can_track(current))
			or current == LANTERN or (choose_guardian and current in ["", "main"])):
		for index in range(GUARDIANS.size()):
			if not collected(index):
				game.set_tracked_quest(GUARDIANS[index].id)
				return
	elif not revealed() and (current == LANTERN or index_for(current) >= 0):
		game.set_tracked_quest("main")

func journal(id: String) -> Dictionary:
	if not revealed():
		return {}
	if id == "main" and game.lantern_lit:
		return game.awakening_quest() if game.completed else grove_objective()
	if id == "main":
		var count: int = game.seal_fragments.collected_ids.size()
		var task := "Defeat the guardians in any order." if count < 3 else "Restore the Northern Lantern."
		return _row(TITLE, DESCRIPTION, "Seal fragments %d/3" % count, count, 3,
			"Restore the Northern Lantern.", task, false)
	if id == LANTERN:
		var ready: bool = game.seal_fragments.complete()
		var lit: bool = game.lantern_lit
		var description := "The Northern Lantern stands at the northern ruins, beside the Ruins waystone."
		var step := "Recover all three fragments to unlock the lantern." if not ready else "Approach the Northern Lantern and use LIGHT / E."
		var result := _row("Restore the Northern Lantern", description,
			"Restored" if lit else "Seal complete" if ready else "Locked · requires 3/3 fragments",
			game.seal_fragments.collected_ids.size(), 3, "Restore the seal's light.",
			"Investigate Ancient Grove." if lit else step, lit)
		result["locked"] = not ready
		return result
	var index := index_for(id)
	if index < 0:
		return {}
	var guardian: Dictionary = GUARDIANS[index]
	var done := collected(index)
	return _row("Defeat the " + guardian.name, "Region · " + guardian.region + "\n" + guardian.trail,
		"Recover Fragment %d" % (index + 1), int(done), 1, "Seal Fragment %d" % (index + 1),
		"Fragment recovered." if done else "Search " + guardian.region + ".", done)

func hud(id: String) -> Dictionary:
	if game.lantern_lit:
		if game.completed or id not in ["", "main"]:
			return {}
		var goal := grove_objective()
		var message: String = goal.next
		if can_investigate_grove():
			message = "Interact to investigate the roots."
		return {"title": goal.title.to_upper(), "message": message, "progress": goal.objective}
	if not revealed():
		return {}
	var count: int = game.seal_fragments.collected_ids.size()
	if id == LANTERN and can_track(id):
		var position: Vector3 = game.player.global_position
		var point: Vector3 = game.lantern.global_position
		return {"title": "NORTHERN LANTERN", "message": "Head %s to the lantern." % _bearing(position, point)
			if _distance(position, point) > 14.0 else "Interact to restore the light.", "progress": "Seal fragments 3/3 · Ready"}
	var index := index_for(id)
	if index >= 0 and can_track(id):
		var guardian: Dictionary = GUARDIANS[index]
		var point := _target(index)
		var position: Vector3 = game.player.global_position
		var hint: String = "Defeat the " + guardian.name + "."
		if _distance(position, point) > 13.0:
			var direction := _bearing(position, point)
			hint = "Head %s to %s." % [direction, guardian.region] if not _discovered(index) else "Follow the %s marker." % direction
		elif not _discovered(index):
			hint = "Search " + guardian.region + "."
		return {"title": ("Defeat the " + guardian.name).to_upper(), "message": hint,
			"progress": "Fragment %d 0/1 · Seal %d/3" % [index + 1, count]}
	if id in ["", "main"]:
		return {"title": TITLE.to_upper(), "message": "Choose a guardian in the Journal.", "progress": "Seal fragments %d/3" % count}
	return {}

func markers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not revealed():
		return result
	for index in range(GUARDIANS.size()):
		if collected(index):
			continue
		var guardian: Dictionary = GUARDIANS[index]
		result.append({"id": guardian.id, "badge": str(index + 1), "point": _target(index),
			"radius": 0.0 if _discovered(index) else guardian.radius, "color": guardian.color,
			"tracked": game.tracked_quest == guardian.id})
	if can_track(LANTERN):
		result.append({"id": LANTERN, "badge": "L", "point": game.lantern.global_position,
			"radius": 0.0, "color": Color("fbdfa0"), "tracked": game.tracked_quest == LANTERN})
	elif grove_pending():
		result.append({"id": "main", "badge": "G", "point": grove_point, "radius": 0.0,
			"color": Color("fbdfa0"), "tracked": game.tracked_quest in ["", "main"]})
	return result

func _target(index: int) -> Vector3:
	var guardian: Dictionary = GUARDIANS[index]
	if _discovered(index):
		var actor: Node3D = game.get_node_or_null(guardian.actor)
		if is_instance_valid(actor):
			return actor.global_position
	return guardian.center

func _discovered(index: int) -> bool:
	return index in game.world_data[SAVE_KEY].regions

static func _distance(a: Vector3, b: Vector3) -> float:
	return Vector2(b.x - a.x, b.z - a.z).length()

static func _bearing(a: Vector3, b: Vector3) -> String:
	var direction := atan2(b.x - a.x, a.z - b.z)
	return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][posmod(roundi(direction / (PI / 4.0)), 8)]

static func _row(title: String, description: String, objective: String, value: int, total: int,
		reward: String, next: String, done: bool) -> Dictionary:
	return {"title": title, "description": description, "objective": objective, "value": value,
		"total": total, "reward": reward, "next": next, "done": done}
