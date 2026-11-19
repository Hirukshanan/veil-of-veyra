extends RefCounted

static func draw(canvas: Control, at: Vector2, marker: Dictionary, size: float, pixels_per_meter: float) -> void:
	var color: Color = marker.color
	var radius: float = marker.radius * pixels_per_meter
	if radius > 0.0:
		canvas.draw_circle(at, radius, Color(color, .14))
		canvas.draw_arc(at, radius, 0, TAU, 24, Color(color, .70 if marker.tracked else .42), 1, true)
	if marker.tracked:
		canvas.draw_arc(at, size + 2.3, 0, TAU, 20, Color("fff0c5"), 1.4, true)
	canvas.draw_circle(at, size + 1.0, Color("222320"))
	canvas.draw_circle(at, size, color)
	var font := ThemeDB.fallback_font
	var pixels := maxi(8, roundi(size * 1.44))
	var bounds := font.get_string_size(marker.badge, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pixels)
	canvas.draw_string(font, at + Vector2(-bounds.x * .5, font.get_ascent(pixels) - bounds.y * .5),
		marker.badge, HORIZONTAL_ALIGNMENT_LEFT, -1.0, pixels, Color("1f211e"))
