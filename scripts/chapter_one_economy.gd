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

func _cost(level: int) -> int:
	return UPGRADE_COSTS[clampi(level, 0, UPGRADE_COSTS.size()-1)]

func _defeat_world_enemy(index: int) -> void:
	if index >= 0 and index < 5 and index not in world_data.cleared:
		_award_shards(WARG_SHARDS if index == CHAPTER_GUARDIANS.WARG_INDEX else WOLF_SHARDS)
	super._defeat_world_enemy(index)

func _defeat_fox() -> void:
	if not guardians.fox_defeated():
		_award_shards(FOX_SHARDS)
	super._defeat_fox()

func _boar_shard_reward() -> int:
	return BOAR_SHARDS

func _lantern_shard_reward() -> int:
	return NORTHERN_LANTERN_SHARDS

func _grove_shard_reward() -> int:
	return ANCIENT_GROVE_SHARDS

func _bear_victory() -> void:
	if not world_data.get(CHAPTER_GUARDIANS.BEAR_FLAG, false):
		world_data["bear_shards_paid"] = true
	super._bear_victory()

func _bear_shard_reward() -> int:
	return BEAR_SHARDS

func _chapter_shard_reward() -> int:
	# A legacy save between the Bear and the altar still has its full payout due.
	return CHAPTER_SHARDS if world_data.get("bear_shards_paid", false) == true else super._chapter_shard_reward()

func _store_action() -> Callable:
	return _show_store

func _show_store(feedback := "") -> void:
	if is_instance_valid(title_screen):
		title_screen.hide()
	var detail := "Tide Shards  %d\nHealing potions carried  %d\n\nA potion restores up to 50 health. The Store refills your pouch up to %d potions." % [
		shards, potions, STORE_POTION_LIMIT]
	var can_save := not progress_unreadable and (started or _has_valid_journey())
	if not can_save:
		detail += "\nStart or continue a valid journey to buy supplies."
	elif potions >= STORE_POTION_LIMIT:
		detail += "\nYour pouch is stocked."
	elif shards < POTION_PRICE:
		detail += "\nYou need %d more Tide Shards." % (POTION_PRICE-shards)
	if not feedback.is_empty():
		detail += "\n" + feedback
	_clear_menu("STORE", detail, false)
	_menu_button("Buy healing potion  ·  %d Tide Shards" % POTION_PRICE, _buy_potion,
		not can_save or potions >= STORE_POTION_LIMIT or shards < POTION_PRICE)
	_menu_button("Back to menu", _show_title)
	_style_pause_panel()
	menu_shade.color = Color("110c10")
	(menu_box.get_child(3) if menu_box.get_child(2).disabled else menu_box.get_child(2)).grab_focus()

func _buy_potion() -> void:
	if progress_unreadable or (not started and not _has_valid_journey()) or shards < POTION_PRICE or potions >= STORE_POTION_LIMIT:
		return
	shards -= POTION_PRICE
	potions += 1
	var saved_potions: int = world_data.potions
	world_data.potions = potions
	if not _save_progress(started):
		shards += POTION_PRICE
		potions -= 1
		world_data.potions = saved_potions
		_show_store("Purchase could not be saved. Your shards were restored.")
		return
	_show_store("Healing potion added.")
