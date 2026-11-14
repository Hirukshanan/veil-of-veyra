extends CanvasLayer

const TITLE=preload("res://assets/ui/fonts/Cinzel.ttf")
const GOLD:=Color("d0ba80")
var controller
var back: Callable
var draft: Dictionary
var selected := "AttackButton"
var root_ui: Control
var preview: Control
var footer: Array[Panel]=[]
var header: Label
var status: Label
var selection: OptionButton
var size_slider: HSlider
var opacity_slider: HSlider
var scale_label: Label
var opacity_label: Label
var preset_buttons: Array[Button]=[]
var save_button: Button
var cancel_button: Button
var reset_button: Button
var _field_rect: Rect2

class PresetCard extends Button:
	var preset := "Battle"
	var chosen := false
	func _draw():
		var mirrored:=preset=="Left-Handed"
		var movement:=Vector2(size.x*(0.77 if mirrored else 0.23),31)
		var actions:=Vector2(size.x*(0.27 if mirrored else 0.73),33)
		draw_arc(movement,12,0,TAU,24,Color("bcaf8a"),1,true)
		draw_circle(movement,4,Color("999b88"))
		for p in [Vector2.ZERO,Vector2(-12,12),Vector2(-2,-14),Vector2(-16,-4)]: draw_arc(actions+p,5 if p!=Vector2.ZERO else 8,0,TAU,20,Color("bcaf8a"),1,true)
		var label: String=preset
		var pixels:=11 if size.x<90 else 14
		var font:=ThemeDB.fallback_font
		var width:=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels).x
		draw_string(font,Vector2((size.x-width)*0.5,size.y-12),label,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,Color("f4e6c9"))
		if chosen:
			draw_circle(Vector2(size.x-12,12),7,Color("e2bd66"))
			draw_polyline(PackedVector2Array([Vector2(size.x-15,12),Vector2(size.x-12,15),Vector2(size.x-8,9)]),Color("202520"),2,true)

class Preview extends Control:
	var editor
	var pointer := -2
	var resizing := false
	var drag_offset := Vector2.ZERO
	func _draw(): editor.draw_preview(self)
	func _gui_input(event: InputEvent):
		var at:=Vector2.ZERO
		var down:=false
		var release:=false
		var motion:=false
		var index: int=-1
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			at=event.position
			down=event.pressed
			release=not event.pressed
		elif event is InputEventMouseMotion:
			at=event.position
			motion=true
		elif event is InputEventScreenTouch:
			at=event.position
			down=event.pressed and not event.canceled
			release=not event.pressed or event.canceled
			index=event.index
		elif event is InputEventScreenDrag:
			at=event.position
			index=event.index
			motion=true
		else: return
		if down and pointer==-2:
			var rects: Dictionary=editor.preview_rects()
			var active: Rect2=rects[editor.selected]
			resizing=at.distance_to(active.end)<18
			if not resizing:
				var hit: String=""
				for key in editor.controller.MOVABLE:
					var rect: Rect2=rects[key]
					if at.distance_to(rect.get_center())<=maxf(20,rect.size.x*0.5): hit=key
				if hit.is_empty(): return
				editor.select_control(hit)
				active=rects[hit]
			pointer=index
			drag_offset=at-active.get_center()
			accept_event()
		elif pointer==index and release:
			pointer=-2
			accept_event()
		elif pointer==index and motion:
			if resizing:
				var rects: Dictionary=editor.preview_rects()
				var rect: Rect2=rects[editor.selected]
				var old: float=editor.draft.controls.get(editor.selected,{}).get("scale",1.0)
				var diameter:=maxf(24,(at-rect.get_center()).length()*1.414)
				editor.change_value("scale",clampf(old*diameter/rect.size.x,0.75,1.5))
			else: editor.move_control(at-drag_offset)
			accept_event()

func _ready() -> void:
	draft=controller.profile.duplicate(true)
	root_ui=preload("res://scripts/safe_area.gd").new()
	root_ui.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(root_ui)
	var tint:=ColorRect.new()
	tint.color=Color(0.015,0.025,0.027,0.20)
	tint.mouse_filter=Control.MOUSE_FILTER_IGNORE
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(tint)
	header=_label(root_ui,"CUSTOMIZE HUD",22)
	preview=Preview.new()
	preview.name="HUDPreview"
	preview.editor=self
	preview.mouse_filter=Control.MOUSE_FILTER_STOP
	root_ui.add_child(preview)
	for title in ["CONTROL CUSTOMIZATION","CONTROL PRESETS","LAYOUT CHECK"]:
		var panel:=Panel.new()
		panel.add_theme_stylebox_override("panel",_style(Color(0.045,0.061,0.063,0.96)))
		root_ui.add_child(panel)
		var caption:=_label(panel,title,16)
		caption.position=Vector2(14,12)
		footer.append(panel)
	selection=OptionButton.new()
	selection.name="SelectedControl"
	for key in controller.MOVABLE: selection.add_item(controller.display_name(key))
	selection.item_selected.connect(func(index: int): select_control(controller.MOVABLE[index]))
	footer[0].add_child(selection)
	scale_label=_label(footer[0],"Size",13,false)
	opacity_label=_label(footer[0],"Opacity",13,false)
	size_slider=_slider(footer[0],"HUDScaleSlider",0.75,1.5,func(value: float): change_value("scale",value))
	opacity_slider=_slider(footer[0],"HUDOpacitySlider",0.25,1.0,func(value: float): change_value("opacity",value))
	for preset in ["Battle","Classic","Left-Handed"]:
		var button:=PresetCard.new()
		button.preset=preset
		button.add_theme_stylebox_override("normal",_style(Color("182326")))
		button.add_theme_stylebox_override("hover",_style(Color("34403b")))
		button.add_theme_stylebox_override("pressed",_style(Color("5c5034")))
		button.pressed.connect(func(): choose_preset(preset))
		footer[1].add_child(button)
		button.name="Preset"+preset.replace("-","")
		button.tooltip_text=preset
		button.accessibility_name=preset+" control preset"
		preset_buttons.append(button)
	status=_label(footer[2],"",13,false)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.max_lines_visible=3
	reset_button=_button(footer[2],"Reset layout",reset_layout)
	reset_button.name="ResetHUDButton"
	save_button=_button(root_ui,"Save layout",save_layout)
	save_button.name="SaveHUDButton"
	cancel_button=_button(root_ui,"Cancel",func(): back.call())
	cancel_button.name="CancelHUDButton"
	root_ui.resized.connect(_layout)
	_layout()
	_sync()

func _style(background: Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=background
	style.border_color=Color(0.8,0.71,0.48,0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style

func _label(parent: Node, text: String, pixels: int, title:=true) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_color_override("font_color",GOLD if title else Color("e5e7dc"))
	label.add_theme_font_size_override("font_size",pixels)
	if title: label.add_theme_font_override("font",TITLE)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button:=Button.new()
	button.text=text
	button.clip_text=true
	button.add_theme_font_size_override("font_size",14)
	button.add_theme_color_override("font_color",Color("f5e8c9"))
	button.add_theme_stylebox_override("normal",_style(Color("182326")))
	button.add_theme_stylebox_override("hover",_style(Color("34403b")))
	button.add_theme_stylebox_override("pressed",_style(Color("5c5034")))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _slider(parent: Node, node_name: String, minimum: float, maximum: float, callback: Callable) -> HSlider:
	var slider:=HSlider.new()
	slider.name=node_name
	slider.accessibility_name="Control opacity" if node_name=="HUDOpacitySlider" else "Control size"
	slider.min_value=minimum
	slider.max_value=maximum
	slider.step=0.05
	slider.value_changed.connect(callback)
	parent.add_child(slider)
	return slider

func _layout() -> void:
	var bounds:=root_ui.size
	var bottom:=clampf(bounds.y*0.28,160,210)
	header.position=Vector2(20,15)
	cancel_button.position=Vector2(bounds.x-252,10)
	cancel_button.size=Vector2(100,36)
	save_button.position=Vector2(bounds.x-142,10)
	save_button.size=Vector2(122,36)
	preview.position=Vector2(18,56)
	preview.size=Vector2(bounds.x-36,bounds.y-bottom-72)
	var width: float=(bounds.x-56)/3
	for i in range(3):
		footer[i].position=Vector2(16+i*(width+12),bounds.y-bottom-10)
		footer[i].size=Vector2(width,bottom)
		footer[i].get_child(0).add_theme_font_size_override("font_size",14 if width<300 else 17)
	selection.position=Vector2(14,43)
	selection.size=Vector2(width-28,30)
	scale_label.position=Vector2(14,82)
	size_slider.position=Vector2(82,77)
	size_slider.size=Vector2(width-98,30)
	opacity_label.position=Vector2(14,120)
	opacity_slider.position=Vector2(82,115)
	opacity_slider.size=Vector2(width-98,30)
	for i in range(3):
		preset_buttons[i].position=Vector2(12+i*(width-16)/3,46)
		preset_buttons[i].size=Vector2((width-28)/3,86)
		preset_buttons[i].add_theme_font_size_override("font_size",12 if width<300 else 16)
	status.position=Vector2(14,44)
	status.size=Vector2(width-28,bottom-100)
	reset_button.position=Vector2(14,bottom-48)
	reset_button.size=Vector2(width-28,34)
	preview.queue_redraw()

func _actual_bounds() -> Vector2:
	return controller.control("MovementJoystick").get_parent().size

func _preview_transform() -> Transform2D:
	var bounds:=_actual_bounds()
	var factor:=minf(preview.size.x/bounds.x,preview.size.y/bounds.y)
	return Transform2D(Vector2(factor,0),Vector2(0,factor),(preview.size-bounds*factor)*0.5)

func preview_rects() -> Dictionary:
	var rects: Dictionary=controller.rectangles(_actual_bounds(),draft)
	var transform:=_preview_transform()
	var result: Dictionary={}
	for key in controller.MOVABLE: result[key]=transform*rects[key]
	return result

func select_control(key: String) -> void:
	selected=key
	_sync()

func change_value(key: String, value: float) -> void:
	if not draft.controls.has(selected): draft.controls[selected]={}
	draft.controls[selected][key]=value
	_sync()

func move_control(point: Vector2) -> void:
	var at:=_preview_transform().affine_inverse()*point
	var bounds:=_actual_bounds()
	var rects: Dictionary=controller.rectangles(bounds,draft)
	var half: Vector2=rects[selected].size*0.5+Vector2.ONE*8
	at=at.clamp(half,bounds-half)
	if not draft.controls.has(selected): draft.controls[selected]={}
	draft.controls[selected].x=at.x/bounds.x
	draft.controls[selected].y=at.y/bounds.y
	_sync()

func choose_preset(preset: String) -> void:
	draft={"preset":preset,"controls":{}}
	_sync()

func reset_layout() -> void:
	choose_preset("Battle")

func _sync() -> void:
	if not is_instance_valid(selection): return
	selection.select(controller.MOVABLE.find(selected))
	var entry: Dictionary=draft.controls.get(selected,{})
	size_slider.set_value_no_signal(float(entry.get("scale",1.0)))
	opacity_slider.set_value_no_signal(float(entry.get("opacity",0.82)))
	scale_label.text="Size %d%%" % int(size_slider.value*100)
	opacity_label.text="Opacity"
	opacity_slider.tooltip_text="%d%%" % int(opacity_slider.value*100)
	var issue: String=controller.layout_error(draft,_actual_bounds())
	status.text="Drag to move. Corner handle resizes.\nChanges apply only after Save." if issue.is_empty() else issue+"\nMove or resize before saving."
	status.add_theme_color_override("font_color",Color("d4d8c9") if issue.is_empty() else Color("f2ad87"))
	for i in range(3):
		var preset: String=["Battle","Classic","Left-Handed"][i]
		preset_buttons[i].chosen=draft.preset==preset
		if not preset_buttons[i].has_meta("selected_preset") or preset_buttons[i].get_meta("selected_preset")!=(draft.preset==preset):
			var style:=_style(Color("383527") if draft.preset==preset else Color("182326"))
			style.set_border_width_all(2 if draft.preset==preset else 1)
			preset_buttons[i].add_theme_stylebox_override("normal",style)
			preset_buttons[i].set_meta("selected_preset",draft.preset==preset)
		preset_buttons[i].queue_redraw()
	preview.queue_redraw()

func save_layout() -> void:
	var issue: String=controller.layout_error(draft,_actual_bounds())
	if not issue.is_empty():
		status.text=issue+"\nMove or resize before saving."
		return
	var error: Error=controller.save_profile(draft)
	if error!=OK:
		status.text="Layout could not be saved. Your previous layout is safe. Try again."
		return
	back.call()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		back.call()

func draw_preview(canvas: Control) -> void:
	var transform:=_preview_transform()
	var bounds:=_actual_bounds()
	var frame:=transform*Rect2(Vector2.ZERO,bounds)
	canvas.draw_rect(frame,Color(0.02,0.03,0.035,0.35))
	canvas.draw_rect(frame,Color(0.68,0.63,0.46,0.6),false,1)
	for x in range(int(frame.position.x),int(frame.end.x),32): canvas.draw_line(Vector2(x,frame.position.y),Vector2(x,frame.end.y),Color(0.7,0.75,0.7,0.055),1)
	for y in range(int(frame.position.y),int(frame.end.y),32): canvas.draw_line(Vector2(frame.position.x,y),Vector2(frame.end.x,y),Color(0.7,0.75,0.7,0.055),1)
	var rects:=preview_rects()
	for key in controller.MOVABLE:
		var rect: Rect2=rects[key]
		var center:=rect.get_center()
		var alpha: float=draft.controls.get(key,{}).get("opacity",0.82)
		canvas.draw_circle(center,rect.size.x*0.5,Color(0.035,0.05,0.055,alpha))
		canvas.draw_arc(center,rect.size.x*0.5,0,TAU,48,Color(0.88,0.81,0.61,alpha),1.5,true)
		var action=controller.control(key)
		if key=="MovementJoystick":
			canvas.draw_circle(center,rect.size.x*0.16,Color(0.8,0.79,0.65,alpha*0.5))
		elif action!=null and action.icon!=null:
			canvas.draw_texture_rect(action.icon,Rect2(center-rect.size*0.27,rect.size*0.54),false,Color(1,0.96,0.83,alpha))
	var active: Rect2=rects[selected].grow(4)
	canvas.draw_rect(active,Color("8ee0cf"),false,1.5)
	for point in [active.position,active.end,Vector2(active.position.x,active.end.y),Vector2(active.end.x,active.position.y)]: canvas.draw_circle(point,4,Color("8ee0cf"))
	canvas.draw_string(ThemeDB.fallback_font,frame.position+Vector2(12,23),"PAUSED PREVIEW   •   "+controller.display_name(selected),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e5dcc1"))
