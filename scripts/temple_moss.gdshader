shader_type spatial;

uniform sampler2D rock : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D moss : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D relief : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float patina = 1.0;
varying vec3 position_ws;
varying vec3 normal_ws;

void vertex() {
	position_ws = (MODEL_MATRIX * vec4(VERTEX,1.)).xyz;
	normal_ws = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 p = position_ws;
	vec3 n = normalize(normal_ws);
	vec3 axis = abs(n);
	vec2 uv = axis.y > max(axis.x, axis.z) ? p.xz : (axis.x > axis.z ? p.zy : p.xy);
	vec3 grit = texture(rock,uv*.63).rgb;
	vec3 growth = texture(moss,uv*.83).rgb;
	float grain = dot(grit,vec3(.3,.5,.2));
	float blot = texture(moss,p.xz*.071+p.y*.034).g;
	float basin = exp(-dot(p.xz-vec2(-1.,5.8),p.xz-vec2(-1.,5.8))*.024);
	float damp = .26*sin(p.x*.68+p.z*.58+p.y*.32) + .21*cos(p.z*.47-p.x*1.2) + .11*sin(p.y*1.5+p.x*2.1-p.z*1.8);
	float cover = smoothstep(.20,.54,damp+.14*n.y+.16*basin+.47*(blot-.36)+.30*(growth.g-.27));
	vec3 mineral = grit*vec3(.78,.80,.74)*patina;
	vec3 lichen = (grit*.42 + growth*.62)*vec3(.62,.80,.39);
	vec3 surface = mix(mineral,lichen,cover);
	if (n.y>.7 && p.y<34.12) {
		// Offset rows and warp their edges into narrow, dark joints.
		vec2 q = p.xz + .12*vec2(sin(p.z*2.),cos(p.x*1.7)) + .12*(growth.rg-.5);
		q.x += floor(q.y/2.2)*1.38;
		vec2 edges = abs(fract(q/vec2(3.1,2.2))-.5);
		float grout = smoothstep(.46,.495,max(edges.x,edges.y));
		surface *= 1.-grout*mix(.22,.53,cover);
	}
	// A dog-legged roof fissure has a softly exposed throat edged by stone.
	vec2 well = (p.xz-vec2(-1.,5.8))/vec2(4.9,3.7);
	float rim = length(well)+.095*sin(p.x*1.6)+.09*cos(p.z*1.4);
	float aperture = n.y<-.8 && p.y>43.9 ? 1.-smoothstep(.50,1.09,rim+(grain-.3)*.8) : 0.;
	float sun = exp(-dot(well,well)*.48);
	vec2 bump = texture(relief,uv*.63).rg*2.-1.;
	vec3 detail = axis.y>max(axis.x,axis.z) ? vec3(bump.x,0.,bump.y) : (axis.x>axis.z ? vec3(0.,bump.y,bump.x) : vec3(bump,0.));
	NORMAL = normalize((VIEW_MATRIX*vec4(normalize(n+detail*.46),0.)).xyz);
	ALBEDO = surface;
	ROUGHNESS = .94;
	EMISSION = surface*(.085+sun*.36) + aperture*mix(vec3(.26,.31,.22),vec3(.85,.90,.75),clamp(1.-rim,0.,1.));
}
