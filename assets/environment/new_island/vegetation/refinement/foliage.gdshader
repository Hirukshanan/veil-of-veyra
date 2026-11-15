shader_type spatial;
render_mode cull_disabled;
#include "res://assets/environment/new_island/vegetation/refinement/tree_common.gdshaderinc"
uniform sampler2D twig_atlas:source_color,filter_linear_mipmap,repeat_disable;
void vertex(){
 int form=int(round(INSTANCE_CUSTOM.x*2.0));
 if(form==1){VERTEX+=CUSTOM0.xyz;NORMAL=normalize(CUSTOM2.xyz);}
 if(form==2){VERTEX+=CUSTOM1.xyz;NORMAL=normalize(CUSTOM3.xyz);}
	// Crown centers follow tree height, while individual twigs retain natural proportions.
	float t=smoothstep(.6,5.1,UV2.x);
	float center_y=UV2.x*(form==1?(1.0+.16*t):(form==2?(1.0-.035*t):1.0));
	float aspect=length(MODEL_MATRIX[0].xyz)/max(length(MODEL_MATRIX[1].xyz),.01);
	VERTEX.y=center_y+(VERTEX.y-center_y)*aspect;
	NORMAL=normalize(NORMAL*vec3(1.0,1.0/max(aspect,.1),1.0));
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.x+=sin(TIME*1.05+world.x*.18+world.z*.13)*.012*UV.y;
 vec2 center=(INSTANCE_CUSTOM.yw-vec2(.5))*256.0;
 lod_distance=length(CAMERA_POSITION_WORLD.xz-center);foliage_tint=COLOR.rgb;
}
void fragment(){
 if(!tree_keep(FRAGCOORD.xy))discard;
 vec4 leaf=texture(twig_atlas,UV);
 if(leaf.a<.4)discard;
 ALBEDO=leaf.rgb*foliage_tint;
 ROUGHNESS=.96;SPECULAR=.06;
}
