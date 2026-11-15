shader_type spatial;
render_mode cull_disabled;
uniform bool foam=false;
varying vec3 p;
float hash2(vec2 q){return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);}
float noise2(vec2 q){vec2 i=floor(q);vec2 f=fract(q);f=f*f*(3.0-2.0*f);return mix(mix(hash2(i),hash2(i+vec2(1.0,0.0)),f.x),mix(hash2(i+vec2(0.0,1.0)),hash2(i+vec2(1.0,1.0)),f.x),f.y);}
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float flow=UV.y*21.0-TIME*3.8;
 float stripes=noise2(vec2(UV.x*79.0,UV.y*10.0-TIME*3.8));
 float sheets=noise2(vec2(UV.x*17.0+sin(flow*.3)*.12,UV.y*13.0-TIME*1.8));
 float pearl=smoothstep(0.22,0.83,stripes*0.40+sheets*0.60);
 float edge=min(UV.x,1.0-UV.x);
 ALPHA=smoothstep(0.0,0.09,edge)*(0.72+sin(flow*0.7+UV.x*19.0)*0.28);
 ALPHA_SCISSOR_THRESHOLD=0.28;
 ALBEDO=mix(vec3(0.37,0.55,0.54),vec3(0.74,0.83,0.81),pearl);
 if(foam){
  float radius=length((p.xz-vec2(0.35,-67.0))/vec2(2.7,3.1));
  float ripple=sin(radius*32.0-TIME*3.8+sin(p.x*17.0+p.z*8.0)*1.8)*0.5+0.5;
  float fleck=sin(p.x*43.0+sin(p.z*31.0))*sin(p.z*37.0+p.x*7.0)*0.5+0.5;
  ALPHA=(1.0-smoothstep(0.0,1.0,radius))*smoothstep(0.60,0.9,ripple)*smoothstep(0.4,0.85,fleck);
  ALPHA_SCISSOR_THRESHOLD=0.40;ALBEDO=vec3(0.72,0.83,0.78);
 }
 ROUGHNESS=0.34;SPECULAR=0.35;
}
