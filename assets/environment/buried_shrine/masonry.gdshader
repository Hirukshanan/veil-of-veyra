shader_type spatial;
render_mode cull_disabled;
uniform sampler2D rock : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(.57,.55,.51,1.);
uniform float metalness=0.;
uniform bool weathered = false;
uniform bool cavern_portal = false;
uniform int passage_shadow = 0;
uniform int seal_half = 0;
uniform float seal_charge = 0.;
varying float seal_x;
varying vec3 p;
varying vec3 nw;
void vertex(){seal_x=VERTEX.x;p=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;nw=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
	if (cavern_portal && p.z>46.70 && p.z<48.02 && abs(p.x-2.7)<2.30 && p.y<38.55) { discard; }
	if (seal_half != 0 && (seal_x-2.7)*float(seal_half)<0.) { discard; }
	vec3 n=normalize(nw);
	vec3 a=abs(n);
	vec2 uv=a.y>max(a.x,a.z)?p.xz:(a.x>a.z?p.zy:p.xy);
	vec3 grain=texture(rock,uv*.37).rgb;
	vec2 bump=texture(normal_tex,uv*.37).rg*2.-1.;
	vec3 relief=a.y>max(a.x,a.z)?vec3(bump.x,0.,bump.y):(a.x>a.z?vec3(0.,bump.y,bump.x):vec3(bump,0.));
	NORMAL=normalize((VIEW_MATRIX*vec4(normalize(n+.38*relief),0.)).xyz);
	float pooled=exp(-.021*dot(p.xz-vec2(1.,12.),p.xz-vec2(1.,12.)));
	float damp=smoothstep(8.3,11.8,abs(p.x))*smoothstep(.18,.71,grain.g+.16*sin(uv.x*1.4))*(1.-smoothstep(34.2,37.8,p.y));
	vec3 base=tint.rgb*(.40+grain*1.30);
	if (weathered) {
		vec3 patina = texture(rock, uv*.108).rgb;
		float fleck = texture(rock,uv*2.1).r;
		float erosion = smoothstep(.28,.68,patina.r + .26*fleck);
		base *= mix(vec3(.59,.61,.65),vec3(1.12,1.03,.88),erosion);
		// Hairline chips stratify the cuts of each stone without affecting its silhouette.
		float split = abs(fract(uv.y*.47 + patina.r*.31 + sin(uv.x*3.9)*.025)-.5);
		float scar = smoothstep(.480,.500,split)*smoothstep(.31,.51,patina.r);
		base *= 1.-scar*.29*(1.-metalness);
	}
	ALBEDO=mix(base,base*vec3(.73,.86,.53),damp*.65*(1.-metalness));
	float light_falloff = 1.;
	if (passage_shadow==2 || (passage_shadow==1 && p.z>39.0 && abs(p.x-2.7)<3.2)) {
		float depth = smoothstep(39.2,55.5,p.z);
		float haze = smoothstep(4.5,17.5,max(0.,p.z-CAMERA_POSITION_WORLD.z));
		light_falloff = (1.-.50*depth)*(1.-.91*haze);
		ALBEDO *= light_falloff;
	}
	ROUGHNESS=mix(.93,.55,metalness);METALLIC=metalness*.48;
	EMISSION=ALBEDO*(.105+.15*pooled)*light_falloff+vec3(1.,.025,.012)*seal_charge*metalness*1.35;
}
