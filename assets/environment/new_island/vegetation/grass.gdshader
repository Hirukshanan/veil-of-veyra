shader_type spatial;
render_mode cull_disabled;
varying vec4 tint;
void vertex(){
    tint=COLOR;
    vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float sway=sin(TIME*1.3+p.x*.7+p.z*.4)*UV.y*UV.y;
    VERTEX.x+=sway*.035;
    VERTEX.z+=sway*.018;
}
void fragment(){
    ALBEDO=tint.rgb;
    ROUGHNESS=.96;
    SPECULAR=.05;
}
