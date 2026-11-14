extends SceneTree

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 assert(OS.get_environment("VEYRA_TEST") == "1")
 var scene = load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene._resume()
 var hero = scene.player
 hero.set_physics_process(false)
 for enemy in get_nodes_in_group("combat_enemies"):
  enemy.set_physics_process(false)
 hero._attack_cooldown = 0.3
 hero.attack()
 assert(hero._attack_buffer == 0, "Early presses must not queue a future attack")
 hero._attack_cooldown = 0.1
 hero.combo_step = 1
 hero._combo_window = 0.6
 hero.attack()
 hero.attack()
 assert(hero.combo_step == 1, "Buffered input must not immediately advance combo")
 hero._physics_process(0.11)
 assert(hero.combo_step == 2 and hero._attack_buffer == 0, "Repeated presses must queue only one next swing")
 hero._physics_process(0.4)
 assert(hero.combo_step == 2, "One buffered press must not repeat indefinitely")
 hero._attack_cooldown = 0.1
 hero.attack()
 hero.dodge()
 assert(hero._attack_buffer == 0, "Dodge must clear queued input")
 hero._attack_cooldown = 0.1
 hero.attack()
 hero._invulnerability_time = 0
 hero.take_damage(1)
 assert(hero._attack_buffer == 0, "Damage must clear queued input")
 hero._attack_cooldown = 0.1
 hero.attack()
 scene._show_camp()
 assert(hero._attack_buffer == 0, "Menus must clear queued input")
 hero.attack()
 assert(hero._attack_buffer == 0, "Paused input must not queue attacks")
 scene._resume()
 hero.cancel_swing()
 await create_timer(0.4).timeout
 scene.queue_free()
 await process_frame
 await create_timer(0.4).timeout
 print("PASS: late input, early rejection, one buffered swing, dodge/damage/menu cancellation")
 quit()
