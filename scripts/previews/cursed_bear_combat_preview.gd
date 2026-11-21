extends "res://scripts/main.gd"

const BEAR := preload("res://scenes/enemies/cursed_bear_boss.tscn")

var bear: CharacterBody3D

func _ready() -> void:
	_setup_input()
	_build_player()
	player.set_collision_mask_value(2, true)
	player.position = Vector3(0, .06, 2.2)
	player.rescue_position = player.position
	_build_hud()
	status_label.text = "CURSED BEAR  •  COMBAT PREVIEW"
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
	bear = BEAR.instantiate()
	bear.position = Vector3(0, .06, -6.8)
	bear.rotation.y = PI
	bear.target = player
	bear.defeated.connect(func(): status_label.text = "CURSED BEAR DEFEATED")
	bear.health_changed.connect(_boss_health)
	add_child(bear)
	_boss_health(bear.health, bear.MAX_HEALTH)

func _boss_health(value: int, maximum: int) -> void:
	status_label.text = "CURSED BEAR  %d / %d%s" % [value, maximum, "  •  RAGE" if value > 0 and value * 100 <= maximum * 40 else ""]

func _on_player_defeated() -> void:
	game_finished = true
	status_label.text = "ARU HAS FALLEN  •  RESTART TO TRY AGAIN"

