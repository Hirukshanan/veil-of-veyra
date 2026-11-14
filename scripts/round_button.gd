extends Button

func _ready() -> void:
	add_to_group("gameplay_buttons")

func cancel_touch() -> void:
	# Reset BaseButton's captured press so a menu cannot leave a delayed release action.
	var was_disabled := disabled
	disabled = true
	disabled = was_disabled

func _has_point(point: Vector2) -> bool:
	var radius := minf(size.x, size.y) * 0.5
	return point.distance_squared_to(size * 0.5) <= radius * radius

# Icon-only controls retain a compact visual resource/hold indicator.
var meter := 0.0:
	set(value):
		meter = clampf(value,0.0,1.0)
		queue_redraw()

func _draw() -> void:
	if meter > 0.001:
		draw_arc(size*0.5,minf(size.x,size.y)*0.5-5,-PI/2,-PI/2+TAU*meter,40,Color(0.9,0.74,0.40),3,true)
