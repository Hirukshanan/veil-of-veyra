extends Node

const PATH := "user://hud_profile.cfg"
const MOVABLE := ["MovementJoystick","SprintButton","AttackButton","DodgeButton","JumpButton","GuardButton","TargetLockButton","SpiritBurstButton","InteractButton","HealButton"]
const SIZES := {"MovementJoystick":144.0,"SprintButton":54.0,"AttackButton":100.0,"DodgeButton":68.0,"JumpButton":68.0,"GuardButton":72.0,"TargetLockButton":60.0,"SpiritBurstButton":62.0,"InteractButton":56.0,"HealButton":56.0}
var hud_scale := 1.0
var left_handed := false
var profile: Dictionary = {"preset":"Battle","controls":{}}
var chrome: Control
var editor: CanvasLayer
var load_notice := ""
var _layer_visibility := {}
var _controls := {}
var _overlay_input := false

func _ready() -> void:
	load_profile()
	get_viewport().size_changed.connect(call_deferred.bind("refresh"))
	var scene := get_parent()
	for safe in scene.find_children("*","Control",true,false):
		if safe.get_script()==preload("res://scripts/safe_area.gd"):
			safe.resized.connect(call_deferred.bind("refresh"))
	scene.status_label.hide()
	scene.health_label.hide()
	scene.relic_status.hide()
	chrome=preload("res://scripts/premium_hud.gd").new()
	chrome.name="GameplayHUD"
	chrome.scene=scene
	chrome.controller=self
	scene.status_label.get_parent().add_child(chrome)
	refresh()

func ui_factor(bounds: Vector2) -> float:
	return clampf(minf(bounds.x/1100.0,bounds.y/620.0),0.65,1.0)

func control(control_name: String) -> Control:
	if is_instance_valid(_controls.get(control_name)): return _controls[control_name]
	var found: Control
	if control_name=="MovementJoystick": found=get_tree().get_first_node_in_group("movement_joysticks") as Control
	else: found=get_parent().find_child(control_name,true,false) as Control
	_controls[control_name]=found
	return found

func rectangles(bounds: Vector2, draft: Dictionary = {}, use_settings := true) -> Dictionary:
	var data: Dictionary = profile if draft.is_empty() else draft
	var f := ui_factor(bounds)
	var s := f * (hud_scale if use_settings else 1.0)
	var centers := {
		"MovementJoystick":Vector2(38+72*s,bounds.y-40-72*s),
		"SprintButton":Vector2(38+72*s,bounds.y-56-174*s),
		"AttackButton":bounds+Vector2(-90,-100)*s,
		"DodgeButton":bounds+Vector2(-202,-80)*s,
		"JumpButton":bounds+Vector2(-84,-214)*s,
		"GuardButton":bounds+Vector2(-198,-188)*s,
		"TargetLockButton":bounds+Vector2(-298,-128)*s,
		"SpiritBurstButton":bounds+Vector2(-202,-286)*s,
		"InteractButton":bounds+Vector2(-84,-308)*s,
		"HealButton":Vector2(bounds.x*0.5-66*f,bounds.y-48*f)
	}
	var preset: String = str(data.get("preset","Battle"))
	if preset=="Classic":
		centers.TargetLockButton=bounds+Vector2(-300,-75)*s
	var mirror := preset=="Left-Handed" or (use_settings and left_handed)
	var result := {}
	for key in MOVABLE:
		var entry: Dictionary = data.get("controls",{}).get(key,{})
		var diameter := clampf(float(SIZES[key])*s*float(entry.get("scale",1.0)),104.0 if key=="MovementJoystick" else 48.0,210.0 if key=="MovementJoystick" else 150.0)
		var center: Vector2 = centers[key]
		if mirror: center.x=bounds.x-center.x
		if entry.has("x") and entry.has("y"): center=Vector2(float(entry.x),float(entry.y))*bounds
		center=center.clamp(Vector2.ONE*(diameter*0.5+8),bounds-Vector2.ONE*(diameter*0.5+8))
		result[key]=Rect2(center-Vector2.ONE*diameter*0.5,Vector2.ONE*diameter)
	var map_diameter := 132*f
	for i in range(4):
		result[["CampButton","QuestScrollButton","MapButton","PauseButton"][i]]=Rect2(bounds.x-20-map_diameter-18-200+i*52,20,44,44)
	return result

func refresh() -> void:
	var scene := get_parent()
	var joystick := control("MovementJoystick")
	if joystick==null: return
	var bounds: Vector2 = joystick.get_parent().size
	var rects := rectangles(bounds)
	if not layout_error(profile,bounds).is_empty() and not profile.controls.is_empty():
		rects=rectangles(bounds,{"preset":profile.preset,"controls":{}})
		load_notice="Your saved layout was adapted to fit this screen. Review it in Customize HUD."
	for key in rects:
		var button := control(key)
		if button==null: continue
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		button.position=rects[key].position
		button.size=rects[key].size
		button.modulate.a=float(profile.get("controls",{}).get(key,{}).get("opacity",0.82))
		if button is Button: style_button(button)
	if is_instance_valid(chrome):
		chrome.position=Vector2.ZERO
		chrome.size=bounds
		chrome.queue_redraw()
	var f := ui_factor(bounds)
	scene.boss_name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	scene.boss_name_label.position=Vector2(bounds.x*0.5-110*f,62*f)
	scene.boss_name_label.size=Vector2(220*f,24*f)
	scene.boss_name_label.add_theme_font_size_override("font_size",int(16*f))
	scene.boss_health_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	scene.boss_health_bar.position=Vector2(bounds.x*0.5-110*f,88*f)
	scene.boss_health_bar.size=Vector2(220*f,10*f)

static func style_button(button: Button) -> void:
	if not button.has_meta("premium_styled"):
		for state in ["normal","hover","pressed","disabled"]:
			var style:=StyleBoxFlat.new()
			style.bg_color=Color(0.045,0.065,0.067,0.75 if state=="pressed" else 0.62)
			style.border_color=Color("f4e6b9") if state=="pressed" else Color("ae9e78")
			style.set_border_width_all(2 if state=="pressed" else 1)
			style.set_corner_radius_all(80)
			style.shadow_color=Color(0,0,0,0.25)
			style.shadow_size=2
			button.add_theme_stylebox_override(state,style)
		button.add_theme_color_override("icon_normal_color",Color("f4edda"))
		button.add_theme_color_override("icon_disabled_color",Color("8a8678"))
		button.set_meta("premium_styled",true)
	button.add_theme_constant_override("icon_max_width",int(minf(button.size.x,button.size.y)*0.57))

func valid_data(value: Variant) -> bool:
	if not value is Dictionary or value.get("preset","") not in ["Battle","Classic","Left-Handed"] or not value.get("controls") is Dictionary: return false
	for key in value.controls:
		if key not in MOVABLE or not value.controls[key] is Dictionary: return false
		var entry: Dictionary=value.controls[key]
		if entry.has("x") != entry.has("y"): return false
		for field in entry:
			if field not in ["x","y","scale","opacity"] or not (entry[field] is float or entry[field] is int) or not is_finite(float(entry[field])): return false
			if field in ["x","y"] and (entry[field]<0 or entry[field]>1): return false
			if field=="scale" and (entry[field]<0.75 or entry[field]>1.5): return false
			if field=="opacity" and (entry[field]<0.25 or entry[field]>1.0): return false
	return true

func layout_error(data: Dictionary, bounds: Vector2) -> String:
	if not valid_data(data): return "This layout could not be read. Choose a preset or Reset."
	var rects := rectangles(bounds,data)
	var keys: Array=rects.keys()
	for i in range(keys.size()):
		if keys[i] in MOVABLE and keys[i]!="HealButton":
			var combat_view:=Rect2(bounds*Vector2(0.37,0.28),bounds*Vector2(0.26,0.42))
			if rects[keys[i]].intersects(combat_view): return "Keep the middle of the combat view clear."
		for j in range(i):
			var a: Rect2=rects[keys[i]]
			var b: Rect2=rects[keys[j]]
			if a.get_center().distance_to(b.get_center()) < (a.size.x+b.size.x)*0.5+3:
				return "%s and %s are too close." % [display_name(keys[i]),display_name(keys[j])]
	return ""

static func display_name(value: String) -> String:
	return value.replace("Button","").replace("MovementJoystick","Movement").replace("Target","Target ").replace("SpiritBurst","Spirit burst").capitalize()

func load_profile() -> void:
	for path in [PATH,PATH+".bak"]:
		var config:=ConfigFile.new()
		if config.load(path)==OK and config.get_value("hud","version",0)==1:
			var data: Variant=config.get_value("hud","profile",{})
			# Retire the separate cycle icon without discarding existing custom layouts.
			if data is Dictionary and data.get("controls") is Dictionary:
				data=data.duplicate(true)
				data.controls.erase("TargetSwitchButton")
			if valid_data(data):
				profile=data.duplicate(true)
				return
	if FileAccess.file_exists(PATH): load_notice="Saved layout could not be read; the Battle preset is available."
	elif get_parent().left_handed: profile.preset="Left-Handed"

func save_profile(data: Dictionary) -> Error:
	if not valid_data(data): return ERR_INVALID_DATA
	if not layout_error(data,control("MovementJoystick").get_parent().size).is_empty(): return ERR_INVALID_DATA
	var config:=ConfigFile.new()
	config.set_value("hud","version",1)
	config.set_value("hud","profile",data)
	var error:=config.save(PATH+".tmp")
	if error!=OK: return error
	if FileAccess.file_exists(PATH):
		error=DirAccess.rename_absolute(PATH,PATH+".bak")
		if error!=OK: return error
	error=DirAccess.rename_absolute(PATH+".tmp",PATH)
	if error!=OK:
		if FileAccess.file_exists(PATH+".bak"): DirAccess.rename_absolute(PATH+".bak",PATH)
		return error
	profile=data.duplicate(true)
	get_parent().left_handed=false
	get_parent().player.left_handed_controls=profile.preset=="Left-Handed"
	left_handed=false
	refresh()
	return OK

func open_editor(back: Callable) -> void:
	if is_instance_valid(editor): return
	get_parent()._clear_menu("CONTROLS", "")
	_overlay_input=get_parent().overlay.is_processing_input()
	get_parent().overlay.set_process_input(false)
	_layer_visibility.clear()
	for layer in get_parent().get_children():
		if layer is CanvasLayer:
			_layer_visibility[layer]=layer.visible
			layer.hide()
	editor=preload("res://scripts/hud_editor.gd").new()
	editor.name="HUDCustomization"
	editor.layer=40
	editor.process_mode=Node.PROCESS_MODE_ALWAYS
	editor.controller=self
	editor.back=func():
		for layer in _layer_visibility:
			if is_instance_valid(layer): layer.visible=_layer_visibility[layer]
		_layer_visibility.clear()
		if is_instance_valid(editor): editor.queue_free()
		editor=null
		get_parent().overlay.set_process_input(_overlay_input)
		back.call()
	get_parent().add_child(editor)
