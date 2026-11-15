shader_type spatial;
render_mode cull_disabled;
uniform sampler2D rock:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D rock_normal:hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D grass:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform bool ground_blend=false;
uniform bool interior=false;
uniform bool portal=false;
varying vec3 p;
varying vec3 n;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;n=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 facing_n=n; if(dot(facing_n,CAMERA_POSITION_WORLD-p)<0.0){facing_n=-facing_n;}
 vec3 w=pow(abs(n),vec3(4.0));w/=max(dot(w,vec3(1.0)),0.001);
 vec3 a=texture(rock,p.zy*0.43).rgb*w.x+texture(rock,p.xz*0.43).rgb*w.y+texture(rock,p.xy*0.43).rgb*w.z;
 vec3 nx=texture(rock_normal,p.zy*0.43).rgb*2.0-1.0;
 vec3 ny=texture(rock_normal,p.xz*0.43).rgb*2.0-1.0;
 vec3 nz=texture(rock_normal,p.xy*0.43).rgb*2.0-1.0;
 vec3 detail=vec3(0.0,nx.y,nx.x)*w.x+vec3(ny.x,0.0,ny.y)*w.y+vec3(nz.x,nz.y,0.0)*w.z;
 detail-=facing_n*dot(facing_n,detail);
 NORMAL=normalize((VIEW_MATRIX*vec4(normalize(facing_n+detail*0.38),0.0)).xyz);
 float strata=sin(p.y*5.0+sin(p.x*0.7+p.z*0.4)*0.7)*0.5+0.5;
 a*=mix(vec3(0.73,0.76,0.77),vec3(0.86,0.84,0.79),strata);
 vec3 g=texture(grass,p.xz*0.28).rgb*vec3(0.62,0.96,0.60);
 float toe=(1.0-smoothstep(1.8,4.0,p.y))*smoothstep(0.50,0.93,n.y)*0.75;
 if(ground_blend){toe=max(toe,(1.0-COLOR.r)*smoothstep(0.40,0.86,n.y));}
 bool cave_floor=p.x>73.3 && p.x<78.7 && p.z>-6.1 && p.z<10.1;
 if(interior || portal || cave_floor){toe=0.0;}
 ALBEDO=mix(a,g,toe);
 if(interior || cave_floor){ALBEDO*=mix(0.83,0.45,smoothstep(-5.0,9.0,p.z));}
 ROUGHNESS=0.93;SPECULAR=0.17;
}
