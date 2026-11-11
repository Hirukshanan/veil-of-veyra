shader_type spatial;
uniform sampler2D sand_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_color : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D soil_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D trail_mask : filter_linear, repeat_disable;
uniform vec4 chapter_tint : source_color = vec4(1.0);
uniform float trail_span = 256.0;
uniform float grass_edge = 90.0;
uniform float waterline_base = 114.5;
uniform vec4 forest_a = vec4(-39.0,-7.0,20.0,26.0);
uniform vec4 forest_b = vec4(30.0,-41.0,21.0,20.0);
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	TANGENT = normalize(vec3(NORMAL.y, -NORMAL.x, 0.0));
	BINORMAL = normalize(cross(TANGENT, NORMAL));
}

void fragment() {
	vec2 p = world_position.xz;
	float angle = atan(p.y, p.x);
	float contour = length(p) - (1.5 * sin(angle * 3.0) + 0.8 * sin(angle * 5.0) + 0.5 * sin(angle * 7.0));
	// Low-frequency variation breaks up material boundaries and tiling.
	float variation = sin(p.x * 0.43 + sin(p.y * 0.31)) * sin(p.y * 0.57 + cos(p.x * 0.24));
	float grass = 1.0 - smoothstep(grass_edge - 2.0, grass_edge + 7.0, contour + variation * 1.8);
	float path = texture(trail_mask, p / trail_span + 0.5).r;
	path = smoothstep(0.08 + variation * 0.06, 0.92 + variation * 0.06, path);
	vec3 sand = texture(sand_color, p * 0.12).rgb;
	vec3 grass_detail = texture(grass_color, p * 0.65).rgb;
	float grass_value = dot(grass_detail, vec3(0.299, 0.587, 0.114));
	vec3 greenery = mix(vec3(0.11, 0.16, 0.055), vec3(0.27, 0.34, 0.12), grass_value) * (0.94 + variation * 0.10);
	vec3 soil = texture(soil_color, p * 0.25).rgb * vec3(0.85, 0.85, 0.8);
	float canopy = 1.0 - smoothstep(0.65,1.15,min(length((p-forest_a.xy)/forest_a.zw),length((p-forest_b.xy)/forest_b.zw)));
	greenery = mix(greenery,greenery*0.63+soil*0.13,canopy);
	vec3 color = mix(sand, greenery, grass);
	color = mix(color, soil, path);
	float wet = smoothstep(waterline_base - 10.5, waterline_base - 0.5, contour + variation * 0.3);
	ALBEDO = color * (1.0 + variation * 0.045) * mix(1.0, 0.56, wet);
	vec3 detail = mix(texture(sand_normal, p * 0.12).rgb, texture(grass_normal, p * 0.25).rgb, grass);
	NORMAL_MAP = mix(detail, texture(soil_normal, p * 0.25).rgb, path);
	NORMAL_MAP_DEPTH = 0.55;
	ROUGHNESS = mix(0.92, 0.38, wet);
	SPECULAR = mix(0.22, 0.42, wet);
}