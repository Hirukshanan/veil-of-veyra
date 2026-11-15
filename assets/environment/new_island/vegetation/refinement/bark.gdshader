shader_type spatial;
#include "res://assets/environment/new_island/vegetation/refinement/tree_common.gdshaderinc"
uniform sampler2D bark:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D bark_normal:hint_normal,filter_linear_mipmap,repeat_enable;
void vertex(){
 int form=int(round(INSTANCE_CUSTOM.x*2.0));
 if(form==1){VERTEX+=CUSTOM0.xyz;NORMAL=normalize(CUSTOM2.xyz);}
 if(form==2){VERTEX+=CUSTOM1.xyz;NORMAL=normalize(CUSTOM3.xyz);}
 TANGENT=normalize(TANGENT-NORMAL*dot(TANGENT,NORMAL));BINORMAL=normalize(cross(NORMAL,TANGENT));
 vec2 center=(INSTANCE_CUSTOM.yw-vec2(.5))*256.0;
 lod_distance=length(CAMERA_POSITION_WORLD.xz-center);foliage_tint=COLOR.rgb;
}
void fragment(){
 if(!tree_keep(FRAGCOORD.xy))discard;
 ALBEDO=texture(bark,UV).rgb*foliage_tint*vec3(.82,.85,.76);
 NORMAL_MAP=texture(bark_normal,UV).rgb;NORMAL_MAP_DEPTH=.3;
 ROUGHNESS=.95;SPECULAR=.08;
}
