shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float front = -2.0;
uniform vec4 ember : source_color = vec4(1.0,0.42,0.11,1.0);

void fragment() {
	float revealed = front - UV.x;
	if (revealed < 0.0) { discard; }
	float core = 1.0 - abs(UV.y * 2.0 - 1.0);
	float fissure = 0.67 + 0.20 * sin(UV.x * 4.1) + 0.12 * sin(UV.x * 10.3);
	if (core < 1.0 - fissure) { discard; }
	float beat = 0.5 + 0.5 * cos(UV.x * 1.7 - TIME * 2.6);
	float crest = 1.0 - smoothstep(0.0, 2.5, revealed);
	ALBEDO = ember.rgb * (0.19 + core * fissure * (0.46 + beat * 0.34) + crest * 1.1);
}
