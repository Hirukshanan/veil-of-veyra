shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled;
uniform float density = .072;
void fragment(){
	float edge=pow(abs(dot(normalize(NORMAL),normalize(VIEW))),1.15);
	float ends=smoothstep(.01,.22,UV.y)*(1.-smoothstep(.55,1.,UV.y));
	ALBEDO=vec3(.67,.73,.78);
	ALPHA=density*edge*ends;
}
