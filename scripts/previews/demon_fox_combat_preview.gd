extends "res://scripts/main.gd"

const FOX := preload("res://scenes/enemies/demon_fox_combat.tscn")

var fox: CharacterBody3D

func _ready() -> void:
	_setup_input()
	_build_player()
	player.position = Vector3(0, .06, 2.2)
	player.rescue_position = player.position
	_build_hud()
	status_label.text = "DEMON FOX  •  COMBAT PREVIEW"
	find_child("ControlsHint", true, false).text = "Move: WASD   Attack: J   Heavy: H   Dodge: K   Guard: F"
	var reset := Button.new()
	reset.text = "Restart"
	reset.custom_minimum_size = Vector2(110, 44)
	reset.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	reset.offset_left = -142.0
	reset.offset_right = -24.0
	reset.offset_top = 23.0
	reset.pressed.connect(func(): get_tree().reload_current_scene())
	health_label.get_parent().add_child(reset)
	fox = FOX.instantiate()
	fox.position = Vector3(0, .06, -3.2)
	fox.rotation.y = PI
	fox.target = player
	fox.defeated.connect(func(): status_label.text = "DEMON FOX DEFEATED")
	add_child(fox)

func _on_player_defeated() -> void:
	game_finished = true
	status_label.text = "ARU HAS FALLEN  •  RESTART TO TRY AGAIN"
