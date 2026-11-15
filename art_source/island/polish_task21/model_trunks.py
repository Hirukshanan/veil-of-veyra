import bpy,math,json
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parents[3];S=R/'art_source/island/polish_task21';A=R/'assets/environment/new_island/vegetation/refinement';S.mkdir(exist_ok=True);A.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
vertices=[];faces=[];tips=[]
def catmull(a,b,c,d,t):return .5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
def tube(points,radii,sides=10):
 pts=[Vector(p) for p in points];samples=[];rs=[]
 for i in range(len(pts)-1):
  for j in range(4):
   t=j/4;samples.append(catmull(pts[max(0,i-1)],pts[i],pts[i+1],pts[min(len(pts)-1,i+2)],t));rs.append(radii[i]*(1-t)+radii[i+1]*t)
 samples.append(pts[-1]);rs.append(radii[-1]);start=len(vertices)
 for i,p in enumerate(samples):
  tangent=(samples[min(i+1,len(samples)-1)]-samples[max(0,i-1)]).normalized();axis=tangent.cross(Vector((0,1,0))).normalized();other=tangent.cross(axis).normalized()
  for k in range(sides):
   theta=k*2*math.pi/sides;radius=rs[i]*(1+.045*math.sin(theta*3+i*.17));vertices.append(p+radius*(axis*math.cos(theta)+other*math.sin(theta)))
 for i in range(len(samples)-1):
  for k in range(sides):
   a=start+i*sides+k;b=start+i*sides+(k+1)%sides;c=start+(i+1)*sides+(k+1)%sides;d=start+(i+1)*sides+k;faces.append((a,b,c,d))
 faces.append(tuple(start+k for k in reversed(range(sides))));faces.append(tuple(start+(len(samples)-1)*sides+k for k in range(sides)))
tube([(0,0,-.04),(.02,.01,.8),(-.09,.04,1.7),(.10,.08,2.6),(.02,.1,3.5),(.23,.05,4.4),(.17,0,5.0)],[.36,.29,.24,.19,.14,.07,.018],12)
tips.append({'point':[.17,5.0,0],'parent':[.23,4.4,-.05]})
for i in range(8):
 angle=i*2.399+.3;dx,dy=math.cos(angle),math.sin(angle);z=1.85+i*.23;reach=1.75+.30*math.sin(i*1.4);endz=3.65+.30*i/7+.28*math.sin(i)
 start=Vector((.03,0,z));middle=Vector((dx*.65,dy*.65,z+.45));end=Vector((dx*reach,dy*reach,endz))
 tube([start,start+Vector((dx*.2,dy*.2,.18)),middle,end],[.145,.13,.08,.026],9)
 for sign in [-1,1]:
  theta=angle+sign*.42;tip=end+Vector((math.cos(theta)*.65,math.sin(theta)*.65,.38+sign*.13))
  parent=middle.lerp(end,.65);tube([parent,end*.65+tip*.35,tip],[.055,.036,.008],7)
  tips.append({'point':[tip.x,tip.z,-tip.y],'parent':[parent.x,parent.z,-parent.y]})
for i in range(5):
 a=i*2*math.pi/5;tube([(0,0,.65),(.28*math.cos(a),.28*math.sin(a),.25),(.66*math.cos(a),.66*math.sin(a),-.03)],[.12,.13,.015],8)
mesh=bpy.data.meshes.new('Joined_Branch_Skeleton');mesh.from_pydata(vertices,[],faces);mesh.update();tree=bpy.data.objects.new('Organic_Woodland_Master',mesh);bpy.context.collection.objects.link(tree);bpy.context.view_layer.objects.active=tree;tree.select_set(True)
remesh=tree.modifiers.new('Organic_Fork_Union','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.045;remesh.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth=tree.modifiers.new('Smooth_Branch_Collars','SMOOTH');smooth.factor=1.1;smooth.iterations=4;bpy.ops.object.modifier_apply(modifier=smooth.name)
for p in tree.data.polygons:p.use_smooth=True
master=tree.data.copy()
def deform(v,form):
 x,y,z=v;h=max(0,min(1,(z-.6)/4.5));t=h*h*(3-2*h)
 if form==1:return Vector((x*(1-.34*t)+.12*math.sin(z*.9)*t,y*(1-.26*t),z*(1+.16*t)))
 if form==2:return Vector((x*(1-.08*t)+1.25*t,y*(1-.14*t)+.18*math.sin(z*.8)*t,z*(1-.035*t)))
 return v.copy()
for form,name in enumerate(['Broad_Fork','Tall_Column','Leaning_Crown']):
 copy=bpy.data.objects.new(name,master.copy());bpy.context.collection.objects.link(copy)
 for v in copy.data.vertices:v.co=deform(v.co,form)
 copy.hide_render=True;copy.hide_viewport=True
for lod,target in enumerate([1100,480,170]):
 tree.data=master.copy();modifier=tree.modifiers.new('Mobile_LOD','DECIMATE');modifier.ratio=min(1,target/(len(tree.data.polygons)*2));bpy.ops.object.modifier_apply(modifier=modifier.name)
 tree.data.validate(clean_customdata=True);tree.data.update()
 uv=tree.data.uv_layers.new(name='BarkUV')
 for p in tree.data.polygons:
  p.use_smooth=True
  for li in p.loop_indices:
   v=tree.data.vertices[tree.data.loops[li].vertex_index];co=v.co;n=v.normal
   uv.data[li].uv=(co.y*1.1,co.z*.9) if abs(n.x)>abs(n.y) else (co.x*1.1,co.z*.9)
 bpy.ops.object.select_all(action='DESELECT');tree.select_set(True);bpy.context.view_layer.objects.active=tree
 bpy.ops.export_scene.gltf(filepath=str(A/('organic_trunk_lod%d.glb'%lod)),use_selection=True,export_format='GLB',export_animations=False)
 print('ORGANIC_TRUNK_LOD',lod,'polygons',len(tree.data.polygons),flush=True)
tree.data=master;tree.name='Editable_Master_Before_Decimation'
bpy.ops.wm.save_as_mainfile(filepath=str(S/'forest_forms.blend'))
(A/'branch_tips.json').write_text(json.dumps(tips,indent=2));print('PASS: original joined trunk forks, 3 editable forms and 3 mobile source LODs saved')
