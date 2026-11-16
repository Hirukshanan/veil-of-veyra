extends Resource

@export var origin := Vector2(-120,-120)
@export var spacing := 1.25
@export var columns := 193
@export var heights := PackedFloat32Array()
@export var cells := PackedByteArray()
@export var preserved_sources := PackedVector3Array()
@export var preserved_positions := PackedVector3Array()

func coarse_sample(point: Vector2) -> float:
	var p := (point-origin)/spacing
	var x := clampi(floori(p.x),0,columns-2)
	var z := clampi(floori(p.y),0,columns-2)
	var u := clampf(p.x-x,0,1)
	var v := clampf(p.y-z,0,1)
	var a := heights[z*columns+x]
	var b := heights[z*columns+x+1]
	var c := heights[(z+1)*columns+x]
	var d := heights[(z+1)*columns+x+1]
	return a+(b-a)*u+(c-a)*v if u+v<=1.0 else d+(c-d)*(1.0-u)+(b-d)*(1.0-v)

func preserved_point(point: Vector3) -> Vector3:
	for index in range(preserved_sources.size()):
		var source := preserved_sources[index]
		if absf(source.x-point.x)<0.01 and absf(source.z-point.z)<0.01:return preserved_positions[index]
	return Vector3(INF,INF,INF)

func sample(point:Vector2) -> float:
	var h:float=feature_height(Vector3(point.x,coarse_sample(point),point.y))
	# Match the existing long boar capsule without moving its approved spawn.
	h=lerpf(h,2.659828,1-smoothstep(1.7,3.0,point.distance_to(Vector2(33.5,-19.5))))
	# Keep the approach flush with the existing relic floor and bed the new ridge.
	if point.y >= -16 and point.y <= 59:
		var axis:float=lerpf(76,65,smoothstep(6,24,point.y))
		var width:float=lerpf(6,14,smoothstep(30,42,point.y))
		var weight:float=(1-smoothstep(width,width+4,absf(point.x-axis)))*smoothstep(-16,-12,point.y)*(1-smoothstep(55,59,point.y))
		h=lerpf(h,minf(h,1.32),weight)
	# Feather the eastern ridge toes into the existing hillside outside cave headroom.
	if point.x > 30 and point.x < 106 and point.y > -19 and point.y < 80:
		var axis:float=lerpf(76,65,smoothstep(6,24,point.y))
		var distance:float=absf(point.x-axis)
		var shoulder:float=4.2*exp(-pow((distance-19.0)/8.0,2.0))
		var margin:float=smoothstep(14.0,18.0,distance)*(1-smoothstep(29.0,38.0,distance))
		var length_blend:float=smoothstep(-19.0,-5.0,point.y)*(1-smoothstep(55.0,80.0,point.y))
		h+=shoulder*margin*length_blend
	var z:float=point.y
	# Build the headwater bed and both banks from one continuous cross-section.
	if z >= -73 and z <= -32:
		var offset:=absf(point.x-river_center(z))
		var width:=river_width(z)
		var level:=river_level(z)
		var shore:=offset-width-.28*sin(z*.73)-.17*sin(z*1.42+point.x*.31)
		var profile:=level+clampf(shore*.46,-.78,1.9)
		var influence:float=(1-smoothstep(width+14,width+27,offset))*smoothstep(-73,-69,z)*(1-smoothstep(-37,-32,z))
		if influence > 0:
			var base:float=h
			if z > -37:base=level-.75*(1-smoothstep(0,width,offset)) if shore<0 else maxf(level+.1,h)
			return lerpf(base,profile,influence)
	if z < -68 or z > 118:return h
	var d:float=absf(point.x-river_center(z))
	var w:float=river_width(z)
	# Broaden the upper gorge's inaccessible banks into continuous real slopes.
	# The downstream channel and estuary keep their approved Task 1 profile.
	if z < -30 and z > -68 and d > w:
		var side:float=signf(point.x-river_center(z))
		var outer:=Vector2(river_center(z)+side*(w+24),z)
		var top:float=feature_height(Vector3(outer.x,coarse_sample(outer),z))
		var bank:float=lerpf(river_level(z),maxf(river_level(z)+1.2,top),smoothstep(w,w+24,d)) + .16*smoothstep(w,w+1,d)
		var blend:float=smoothstep(-68,-64,z)*(1-smoothstep(-34,-30,z))*(1-smoothstep(w+22,w+24,d))
		h=lerpf(h,bank,blend)
		if d>w+.5:return h
	if d>w+2:return h
	var level:float=river_level(z)
	var depth:float=lerpf(.75,1.45,smoothstep(-34,-26,z))-.55*smoothstep(88,114,z)
	var target:float=level-depth*(1-smoothstep(0,w,d)) if d<=w else level+.75*(1-smoothstep(100,112,z))*smoothstep(w,w+8,d)
	if z > -64 and z < -34 and d>w:return h
	return lerpf(h,target,1-smoothstep(w+.5,w+2,d))

func river_center(z:float) -> float:
	var upper:float=(z+68)*22.0/30.0+3.0*sin(clampf((z+68)/30.0,0,1)*PI)
	var lower:float=23.0+5.0*sin((z+35)*0.065)
	return lerpf(upper,lower,smoothstep(-40,-36,z)) if z < -36 else lower

func river_width(z:float) -> float:
	return 2.1+0.6*smoothstep(-45,-30,z)+0.22*sin(z*0.17)+4.5*smoothstep(88,114,z)

func river_level(z:float) -> float:
	return 1.6-1.7*smoothstep(-68,-38,z) if z < -38 else -0.1-1.39*smoothstep(75,112,z)

func cuts(x:float,z:float) -> int:
	return 4 if z>=-69 and z<=119 and absf(x-river_center(z))<river_width(z)+5 else 1

func vertex_at(x:float,z:float) -> Vector3:
	var p:=Vector2(x,z)
	var grid:Vector2=(p-origin)/spacing
	var cell:=grid.floor()
	var f:=grid-cell
	var center:=origin+(cell+Vector2(.5,.5))*spacing
	var h:=sample(p)
	# Refined edge vertices must lie on the adjacent coarse triangle edge.
	if is_zero_approx(f.x) and f.y>0 and (cuts(center.x,center.y)==1 or cuts(center.x-spacing,center.y)==1):
		var a:=Vector2(x,origin.y+cell.y*spacing)
		h=lerpf(sample(a),sample(a+Vector2(0,spacing)),f.y)
	elif is_zero_approx(f.y) and f.x>0 and (cuts(center.x,center.y)==1 or cuts(center.x,center.y-spacing)==1):
		var a:=Vector2(origin.x+cell.x*spacing,z)
		h=lerpf(sample(a),sample(a+Vector2(spacing,0)),f.x)
	return Vector3(x,h,z)

# Selective metre-scale correction, never a whole-island transform.
func feature_height(p:Vector3)->float:
	var core:float=(1-smoothstep(17,24,absf(p.x)))*smoothstep(-97,-89,p.z)*(1-smoothstep(-53,-42,p.z))
	# Preserve the low river corridor and all existing gameplay anchors.
	if p.z > -68:core*=smoothstep(river_width(p.z)+12,river_width(p.z)+17,absf(p.x-river_center(p.z)))
	var mountain:float=maxf(0,p.y-2.0)*1.1*core
	var hill:float=3.2*(1-smoothstep(0,15,Vector2(p.x+14,p.z+8).length()))
	return p.y+mountain+hill
