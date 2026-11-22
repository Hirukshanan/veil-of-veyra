shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D atlas : source_color, filter_linear;
uniform int frame_index = 0;
uniform float exposure = 0.;
varying float edge_blend;
void vertex() {
	edge_blend = COLOR.r;
}
void fragment() {
	vec2 panel = vec2(float(frame_index % 3), float(frame_index / 3));
	vec2 sample_uv = (panel + clamp(UV,vec2(.001),vec2(.999)))/vec2(3.,2.);
	vec3 rgb = texture(atlas,sample_uv).rgb;
	ALBEDO = rgb;
	ALPHA = exposure * smoothstep(.0,.18,edge_blend);
}
