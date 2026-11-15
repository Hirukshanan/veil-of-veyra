extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var current=load("res://scripts/mobile_hud.gd").new()
	var before=load("res://art_source/island/task54/baseline/scripts/mobile_hud.gd").new()
	var rows:=[]
	for bounds in [Vector2(1280,720),Vector2(1600,720),Vector2(960,540),Vector2(800,450),Vector2(732,414),Vector2(664,378)]:
		for scale in [.85,1.,1.2]:
			for preset in ["Battle","Classic","Left-Handed"]:
				current.hud_scale=scale;before.hud_scale=scale
				var data:={"preset":preset,"controls":{}}
				var rects:Dictionary=current.rectangles(bounds,data);var old:Dictionary=before.rectangles(bounds,data)
				assert(current.layout_error(data,bounds).is_empty())
				assert(rects.MovementJoystick.size==rects.AttackButton.size)
				assert(is_equal_approx(rects.MovementJoystick.get_center().x+rects.AttackButton.get_center().x,bounds.x) and is_equal_approx(rects.MovementJoystick.get_center().y,rects.AttackButton.get_center().y))
				for key in ["DodgeButton","SpiritBurstButton"]:assert(rects[key].get_center().is_equal_approx(old[key].get_center()),"Approved boot/star centers must stay exact under aspect/hand/scale changes")
				for key in current.MOVABLE:
					assert(Rect2(Vector2.ZERO,bounds).encloses(rects[key]))
					if key not in current.PRIMARY:assert(rects[key].size.x<rects.AttackButton.size.x)
					for other in current.MOVABLE:
						if other!=key:assert(not rects[key].intersects(rects[other]),"Enlarged controls need clear rectangular touch regions")
				rows.append({"bounds":bounds,"scale":scale,"preset":preset,"primary_diameter":rects.AttackButton.size.x,"mirrored_anchors":true,"kick_and_special_centers_preserved":true,"no_overlap":true})
	current.hud_scale=1
	var defaults:Dictionary=current.rectangles(Vector2(1280,720),{"preset":"Battle","controls":{}})
	assert(defaults.AttackButton.size==Vector2(176,176) and defaults.DodgeButton.size==Vector2(76,76))
	var output:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	FileAccess.open(output+"/control_layout_results.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"rows":rows,"default_1280x720_rects":defaults,"old_primary_diameter":144,"new_primary_diameter":176},"  "))
	current.free();before.free();print("PASS:54 default landscape/scale/preset combinations; matched mirrored anchors, larger primaries, smaller secondary controls, exact boot/star centers and no rectangular touch overlap");quit()
