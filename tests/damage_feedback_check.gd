extends SceneTree
func _initialize():
 call_deferred("_run")
func _run():
 assert(OS.get_environment("VEYRA_TEST") == "1")
 var world := Node3D.new()
 root.add_child(world)
 var enemy = load("res://scripts/enemy.gd").new()
 world.add_child(enemy)
 enemy.set_physics_process(false)
 enemy.take_damage(1)
 var numbers = get_nodes_in_group("damage_numbers")
 assert(numbers.size() == 1 and numbers[0].text == "1")
 enemy.take_damage(999)
 await process_frame
 numbers = get_nodes_in_group("damage_numbers")
 assert(numbers.size() == 2 and numbers[1].text == "2", "Finishing hit shows remaining health and survives victim removal")
 paused = true
 await create_timer(0.8, true).timeout
 assert(get_nodes_in_group("damage_numbers").size() == 2, "Feedback must freeze during menus")
 paused = false
 await create_timer(0.8).timeout
 assert(get_nodes_in_group("damage_numbers").is_empty(), "Feedback must clean up")
 var boss = load("res://scripts/boss.gd").new()
 world.add_child(boss)
 boss.set_physics_process(false)
 boss.take_damage(0)
 assert(get_nodes_in_group("damage_numbers").is_empty())
 boss.take_damage(3)
 assert(get_nodes_in_group("damage_numbers")[0].text == "3")
 for i in range(30):
  load("res://scripts/damage_number.gd").show_hit(boss, 1, 3.0)
 assert(get_nodes_in_group("damage_numbers").size() == 24, "Crowd feedback must stay bounded")
 world.queue_free()
 await process_frame
 assert(get_nodes_in_group("damage_numbers").is_empty())
 print("PASS: damage values, lethal persistence, pause, expiry, boss and crowd limit")
 quit()
