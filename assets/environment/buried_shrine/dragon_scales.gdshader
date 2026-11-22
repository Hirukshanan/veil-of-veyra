shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha, shadows_disabled;
uniform sampler2D mineral : source_color, repeat_enable, filter_linear_mipmap;
uniform float relief_light = 0.;
uniform float lid_open = 1.;
varying vec3 position_local;
varying float seam;
varying float tone;
varying float contour;
void vertex() {
	seam = COLOR.r;
	tone = COLOR.b;
	contour = COLOR.a;
	VERTEX.y += (COLOR.g-.5) * 4.5 * seam * (1.-lid_open);
	position_local = VERTEX;
}
void fragment() {
	vec3 rock = texture(mineral, position_local.xy*.69).rgb;
	float form = .30+.70*abs(dot(normalize(NORMAL),normalize(vec3(-.24,.48,.82))));
	vec3 ink = rock * mix(vec3(.15,.15,.17),vec3(.31,.26,.24),tone) * form;
	float rim = exp(-abs(position_local.y)*.45) * (1.-smoothstep(1.6,5.4,abs(position_local.x)));
	ALBEDO = (ink*vec3(.56,.16,.12)*(.19+.81*seam)+vec3(.15,.011,.005)*seam*.49)*rim*relief_light*lid_open;
	ALPHA = contour * relief_light;
}