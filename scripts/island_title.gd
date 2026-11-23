extends "res://scripts/campaign.gd"

const HOME_ART := preload("res://assets/ui/brand/homepg_veil_of_vera.png")

enum Entry { TITLE, CAMP, PLAY }

const ENTRY_KEY := &"veil_title_entry"
var title_screen: CanvasLayer
var continue_button: Button
var new_game_button: Button
var starting_new_game := false

func _initialize_title() -> void:
	if not _uses_title_screen():
		return
	var entry: int = get_tree().get_meta(ENTRY_KEY, Entry.TITLE)
	get_tree().remove_meta(ENTRY_KEY)
	match entry:
		Entry.PLAY:
			_resume()
		Entry.CAMP:
			started = true
			_show_camp()
		_:
			_build_title()
			_show_title()

func _show_camp() -> void:
	if started or not _uses_title_screen():
		super._show_camp()
	elif is_instance_valid(title_screen):
		_show_title()
	else:
		get_tree().paused = true

func _uses_title_screen() -> bool:
	return false

func _armory_action() -> Callable:
	return Callable()

func _clear_menu(title: String, message: String, save_world := true) -> void:
	super._clear_menu(title, message, save_world and (started or not _uses_title_screen()))

func _quit_world() -> void:
	if started or not _uses_title_screen():
		super._quit_world()
	else:
		get_tree().quit()

func _build_title() -> void:
	title_screen = CanvasLayer.new()
	title_screen.name = "TitleScreen"
	title_screen.layer = 20
	title_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(title_screen)
	var backdrop := ColorRect.new()
	backdrop.color = Color("11131b")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(backdrop)
	var fit := AspectRatioContainer.new()
	fit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fit.ratio = float(HOME_ART.get_width()) / HOME_ART.get_height()
	fit.stretch_mode = AspectRatioContainer.STRETCH_FIT
	backdrop.add_child(fit)
	var art := TextureRect.new()
	art.name = "HomeArtwork"
	art.texture = HOME_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fit.add_child(art)

	# The supplied artwork includes the labels. The controls share its fitted rectangle.
	continue_button = _title_button(art, "Continue", Rect2(127, 272, 362, 79), _continue_journey)
	new_game_button = _title_button(art, "New Game", Rect2(127, 371, 362, 67), _new_journey)
	_title_button(art, "Armory", Rect2(127, 459, 362, 68), _armory_action())
	_title_button(art, "Store", Rect2(127, 547, 362, 68))
	_title_button(art, "Settings", Rect2(127, 635, 362, 68), _open_title_settings)
	_title_button(art, "About", Rect2(127, 724, 362, 69), _open_title_about)

func _title_button(art: TextureRect, caption: String, bounds: Rect2, action := Callable()) -> Button:
	var button := Button.new()
	button.name = caption.replace(" ", "")
	button.accessibility_name = caption
	button.disabled = not action.is_valid()
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for style in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("f6bf6ba6")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(6)
	button.add_theme_stylebox_override("focus", focus)
	art.add_child(button)
	var image_size := HOME_ART.get_size()
	button.anchor_left = bounds.position.x / image_size.x
	button.anchor_top = bounds.position.y / image_size.y
	button.anchor_right = bounds.end.x / image_size.x
	button.anchor_bottom = bounds.end.y / image_size.y
	if action.is_valid():
		button.pressed.connect(action)
	return button

func _show_title() -> void:
	_close_settings()
	overlay.hide()
	title_screen.show()
	continue_button.disabled = not _has_valid_journey()
	var focus := continue_button if not continue_button.disabled else new_game_button
	focus.grab_focus()

func _has_valid_journey() -> bool:
	return CAMPAIGN_STORE.read_file(CAMPAIGN_STORE.PATH).error == OK or CAMPAIGN_STORE.read_file(CAMPAIGN_STORE.BACKUP).error == OK

func _open_title_settings() -> void:
	title_screen.hide()
	_show_settings(_show_title)

func _open_title_about() -> void:
	title_screen.hide()
	_show_art_credits()
	var heading := menu_box.get_child(0) as Label
	heading.text = "ABOUT"
	var back := menu_box.get_child(menu_box.get_child_count() - 1) as Button
	back.text = "Back to title"

func _continue_journey() -> void:
	title_screen.hide()
	_resume()

func _new_journey() -> void:
	title_screen.hide()
	if FileAccess.file_exists(CAMPAIGN_STORE.PATH) or FileAccess.file_exists(CAMPAIGN_STORE.BACKUP):
		_clear_menu("BEGIN A NEW JOURNEY?", "A new game replaces your active island progress, shards and upgrades.", false)
		_menu_button("Keep my journey", _show_title)
		_menu_button("Start new game", _reset_world)
	else:
		_reset_world()

func _reset_world() -> void:
	if not started:
		# Retries from the inherited save-error screen also enter the new journey.
		starting_new_game = true
	super._reset_world()
	starting_new_game = false

func _reload() -> void:
	if _uses_title_screen():
		get_tree().set_meta(ENTRY_KEY, Entry.PLAY if starting_new_game else (Entry.CAMP if started else Entry.TITLE))
	super._reload()
