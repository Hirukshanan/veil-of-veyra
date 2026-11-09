extends RefCounted

const PATH := "user://campaign.cfg"
const BACKUP := PATH + ".bak"
const TEMP := PATH + ".tmp"
const VERSION := 3
const DEFAULTS := {"shards": 0, "blade_level": 0, "armor_level": 0, "completed": false}
const MAXIMUMS := {"shards": 999999, "blade_level": 4, "armor_level": 4}

static func fresh_world() -> Dictionary:
	return {"cleared": [], "herbs": [], "relics": [], "discovered": [true,false,false], "checkpoint": -1, "lantern": false, "position": Vector3(0,0,27), "health": 100, "potions": 3, "accepted": false, "reported": false, "relic_reward": false, "bounty_reward": false, "grove_reward": false}

static func valid_world(world: Variant, completed: bool, armor: int) -> bool:
	if not world is Dictionary:
		return false
	for key in fresh_world():
		if not world.has(key):
			return false
	for key in ["cleared", "herbs", "relics"]:
		var limit: int = {"cleared":6,"herbs":13,"relics":3}[key]
		if not world[key] is Array or world[key].size() > limit:
			return false
		var seen := []
		for value in world[key]:
			if not value is int or value < 0 or value >= limit or value in seen:
				return false
			seen.append(value)
	if not world.discovered is Array or world.discovered.size() != 3:
		return false
	for value in world.discovered:
		if not value is bool:
			return false
	if not world.discovered[0] or not world.checkpoint is int or world.checkpoint < -1 or world.checkpoint > 2:
		return false
	if world.checkpoint >= 0 and not world.discovered[world.checkpoint]:
		return false
	for key in ["lantern", "accepted", "reported", "relic_reward", "bounty_reward", "grove_reward"]:
		if not world[key] is bool:
			return false
	if not world.position is Vector3 or not world.position.is_finite() or Vector2(world.position.x,world.position.z).length() > 92 or world.position.y < -8 or world.position.y > 50:
		return false
	if not world.health is int or world.health < 0 or world.health > 100 + armor * 25:
		return false
	if not world.potions is int or world.potions < 0 or world.potions > 16:
		return false
	if (world.lantern and world.cleared.size() != 6) or (completed and not world.lantern):
		return false
	if (world.reported and not world.accepted) or (world.relic_reward and (not completed or world.relics.size() != 3)) or (world.bounty_reward and (not completed or not world.reported)):
		return false
	var grove_count := 0
	for id in world.herbs:
		if id >= 8:
			grove_count += 1
	if world.grove_reward and grove_count < 3:
		return false
	return true

static func read_file(path: String) -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		return {"error": error}
	var version: Variant = config.get_value("campaign", "version", 1)
	if not version is int or version not in [1, 2, VERSION]:
		return {"error": ERR_INVALID_DATA}
	var data := {}
	for key in DEFAULTS:
		var value: Variant = config.get_value("campaign", key, DEFAULTS[key])
		if key == "completed":
			if not value is bool:
				return {"error": ERR_INVALID_DATA}
		elif not value is int or value < 0 or value > MAXIMUMS[key]:
			return {"error": ERR_INVALID_DATA}
		data[key] = value
	if version == 1:
		var chapter: Variant = config.get_value("campaign", "chapter", -1)
		if not chapter is int or chapter < 0 or chapter > 2:
			return {"error": ERR_INVALID_DATA}
		data.world_data = fresh_world()
		data.world_data.health = 100 + data.armor_level * 25
		# Old saves did not contain current-hunt state; retain economy and completion.
		if data.completed:
			data.world_data.cleared = [0,1,2,3,4,5]
			data.world_data.lantern = true
	else:
		data.world_data = config.get_value("campaign", "world", {})
		if version == 2 and data.world_data is Dictionary:
			data.world_data = data.world_data.duplicate(true)
			data.world_data["grove_reward"] = false
	if not valid_world(data.world_data, data.completed, data.armor_level):
		return {"error": ERR_INVALID_DATA}
	return {"error": OK, "data": data, "migrated": version != VERSION}

static func load_progress() -> Dictionary:
	var primary := read_file(PATH)
	if primary.error == OK:
		primary["recovered"] = false
		return primary
	var backup := read_file(BACKUP)
	if backup.error == OK:
		backup["recovered"] = true
		return backup
	if primary.error == ERR_FILE_NOT_FOUND and backup.error == ERR_FILE_NOT_FOUND:
		var data := DEFAULTS.duplicate()
		data.world_data = fresh_world()
		return {"error": OK, "data": data, "recovered": false, "migrated": false}
	return {"error": ERR_INVALID_DATA}

static func save_progress(data: Dictionary) -> Error:
	var config := ConfigFile.new()
	config.set_value("campaign", "version", VERSION)
	for key in DEFAULTS:
		config.set_value("campaign", key, data[key])
	config.set_value("campaign", "world", data.world_data)
	var error := config.save(TEMP)
	if error != OK:
		return error
	if read_file(TEMP).error != OK:
		return ERR_INVALID_DATA
	if read_file(PATH).error == OK:
		error = DirAccess.rename_absolute(PATH, BACKUP)
		if error != OK:
			return error
	return DirAccess.rename_absolute(TEMP, PATH)
