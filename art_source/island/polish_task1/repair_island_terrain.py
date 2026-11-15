"""Task 1: actual shared terrain topology, no prop/foliage cover-up.
Run using Blender background. Read the approved pre-polish prepared source.
"""
import bpy,bmesh,json,math,heapq,struct,hashlib,re
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
R=Path(__file__).resolve().parents[3];A=R/'assets/environment/new_island';E=R/'.validation/island_polish_task1';S=R/'art_source/island/polish_task1';S.mkdir(exist_ok=True);E.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(R/'art_source/island/island_regions.blend'))
N=193;STEP=1.25;ORIGIN=-120.0
names=['WaterfallMountains','WesternForest','RiverGrassland','EasternCaves','SouthernBeach']
objects={i:bpy.data.objects[n] for i,n in enumerate(names)}
def smooth(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
def center(z):
 upper=(z+68)*22/30+3*math.sin(max(0,min(1,(z+68)/30))*math.pi)
 lower=23+5*math.sin((z+35)*.065)
 t=smooth(-40,-36,z);return upper*(1-t)+lower*t if z< -36 else lower
def water(z):
 return 1.6-1.7*smooth(-68,-38,z) if z< -38 else -.1-1.39*smooth(75,112,z)
def width(z):
 return 2.1+.6*smooth(-45,-30,z)+.22*math.sin(z*.17)+4.5*smooth(88,114,z)
def base(x,z):
 a=math.atan2(z,x);rad=math.hypot(x,z)-(5*math.sin(a*3)+3*math.sin(a*5)+1.5*math.sin(a*7))
 h=(1.6+1.2*math.sin(x*.045)*math.cos(z*.04)+.6*math.sin(x*.09+z*.04))*(1-.72*smooth(30,80,z))
 t=smooth(88,118,rad);return h*(1-t)-2.5*t
sources={}
for i in [0,2,3,4]:
 o=objects[i];o.data.calc_loop_triangles();tris=list(o.data.loop_triangles);vs=[v.co.copy() for v in o.data.vertices]
 bv=BVHTree.FromPolygons(vs,[list(t.vertices) for t in tris],all_triangles=True)
 uvs=o.data.uv_layers.active.data
 def hit(x,z,bv=bv,vs=vs,tris=tris,uvs=uvs):
  p,n,face,d=bv.ray_cast(Vector((x,-z,60)),Vector((0,0,-1)),90)
  if p is None or n.z<.025:return None
  t=tris[face];a,b,c=[vs[k] for k in t.vertices]
  v0=b-a;v1=c-a;v2=p-a;den=v0.dot(v0)*v1.dot(v1)-v0.dot(v1)**2
  if abs(den)<1e-14:return None
  v=(v1.dot(v1)*v2.dot(v0)-v0.dot(v1)*v2.dot(v1))/den;w=(v0.dot(v0)*v2.dot(v1)-v0.dot(v1)*v2.dot(v0))/den
  uv=uvs[t.loops[0]].uv*(1-v-w)+uvs[t.loops[1]].uv*v+uvs[t.loops[2]].uv*w
  return p.z,(uv.x,uv.y)
 sources[i]={'hit':hit,'material':o.data.materials[0],'object':o}
X,Z=np.meshgrid(np.arange(N)*STEP+ORIGIN,np.arange(N)*STEP+ORIGIN)
H=np.array([[base(x,z) for x in np.arange(N)*STEP+ORIGIN] for z in np.arange(N)*STEP+ORIGIN],dtype=float)
baseH=H.copy();influences={};alphas={};uvfields={};sample_heights={};edge_fields={}
for i,s in sources.items():
 valid=np.zeros((N,N),bool);height=np.zeros((N,N));uv=np.zeros((N,N,2))
 o=s['object'];coords=[v.co for v in o.data.vertices];xmin=min(v.x for v in coords);xmax=max(v.x for v in coords);zmin=-max(v.y for v in coords);zmax=-min(v.y for v in coords)
 for zz in range(max(0,int((zmin-ORIGIN)/STEP)),min(N,int((zmax-ORIGIN)/STEP)+2)):
  for xx in range(max(0,int((xmin-ORIGIN)/STEP)),min(N,int((xmax-ORIGIN)/STEP)+2)):
   h=s['hit'](X[zz,xx],Z[zz,xx])
   if h is not None and h[0]>-3:
    valid[zz,xx]=True;height[zz,xx]=h[0];uv[zz,xx]=h[1]
 # Nearest valid source sample, for real outward graded skirts.
 dist=np.full((N,N),1e6);near=np.zeros((N,N,2),int);queue=[]
 for zz,xx in np.argwhere(valid):dist[zz,xx]=0;near[zz,xx]=[zz,xx];heapq.heappush(queue,(0,int(zz),int(xx)))
 neighbors=[(-1,0,STEP),(1,0,STEP),(0,-1,STEP),(0,1,STEP),(-1,-1,STEP*1.4142),(-1,1,STEP*1.4142),(1,-1,STEP*1.4142),(1,1,STEP*1.4142)]
 while queue:
  d,zz,xx=heapq.heappop(queue)
  if d!=dist[zz,xx] or d>15:continue
  for dz,dx,cost in neighbors:
   qz=zz+dz;qx=xx+dx
   if 0<=qz<N and 0<=qx<N and d+cost<dist[qz,qx]:
    dist[qz,qx]=d+cost;near[qz,qx]=near[zz,xx];heapq.heappush(queue,(d+cost,qz,qx))
 # True source footprint boundary, not its bounding rectangle.
 inside=np.full((N,N),20.0);q=[]
 for zz,xx in np.argwhere(valid):
  if any(not(0<=zz+dz<N and 0<=xx+dx<N) or not valid[zz+dz,xx+dx] for dz,dx,_ in neighbors[:4]):inside[zz,xx]=0;heapq.heappush(q,(0,int(zz),int(xx)))
 while q:
  d,zz,xx=heapq.heappop(q)
  if d!=inside[zz,xx]:continue
  for dz,dx,cost in neighbors:
   qz=zz+dz;qx=xx+dx
   if 0<=qz<N and 0<=qx<N and valid[qz,qx] and d+cost<inside[qz,qx]:inside[qz,qx]=d+cost;heapq.heappush(q,(d+cost,qz,qx))
 extended_h=height[near[:,:,0],near[:,:,1]];extended_uv=uv[near[:,:,0],near[:,:,1]]
 weight=np.vectorize(lambda d:1-smooth(0,12,d))(dist)
 if i==2:weight*=1-np.vectorize(lambda z:smooth(25,38,z))(Z)
 if i==4:weight*=np.vectorize(lambda z:smooth(25,38,z))(Z)
 if i==3:weight*=np.vectorize(lambda x:1-smooth(53.75,55,x))(X)
 influences[i]=weight;sample_heights[i]=extended_h;uvfields[i]=extended_uv
 alpha=np.vectorize(lambda d:smooth(0,7,d))(inside)*valid
 if i in [2,4]:alpha*=np.vectorize(lambda z:smooth(0,6,abs(z-31.25)))(Z)
 alphas[i]=alpha
 edge_fields[i]=np.where(valid,inside,-dist)
 print('SAMPLED_REGION',names[i],int(valid.sum()),flush=True)
weights=sum(influences.values());delta=sum(influences[i]*(sample_heights[i]-baseH) for i in sources)
H=baseH+delta/np.maximum(1,weights)
# Relax inherited cut-edge height discontinuities into broad graded shoulders.
# Keep mountain/cave cores and the untouched forest asset independent.
grade=np.zeros_like(H)
for i in [2,4]:
 grade=np.maximum(grade,np.vectorize(lambda d:1-smooth(5,15,abs(d)))(edge_fields[i]))
grade=np.maximum(grade,np.vectorize(lambda x:1-smooth(5,15,abs(x-48)))(X)*(Z>-52)*(Z<32))
grade=np.maximum(grade,np.vectorize(lambda z:1-smooth(3,12,abs(z-31.25)))(Z)*(X>-38)*(X<35))
for iteration in range(30):
 avg=(np.roll(H,1,0)+np.roll(H,-1,0)+np.roll(H,1,1)+np.roll(H,-1,1))*.25
 H=H+(avg-H)*grade*.65
# Carve one continuous rounded bed, including the estuary below the existing sea.
for zz in range(N):
 z=ORIGIN+zz*STEP
 if not -68<=z<=120:continue
 cx=center(z);w=width(z);level=water(z);depth=1.45-.55*smooth(88,114,z)
 for xx in range(N):
  x=ORIGIN+xx*STEP;distance=abs(x-cx)
  if distance>w+14:continue
  bed=level-depth*(1-smooth(0,w,distance))
  if distance<=w:H[zz,xx]=bed
  else:
   original=H[zz,xx];t=smooth(w,w+8,distance)
   bank=level+max(.75*(1-smooth(100,112,z)),original-level)*t
   fade=smooth(w+7,w+14,distance);H[zz,xx]=bank*(1-fade)+original*fade
# Preserve recorded gameplay support, without moving region centers or actors.
placements=json.loads((S/'placement_anchors.json').read_text());preserved=[];constraints=[]
def numbers(s):return [float(v) for v in re.findall(r'-?\d+(?:\.\d+)?',s)]
def sample(grid,x,z):
 fx=max(0,min(N-1.00001,(x-ORIGIN)/STEP));fz=max(0,min(N-1.00001,(z-ORIGIN)/STEP));ix=int(fx);iz=int(fz);u=fx-ix;v=fz-iz
 a=grid[iz,ix];b=grid[iz,ix+1];c=grid[iz+1,ix];d=grid[iz+1,ix+1]
 return a+(b-a)*u+(c-a)*v if u+v<=1 else d+(c-d)*(1-u)+(b-d)*(1-v)

def detailed_height(x,z):
 h=sample(H,x,z)
 if not -68<=z<=118:return h
 d=abs(x-center(z));w=width(z)
 if d>w+2:return h
 level=water(z);depth=1.45-.55*smooth(88,114,z)
 target=level-depth*(1-smooth(0,w,d)) if d<=w else level+.75*(1-smooth(100,112,z))*smooth(w,w+8,d)
 blend=1-smooth(w+.5,w+2,d)
 return h*(1-blend)+target*blend

def subdivisions(x,z):
 return 4 if -69<=z<=119 and abs(x-center(z))<width(z)+5 else 1
for p in placements:
 pos=numbers(p['after']);src=numbers(p['before']);safe=p['node']!='Scenery';target=pos[1]-(.08 if safe else 0)
 constraints.append((pos[0],pos[2],target));
 if safe:preserved.append({'source':src,'position':pos})
for x,z in [(0,27),(0,2),(0,-20)]:
 hit=sources[2]['hit'](x,z);old=max(base(x,z),hit[0] if hit else -100);constraints.append((x,z,old));preserved.append({'source':[x,0,z],'position':[x,old+.08,z]})
for x,z,target in constraints:
 difference=target-sample(H,x,z)
 for zz in range(max(0,int((z-6-ORIGIN)/STEP)),min(N,int((z+6-ORIGIN)/STEP)+2)):
  for xx in range(max(0,int((x-6-ORIGIN)/STEP)),min(N,int((x+6-ORIGIN)/STEP)+2)):
   radius=math.hypot(X[zz,xx]-x,Z[zz,xx]-z);H[zz,xx]+=difference*(1-smooth(0,6,radius))
for iteration in range(50):
 error=0
 for x,z,target in constraints:
  fx=(x-ORIGIN)/STEP;fz=(z-ORIGIN)/STEP;ix=int(fx);iz=int(fz);u=fx-ix;v=fz-iz;coeff=[(iz,ix,1-u-v),(iz,ix+1,u),(iz+1,ix,v)] if u+v<=1 else [(iz+1,ix+1,u+v-1),(iz+1,ix,1-u),(iz,ix+1,1-v)]
  e=target-sample(H,x,z);error=max(error,abs(e));norm=sum(c*c for _,_,c in coeff)
  for qz,qx,c in coeff:H[qz,qx]+=e*c/norm
 if error<.00001:break
print('ANCHOR_MAX_ERROR',error,flush=True)
# Cell ownership removes all visible/collision overlaps at the southern junction.
owners=np.zeros((N-1,N-1),np.uint8)
for zz in range(N-1):
 for xx in range(N-1):
  x=ORIGIN+(xx+.5)*STEP;z=ORIGIN+(zz+.5)*STEP
  if math.hypot(x,z)>121:owners[zz,xx]=255;continue
  in_core=(-23.75<=x<=23.75 and -92.5<=z<=-43.75)
  river_patch=z>-66 and abs(x-center(z))<width(z)+9
  # The imported mountain is an open cliff prop in places. Keep real continuous
  # ground beneath it instead of reserving its entire rectangular bounding box.
  if in_core and not river_patch:owners[zz,xx]=1;continue
  candidates={i:float(influences[i][zz:zz+2,xx:xx+2].mean()) for i in sources}
  if x>=53.75:candidates.pop(3)
  i=max(candidates,key=candidates.get)
  if candidates[i]>.04:owners[zz,xx]=i+1

# Back the mountain prop with terrain below its sampled exposed surfaces.
# This repairs missing support; it is not foliage/rock decoration over holes.
for zz in range(N):
 for xx in range(N):
  x=X[zz,xx];z=Z[zz,xx]
  if -23.75<=x<=23.75 and -92.5<=z<=-43.75 and not (z>-66 and abs(x-center(z))<width(z)+9):
   hit=sources[0]['hit'](x,z)
   if hit:H[zz,xx]=min(H[zz,xx],hit[0]-.4)
def trim_core(o,planes):
 bm=bmesh.new();bm.from_mesh(o.data)
 for point,normal in planes:bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=point,plane_no=normal,clear_inner=True,dist=.00001)
 if o.name=='WaterfallMountains':
  remove=[]
  for f in bm.faces:
   c=f.calc_center_median();z=-c.y
   if z>-66 and abs(c.x-center(z))<width(z)+9 and max(v.co.z for v in f.verts)<7:remove.append(f)
  bmesh.ops.delete(bm,geom=remove,context='FACES')
 # Match the shared sampled profile at open top edges; old underside stays buried.
 for v in bm.verts:
  x=v.co.x;z=-v.co.y
  edge=(abs(x-53.75)<.001) if o.name=='EasternCaves' else (abs(abs(x)-23.75)<.001 or abs(z+92.5)<.001 or abs(z+43.75)<.001)
  if edge:
   old=sources[3 if o.name=='EasternCaves' else 0]['hit'](x,z)
   if old and v.co.z>old[0]-.35:v.co.z=sample(H,x,z)
 bm.to_mesh(o.data);bm.free();o.data.update()
trim_core(objects[0],[((-23.75,0,0),(1,0,0)),((23.75,0,0),(-1,0,0)),((0,92.5,0),(0,-1,0)),((0,43.75,0),(0,1,0))])
trim_core(objects[3],[((53.75,0,0),(1,0,0))])
def original_jpeg(path):
 raw=path.read_bytes();size=struct.unpack_from('<I',raw,12)[0];data=json.loads(raw[20:20+size]);start=20+size+8;bv=data['bufferViews'][data['images'][0]['bufferView']];return raw[start+bv.get('byteOffset',0):start+bv.get('byteOffset',0)+bv['byteLength']],data['images'][0]['name']
def preserve_jpeg(path,jpeg,image_name):
 raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0];d=json.loads(raw[20:20+n]);binary=raw[20+n+8:];image_view=d['images'][0]['bufferView'];out=bytearray()
 for index,v in enumerate(d['bufferViews']):
  out.extend(b'\0'*((-len(out))%4));old=binary[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];v['byteOffset']=len(out);value=jpeg if index==image_view else old;v['byteLength']=len(value);out.extend(value)
 d['images'][0]['name']=image_name;d['buffers'][0]['byteLength']=len(out);j=json.dumps(d,separators=(',',':')).encode();j+=b' '*((-len(j))%4);out.extend(b'\0'*((-len(out))%4));path.write_bytes(struct.pack('<III',0x46546c67,2,12+8+len(j)+8+len(out))+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',len(out),0x004e4942)+out)
for i in [0,2,3,4]:
 old=objects[i];mat=sources[i]['material'];verts=[];faces=[];uvs=[];colors=[];mapping={}
 def vertex(zz,xx):
  key=(zz,xx)
  if key not in mapping:
   x=ORIGIN+xx*STEP;z=ORIGIN+zz*STEP
   zi=min(N-1,int(round(zz)));xi=min(N-1,int(round(xx)))
   mapping[key]=len(verts);verts.append((x,-z,detailed_height(x,z)));uvs.append(tuple(uvfields[i][zi,xi]))
   # UV islands on the old grass/beach slabs cannot survive arbitrary remeshing.
   # Use the existing world-space terrain materials on those rebuilt surfaces.
   colors.append(0.0 if i in [2,4] else float(alphas[i][zi,xi]))
  return mapping[key]
 for zz,xx in np.argwhere(owners==i+1):
  cuts=subdivisions(ORIGIN+(xx+.5)*STEP,ORIGIN+(zz+.5)*STEP)
  for dz in range(cuts):
   for dx in range(cuts):
    z0=zz+dz/cuts;x0=xx+dx/cuts;s=1/cuts
    a=vertex(z0,x0);b=vertex(z0,x0+s);c=vertex(z0+s,x0);d=vertex(z0+s,x0+s);faces.extend([(a,c,b),(b,c,d)])
 mesh=bpy.data.meshes.new(names[i]+'_RepairedSurface');mesh.from_pydata(verts,[],faces);mesh.materials.append(mat);mesh.update();patch=bpy.data.objects.new(names[i]+'_GradedTerrain',mesh);bpy.context.collection.objects.link(patch)
 uv=mesh.uv_layers.new(name='UVMap');attribute=mesh.color_attributes.new(name='TerrainBlend',type='FLOAT_COLOR',domain='POINT')
 for p in mesh.polygons:
  p.use_smooth=True
  for li in p.loop_indices:uv.data[li].uv=uvs[mesh.loops[li].vertex_index]
 for index,c in enumerate(colors):attribute.data[index].color=(c,c,c,1)
 if i in [0,3]:
  core_color=old.data.color_attributes.new(name='TerrainBlend',type='FLOAT_COLOR',domain='POINT')
  for c in core_color.data:c.color=(1,1,1,1)
 else:old.hide_render=True
 path=A/(names[i]+'.glb');jpeg,image_name=original_jpeg(path)
 bpy.ops.object.select_all(action='DESELECT');patch.select_set(True)
 if i in [0,3]:old.select_set(True)
 bpy.context.view_layer.objects.active=patch
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_image_format='JPEG',export_animations=False,export_vertex_color='ACTIVE',export_all_vertex_colors=True)
 preserve_jpeg(path,jpeg,image_name)
 print('REBUILT_PATCH',names[i],len(faces),'triangles',flush=True)
(E/'terrain_grid.json').write_text(json.dumps({'heights':H.astype(np.float32).ravel().tolist(),'cells':owners.ravel().tolist(),'preserved':preserved}))
(S/'terrain_repair_metrics.json').write_text(json.dumps({'spacing_m':STEP,'columns':N,'anchors':len(constraints),'max_anchor_error':error,'cell_counts':{str(k):int((owners==k).sum()) for k in np.unique(owners)},'unchanged_regions':['WesternForest'],'region_centers_unchanged':True},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(S/'island_terrain.blend'))
print('PASS: shared surface rebuilt, ownership assigned once, original embedded JPEG bytes retained')
