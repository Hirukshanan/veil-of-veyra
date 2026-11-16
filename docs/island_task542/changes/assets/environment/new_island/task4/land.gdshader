shader_type spatial;
uniform sampler2D grass:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D sand:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D soil:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D trail_mask:filter_linear;
uniform sampler2D journey_mask:filter_linear_mipmap,repeat_disable;
uniform sampler2D cliff_rock:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 p;
varying vec3 world_normal;
void vertex(){world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
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
	vec3 color=mix(g,s,beach);
	float path=texture(trail_mask,p.xz/256.0+0.5).r;
	ALBEDO=mix(color,texture(soil,p.xz*0.25).rgb,path*0.46);
	vec2 journey=texture(journey_mask,p.xz/256.0+0.5).rg;
 float inland_mask=(1.0-smoothstep(48.0,62.0,p.z))*(1.0-smoothstep(85.0,99.0,radial));
 float noise=sin(p.x*1.3+sin(p.z*.74))*sin(p.z*1.05+p.x*.32)*.5+.5;
 float footpath=journey.r*(.30+noise*.20)*inland_mask;
 vec3 dry=texture(soil,p.xz*.25).rgb*vec3(.93,.99,.85);
 ALBEDO=mix(ALBEDO,dry,footpath);
 float luma=dot(ALBEDO,vec3(.299,.587,.114));
 ALBEDO=mix(ALBEDO,vec3(luma)*vec3(.98,1.02,.89),.12*inland_mask);
 ALBEDO*=1.0-journey.g*.43*inland_mask;
float mountain_zone=(1.0-smoothstep(16.0,28.0,abs(p.x)))*smoothstep(-95.0,-89.0,p.z)*(1.0-smoothstep(-56.0,-48.0,p.z));
 vec3 weights=pow(abs(world_normal),vec3(4.0));weights/=max(dot(weights,vec3(1.0)),0.001);
 vec3 stone=texture(cliff_rock,p.zy*0.43).rgb*weights.x+texture(cliff_rock,p.xz*0.43).rgb*weights.y+texture(cliff_rock,p.xy*0.43).rgb*weights.z;
 float strata=sin(p.y*5.0+sin(p.x*0.7+p.z*0.4)*0.7)*0.5+0.5;
 stone*=mix(vec3(0.73,0.76,0.77),vec3(0.86,0.84,0.79),strata);
 float rocky=max(1.0-smoothstep(0.52,0.87,world_normal.y),smoothstep(2.8,7.5,p.y)*0.88);
 float cascade_toe=(1.0-smoothstep(6.0,16.0,abs(p.x)))*smoothstep(-76.0,-71.0,p.z)*(1.0-smoothstep(-65.0,-59.0,p.z));
 rocky=max(rocky,cascade_toe*0.94);
 ALBEDO=mix(ALBEDO,stone,mountain_zone*rocky);
 ROUGHNESS=0.94;
	SPECULAR=0.18;
}
