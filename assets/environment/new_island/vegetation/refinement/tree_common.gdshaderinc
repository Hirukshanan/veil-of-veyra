uniform int lod_level=0;
uniform bool overview=false;
varying float lod_distance;
varying vec3 foliage_tint;
float lod_noise(vec2 pixel){return fract(52.9829189*fract(dot(floor(pixel),vec2(.06711056,.00583715))));}
vec3 tree_weights(float d){float a=1.0-smoothstep(32.0,44.0,d);float c=smoothstep(72.0,84.0,d);return vec3(a,(1.0-a)*(1.0-c),c)*(1.0-smoothstep(145.0,162.0,d));}
bool tree_keep(vec2 pixel){
 if(overview)return true;
 vec3 w=tree_weights(lod_distance);float h=lod_noise(pixel);
 if(lod_level==0)return h<w.x;
 if(lod_level==1)return h>=w.x && h<w.x+w.y;
 return h>=w.x+w.y && h<w.x+w.y+w.z;
}
