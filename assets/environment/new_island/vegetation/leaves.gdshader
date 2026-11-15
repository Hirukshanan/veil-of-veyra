shader_type spatial;
render_mode cull_disabled;
uniform sampler2D leaf_atlas:source_color,filter_linear_mipmap,repeat_disable;
varying vec4 tint;
void vertex(){
    tint=COLOR;
    vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    VERTEX.x+=sin(TIME*1.1+p.x*.17+p.z*.11)*.018;
}
void fragment(){
    vec3 leaf=texture(leaf_atlas,UV).rgb;
    ALBEDO=leaf*vec3(.74,1.02,.67)*tint.rgb;
    ALPHA=max(leaf.r,max(leaf.g,leaf.b));
    ALPHA_SCISSOR_THRESHOLD=.09;
    ROUGHNESS=.95;
    SPECULAR=.08;
}
