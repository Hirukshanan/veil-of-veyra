shader_type spatial;
render_mode cull_disabled;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float wave = sin(world_position.x * 0.3 + TIME * 0.8) * sin(world_position.z * 0.24 - TIME * 0.6);
	float coast = 1.0 - smoothstep(44.0, 61.0, length(world_position.xz));
	ALBEDO = mix(vec3(0.025, 0.12, 0.18), vec3(0.08, 0.36, 0.36), coast) + wave * 0.015;
	NORMAL = normalize(vec3(cos(world_position.x * 0.3 + TIME * 0.8) * 0.025, sin(world_position.z * 0.24 - TIME * 0.6) * 0.025, 1.0));
	ROUGHNESS = 0.65;
	SPECULAR = 0.3;
}
