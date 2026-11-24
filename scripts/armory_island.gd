extends "res://scripts/ancient_grove_review.gd"

const LEVEL_CAP := 4

func _ready() -> void:
	await super._ready()
	_initialize_title()

func _uses_title_screen() -> bool:
	return true

func _armory_action() -> Callable:
	return _open_armory

func _open_armory() -> void:
	title_screen.hide()
	var screen: CanvasLayer = load(_armory_screen_path()).new()
	screen.name = "Armory"
	screen.game = self
	screen.closed.connect(_show_title)
	add_child(screen)

func _armory_screen_path() -> String:
	return "res://scripts/modular_armory_screen.gd"

func _restore_world() -> void:
	super._restore_world()
	_apply_loadout()

func equipped(slot: String) -> bool:
	return world_data.get(slot + "_equipped", true)

func _apply_loadout() -> void:
	player.set_equipment_visuals(equipped("blade"), equipped("armor"))
	player.attack_damage = PLAYER_SCRIPT.blade_power(blade_level) if equipped("blade") else 0
	player.max_health = PLAYER_SCRIPT.armor_vitality(armor_level if equipped("armor") else 0)
	player.health = mini(player.health, player.max_health)
	_on_health_changed(player.health, player.max_health)

func gear_level(slot: String) -> int:
	return blade_level if slot == "blade" else armor_level

func equipment_locked() -> bool:
	return progress_unreadable

func change_gear(slot: String, upgrade: bool) -> String:
	if slot not in ["blade", "armor"] or equipment_locked():
		return "Equipment changes are unavailable."
	var level := gear_level(slot)
	var cost := _cost(level)
	if upgrade and (level >= LEVEL_CAP or shards < cost):
		return "Maximum level reached." if level >= LEVEL_CAP else "You need more Tide Shards."
	var previous_world := world_data.duplicate(true)
	var previous_health: int = player.health
	var previous_shards := shards
	if upgrade:
		shards -= cost
		if slot == "blade":
			blade_level += 1
		else:
			armor_level += 1
	else:
		world_data[slot + "_equipped"] = not equipped(slot)
	_apply_loadout()
	if upgrade and slot == "armor" and equipped("armor"):
		# Camp armor upgrades already refill health.
		player.health = player.max_health
		_on_health_changed(player.health, player.max_health)
	world_data.health = player.health
	if not _save_progress(started):
		world_data = previous_world
		shards = previous_shards
		if slot == "blade":
			blade_level = level
		else:
			armor_level = level
		player.health = previous_health
		_apply_loadout()
		return "Save failed. Your equipment and shards were restored."
	return "Upgrade saved." if upgrade else "Equipment saved."

func _upgrade(blade: bool) -> void:
	var result := change_gear("blade" if blade else "armor", true)
	notice = result
	_show_camp()
