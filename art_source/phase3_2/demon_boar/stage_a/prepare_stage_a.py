"""Preserve approved high source; prepare a separate animation/export mesh."""
import bpy, bmesh, sys, json, math, hashlib
from pathlib import Path
from mathutils import Vector, Matrix
import numpy as np

out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
out.mkdir(parents=True,exist_ok=True)
source=Path(bpy.data.filepath)
model=next(obj for obj in bpy.data.collections['DEMON_BOAR_IMPORTED_SOURCE'].objects if obj.type=='MESH')
coords=np.empty(len(model.data.vertices)*3,dtype=np.float32)
model.data.vertices.foreach_get('co',coords);coords=coords.reshape(-1,3)
mw=np.array(model.matrix_world,dtype=np.float64)
points=coords@mw[:3,:3].T+mw[:3,3]
lo=points.min(axis=0);hi=points.max(axis=0)
scale=3.0/(hi[0]-lo[0])
center=(lo+hi)*.5
# Source +X forward -> Blender +Y forward -> Godot -Z forward.
transform=Matrix(((0,-scale,0,center[1]*scale),(scale,0,0,-center[0]*scale),(0,0,scale,-lo[2]*scale),(0,0,0,1)))
feet={}
for end,front in [('front',True),('rear',False)]:
    for side,positive in [('L',True),('R',False)]:
        mask=(points[:,2]<lo[2]+.12)&(points[:,0]<lo[0]+.83*(hi[0]-lo[0]))&(points[:,0]>lo[0]+.10*(hi[0]-lo[0]))
        mask&=(points[:,0]>-.015) if front else (points[:,0]<-.015)
        mask&=(points[:,1]>0) if positive else (points[:,1]<0)
        group=points[mask]; assert len(group)>20,(end,side)
        minimum=float(group[:,2].min())
        sole=group[group[:,2]<minimum+.018]
        foot=np.array([np.median(sole[:,0]),np.median(sole[:,1]),minimum])
        feet[end+'.'+side]={'source_sole':foot.tolist(),'sole':list(transform@Vector(foot)),'source_lower_leg_points':len(group),'source_sole_points':len(sole)}
model.data.transform(transform@model.matrix_world)
model.matrix_world=Matrix.Identity(4)
model.name='DemonBoar_HighSource'
source_collection=bpy.data.collections.new('HIGH_RES_APPROVED_SOURCE')
bpy.context.scene.collection.children.link(source_collection)
source_collection.objects.link(model)
for old in list(model.users_collection):
    if old!=source_collection:old.objects.unlink(model)

# The existing studio is resized to the same physical unit conversion.
studio=bpy.data.collections['REVIEW_STUDIO_ONLY']
for obj in studio.objects:
    obj.matrix_world=transform@obj.matrix_world
    if obj.type=='LIGHT':obj.data.energy*=scale*scale
    if obj.type=='CAMERA':obj.data.clip_end*=scale;obj.data.clip_start*=scale

low=model.copy();low.data=model.data.copy();low.name='DemonBoar_LOD0'
# Connect geometry across imported UV splits before reduction. Per-corner UVs
# remain separate, while skinning and decimation share the physical surface.
bm=bmesh.new();bm.from_mesh(low.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-5)
bm.to_mesh(low.data);bm.free();low.data.update()
working=bpy.data.collections.new('DEMON_BOAR_STAGE_A')
bpy.context.scene.collection.children.link(working);working.objects.link(low)
bpy.ops.object.select_all(action='DESELECT');low.select_set(True);bpy.context.view_layer.objects.active=low
dec=low.modifiers.new('Review export density','DECIMATE');dec.ratio=120000/1917784;dec.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=dec.name)
low.data.calc_loop_triangles()
assert len(low.data.loop_triangles)<125000
low.data.materials[0]=low.data.materials[0].copy();low.data.materials[0].name='DemonBoar_Preserved_Color_LOD0'

# Coarse closed weight cage only; never exported or rendered as the creature.
cage=model.copy();cage.data=model.data.copy();cage.name='DemonBoar_Weight_Cage'
working.objects.link(cage)
bpy.context.view_layer.objects.active=cage
remesh=cage.modifiers.new('Closed weighting volume','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.035;remesh.use_smooth_shade=True
bpy.ops.object.modifier_apply(modifier=remesh.name)
dec=cage.modifiers.new('Weight cage density','DECIMATE');dec.ratio=.35
bpy.ops.object.modifier_apply(modifier=dec.name)
cage.hide_render=True
model.hide_render=True
model.hide_set(True);cage.hide_set(True)
bpy.context.view_layer.objects.active=low
for obj in list(bpy.context.selected_objects):obj.select_set(False)
low.select_set(True)
report={'source_glb_sha256':'950ca3587e4e0ab59dd727d75d21cec613ed146b6852f2de65e3ef2a82cc06cd','high_source_vertices':len(model.data.vertices),'high_source_triangles':1917784,'export_triangles':len(low.data.loop_triangles),'export_vertices':len(low.data.vertices),'source_scale_to_meters':scale,'provisional_body_length_m':3.0,'blender_forward':'+Y','godot_forward':'-Z','source_to_rig_matrix':[list(row) for row in transform],'feet':feet,'raw_glb_unchanged':True,'appearance_design_changes':False,'optimization_copy_only':True}
(out/'preparation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
bpy.context.scene['phase_scope']='Phase 3.2 Stage A only; rig and idle/walk/run; no combat or game AI integration'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'prepared_source.blend'),compress=True)
print('STAGE_A_PREPARATION_PASS '+json.dumps({key:report[key] for key in ['export_triangles','export_vertices','source_scale_to_meters','feet']}),flush=True)
