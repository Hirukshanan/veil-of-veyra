extends Control

signal value_changed(value:Vector2)
signal sprint_requested(active:bool)
const SPRINT_HOLD:=.25
const AUTO_HOLD:=.45
var player
var _touch_index:=-1
var _value:=Vector2.ZERO
var _raw:=Vector2.ZERO
var _sprint_hold:=0.0
var _auto_hold:=0.0
var _requested:=false
var auto_sprint:=false
var _needs_neutral:=false

func _ready()->void:
	add_to_group("movement_joysticks");mouse_filter=Control.MOUSE_FILTER_STOP
	tooltip_text="Drag beyond the upper rim and hold to sprint. Drag farther up and hold for auto-sprint. Touch the stick again to stop."
	queue_redraw()

func reset()->void:
	_touch_index=-1;_raw=Vector2.ZERO;_needs_neutral=false
	_cancel_sprint();_set_value(Vector2.ZERO)

func _cancel_sprint()->void:
	_requested=false;auto_sprint=false;_sprint_hold=0;_auto_hold=0
	sprint_requested.emit(false);queue_redraw()

func _gui_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and _touch_index==-1:
			_cancel_sprint();_needs_neutral=false;_touch_index=event.index;_update_value(event.position)
		elif (not event.pressed or event.canceled) and event.index==_touch_index:_release(event.canceled)
		accept_event()
	elif event is InputEventScreenDrag and event.index==_touch_index:
		_update_value(event.position);accept_event()

func _input(event:InputEvent)->void:
	if _touch_index<0:return
	if event is InputEventScreenDrag and event.index==_touch_index:
		_update_value(get_global_transform_with_canvas().affine_inverse()*event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.index==_touch_index and (not event.pressed or event.canceled):
		_release(event.canceled);get_viewport().set_input_as_handled()

func _release(canceled:bool)->void:
	_touch_index=-1
	if auto_sprint and not canceled and is_instance_valid(player) and player.sprint_enabled:_set_value(Vector2.UP)
	else:reset()

func _update_value(point:Vector2)->void:
	_raw=(point-size*.5)/(minf(size.x,size.y)*.34)
	if _raw.y> -1.1 or absf(_raw.x)>.55:
		_cancel_sprint();_needs_neutral=false
	_set_value(_raw.limit_length(1))

func _process(delta:float)->void:
	if not is_instance_valid(player):return
	if player.health<=0 or not is_visible_in_tree():
		if _touch_index>=0 or auto_sprint:reset()
		return
	if _requested and not player.sprint_enabled:
		var was_auto:bool=auto_sprint;_cancel_sprint();_needs_neutral=true
		if was_auto and _touch_index<0:_set_value(Vector2.ZERO)
	if player.sprint_enabled:queue_redraw()
	if _touch_index<0 or _needs_neutral:return
	if _raw.y< -1.35 and absf(_raw.x)<.35:
		_sprint_hold+=delta
		if _sprint_hold>=SPRINT_HOLD and not _requested:
			sprint_requested.emit(true)
			_requested=player.sprint_enabled
			if not _requested:_needs_neutral=true
		if _raw.y< -1.95 and _requested:
			_auto_hold+=delta
			if _auto_hold>=AUTO_HOLD:auto_sprint=true
		else:_auto_hold=0
		queue_redraw()
	else:
		_sprint_hold=0;_auto_hold=0

func _notification(what:int)->void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:reset()

func _set_value(value:Vector2)->void:
	_value=value;value_changed.emit(value);queue_redraw()

func _draw()->void:
	var center:=size*.5;var radius:=minf(size.x,size.y)*.5-1
	var active:bool=is_instance_valid(player) and player.sprint_enabled
	var gold:=Color("e6ca84") if active else Color("ae9e78")
	draw_circle(center,radius,Color(.035,.05,.045,.62))
	draw_arc(center,radius,0,TAU,64,gold,2,true)
	draw_arc(center,radius*.91,0,TAU,64,Color(.77,.73,.54,.30),1,true)
	for i in range(4):
		var direction:=Vector2.UP.rotated(i*PI/2);var tangent:=direction.orthogonal();var tip:=center+direction*radius*.81
		draw_colored_polygon(PackedVector2Array([tip,tip-direction*9+tangent*4,tip-direction*9-tangent*4]),Color(.87,.83,.65,.5))
	var thumb:=center+_value*radius*.53
	draw_circle(thumb,radius*.32,Color(.47,.48,.40,.8))
	draw_arc(thumb,radius*.32,0,TAU,40,Color(.89,.84,.65,.8),1.5,true)
	if active:
		var stamina:float=player.stamina/100
		draw_arc(center,radius-5,-PI*.5,-PI*.5+TAU*stamina,48,gold,3,true)
		var text:="AUTO" if auto_sprint else "SPRINT"
		var font:=ThemeDB.fallback_font;var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		draw_string(font,center+Vector2(-width*.5,radius*.79),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,gold)
	elif _sprint_hold>0:
		draw_arc(center,radius-5,-PI*.85,-PI*.85+PI*.7*minf(1,_sprint_hold/SPRINT_HOLD),24,gold,3,true)
