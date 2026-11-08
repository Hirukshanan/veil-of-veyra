shader_type spatial;
render_mode cull_disabled;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.xz;
	float angle = atan(p.y, p.x);
	// Same radial contour as island_terrain.gd; water intersects at base radius 90.5.
	float contour = length(p) - (1.5 * sin(angle * 3.0) + 0.8 * sin(angle * 5.0) + 0.5 * sin(angle * 7.0));
	float shore_distance = contour - 90.5;
	float wave_a = dot(p, vec2(0.18, 0.11)) + TIME * 0.65;
	float wave_b = dot(p, vec2(-0.08, 0.23)) - TIME * 0.43;
	float wave = sin(wave_a) * 0.65 + sin(wave_b) * 0.35;
	float shallow = 1.0 - smoothstep(0.0, 14.0, shore_distance);
	vec3 water = mix(vec3(0.025, 0.12, 0.18), vec3(0.08, 0.36, 0.36), shallow);
	float ripple = sin(shore_distance * 3.0 + TIME * 1.4 + sin(angle * 17.0) * 0.35);
	float foam = smoothstep(0.65, 0.96, ripple) * (1.0 - smoothstep(0.0, 3.2, shore_distance));
	float broken_edge = 0.65 + 0.35 * sin(p.x * 2.7 + sin(p.y * 1.9));
	foam *= broken_edge * smoothstep(-0.2, 0.2, shore_distance);
	ALBEDO = mix(water + wave * 0.012, vec3(0.72, 0.83, 0.79), foam * 0.75);
	NORMAL = normalize(vec3(cos(wave_a) * 0.018, cos(wave_b) * 0.018, 1.0));
	ROUGHNESS = mix(0.65, 0.95, foam);
	SPECULAR = 0.3;
}