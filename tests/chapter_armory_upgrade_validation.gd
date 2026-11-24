extends "res://tests/chapter_armory_check.gd"

var screen: CanvasLayer

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		output = args[0]
	Input.emulate_mouse_from_touch = true
	root.size = Vector2i(1280, 720)
	var seed := SAVE.DEFAULTS.duplicate()
	seed.shards = 32
	seed.blade_level = 1
	seed.armor_level = 1
	seed.world_data = SAVE.fresh_world()
	seed.world_data[SAVE.OWNED_EQUIPMENT] = SAVE.REINFORCED | SAVE.EMBERSTEEL
	assert(SAVE.save_progress(seed) == OK)
	await open_game()
	await open_armory()

	for category in [2, 0]:
		await tap(screen.tabs[category])
		await tap(screen.choices[1])
		var slot := "armor" if category == 2 else "blade"
		assert(game._cost(1) == 36)
		for starting_balance in [32, 35, 36, 40]:
			seed_attempt(starting_balance)
			var primary_before := FileAccess.get_file_as_bytes(SAVE.PATH)
			var backup_before := FileAccess.get_file_as_bytes(SAVE.BACKUP)
			var attack_before: int = game.player.attack_damage
			var health_before: int = game.player.max_health
			assert(not screen.upgrade_button.disabled)
			assert("36 Tide Shards" in screen.cost_text.text)
			await tap(screen.upgrade_button)
			var successful: bool = starting_balance >= 36
			var expected_balance: int = starting_balance - 36 if successful else starting_balance
			var expected_level := 2 if successful else 1
			assert(game.shards == expected_balance and game.gear_level(slot) == expected_level)
			assert(screen.balance.shard_label.text == str(expected_balance))
			var saved: Dictionary = SAVE.load_progress().data
			var level_key := "armor_level" if slot == "armor" else "blade_level"
			assert(saved.shards == expected_balance and saved[level_key] == expected_level)
			if successful:
				assert(screen.status.text == "Upgrade Successful · Level 2 · 36 Tide Shards spent")
				assert(game.player.attack_damage == attack_before + int(slot == "blade"))
				assert(game.player.max_health == health_before + 25 * int(slot == "armor"))
			else:
				assert(screen.status.text == "Insufficient Tide Shards")
				assert(game.player.attack_damage == attack_before and game.player.max_health == health_before)
				assert(FileAccess.get_file_as_bytes(SAVE.PATH) == primary_before)
				assert(FileAccess.get_file_as_bytes(SAVE.BACKUP) == backup_before)
			print("PASS ", slot, " ", starting_balance, "/36 -> ", screen.status.text,
				"; balance ", game.shards, "; level ", game.gear_level(slot))
			if category == 2 and starting_balance == 32:
				await capture("Armor_32_of_36_1280x720")
				root.size = Vector2i(1600, 738)
				await frames(6)
				await capture("Armor_32_of_36_1600x738")
			if category == 2 and starting_balance == 40:
				await capture("Armor_40_of_36_1600x738")
				var again_before := FileAccess.get_file_as_bytes(SAVE.PATH)
				screen.upgrade_button.pressed.emit()
				assert(screen.status.text == "Insufficient Tide Shards" and game.armor_level == 2 and game.shards == 4)
				assert(FileAccess.get_file_as_bytes(SAVE.PATH) == again_before)
				await tap(screen.choices[0])
				assert(screen.status.text.is_empty())
		await tap(screen.tabs[1])
		assert(screen.status.text.is_empty())

	# Both upgrades would be affordable in this fixture, so the rapid tap
	# check proves the debounce, independently of the balance guard.
	await tap(screen.tabs[2])
	await tap(screen.choices[1])
	seed_attempt(150)
	screen.upgrade_button.pressed.emit()
	for _tap in 12:
		screen.upgrade_button.pressed.emit()
	assert(game.shards == 114 and game.armor_level == 2 and game._cost(2) == 74)
	assert(SAVE.load_progress().data.armor_level == 2)
	screen._close()
	await frames(3)
	await open_game()
	assert(game.armor_level == 2 and game.blade_level == 1 and game.shards == 114)
	assert(game.player.max_health == 150)
	await open_armory()
	game.armor_level = game.LEVEL_CAP
	assert(game._save_progress(false))
	await tap(screen.tabs[2])
	var capped := FileAccess.get_file_as_bytes(SAVE.PATH)
	assert(screen.upgrade_button.disabled and not screen.cost_row.visible)
	screen.upgrade_button.pressed.emit()
	assert(game.armor_level == game.LEVEL_CAP and game.shards == 114)
	assert(FileAccess.get_file_as_bytes(SAVE.PATH) == capped)
	print("PASS immediate retry, feedback ownership, rapid taps with enough funds, scene reload and max-level save integrity")
	game.queue_free()
	await frames(5)
	quit()

func open_armory() -> void:
	game.title_screen.find_child("Armory", true, false).pressed.emit()
	await frames(7)
	screen = game.get_node("Armory")

func seed_attempt(amount: int) -> void:
	game.shards = amount
	game.blade_level = 1
	game.armor_level = 1
	game._apply_loadout()
	game.world_data.health = game.player.health
	assert(game._save_progress(false))
	screen.upgrade_after = 0
	screen._refresh()
