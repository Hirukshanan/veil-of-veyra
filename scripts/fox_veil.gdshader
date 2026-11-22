shader_type spatial;
render_mode shadows_disabled, fog_disabled;

uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D coat : source_color, filter_linear_mipmap;
uniform sampler2D coat_normal : hint_normal, filter_linear_mipmap;
uniform vec4 coat_color : source_color = vec4(1.0);
uniform float coat_roughness = 0.9;
uniform float normal_strength = 0.0;
uniform float veil : hint_range(0.0, 1.0) = 0.0;
uniform float tell : hint_range(0.0, 1.0) = 0.0;
uniform float motion : hint_range(0.0, 1.0) = 0.0;
varying vec3 model_point;

void vertex() {
	model_point = VERTEX;
}

void fragment() {
	vec3 fur = texture(coat, UV).rgb * coat_color.rgb;
	vec3 surface_normal = normalize(NORMAL);
	float rim = pow(1.0 - abs(dot(surface_normal, normalize(VIEW))), 2.2);
	float eyes = smoothstep(0.16, 0.43, fur.r - max(fur.g, fur.b))
		* smoothstep(0.53, 0.79, -model_point.z) * smoothstep(0.49, 0.65, model_point.y);
	float charge = smoothstep(0.17, 0.72, tell);
	float shimmer = sin(model_point.y * 27.0 + model_point.z * 11.0 - TIME * (6.0 + motion * 7.0));
	float cross_wave = sin(model_point.x * 20.0 - model_point.z * 17.0 + TIME * 5.0);
	vec2 bending = surface_normal.xy * (0.68 + rim * 0.30)
		+ vec2(shimmer, cross_wave) * (0.13 + motion * 0.10);
	// One bilinear sample of the opaque scene, with the lookup confined to the skinned silhouette.
	vec2 pixels = bending * (9.5 + motion * 7.0 + charge * 6.0);
	vec2 refraction_uv = SCREEN_UV + pixels / VIEWPORT_SIZE * veil;
	vec3 background = texture(scene_color, refraction_uv).rgb;
	float edge_wave = 0.49 + 0.51 * smoothstep(0.52, 0.96, shimmer);
	vec3 crimson = vec3(0.78, 0.022, 0.065);
	float eye_glow = eyes * (0.68 + smoothstep(0.0, 0.22, tell) * 1.05);
	float edge_glow = rim * edge_wave * (0.14 + charge * 0.26);
	ALBEDO = fur * (1.0 - veil);
	ROUGHNESS = coat_roughness;
	if (veil < 0.98 && normal_strength > 0.0) {
		NORMAL_MAP = texture(coat_normal, UV).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
	EMISSION = veil * (background * (0.92 - rim * 0.22) + crimson * (eye_glow + edge_glow));
	ALPHA = 1.0;
}
