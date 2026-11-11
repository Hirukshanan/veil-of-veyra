shader_type spatial;
render_mode cull_disabled;
uniform sampler2D leaf_atlas : source_color, filter_linear_mipmap, repeat_disable;
void fragment() {
	vec3 leaf = texture(leaf_atlas,UV).rgb;
	ALBEDO = leaf * vec3(0.78,1.05,0.7);
	ALPHA = smoothstep(0.025,0.065,max(leaf.r,max(leaf.g,leaf.b)));
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.96;
	SPECULAR = 0.08;
}
