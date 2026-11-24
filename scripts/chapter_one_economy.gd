extends "res://scripts/modular_equipment_review.gd"

const UPGRADE_COSTS := [16, 36, 74, 120]
const WOLF_SHARDS := 4
const WARG_SHARDS := 20
const FOX_SHARDS := 24
const BOAR_SHARDS := 28
const NORTHERN_LANTERN_SHARDS := 12
const ANCIENT_GROVE_SHARDS := 8
const BEAR_SHARDS := 38
const CHAPTER_SHARDS := 42
const POTION_PRICE := 8
const STORE_POTION_LIMIT := 5
const STORE_SCREEN := preload("res://scripts/chapter_store_screen.gd")
const STORE_ITEMS := [
	{"name":"Healing Potion", "category":0, "price":POTION_PRICE, "bit":0, "art":"potion",
		"copy":"Restores up to 50 health."},
	{"name":"Embersteel Sword", "category":1, "price":20, "bit":CAMPAIGN_STORE.EMBERSTEEL, "art":"blade",
		"copy":"A forged embersteel blade. Shares your weapon upgrades."},
	{"name":"Thornward Shield", "category":1, "price":15, "bit":CAMPAIGN_STORE.THORNWARD, "art":"shield",
		"copy":"Bronze-bound oak with a thorn engraving. Uses your existing guard."},
	{"name":"Reinforced Ranger Armor", "category":1, "price":20, "bit":CAMPAIGN_STORE.REINFORCED, "art":"armor",
		"copy":"Fitted plates for Aru’s Ranger Outfit. Shares your armor upgrades."},
]

func _cost(level: int) -> int:
	return UPGRADE_COSTS[clampi(level, 0, UPGRADE_COSTS.size()-1)]

func _defeat_world_enemy(index: int) -> void:
	if index >= 0 and index < 5 and index not in world_data.cleared:
		_award_shards(WARG_SHARDS if index == CHAPTER_GUARDIANS.WARG_INDEX else WOLF_SHARDS)
		if index == CHAPTER_GUARDIANS.WARG_INDEX:
			_award_veil_gems(1)
	super._defeat_world_enemy(index)

func _defeat_fox() -> void:
	if not guardians.fox_defeated():
		_award_shards(FOX_SHARDS)
		_award_veil_gems(1)
	super._defeat_fox()

func _defeat_boar() -> void:
	if not world_data.get("boar_defeated", false):
		_award_veil_gems(1)
	super._defeat_boar()

func _boar_shard_reward() -> int:
	return BOAR_SHARDS

func _lantern_shard_reward() -> int:
	return NORTHERN_LANTERN_SHARDS

func _grove_shard_reward() -> int:
	return ANCIENT_GROVE_SHARDS

func _bear_victory() -> void:
	if not world_data.get(CHAPTER_GUARDIANS.BEAR_FLAG, false):
		world_data["bear_shards_paid"] = true
		_award_veil_gems(2)
	super._bear_victory()

func _finish_bear_chapter() -> void:
	if not completed and world_data.get(CHAPTER_GUARDIANS.BEAR_FLAG, false):
		_award_veil_gems(1)
	super._finish_bear_chapter()

func _bear_shard_reward() -> int:
	return BEAR_SHARDS

func _chapter_shard_reward() -> int:
	# A legacy save between the Bear and the altar still has its full payout due.
	return CHAPTER_SHARDS if world_data.get("bear_shards_paid", false) == true else super._chapter_shard_reward()

func _store_action() -> Callable:
	return _open_store.bind(false)

func _pause_store_action() -> Callable:
	return _open_store.bind(true)

func _toggle_pause() -> void:
	var store := get_node_or_null("StoreScreen")
	if is_instance_valid(store):
		store.close()
		return
	super._toggle_pause()

func _open_store(in_game: bool) -> void:
	if has_node("StoreScreen"):
		return
	if is_instance_valid(title_screen):
		title_screen.hide()
	overlay.hide()
	var screen := STORE_SCREEN.new()
	screen.name = "StoreScreen"
	screen.game = self
	screen.closed.connect(_pause_game if in_game else _show_title)
	add_child(screen)

func store_owns(item: Dictionary) -> bool:
	return item.bit != 0 and (world_data.get(CAMPAIGN_STORE.OWNED_EQUIPMENT, 0) & item.bit) != 0

func buy_store_item(index: int) -> String:
	if index < 0 or index >= STORE_ITEMS.size():
		return "Item unavailable"
	if progress_unreadable or (not started and not _has_valid_journey()):
		return "Start or continue a valid journey to purchase supplies"
	var item: Dictionary = STORE_ITEMS[index]
	if store_owns(item):
		return "Already owned"
	var is_potion: bool = item.bit == 0
	if is_potion and potions >= STORE_POTION_LIMIT:
		return "Potion pouch is full"
	if shards < item.price:
		return "Insufficient Tide Shards"

	var previous_world := world_data.duplicate(true)
	var previous_potions := potions
	shards -= item.price
	if is_potion:
		potions += 1
		world_data.potions = potions
	else:
		world_data[CAMPAIGN_STORE.OWNED_EQUIPMENT] |= item.bit
	if not _save_progress(started):
		shards += item.price
		potions = previous_potions
		world_data = previous_world
		return "Purchase could not be saved"
	return "Purchase Successful"
