shader_type spatial;
render_mode cull_disabled;
uniform int lod_level=0;
uniform bool overview=false;
uniform vec3 grass_viewer=vec3(0.0);
varying vec3 grass_tint;
varying float grass_distance;
float pixel_noise(vec2 pixel){return fract(52.9829189*fract(dot(floor(pixel),vec2(.06711056,.00583715))));}
void vertex(){
 vec2 center=(INSTANCE_CUSTOM.yw-vec2(.5))*256.0;
 float d=length(grass_viewer.xz-center);grass_distance=d;
 float density=mix(1.0,.5,smoothstep(10.0,22.0,d));density=mix(density,.22,smoothstep(28.0,40.0,d));
 float grow=1.0-smoothstep(density-.07,density+.02,INSTANCE_CUSTOM.z);
 if(overview)grow=1.0-smoothstep(.20,.25,INSTANCE_CUSTOM.z);
 float end=overview?1.0:1.0-smoothstep(44.0,54.0,d);
	VERTEX*=grow*end;
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float sway=sin(TIME*1.25+p.x*.7+p.z*.4)*UV.y*UV.y;
	VERTEX.x+=sway*.022*grow*end;VERTEX.z+=sway*.012*grow*end;
 grass_tint=COLOR.rgb;
}
void fragment(){
 if(!overview){
  float a=1.0-smoothstep(10.0,22.0,grass_distance);float c=smoothstep(28.0,40.0,grass_distance);
  vec3 w=vec3(a,(1.0-a)*(1.0-c),c);float h=pixel_noise(FRAGCOORD.xy);
  if(lod_level==0 && h>=w.x)discard;
  if(lod_level==1 && (h<w.x || h>=w.x+w.y))discard;
  if(lod_level==2 && h<w.x+w.y)discard;
 }
 ALBEDO=grass_tint;ROUGHNESS=.96;SPECULAR=.04;
}
