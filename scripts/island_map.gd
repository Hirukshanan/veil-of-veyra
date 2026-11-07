extends Control

const MAP = preload("res://scripts/island_exploration.gd")
var player_position := Vector3.ZERO
var player_heading := 0.0
var camps_cleared: Array[bool] = [true, true, true]
var bound_waystone := -1
var discovered: Array[bool] = [true, false, false]

func _ready() -> void:
	_fit_height()
	get_viewport().size_changed.connect(_fit_height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _point(world: Vector3) -> Vector2:
	var radius := minf(size.x, size.y) * 0.5 - 38.0
	return size * 0.5 + Vector2(world.x, world.z) * radius / 48.0

func _caption(at: Vector2, text: String, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, color)

func _draw() -> void:
	var center := size * 0.5
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var terrain = preload("res://scripts/island_terrain.gd")
	for base in [45.25, 33.0]:
		var outline := PackedVector2Array()
		for index in range(128):
			var angle := index * TAU / 128.0
			outline.append(_point(Vector3(cos(angle), 0, sin(angle)) * terrain.coast_radius(angle, base)))
		draw_colored_polygon(outline, Color(0.73, 0.64, 0.42) if base > 40 else Color(0.19, 0.31, 0.23))
	for peak in preload("res://scripts/mountain_rim.gd").PEAKS:
		var point := _point(Vector3(peak.x, 0, peak.y))
		draw_colored_polygon(PackedVector2Array([point + Vector2(0, -8), point + Vector2(-7, 5), point + Vector2(7, 5)]), Color(0.58, 0.62, 0.65))
	for route in terrain.trails():
		var line := PackedVector2Array()
		for point in route:
			line.append(_point(point))
		draw_polyline(line, Color(0.74, 0.65, 0.43), 4.0, true)
	for index in range(3):
		var camp: Vector3 = MAP.CAMPS[index]
		var spot := _point(camp)
		var color := Color(0.4, 0.95, 0.6) if camps_cleared[index] else Color(1, 0.3, 0.24)
		draw_circle(spot, 7, color)
		_caption(spot + (Vector2(14, 5) if index == 1 else Vector2(-25, -14)), ["West", "Forest", "Ruins"][index], Color.WHITE)
		var stone := _point(MAP.CHECKPOINTS[index])
		draw_rect(Rect2(stone - Vector2(5, 5), Vector2(10, 10)), Color.WHITE if bound_waystone == index else (Color(1, 0.78, 0.25) if discovered[index] else Color(0.4, 0.45, 0.48)))
		_caption(stone + Vector2(9, 5), str(index + 1), Color.WHITE)
	var keeper := _point(preload("res://scripts/shore_keeper.gd").HOME)
	draw_colored_polygon(PackedVector2Array([keeper + Vector2(0, -6), keeper + Vector2(6, 0), keeper + Vector2(0, 6), keeper + Vector2(-6, 0)]), Color(0.25, 0.65, 1.0))
	var hero := _point(player_position)
	var forward := Vector2(-sin(player_heading), -cos(player_heading))
	var right := Vector2(-forward.y, forward.x)
	draw_colored_polygon(PackedVector2Array([hero + forward * 10, hero - forward * 6 + right * 6, hero - forward * 6 - right * 6]), Color(0.3, 0.9, 1))
	_caption(Vector2(center.x - 5, 24), "N", Color.WHITE)
	_caption(Vector2(center.x - 22, size.y - 12), "BEACH", Color.WHITE)

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.13, 0.18)
	return style

func _fit_height() -> void:
	custom_minimum_size = Vector2(0, clampf(get_viewport().get_visible_rect().size.y - 220.0, 220.0, 440.0))
