extends "res://scripts/shrine_review.gd"

const INTRO_FLAG := "bear_awakening_seen"
const ARENA_THRESHOLD := -4.8
var bear_intro: Node3D

func _ready() -> void:
	bear_intro = preload("res://scripts/bear_awakening.gd").new()
	bear_intro.name = "BearAwakening"
	add_child(bear_intro)
	bear_intro.completed.connect(_finish_intro)
	await super._ready()

func _update_bear_encounter() -> void:
	if not shrine.in_cell or _sanctum_open(): return
	if not is_instance_valid(cave_bear):
		cave_bear = _create_cave_bear()
		cave_bear.position = SHRINE.LAIR
		cave_bear.rotation.y = -.13
		cave_bear.health_changed.connect(_bear_health_changed)
		cave_bear.defeated.connect(_bear_victory,CONNECT_ONE_SHOT)
		add_child(cave_bear)
	if introduced or bear_intro.active or player.position.z < ARENA_THRESHOLD or player.position.y > 35.1: return
	if world_data.get(INTRO_FLAG,false):
		_start_bear_combat()
	else:
		bear_intro.start(player,cave_bear)

func _create_cave_bear() -> CharacterBody3D:
	return load(BEAR_SCENE).instantiate()

func _finish_intro() -> void:
	world_data[INTRO_FLAG] = true
	_start_bear_combat()
	_save_progress()

func _start_bear_combat() -> void:
	introduced = true
	cave_bear.target = player
	cave_bear._play("Idle_Breathing_Loop")
	cave_bear._enter(cave_bear.State.RECOVER,1.0)
	cave_bear.set_physics_process(true)
	_bear_health_changed(cave_bear.health,cave_bear.MAX_HEALTH)

func _toggle_pause() -> void:
	if bear_intro.active:
		bear_intro.skip()
	else:
		super._toggle_pause()

func _toggle_journal() -> void:
	if not bear_intro.active: super._toggle_journal()

func _interact_world() -> void:
	if not bear_intro.active: super._interact_world()
