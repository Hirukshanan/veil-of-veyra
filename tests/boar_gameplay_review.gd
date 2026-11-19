extends SceneTree

# Scripted review in the actual campaign scene, using an isolated test profile.
# HUD signals exercise existing action bindings; this is not a physical-touch test.
var scene
var boar
var hero
var review_case := "dodge"
var frames := 0
var ready_for_review := false
var dodged := false
var heavy_used := false
var sword_used := false
var trace: Array[Dictionary] = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--case="):review_case = argument.trim_prefix("--case=")
	call_deferred("setup")

func setup() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	assert(OS.get_environment("APPDATA").replace("\\", "/").contains("/.validation/phase3_3_"), "Use a dedicated review profile")
	for file in ["user://campaign.cfg", "user://campaign.cfg.bak", "user://campaign.cfg.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	scene = preload("res://tests/legacy_campaign_fixture.gd").instantiate()
	root.add_child(scene)
	await process_frame
	hero = scene.player
	boar = scene.get_node("DemonBoar")
	for enemy in get_nodes_in_group("combat_enemies"):
		if enemy != boar:enemy.set_physics_process(false)
	hero.global_position = boar.global_position + Vector3(0, 0.02, 2.0 if review_case == "defeat" else 5.0)
	hero.rotation.y = 0.0
	hero._camera_pivot.rotation = Vector3(0, -0.4 if review_case != "dodge" else 0.0, 0)
	hero._camera_pivot.global_position = hero.global_position + Vector3.UP * 1.2
	if review_case == "defeat":
		# Equivalent to the existing maximum blade upgrade; boar HP remains 24.
		scene.blade_level = 4
		hero.attack_damage = 5
	scene._resume()
	ready_for_review = true
	process_frame.connect(tick)

func tick() -> void:
	if not ready_for_review:return
	# An offscreen capture window can lose focus; keep this test replay running.
	if paused:scene._resume()
	frames += 1
	if review_case == "dodge" and not dodged and boar.state == boar.State.WARNING and boar._elapsed > 1.35:
		get_nodes_in_group("movement_joysticks")[0].call("_set_value", Vector2.RIGHT)
		scene.find_child("DodgeButton", true, false).pressed.emit()
		dodged = true
	if dodged and hero._dodge_time <= 0.0:
		get_nodes_in_group("movement_joysticks")[0].call("reset")
	if review_case == "defeat":
		if frames > 8 and not heavy_used:
			scene.find_child("AttackButton", true, false).heavy_requested.emit()
			heavy_used = true
		elif heavy_used and not sword_used and boar.health <= 4:
			var offset: Vector3 = boar.global_position - hero.global_position
			offset.y = 0.0
			if offset.length() > 1.7:
				var local := offset.normalized().rotated(Vector3.UP, -hero._camera_pivot.rotation.y)
				get_nodes_in_group("movement_joysticks")[0].call("_set_value", Vector2(local.x, local.z))
			else:
				get_nodes_in_group("movement_joysticks")[0].call("reset")
				if hero._attack_cooldown <= 0.0:
					scene.find_child("AttackButton", true, false).tap_requested.emit()
					sword_used = true
	if frames % 10 == 0:
		trace.append({"frame":frames,"boar_state":boar.state,"boar_health":boar.health,"hero_health":hero.health,"hero_position":hero.global_position,"boar_position":boar.global_position,"shards":scene.shards})
	var maximum := 225 if review_case == "dodge" else (195 if review_case == "hit" else 180)
	if frames >= maximum:
		var result := {"case":review_case,"hero_health":hero.health,"boar_health":boar.health,"boar_state":boar.state,"dodged":dodged,"heavy_used":heavy_used,"sword_used":sword_used,"shards":scene.shards,"boar_saved":scene.world_data.get("boar_defeated",false),"trace":trace}
		var file := FileAccess.open("user://boar_" + review_case + "_review.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "  "))
		print("BOAR_ACTUAL_GAMEPLAY_REVIEW ", JSON.stringify(result))
		quit()
