"""Prepare user-authored regional meshes locally; original remains untouched."""
import bpy,bmesh,json,math,sys
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
R=Path(args[0]).resolve() if args else Path(__file__).resolve().parents[2]
A=R/'assets/environment/new_island';S=R/'art_source/island'
A.mkdir(parents=True,exist_ok=True);S.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(S/'Island_original.glb'))
objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
# Blender X/Y is Godot X/-Z. Dimensions are chosen separately, never one giant GLB scale.
settings=[('WaterfallMountains',(0,-68),66,190,7.0),('WesternForest',(-64,-8),54,220,9.0),('RiverGrassland',(5,2),64,70,2.8),('EasternCaves',(68,-10),48,115,5.8),('SouthernBeach',(0,66),86,50,2.1)]
def smooth(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
def ground(x,z):
 radial=math.hypot(x,z)-(5*math.sin(math.atan2(z,x)*3)+3*math.sin(math.atan2(z,x)*5)+1.5*math.sin(math.atan2(z,x)*7))
 h=(1.6+1.2*math.sin(x*.045)*math.cos(z*.04)+.6*math.sin(x*.09+z*.04))*(1-.72*smooth(30,80,z))
 h=h*(1-smooth(88,118,radial))-2.5*smooth(88,118,radial)
 r=(1-smooth(2.3,5.5,abs(x-(23+5*math.sin((z+35)*.065)))))*smooth(-45,-33,z)*(1-smooth(91,106,z))
 h=h*(1-r)-1.8*r
 t=max(0,min(1,(z+68)/30));creek=(1-smooth(2.0,5.0,abs(x-((z+68)*22/30+3*math.sin(t*math.pi)))))*smooth(-70,-66,z)*(1-smooth(-40,-36,z))
 bed=-.0-1.8*max(0,min(1,(z+68)/30))
 return h*(1-creek)+bed*creek
report=[]
for index,(o,(name,center,width,zscale,zoffset)) in enumerate(zip(objects,settings)):
 removed_forest_faces=0
 if index==1:
  # Remove broad reconstruction sheets/slab components, retaining actual tree parts.
  parent=list(range(len(o.data.vertices)))
  def root(x):
   while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
   return x
  for edge in o.data.edges:
   a,b=map(root,edge.vertices);parent[b]=a
  groups={}
  for v in o.data.vertices:groups.setdefault(root(v.index),[]).append(v.co.copy())
  forest_anchors=[]
  for vs in groups.values():
   lo=[min(v[a] for v in vs) for a in range(3)];hi=[max(v[a] for v in vs) for a in range(3)]
   if hi[2]-lo[2]>.01 and max(hi[a]-lo[a] for a in [0,1])<.009:forest_anchors.append(((lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2]))
  unwanted={k for k,vs in groups.items() if max(max(v[a] for v in vs)-min(v[a] for v in vs) for a in [0,1])>.025}
  bm=bmesh.new();bm.from_mesh(o.data);bm.verts.ensure_lookup_table();bm.faces.ensure_lookup_table()
  remove=[f for f in bm.faces if root(f.verts[0].index) in unwanted];removed_forest_faces=len(remove)
  bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(o.data);bm.free()
  # Replant each retained tree-part component relative to its nearest trunk root.
  parent=list(range(len(o.data.vertices)))
  for edge in o.data.edges:
   a,b=map(root,edge.vertices);parent[b]=a
  retained={}
  for v in o.data.vertices:retained.setdefault(root(v.index),[]).append(v.co.copy())
  forest_roots={}
  for k,vs in retained.items():
   x=sum(v.x for v in vs)/len(vs);y=sum(v.y for v in vs)/len(vs)
   forest_roots[k]=min(forest_anchors,key=lambda a:(a[0]-x)**2+(a[1]-y)**2)
 xs=[v.co.x for v in o.data.vertices];ys=[v.co.y for v in o.data.vertices];cx=(min(xs)+max(xs))/2;cy=(min(ys)+max(ys))/2;scale=width/(max(xs)-min(xs))
 halfx=width/2;halfy=(max(ys)-min(ys))*scale/2
 for v in o.data.vertices:
  x=(v.co.x-cx)*scale+center[0];z=-((v.co.y-cy)*scale-center[1]);height=v.co.z*zscale+zoffset
  if index==1:
   anchor=forest_roots[root(v.index)];ax=(anchor[0]-cx)*scale+center[0];az=-((anchor[1]-cy)*scale-center[1])
   height=ground(ax,az)+(v.co.z-anchor[2])*zscale*1.5-.08
  edge=min(halfx-abs(x-center[0]),halfy-abs(z-center[1]))
  # Taper cut diorama edges into the actual connecting landscape, burying slab walls.
  blend=(1-smooth(0,7,edge)) if index!=1 else 0
  height=height*(1-blend)+(ground(x,z)-.035)*blend
  if index in [2,4]:
   channel=(1-smooth(2.3,6,abs(x-(23+5*math.sin((z+35)*.065)))))*smooth(-45,-33,z)
   height=height*(1-channel)-1.8*channel
  if index==0 and height<7.0:
   t=max(0,min(1,(z+68)/30));creek=(1-smooth(2,5,abs(x-((z+68)*22/30+3*math.sin(t*math.pi)))))*smooth(-70,-66,z)*(1-smooth(-40,-36,z))*(1-smooth(3,7,height))
   height=height*(1-creek)+(-1.8*max(0,min(1,(z+68)/30)))*creek
  v.co=Vector((x,-z,height))
 if index==1:
  bm=bmesh.new();bm.from_mesh(o.data)
  remove=[]
  for f in bm.faces:
   c=f.calc_center_median()
   if c.z<ground(c.x,-c.y)+.8 and abs(f.normal.z)>.35:remove.append(f)
  removed_forest_faces+=len(remove)
  bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(o.data);bm.free()
 if index==3:
  # Open a real human-size grotto within the provided cliff region; its interior
  # floor/vault is generated separately in Godot. Do not pretend dark paint is a cave.
  bm=bmesh.new();bm.from_mesh(o.data)
  remove=[]
  for f in bm.faces:
   c=f.calc_center_median()
   if abs(c.x-76)<3.1 and -8 < -c.y < 13 and c.z<5.8:remove.append(f)
  bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(o.data);bm.free()
 o.name=name
 # The source has baked appearance. A 2K derivative is used for ground-level review.
 for mat in o.data.materials:
  for node in mat.node_tree.nodes:
   if node.type=='TEX_IMAGE' and node.image:
    im=node.image
    if im.size[0]>2048:im.scale(2048,2048)
    im.filepath_raw=str(A/(name.lower()+'_albedo.jpg'));im.file_format='JPEG';im.save();im.pack()
  bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bsdf.inputs['Roughness'].default_value=.94
 o.data.update()
 coords=[v.co for v in o.data.vertices]
 report.append({'source_index':index,'region':name,'center_xz':center,'width_m':width,'horizontal_source_to_m':scale,'vertical_source_to_m':zscale,'vertical_offset_m':zoffset,'dimensions_m':[max(v[a] for v in coords)-min(v[a] for v in coords) for a in range(3)],'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'texture_derivative':2048,'edge_taper_m':7 if index!=1 else 0,'removed_forest_sheet_faces':removed_forest_faces,'river_channel_modified':index in [2,4]})
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
 bpy.ops.export_scene.gltf(filepath=str(A/(name+'.glb')),export_format='GLB',use_selection=True,export_yup=True,export_image_format='JPEG',export_image_quality=90,export_animations=False)
(A/'regions.json').write_text(json.dumps(report,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(S/'island_regions.blend'))
print('REGIONAL_ASSETS_READY',json.dumps(report))
