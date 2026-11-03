extends RefCounted

const PATH := "user://campaign.cfg"
const BACKUP := PATH + ".bak"
const TEMP := PATH + ".tmp"
const DEFAULTS := {"chapter": 0, "shards": 0, "blade_level": 0, "armor_level": 0, "completed": false}
const MAXIMUMS := {"chapter": 2, "shards": 999999, "blade_level": 4, "armor_level": 4}

static func read_file(path: String) -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		return {"error": error}
	if not config.has_section_key("campaign", "chapter"):
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
	return {"error": OK, "data": data}

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
		return {"error": OK, "data": DEFAULTS.duplicate(), "recovered": false}
	return {"error": ERR_INVALID_DATA}

static func save_progress(data: Dictionary) -> Error:
	var config := ConfigFile.new()
	for key in DEFAULTS:
		config.set_value("campaign", key, data[key])
	var error := config.save(TEMP)
	if error != OK:
		return error
	if read_file(TEMP).error != OK:
		return ERR_INVALID_DATA
	# Preserve the last valid snapshot before promoting the complete new file.
	# If interrupted between renames, load_progress recovers the backup.
	if read_file(PATH).error == OK:
		error = DirAccess.rename_absolute(PATH, BACKUP)
		if error != OK:
			return error
	return DirAccess.rename_absolute(TEMP, PATH)
