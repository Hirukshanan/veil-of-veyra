shader_type spatial;
render_mode cull_disabled;

// Static split fibres run along the exposed grain inside the four recessed cuts.
void fragment() {
	float grain = UV.x * 1470.0 + sin(UV.y * 19.0) * 1.8 + sin(UV.x * 176.0 + UV.y * 6.5);
	float fibre = smoothstep(.62, .96, sin(grain)) * (.46 + .28 * sin(UV.y * 46.0 + grain * .12));
	float tear = smoothstep(.93, 1.0, sin(grain * .37 + UV.y * 7.0));
	ALBEDO = COLOR.rgb * (1.02 - .33 * fibre - .17 * tear);
	ROUGHNESS = .96;
	SPECULAR = .13;
}
