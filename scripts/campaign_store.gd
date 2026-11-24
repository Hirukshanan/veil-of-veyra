extends RefCounted

const TERRAIN = preload("res://scripts/island_terrain.gd")

const PATH := "user://campaign.cfg"
const BACKUP := PATH + ".bak"
const TEMP := PATH + ".tmp"
const VERSION := 6
const OWNED_EQUIPMENT := "owned_equipment"
const EMBERSTEEL := 1
const THORNWARD := 2
const REINFORCED := 4
const TIDEWARDEN := "tidewarden_seals"
const DEFAULTS := {"shards": 0, "veil_gems": 0, "blade_level": 0, "armor_level": 0, "completed": false}
const MAXIMUMS := {"shards": 999999, "veil_gems": 999999, "blade_level": 4, "armor_level": 4}

static func fresh_world() -> Dictionary:
	return {"cleared": [], "herbs": [], "lantern": false, "position": Vector3(0,0,27), "health": 100, "potions": 3, "accepted": false, "reported": false, "bounty_reward": false, "grove_reward": false, "seal_fragments": [], OWNED_EQUIPMENT: 0}

static func valid_world(world: Variant, completed: bool, armor: int) -> bool:
	if not world is Dictionary:
		return false
	for key in fresh_world():
		if not world.has(key):
			return false
	for key in ["cleared", "herbs", "seal_fragments"]:
		var limit: int = {"cleared":6,"herbs":13,"seal_fragments":3}[key]
		if not world[key] is Array or world[key].size() > limit:
			return false
		var seen := []
		for value in world[key]:
			if not value is int or value < 0 or value >= limit or value in seen:
				return false
			seen.append(value)
	var owned: Variant = world.get(OWNED_EQUIPMENT, 0)
	if not owned is int or owned < 0 or owned > 7:
		return false
	var shrine_progress: Variant = world.get(TIDEWARDEN, 0)
	if not shrine_progress is int or shrine_progress < 0 or shrine_progress > 15:
		return false
	for id in 3:
		if (shrine_progress & (1 << id)) != 0 and id not in world.seal_fragments:
			return false
	for key in ["lantern", "accepted", "reported", "bounty_reward", "grove_reward"]:
		if not world[key] is bool:
			return false
	# Additive optional encounter flag: version-4 and earlier saves remain valid.
	# Optional v4 story flag. Earlier saves need no migration or new inventory.
	if not world.get("lantern_awakening", false) is bool:
		return false
	if not world.get("cursed_bear_defeated", false) is bool or (world.get("cursed_bear_defeated", false) and not world.get("ancient_grove_investigated", false)):
		return false
	if not world.get("ancient_grove_investigated", false) is bool or (world.get("ancient_grove_investigated", false) and not world.lantern):
		return false
	if world.get("lantern_awakening", false) and not completed:
		return false
	if not world.get("boar_defeated", false) is bool:
		return false
	for slot in ["blade_equipped", "armor_equipped"]:
		if not world.get(slot, true) is bool:
			return false
	if world.has("guardian_quest") and not _valid_guardian_quest(world.guardian_quest, world.seal_fragments):
		return false
	if not world.position is Vector3 or not world.position.is_finite() or world.position.y < -8 or world.position.y > 50:
		return false
	var flat := Vector2(world.position.x, world.position.z)
	var coast_limit := TERRAIN.coast_radius(flat.angle(), TERRAIN.SHALLOW_WATER_BASE)
	# Accept the old 92m save area for relocation on load, plus the new wading area.
	if flat.length() > maxf(92.0, coast_limit):
		return false
	if not world.health is int or world.health < 0 or world.health > 100 + armor * 25:
		return false
	if not world.potions is int or world.potions < 0 or world.potions > 16:
		return false
	if world.lantern and (world.seal_fragments.size() != 3 or (not world.has("guardian_quest") and world.cleared.size() != 6)):
		return false
	if completed and not world.lantern:
		return false
	if (world.reported and not world.accepted) or (world.bounty_reward and (not completed or not world.reported)):
		return false
	var grove_count := 0
	for id in world.herbs:
		if id >= 8:
			grove_count += 1
	if world.grove_reward and grove_count < 3:
		return false
	return true

static func _valid_guardian_quest(progress: Variant, fragments: Array) -> bool:
	if not progress is Dictionary or not progress.get("investigated") is bool or not progress.get("fox_defeated") is bool:
		return false
	for marker in ["foothill_marker", "central_east_markers"]:
		if not progress.get(marker, false) is bool:
			return false
	var regions: Variant = progress.get("regions")
	if not regions is Array or regions.size() > 3 or (progress.fox_defeated and 1 not in fragments):
		return false
	var seen := []
	for region in regions:
		if not region is int or region < 0 or region > 2 or region in seen:
			return false
		seen.append(region)
	return true

static func read_file(path: String) -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		return {"error": error}
	var version: Variant = config.get_value("campaign", "version", 1)
	if not version is int or version not in [1, 2, 3, 4, 5, VERSION]:
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
	# Existing lit lanterns remain lit; earlier versions had no fragment quest.
	if version < 4 and data.world_data is Dictionary:
		data.world_data = data.world_data.duplicate(true)
		data.world_data["seal_fragments"] = [0,1,2] if data.world_data.get("lantern",false) == true else []
	if version < 6 and data.world_data is Dictionary:
		data.world_data[OWNED_EQUIPMENT] = legacy_ownership(data)
	if not valid_world(data.world_data, data.completed, data.armor_level):
		return {"error": ERR_INVALID_DATA}
	data.world_data.erase("relics")
	data.world_data.erase("relic_reward")
	if version < 5:
		data.veil_gems = legacy_gem_credit(data.world_data, data.completed)
	# Earlier saves may contain the removed fast-travel state.
	data.world_data.erase("discovered")
	data.world_data.erase("checkpoint")
	return {"error": OK, "data": data, "migrated": version != VERSION}

static func legacy_ownership(data: Dictionary) -> int:
	# The shield was available to every existing journey before Store ownership.
	var owned := THORNWARD
	var equipped: Variant = data.world_data.get("modular_equipment", {})
	if not equipped is Dictionary:
		equipped = {}
	if data.blade_level >= 1 or equipped.get("blade") == 1:
		owned |= EMBERSTEEL
	if data.armor_level >= 1 or equipped.get("armor") == 1:
		owned |= REINFORCED
	return owned

static func legacy_gem_credit(world: Dictionary, completed: bool) -> int:
	# Older saves used index 2 for a normal wolf.
	var earned := int(world.has("guardian_quest") and 2 in world.cleared and 0 in world.seal_fragments)
	earned += int(world.get("guardian_quest", {}).get("fox_defeated", false))
	earned += int(world.get("boar_defeated", false))
	earned += 2 * int(world.get("cursed_bear_defeated", false))
	earned += int(completed)
	return earned

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
		config.set_value("campaign", key, data.get(key, DEFAULTS[key]))
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
