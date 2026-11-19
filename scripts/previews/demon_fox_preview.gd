extends Node3D

const CLIP_ORDER := ["Idle", "Walk", "Run", "Alert", "Bite", "Quick Leap", "Hit Reaction", "Death"]
const VIEWS := [Vector3(-3.15, 1.59, -1.81), Vector3(-3.7, 1.10, 0), Vector3(-.35, 1.39, -3.8)]

@onready var _camera: Camera3D = $Camera
@onready var _clips: OptionButton = $Interface/Panel/Controls/Clips

var _player: AnimationPlayer
var _view_index := 0

func _ready() -> void:
	_player = $Fox.find_children("*", "AnimationPlayer", true, false).front() as AnimationPlayer
	for clip in CLIP_ORDER:
		if _player.has_animation(clip):
			_clips.add_item(clip)
	_clips.item_selected.connect(_play)
	$Interface/Panel/Controls/Replay.pressed.connect(func(): _play(_clips.selected))
	$Interface/Panel/Controls/View.pressed.connect(_change_view)
	_place_camera()
	_play(0)

func _play(index: int) -> void:
	if index < 0 or index >= _clips.item_count:
		return
	_player.stop()
	_player.play(_clips.get_item_text(index))

func _change_view() -> void:
	_view_index = (_view_index + 1) % VIEWS.size()
	_place_camera()

func _place_camera() -> void:
	_camera.position = VIEWS[_view_index]
	_camera.look_at(Vector3(0, .47, -.03))
