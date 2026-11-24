extends "res://scripts/armory_island.gd"

const EQUIPMENT := preload("res://scripts/aru_modular_equipment.gd")

var modular: EQUIPMENT

func _armory_screen_path() -> String:
	return "res://scripts/modular_armory_screen.gd"

func _apply_loadout() -> void:
	super._apply_loadout()
	if not is_instance_valid(modular):
		modular = EQUIPMENT.new()
		modular.name = "ModularEquipment"
		player.add_child(modular)
		modular.bind_hero(player)
	modular.apply(gear_selection())

func owns_gear(slot: String, option: int) -> bool:
	if option < 0 or (slot != "shield" and option == 0):
		return true
	var bit: int = {"blade": CAMPAIGN_STORE.EMBERSTEEL, "shield": CAMPAIGN_STORE.THORNWARD,
		"armor": CAMPAIGN_STORE.REINFORCED}.get(slot, 0)
	return (world_data.get(CAMPAIGN_STORE.OWNED_EQUIPMENT, 0) & bit) != 0

func gear_selection() -> Dictionary:
	var stored: Variant = world_data.get("modular_equipment", {})
	if not stored is Dictionary:
		stored = {}
	return {
		"blade": 1 if equipped("blade") and owns_gear("blade", 1) and stored.get("blade") == 1 else (0 if equipped("blade") else -1),
		"shield": 0 if stored.get("shield") == 0 and owns_gear("shield", 0) else -1,
		"armor": 1 if equipped("armor") and owns_gear("armor", 1) and stored.get("armor") == 1 else (0 if equipped("armor") else -1),
	}

func select_gear(slot: String, option: int) -> String:
	if equipment_locked() or not slot in ["blade","shield","armor"] or not option in [-1,0,1]:
		return "Equipment changes are unavailable."
	if slot == "shield" and option == 1:
		return "Shield unavailable."
	if not owns_gear(slot, option):
		return "Purchase this equipment in the Store."
	var previous := world_data.duplicate(true)
	var previous_health: int = player.health
	var selection := gear_selection()
	selection[slot] = option
	world_data["modular_equipment"] = selection
	if slot != "shield":
		world_data[slot + "_equipped"] = option >= 0
	_apply_loadout()
	world_data.health = player.health
	if not _save_progress(started):
		world_data = previous
		player.health = previous_health
		_apply_loadout()
		return "Save failed. Your loadout was restored."
	return "Loadout saved."
