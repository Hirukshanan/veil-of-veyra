extends SceneTree

const STORE = preload("res://scripts/campaign_store.gd")
const BOAR = preload("res://scripts/demon_boar.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	for file in [STORE.PATH, STORE.BACKUP, STORE.TEMP]:DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	scene.player.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):enemy.set_physics_process(false)
	var boar = scene.get_node("DemonBoar")
	assert(scene.remaining_enemies == 5 and scene.get_node_or_null("CampDemon5") == null)
	assert(get_nodes_in_group("combat_enemies").filter(func(enemy):return enemy.get_script() == BOAR).size() == 1)
	assert(boar.position.is_equal_approx(BOAR.SPAWN))
	var hero = scene.player
	hero.health = 100
	hero._invulnerability_time = 0.0
	hero.dodge()
	hero.take_charge_damage(18, Vector3.FORWARD)
	assert(hero.health == 100 and hero._charge_knockback == Vector3.ZERO, "Real dodge i-frames prevent damage and knockback")
	hero._invulnerability_time = 0.0
	hero.take_charge_damage(18, Vector3.FORWARD)
	assert(hero.health == 82 and is_equal_approx(hero._charge_knockback.length(), 4.0))
	hero._dodge_cooldown = 0.0
	hero.dodge()
	assert(hero._charge_knockback == Vector3.ZERO, "A fresh dodge restores full directional control")
	var old_world := STORE.fresh_world()
	assert(STORE.valid_world(old_world, false, 0), "Legacy save without an encounter flag remains valid")
	old_world["boar_defeated"] = "bad"
	assert(not STORE.valid_world(old_world, false, 0))
	var shards: int = scene.shards
	boar.take_damage(1000)
	assert(scene.shards == shards + 20 and scene.world_data.boar_defeated and scene.remaining_enemies == 5)
	scene._defeat_boar()
	assert(scene.shards == shards + 20, "Boar rewards must be issued once")
	assert(STORE.load_progress().data.world_data.boar_defeated)
	scene.queue_free()
	await process_frame
	await process_frame
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.get_node_or_null("DemonBoar") == null and scene.remaining_enemies == 5)
	assert(scene.shards == shards + 20 and scene.get_node_or_null("CampDemon5") == null)
	scene.queue_free()
	paused = false
	await process_frame
	print("PASS: one optional boar, real dodge/knockback, backward-compatible flag, one-time reward, reload persistence and unchanged camp/retired-wolf IDs")
	quit()
