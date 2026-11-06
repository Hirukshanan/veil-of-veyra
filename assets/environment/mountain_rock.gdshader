shader_type spatial;
uniform sampler2D rock : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 blend = pow(abs(world_normal), vec3(4.0));
	blend /= max(dot(blend, vec3(1.0)), 0.001);
	vec3 detail = texture(rock, world_position.yz * 0.2).rgb * blend.x
		+ texture(rock, world_position.xz * 0.2).rgb * blend.y
		+ texture(rock, world_position.xy * 0.2).rgb * blend.z;
	float grain = dot(detail, vec3(0.3, 0.59, 0.11));
	float strata = 0.95 + 0.05 * sin(world_position.y * 3.2 + world_position.x * 0.3);
	ALBEDO = mix(vec3(0.22, 0.21, 0.20), vec3(0.55, 0.53, 0.48), grain) * strata;
	ROUGHNESS = 0.96;
	SPECULAR = 0.18;
}