extends Control

# Safe rects are in physical display pixels; canvas_items UI uses logical units.
var test_safe_rect := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(refresh)
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(refresh)
	add_child(timer)
	timer.start()
	refresh()

static func logical_rect(safe_pixels: Rect2, screen_transform: Transform2D, viewport_rect: Rect2) -> Rect2:
	if not safe_pixels.has_area():
		return viewport_rect
	var safe := (screen_transform.affine_inverse() * safe_pixels).intersection(viewport_rect)
	return safe if safe.has_area() else viewport_rect

func refresh() -> void:
	var bounds := get_viewport().get_visible_rect()
	var safe := bounds
	if test_safe_rect.has_area():
		safe = test_safe_rect.intersection(bounds)
	elif OS.has_feature("android") or OS.has_feature("ios"):
		safe = logical_rect(Rect2(DisplayServer.get_display_safe_area()), get_viewport().get_screen_transform(), bounds)
	position = safe.position
	size = safe.size
