shader_type spatial;
render_mode cull_disabled, shadows_disabled;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 point = world_position.xz;
	float angle = atan(point.y, point.x);
	float radial = length(point) - (5.0 * sin(angle * 3.0) + 3.0 * sin(angle * 5.0) + 1.5 * sin(angle * 7.0));
	float distance_to_coast = radial - 110.0;
	float wave_a = dot(point, vec2(0.18, 0.11)) + TIME * 0.65;
	float wave_b = dot(point, vec2(-0.08, 0.23)) - TIME * 0.43;
	float wave = (sin(wave_a) * 0.65 + sin(wave_b) * 0.35) * 0.012;
	float shallow = 1.0 - smoothstep(0.0, 14.0, distance_to_coast);
	vec3 tidal_color = mix(vec3(0.025, 0.12, 0.18), vec3(0.08, 0.36, 0.36), shallow);
	float flow = sin(UV.y * 8.0 - TIME * 1.8 + sin(point.x * 1.8));
	vec3 river_color = mix(vec3(0.035, 0.25, 0.25), vec3(0.22, 0.49, 0.46), flow * 0.15 + 0.35);
	river_color = mix(river_color, vec3(0.15, 0.38, 0.34), COLOR.r * 0.14);
	float outlet = smoothstep(85.0, 106.0, point.y);
	ALBEDO = mix(river_color, tidal_color, outlet) + wave;
	NORMAL = normalize((VIEW_MATRIX * vec4(cos(wave_a) * 0.018, 1.0, cos(wave_b) * 0.018, 0.0)).xyz);
	ROUGHNESS = 0.65;
	SPECULAR = 0.3;
	// Green stores depth measured against the same ground triangles as collision.
	float water_opacity = smoothstep(0.0, 0.12, COLOR.g) * mix(0.36, 0.96, smoothstep(0.02, 0.76, COLOR.g));
	float sea_overlap = smoothstep(-1.45, -1.30, world_position.y);
	ALPHA = mix(1.0, water_opacity, smoothstep(90.0, 95.0, point.y)) * sea_overlap;
}
