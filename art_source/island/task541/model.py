import bpy, math, random, sys
from pathlib import Path
from math import sin,cos,pi
root=Path(sys.argv[-1])
bpy.ops.wm.read_factory_settings(use_empty=True)
# Cross sections: z, centre x, half-width, vault clearance, floor height.
stations=[(-12,76,5.6,5.3,1.48),(-7,76,4.8,5,1.5),(0,76,5.4,5.7,1.5),(6,76,4,4.6,1.5),(10,75,3.6,4.3,1.65),(15,71,3.8,4.8,2),(19,68,5.4,6,2.2),(24,66,8,7.5,2.35),(28,66,7.5,7,2.45),(32,67,4.8,5.4,2.6),(35,67,5.8,6.5,2.8),(42,65,12,11,3),(48,64,13,12,3),(54,64,9,9,3),(58,65,4,5,3)]
rings=[]
for a,b in zip(stations,stations[1:]):
 n=math.ceil((b[0]-a[0])/1.4)
 for k in range(n):
  t=k/n;rings.append([a[i]+(b[i]-a[i])*t for i in range(5)])
rings.append(stations[-1])
verts=[];faces=[]
def point(x,y,z):
 verts.append((x,-z,y));return len(verts)-1
def bridge(a,b):
 for i in range(len(a)):
  j=(i+1)%len(a);faces.append((a[i],a[j],b[j],b[i]))
prev=None
for k,(z,x,w,h,floor) in enumerate(rings):
 floor -= 1.65*max(0,1-(z+12)/4)
 sections=[]
 for outer in [False,True]:
  row=[]
  for j in range(26):
   a=pi*j/25
   crest=sin(a)**.78
   ripple=.18*sin(j*1.24+k*.61)+.26*sin(a*7+k*.34)
   if outer:
    breadth=w+5+2*sin(z*.13)+1.2*cos(a*4+k*.1)
    altitude=(h+4+2.6*sin(z*.21+a*3)+.7*sin(k*1.1+j*.8))*crest
    row.append(point(x+cos(a)*breadth,-.9+altitude,z+(1.15*sin(3*a+.5)+.34*cos(j*1.5))*(1 if k==0 else .24)))
   else:row.append(point(x+cos(a)*(w+ripple),floor+crest*(h+ripple*2),z+.35*sin(3*a+k*.17)))
  # Additional bottom vertices keep broad chamber floors gently uneven.
  for j in range(1,8):
   u=j/8;row.append(point(x+(2*u-1)*(breadth if outer else w),-.95 if outer else floor+.08*sin(u*pi)*sin(z*.43+u*4),z))
  sections.append(row)
  if prev:bridge(prev[int(outer)],row)
 if k==0:bridge(*sections)
 if k==len(rings)-1:
  for row in sections:faces.append(tuple(row))
 prev=sections
mesh=bpy.data.meshes.new("Stratified limestone");mesh.from_pydata(verts,[],faces);mesh.update()
obj=bpy.data.objects.new("Eastern ridge and chambers",mesh);bpy.context.collection.objects.link(obj);bpy.context.view_layer.objects.active=obj;obj.select_set(True)
bpy.ops.object.mode_set(mode="EDIT");bpy.ops.mesh.select_all(action="SELECT");bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode="OBJECT")
for p in mesh.polygons:p.use_smooth=True
# Fused-looking limestone buttresses; bases are buried in the ridge or chamber wall.
rng=random.Random(541)
for x,z,y,r,height in [(68,-10,.4,3.8,5.3),(84,-10,.4,4.2,6.3),(69,-5,1,3.1,6),(83,-6,1,3.3,5),(58.8,24,2.2,1.55,8),(71.6,25,2,1.75,7.4),(54.2,43,2.6,2.3,10),(74,46,2.7,2.2,10),(64,56,2.8,3,7)]:
 v=[];f=[];phase=rng.random()*6
 for level,(lift,width) in enumerate([(-.25,1.2),(.12,1),(.48,.69),(.76,.61),(1,.24)]):
  for j in range(9):
   a=2*pi*j/9+phase+.11*level;rr=r*width*rng.uniform(.85,1.17)
   v.append((x+cos(a)*rr+.23*level,-z+sin(a)*rr,y+height*lift+.13*sin(3*a)))
  if level:
   for j in range(9):
    k=(j+1)%9;i=9*level;f.append((i-9+j,i-9+k,i+k,i+j))
 f.extend([tuple(reversed(range(9))),tuple(range(36,45))])
 m=bpy.data.meshes.new("Fracture");m.from_pydata(v,[],f);m.update()
 o=bpy.data.objects.new("Limestone spur",m);bpy.context.collection.objects.link(o)
bpy.ops.object.select_all(action="SELECT");bpy.ops.object.join()
bpy.ops.wm.save_as_mainfile(filepath=str(root/"Cave.blend"))
bpy.ops.wm.obj_export(filepath=str(root/"cave.obj"),export_materials=False,export_triangulated_mesh=True)
