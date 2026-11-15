shader_type spatial;
render_mode cull_disabled;
uniform sampler2D source_map:source_color,filter_linear_mipmap_anisotropic;
uniform sampler2D grass:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D sand:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D trail_mask:filter_linear;
uniform vec4 footprint;
uniform bool waterfall_region=false;
uniform bool vertex_blend=false;
uniform sampler2D journey_mask:filter_linear_mipmap,repeat_disable;
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	float angle=atan(p.z,p.x);
	float radial=length(p.xz)-(5.0*sin(angle*3.0)+3.0*sin(angle*5.0)+1.5*sin(angle*7.0));
	vec3 g=texture(grass,p.xz*0.28).rgb*vec3(0.62,0.96,0.60);
	float inland=smoothstep(-40.0,-30.0,p.z)*(1.0-smoothstep(46.0,65.0,p.z));
	float patch=sin(p.x*0.13+sin(p.z*0.09))*sin(p.z*0.18+p.x*0.04);
	g*=mix(vec3(0.93,0.98,0.89),vec3(1.04,1.02,0.96),patch*0.5+0.5);
	float woodland=(1.0-smoothstep(0.68,1.16,length((p.xz-vec2(-64.0,-8.0))/vec2(27.0,32.0))))*inland;
	g=mix(g,texture(soil,p.xz*0.25).rgb*vec3(0.91,0.99,0.86),woodland*0.68);

	vec3 s=texture(sand,p.xz*0.14).rgb;
	float beach=max(smoothstep(86.0,100.0,radial),smoothstep(38.0,70.0,p.z)*0.8);
	vec3 ground=mix(g,s,beach);
	ground=mix(ground,texture(soil,p.xz*0.25).rgb,texture(trail_mask,p.xz/256.0+0.5).r*0.46);
	float edge=min(footprint.z-abs(p.x-footprint.x),footprint.w-abs(p.z-footprint.y));
	ALBEDO=mix(ground,texture(source_map,UV).rgb,(vertex_blend ? COLOR.r : smoothstep(0.2,6.0,edge)));
	vec3 src=texture(source_map,UV).rgb;
	if(waterfall_region && abs(p.x)<2.0 && p.z>-75.0 && p.z<-65.0 && p.y>2.0 && src.b>src.r*1.04 && src.g>src.r*1.03 && src.b>0.5){
		float streak=sin(p.y*7.0+TIME*4.2+sin(p.x*8.0));
		ALBEDO=mix(ALBEDO,mix(vec3(0.40,0.69,0.70),vec3(0.91,0.96,0.93),streak*0.25+0.7),0.65);
	}
	vec2 journey=texture(journey_mask,p.xz/256.0+0.5).rg;
 float inland_mask=(1.0-smoothstep(48.0,62.0,p.z))*(1.0-smoothstep(85.0,99.0,radial));
 float noise=sin(p.x*1.3+sin(p.z*.74))*sin(p.z*1.05+p.x*.32)*.5+.5;
 float footpath=journey.r*(.30+noise*.20)*inland_mask;
 vec3 dry=texture(soil,p.xz*.25).rgb*vec3(.93,.99,.85);
 ALBEDO=mix(ALBEDO,dry,footpath);
 float luma=dot(ALBEDO,vec3(.299,.587,.114));
 ALBEDO=mix(ALBEDO,vec3(luma)*vec3(.98,1.02,.89),.12*inland_mask);
 ALBEDO*=1.0-journey.g*.43*inland_mask;
 ROUGHNESS=0.94;
	SPECULAR=0.18;
}
