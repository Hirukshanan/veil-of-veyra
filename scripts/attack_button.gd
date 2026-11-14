extends "res://scripts/round_button.gd"

signal tap_requested
signal heavy_requested
const HOLD_SECONDS := 0.4
var _pointer := -2
var _elapsed := 0.0
var _started_msec := 0
var _heavy_fired := false

func _ready() -> void:
	super._ready()
	add_to_group("attack_gestures")

func _gui_input(event: InputEvent) -> void:
	if disabled: return
	if event is InputEventScreenTouch:
		if event.pressed and _pointer == -2 and _has_point(event.position):
			_begin(event.index)
		elif not event.pressed and _pointer == event.index:
			_finish(_has_point(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _pointer == -2 and _has_point(event.position):
			_begin(-1)
		elif not event.pressed and _pointer == -1:
			_finish(_has_point(event.position))
	elif event is InputEventScreenDrag and _pointer == event.index:
		if not _has_point(event.position): cancel_hold()
	elif event is InputEventMouseMotion and _pointer == -1:
		if not _has_point(event.position): cancel_hold()

func _begin(pointer: int) -> void:
	if get_tree().paused: return
	_pointer = pointer
	_elapsed = 0.0
	_started_msec = Time.get_ticks_msec()
	_heavy_fired = false
	meter = 0.0

func _process(delta: float) -> void:
	if _pointer == -2: return
	if not is_visible_in_tree() or get_tree().paused:
		cancel_hold()
		return
	_elapsed += delta
	if not _heavy_fired:
		meter = _elapsed / HOLD_SECONDS
		if _elapsed >= HOLD_SECONDS:
			_heavy_fired = true
			meter = 0.0
			heavy_requested.emit()

func _finish(inside: bool) -> void:
	if _pointer == -2: return
	var held := maxf(_elapsed,float(Time.get_ticks_msec()-_started_msec)/1000.0)
	var fired := _heavy_fired
	cancel_hold()
	if not inside or get_tree().paused or fired: return
	if held >= HOLD_SECONDS:
		heavy_requested.emit()
	else:
		tap_requested.emit()

func cancel_hold() -> void:
	_pointer = -2
	_elapsed = 0.0
	_heavy_fired = false
	meter = 0.0
