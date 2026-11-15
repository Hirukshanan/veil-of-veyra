extends SceneTree
func _initialize():call_deferred("run")
func run():
	assert(OS.get_environment("VEYRA_TEST")=="1")
	var scene=load("res://scenes/island_candidate.tscn").instantiate();root.add_child(scene)
	while not scene.placement_ready:await physics_frame
	var image:=Image.create(512,512,false,Image.FORMAT_RGBA8);image.fill(Color(0,0,0,1))
	var vegetation:Node=scene.landscape.get_node("CandidateVegetation")
	for tree in vegetation.tree_positions:paint(image,Vector2(tree.x,tree.z)+Vector2(1.8,1.0),4.7,1)
	# Reuse already traversed routes; no visual trail is a promise of new navigation.
	var routes:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://.validation/island_visual_2026-11-15/connection_routes.json"))
	var route_names:=[]
	for row in routes.routes:
		if row.name not in ["WesternForest","WaterfallMountains","RiverGrassland","SouthernBeach"]:continue
		route_names.append(row.name)
		var numbers:=RegEx.new();numbers.compile("\\(([^)]+)\\)")
		var previous:=Vector2(INF,INF)
		for entry in numbers.search_all(row.route):
			var v:PackedStringArray=entry.get_string(1).split(",");var p:=Vector2(float(v[0]),float(v[2]))
			if previous.is_finite():
				for i in range(5):
					var sample:Vector2=previous.lerp(p,i/4.0)
					if sample.y<53:paint(image,sample,1.15,0)
			previous=p
	var path:="res://assets/environment/new_island/task4/journey_mask.png"
	assert(image.save_png(path)==OK)
	var f:=FileAccess.open("res://assets/environment/new_island/task4/mask_source.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"resolution":[512,512],"world_extent_m":256,"red":"soft footpath hints along existing verified routes; stops before beach","green":"static approximate canopy ground shade from approved tree anchors; not dynamic occlusion","tree_anchors":vegetation.tree_positions.size(),"route_names":route_names,"original_vegetation_placement_unchanged":true},"  "))
	print("PASS: original local canopy/path mask baked from ",vegetation.tree_positions.size()," accepted tree anchors and four already verified routes");quit()
func paint(image:Image,p:Vector2,radius:float,channel:int):
	var center:Vector2=(p/256.0+Vector2.ONE*.5)*512
	var count:int=ceili(radius*2)
	for y in range(maxi(0,int(center.y)-count),mini(512,int(center.y)+count+1)):
		for x in range(maxi(0,int(center.x)-count),mini(512,int(center.x)+count+1)):
			var distance:float=(Vector2(x+.5,y+.5)-center).length()*.5
			var weight:float=1.0-smoothstep(radius*.15,radius,distance)
			if channel==1:weight*=.78+.22*sin(x*.71+sin(y*.53))*sin(y*.67)
			var color:Color=image.get_pixel(x,y)
			color[channel]=maxf(color[channel],weight);image.set_pixel(x,y,color)
