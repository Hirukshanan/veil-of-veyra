extends SceneTree
func _initialize():
 call_deferred("_run")
func _run():
 assert(OS.get_environment("VEYRA_TEST") == "1")
 var scene = load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene._show_journal()
 assert(not scene.journal_open, "Camp must not open an active hunt journal")
 scene._resume()
 scene.player._attack_buffer = 0.1
 var key := InputEventKey.new()
 key.physical_keycode = KEY_Q
 key.pressed = true
 Input.parse_input_event(key)
 await process_frame
 assert(scene.journal_open and paused)
 assert(scene.player._attack_buffer == 0, "Journal must clear queued combat")
 assert("remaining" in scene._journal_text() and "LOCKED" in scene._journal_text())
 scene._toggle_pause()
 assert(not paused and not scene.journal_open, "Escape must resume")
 scene.remaining_enemies = 0
 assert("READY" in scene._journal_text())
 scene.lantern_lit = true
 scene.boss_spawned = true
 assert("ACTIVE" in scene._journal_text())
 scene._pause_game()
 for button in scene.menu_box.get_children():
  if button is Button and button.text == "Quest Journal [Q]": button.pressed.emit()
 assert(scene.journal_open and paused, "Touch pause menu must open journal")
 scene._toggle_journal()
 assert(not paused)
 scene.game_finished = true
 scene._show_journal()
 assert(not scene.journal_open, "Ended hunts must not reopen journal")
 scene.queue_free()
 await process_frame
 await create_timer(0.4).timeout
 print("PASS: journal keyboard/menu access, objectives, pause/resume and combat guards")
 quit()
