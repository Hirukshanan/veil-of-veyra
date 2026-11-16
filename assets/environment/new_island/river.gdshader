shader_type spatial;
render_mode cull_disabled;
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
    // Match the preserved sea surface at the estuary; no screen-space effects.
    float angle=atan(p.z,p.x);
    float contour=length(p.xz)-(5.0*sin(angle*3.0)+3.0*sin(angle*5.0)+1.5*sin(angle*7.0));
    float shore_distance=contour-110.0;
    float wave_a=dot(p.xz,vec2(0.18,0.11))+TIME*0.65;
    float wave_b=dot(p.xz,vec2(-0.08,0.23))-TIME*0.43;
    float wave=sin(wave_a)*0.65+sin(wave_b)*0.35;
    float shallow=1.0-smoothstep(0.0,14.0,shore_distance);
    vec3 sea=mix(vec3(0.025,0.12,0.18),vec3(0.08,0.36,0.36),shallow);
    float ripple=sin(shore_distance*3.0+TIME*1.4+sin(angle*17.0)*0.35);
    float foam=smoothstep(0.65,0.96,ripple)*(1.0-smoothstep(0.0,3.2,shore_distance));
    foam*=(0.65+0.35*sin(p.x*2.7+sin(p.z*1.9)))*smoothstep(-0.2,0.2,shore_distance);
    vec3 ocean=mix(sea+wave*0.012,vec3(0.72,0.83,0.79),foam*0.75);
    float flow=sin(UV.y*8.0-TIME*1.8+sin(p.x*1.8));
    vec3 river=mix(vec3(0.035,0.25,0.25),vec3(0.22,0.49,0.46),flow*0.15+0.35)+wave*0.012;
    // Shore coverage comes from the actual clipped terrain triangles.
    river=mix(river,vec3(0.15,0.38,0.34),COLOR.r*0.14);
    float outlet=smoothstep(85.0,106.0,p.z);
    ALBEDO=mix(river,ocean,outlet);
    NORMAL=normalize((VIEW_MATRIX*vec4(cos(wave_a)*0.018,1.0,cos(wave_b)*0.018,0.0)).xyz);
    ROUGHNESS=mix(0.65,mix(0.65,0.95,foam),outlet);
    SPECULAR=0.3;
}
