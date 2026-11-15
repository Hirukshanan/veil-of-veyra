extends Control

const FIELDS:=["camera_sensitivity","hud_scale","invert_y","left_handed","camera_distance","sound_volume","shadows_enabled","frame_limit"]
const DEFAULTS:={"camera_sensitivity":1.0,"hud_scale":1.0,"invert_y":false,"left_handed":false,"camera_distance":6.3,"sound_volume":.7,"shadows_enabled":false,"frame_limit":30}
var scene
var back:Callable
var current_tab:="Controls"
var snapshot:Dictionary={}
var tabs:Dictionary={}
var sliders:Dictionary={}
var scroll:ScrollContainer
var cards:GridContainer
var status:Label
var save_button:Button
var cancel_button:Button
var reset_button:Button

class TouchScroll extends ScrollContainer:
	var pointer:=-1
	var start_y:=0.0
	var start_scroll:=0
	func _ready():mouse_filter=Control.MOUSE_FILTER_STOP
	func _gui_input(event:InputEvent):
		# Buttons/sliders consume their own presses. Only blank/label space bubbles here.
		if event is InputEventScreenTouch and event.pressed and not event.canceled and pointer<0:
			pointer=event.index;start_y=(get_global_transform_with_canvas()*event.position).y;start_scroll=scroll_vertical;accept_event()
	func _input(event:InputEvent):
		if event is InputEventScreenDrag and event.index==pointer:
			if absf(event.position.y-start_y)>8:scroll_vertical=start_scroll-roundi(event.position.y-start_y)
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and event.index==pointer and (not event.pressed or event.canceled):
			pointer=-1;get_viewport().set_input_as_handled()

class TouchSlider extends HSlider:
	var pointer:=-1
	func _gui_input(event:InputEvent):
		if event is InputEventScreenTouch:
			if event.pressed and not event.canceled and pointer<0:
				pointer=event.index;_at(event.position.x)
			accept_event()
	func _input(event:InputEvent):
		if event is InputEventScreenDrag and event.index==pointer:
			_at((get_global_transform_with_canvas().affine_inverse()*event.position).x)
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch and event.index==pointer and (not event.pressed or event.canceled):
			pointer=-1;get_viewport().set_input_as_handled()
	func _at(x:float):
		value=min_value+clampf((x-8)/maxf(1,size.x-16),0,1)*(max_value-min_value)

func _ready():
	for field in FIELDS:snapshot[field]=scene.get(field)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
	add_child(margin)
	var stack:=VBoxContainer.new();stack.add_theme_constant_override("separation",10);margin.add_child(stack)
	var title:=Label.new();title.text="SETTINGS";title.add_theme_font_override("font",preload("res://assets/ui/fonts/Cinzel.ttf"));title.add_theme_font_size_override("font_size",26);title.add_theme_color_override("font_color",Color("e6d3a2"));stack.add_child(title)
	var navigation:=HBoxContainer.new();navigation.add_theme_constant_override("separation",10);stack.add_child(navigation)
	for caption in ["Controls","Camera","Graphics & Sound"]:
		var button:=_button(caption,func():select_tab(caption));button.name=caption.replace(" & ","")+"Tab";button.toggle_mode=true;navigation.add_child(button);tabs[caption]=button
	scroll=TouchScroll.new();scroll.name="SettingsScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	cards=GridContainer.new();cards.name="SettingsCards";cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cards.add_theme_constant_override("h_separation",14);cards.add_theme_constant_override("v_separation",14);cards.mouse_filter=Control.MOUSE_FILTER_PASS;scroll.add_child(cards)
	status=Label.new();status.text=scene.camera_save_notice;status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",13);status.custom_minimum_size.y=18;stack.add_child(status)
	var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",12);stack.add_child(footer)
	reset_button=_button("Reset defaults",reset_defaults);reset_button.name="ResetSettingsButton";footer.add_child(reset_button)
	cancel_button=_button("Back without saving",cancel);cancel_button.name="CancelSettingsButton";footer.add_child(cancel_button)
	save_button=_button("Save and back",save);save_button.name="SaveSettingsButton";footer.add_child(save_button)
	resized.connect(_layout);_layout();select_tab(current_tab)

func _button(caption:String,action:Callable)->Button:
	var button:=Button.new();button.text=caption;button.custom_minimum_size.y=48;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",16)
	for state in ["normal","hover","pressed"]:
		var style:=StyleBoxFlat.new();style.bg_color=Color("34413c") if state=="pressed" else Color("172b2e");style.border_color=Color("ac9a6c");style.set_border_width_all(1);style.set_corner_radius_all(10);style.content_margin_left=12;style.content_margin_right=12;button.add_theme_stylebox_override(state,style)
	button.pressed.connect(action);return button

func _layout():
	if is_instance_valid(cards):cards.columns=2 if size.x>=1050 else 1

func _card(title:String)->VBoxContainer:
	var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.mouse_filter=Control.MOUSE_FILTER_PASS
	var style:=StyleBoxFlat.new();style.bg_color=Color("142427");style.border_color=Color("43534b");style.set_border_width_all(1);style.set_corner_radius_all(10)
	for side in ["left","right","top","bottom"]:style.set("content_margin_"+side,14)
	panel.add_theme_stylebox_override("panel",style);cards.add_child(panel)
	var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);body.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_child(body)
	var heading:=Label.new();heading.text=title;heading.add_theme_color_override("font_color",Color("e1c990"));heading.add_theme_font_size_override("font_size",18);heading.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(heading)
	return body

func _text(parent:Control,message:String):
	var text:=Label.new();text.text=message;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.add_theme_font_size_override("font_size",15);text.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(text)

func _slider(title:String,field:String,minimum:float,maximum:float,increment:float):
	var body:=_card(title);var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);body.add_child(row)
	var slider:=TouchSlider.new();slider.name=field+"Slider";slider.min_value=minimum;slider.max_value=maximum;slider.step=increment;slider.value=scene.get(field);slider.custom_minimum_size=Vector2(120,48);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(slider);sliders[field]=slider
	var value:=Label.new();value.custom_minimum_size.x=58;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;value.text="%.2f"%slider.value;value.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(value)
	slider.value_changed.connect(func(updated:float):
		value.text="%.2f"%updated;scene.set(field,updated);scene._apply_settings()
	)
	_text(body,"Swipe this card's title or empty space to scroll.")

func _toggle(title:String,field:String,help:String):
	var body:=_card(title);var toggle:=CheckButton.new();toggle.name="InvertYToggle" if field=="invert_y" else "ShadowsToggle";toggle.text="Enabled";toggle.button_pressed=scene.get(field);toggle.custom_minimum_size.y=48;body.add_child(toggle)
	toggle.toggled.connect(func(value:bool):scene.set(field,value);scene._apply_settings())
	_text(body,help)

func select_tab(caption:String):
	current_tab=caption;scroll.pointer=-1;scroll.scroll_vertical=0;sliders.clear()
	for child in cards.get_children():cards.remove_child(child);child.queue_free()
	for key in tabs:tabs[key].set_pressed_no_signal(key==caption)
	match caption:
		"Controls":
			_slider("Control size","hud_scale",.85,1.2,.05)
			var layout:=_card("HUD layout")
			_text(layout,"Current preset: "+scene.mobile_hud.profile.preset+". Move, resize and adjust opacity only in the HUD editor.")
			layout.add_child(_button("Customize HUD",_customize))
			var sprint:=_card("Upward sprint")
			_text(sprint,"Normal stick movement stays inside the ring. Drag beyond the upper rim and hold briefly to sprint. Gold ring and SPRINT confirm activation.")
			var auto:=_card("Deliberate auto-sprint")
			_text(auto,"Drag farther up and hold until AUTO appears, then release to continue. Touch the stick again to stop; moving it normally cancels sprint. Menus, focus loss, combat interruption or empty stamina cancel auto-sprint.")
		"Camera":
			_slider("Camera sensitivity","camera_sensitivity",.25,2,.05)
			_slider("Camera distance","camera_distance",4,9,.1)
			_toggle("Invert vertical look","invert_y","Affects normal touch and mouse camera look.")
			var pinch:=_card("Pinch zoom")
			_text(pinch,"Use two fingers on empty gameplay space. Spread them to move closer; pinch together to move farther. Joystick and combat touches remain separate. Camera collision stays enabled.")
		"Graphics & Sound":
			_slider("Sound volume","sound_volume",0,1,.05)
			var graphics:=_card("Frame limit")
			var choice:=OptionButton.new();choice.name="FrameLimitChoice";choice.add_item("30 FPS",30);choice.add_item("60 FPS",60);choice.select(0 if scene.frame_limit==30 else 1);choice.custom_minimum_size.y=48;graphics.add_child(choice)
			choice.item_selected.connect(func(index:int):scene.frame_limit=choice.get_item_id(index);scene._apply_settings())
			_text(graphics,"Choose a frame limit that feels smooth on your device.")
			_toggle("Nearby shadows","shadows_enabled","Optional quality setting. Leave off for the existing mobile baseline.")
			var sound:=_card("Sound preview");sound.add_child(_button("Preview sound",func():scene.player.play_sound("sword")))

func _customize():
	var owner_scene=scene;var destination:Callable=back
	owner_scene.mobile_hud.open_editor(func():owner_scene._show_settings(destination,"Controls"))

func reset_defaults():
	for field in DEFAULTS:scene.set(field,DEFAULTS[field])
	scene._apply_settings();select_tab(current_tab);status.text="Defaults previewed. Save to keep them; Back restores your previous settings."

func cancel():
	for field in snapshot:scene.set(field,snapshot[field])
	scene._apply_settings();back.call()

func save():
	if scene._save_settings()==OK:back.call()
	else:status.text="Settings could not be saved. Your previous file is safe. Try again or go back."

func _input(event:InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode==KEY_ESCAPE or event.keycode==KEY_ESCAPE):
		get_viewport().set_input_as_handled();cancel()

func _notification(what:int):
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		if is_instance_valid(scroll):scroll.pointer=-1
		for slider in sliders.values():
			if is_instance_valid(slider):slider.pointer=-1
