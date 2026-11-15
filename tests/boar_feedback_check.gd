extends SceneTree

var cues: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	assert(OS.get_environment("VEYRA_TEST") == "1")
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._resume()
	var hero = scene.player
	hero.set_physics_process(false)
	for enemy in get_nodes_in_group("combat_enemies"):
		enemy.set_physics_process(false)
		enemy.position = Vector3(20, 0, 20)
	var boar = scene.get_node("DemonBoar")
	var feedback = boar._feedback
	feedback.cue_played.connect(func(cue: String, _channel: int): cues.append(cue))
	assert(feedback.voices.size() == 3)
	for voice in feedback.voices:
		assert(voice is AudioStreamPlayer3D and voice.max_polyphony == 1 and voice.bus == &"Master")
		assert(voice.max_distance <= 26.0 and voice.max_db <= 0)
	for cue in feedback.CUES.values():
		assert(cue[0].get_length() > 0 and cue[0].get_length() < 2.0 and cue[0].loop_mode == AudioStreamWAV.LOOP_DISABLED)
	# Footstep events require actual grounded motion, and are culled beyond hearing range.
	for flags in [[false, true, true], [true, false, true], [true, true, false]]:
		feedback.sync_pose("run", 0.29, 0.02, flags[0], flags[1], flags[2])
	assert(cues.is_empty())
	feedback.sync_pose("run", 0.29, 0.02, true, true, true)
	assert(cues.size() == 1 and cues[0].begins_with("hoof_"))
	cues.clear()
	# A real upgraded NORMAL swing must remain a light hit even at damage 5.
	hero.global_position = boar.SPAWN + Vector3(0, 0, 1.5)
	hero.rotation = Vector3.ZERO
	boar.global_position = boar.SPAWN
	boar.rotation = Vector3.ZERO
	boar._enter(boar.State.IDLE)
	hero.attack_damage = 5
	await physics_frame
	await physics_frame
	hero.attack()
	await create_timer(0.25, false, true).timeout
	assert(boar.health == 19 and cues.count("hit_light") == 1 and not "hit_heavy" in cues)
	# Heavy context is explicit, with the existing 4x damage and stagger preserved.
	hero.cancel_swing()
	hero._attack_cooldown = 0
	hero.attack_damage = 1
	boar._enter(boar.State.WARNING)
	cues.clear()
	hero.heavy_attack()
	await create_timer(0.75, false, true).timeout
	assert(boar.health == 15 and cues.count("hit_heavy") == 1 and not "hit_light" in cues)
	assert(boar.state == boar.State.HURT and not boar._warning.visible)
	assert(hero.stamina == 60 and hero.spirit == 50)
	# Feedback has no collision or residual geometry; spam stays bounded.
	for index in range(6):feedback.strike(hero.global_position, false)
	assert(feedback._sparks.size() <= 2)
	await create_timer(0.3, false, true).timeout
	for spark in feedback._sparks:assert(not is_instance_valid(spark))
	var hurt_count := cues.count("hurt")
	feedback.cue("hurt")
	feedback.cue("hurt")
	assert(cues.count("hurt") <= hurt_count + 1, "Vocal restarts are rate limited")
	# Existing Master mute remains authoritative; the controller never overrides it.
	AudioServer.set_bus_mute(0, true)
	feedback.cue("warning")
	assert(AudioServer.is_bus_mute(0))
	AudioServer.set_bus_mute(0, false)
	scene.queue_free()
	await process_frame
	# Let the audio mixer release the fixture voices before the test process exits.
	await create_timer(.25,true,false,true).timeout
	print("PASS: bounded spatial audio, authored grounded footsteps, distance gating, explicit normal/heavy contact, unchanged damage/stagger/stamina/spirit, short bounded effects and Master mute")
	quit()
