"""Quadruped IK rig and skinning of the approved imported boar, Stage A only."""
import bpy, sys, json, math
from pathlib import Path
from mathutils import Vector, Matrix
import numpy as np

out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
prep=json.loads((out/'preparation.json').read_text())
space=Matrix(prep['source_to_rig_matrix'])
def P(x,y,z):return space@Vector((x,y,z))
scene=bpy.context.scene
high=bpy.data.objects['DemonBoar_HighSource']
low=bpy.data.objects['DemonBoar_LOD0']
cage=bpy.data.objects['DemonBoar_Weight_Cage']
collection=bpy.data.collections['DEMON_BOAR_STAGE_A']

# Bake source geometry detail to the export derivative; preserve original colour.
texture_dir=out/'textures';texture_dir.mkdir(exist_ok=True)
normal_path=texture_dir/'normal_2048.png'
mat=low.data.materials[0];nodes=mat.node_tree.nodes
normal_node=nodes.new('ShaderNodeTexImage');normal_node.name='Baked source normal'
if normal_path.is_file():
    normal=bpy.data.images.load(str(normal_path),check_existing=False)
else:
    normal=bpy.data.images.new('DemonBoar_Source_Normal_2048',2048,2048,alpha=False)
    normal.colorspace_settings.name='Non-Color';normal_node.image=normal;nodes.active=normal_node
    high.hide_set(False);high.hide_render=False
    low.hide_set(False);low.hide_render=False
    bpy.ops.object.select_all(action='DESELECT');high.select_set(True);low.select_set(True)
    bpy.context.view_layer.objects.active=low
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
    bpy.ops.object.bake(type='NORMAL',use_selected_to_active=True,cage_extrusion=.025,max_ray_distance=.06,normal_space='TANGENT',margin=8)
    normal.filepath_raw=str(normal_path);normal.file_format='PNG';normal.save()
normal.colorspace_settings.name='Non-Color';normal.pack();normal_node.image=normal
normal_map=nodes.new('ShaderNodeNormalMap');normal_map.name='Preserved high-source surface detail'
mat.node_tree.links.new(normal_node.outputs['Color'],normal_map.inputs['Color'])
bs=next(node for node in nodes if node.type=='BSDF_PRINCIPLED')
mat.node_tree.links.new(normal_map.outputs['Normal'],bs.inputs['Normal'])
high.hide_render=True;high.hide_set(True)
print('SOURCE_NORMAL_BAKE_READY',flush=True)

data=bpy.data.armatures.new('DemonBoar_Quadruped_Skeleton')
rig=bpy.data.objects.new('DemonBoarRig',data);collection.objects.link(rig)
rig.show_in_front=True;data.display_type='OCTAHEDRAL'
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
def bone(name,head,tail,parent=None,deform=True):
    b=data.edit_bones.new(name);b.head=head;b.tail=tail
    if parent:b.parent=data.edit_bones[parent]
    b.use_deform=deform;b.inherit_scale='NONE'
    return b
bone('root',Vector((0,0,0)),Vector((0,0,.25)),deform=False)
bone('pelvis',P(-.18,0,.04),P(-.08,0,.07),'root')
bone('spine_01',P(-.08,0,.07),P(0,0,.08),'pelvis')
bone('spine_02',P(0,0,.08),P(.07,0,.08),'spine_01')
bone('chest',P(.07,0,.08),P(.18,0,.08),'spine_02')
bone('neck',P(.18,0,.08),P(.29,0,.03),'chest')
bone('head',P(.29,0,.03),P(.44,0,-.06),'neck')
bone('jaw',P(.33,0,-.065),P(.445,0,-.12),'head')
bone('tail_01',P(-.28,0,.07),P(-.37,0,.075),'pelvis')
bone('tail_02',P(-.37,0,.075),P(-.43,0,.07),'tail_01')
bone('tail_03',P(-.43,0,.07),P(-.485,0,.075),'tail_02')
bone('mane_01',P(.07,0,.15),P(.11,0,.235),'chest')
bone('mane_02',P(.18,0,.14),P(.23,0,.22),'neck')
legs={}
for side,sign in [('L',1),('R',-1)]:
    bone('ear.'+side,P(.28,sign*.095,.085),P(.29,sign*.135,.13),'head')
    for end in ['front','rear']:
        tag=end+'.'+side
        sole=Vector(prep['feet'][tag]['source_sole'])
        ankle=P(sole.x-.020,sole.y,sole.z+.055)
        toe=P(sole.x+.045,sole.y,sole.z+.013)
        ctl='CTRL_foot_'+tag
        bone(ctl,ankle,toe,'root',False)
        if end=='front':
            shoulder=P(.16,sign*.105,.065);elbow=P(.20,sign*.110,-.080)
            bone('shoulder.'+side,P(.10,0,.08),shoulder,'chest')
            upper='front_upper.'+side;lower='front_lower.'+side;hoof='front_hoof.'+side
            bone(upper,shoulder,elbow,'shoulder.'+side)
            bone(lower,elbow,ankle,upper)
            bone(hoof,ankle,toe,lower)
            target=ctl;joint=elbow
        else:
            hip=P(-.19,sign*.105,.055);knee=P(-.115,sign*.110,-.075);hock=P(-.255,sign*.120,-.145)
            upper='rear_thigh.'+side;lower='rear_shin.'+side;hoof='rear_hoof.'+side
            bone(upper,hip,knee,'pelvis');bone(lower,knee,hock,upper)
            pastern='rear_pastern.'+side
            bone(pastern,hock,ankle,lower);bone(hoof,ankle,toe,pastern)
            target='CTRL_hock_'+side;bone(target,hock,ankle,ctl,False)
            joint=knee
        start=data.edit_bones[upper].head.copy();finish=data.edit_bones[lower].tail.copy()
        axis=finish-start;projection=start+axis*((joint-start).dot(axis)/axis.length_squared)
        bend=(joint-projection).normalized()
        pole='CTRL_pole_'+tag;position=joint+bend*1.2
        bone(pole,position,position+Vector((0,0,.12)),'root',False)
        legs[tag]={'upper':upper,'lower':lower,'hoof':hoof,'controller':ctl,'pole':pole,'ik_target':target,'ankle_rest':list(ankle),'sole_rest':prep['feet'][tag]['sole'],'sole_offset':list(Vector(prep['feet'][tag]['sole'])-ankle),'joint_rest':list(joint)}
bpy.ops.object.mode_set(mode='POSE')
for tag,leg in legs.items():
    lower=rig.pose.bones[leg['lower']]
    ik=lower.constraints.new('IK');ik.name='Stable two-link leg IK'
    ik.target=rig;ik.subtarget=leg['ik_target'];ik.chain_count=2;ik.use_stretch=False
    ik.pole_target=rig;ik.pole_subtarget=leg['pole']
    for name in [leg['upper'],leg['lower']]:rig.pose.bones[name].ik_stretch=0
    if tag.startswith('rear'):
        follow=rig.pose.bones['rear_pastern.'+tag[-1]].constraints.new('COPY_ROTATION')
        follow.target=rig;follow.subtarget=leg['ik_target'];follow.owner_space='POSE';follow.target_space='POSE'
    follow=rig.pose.bones[leg['hoof']].constraints.new('COPY_ROTATION')
    follow.target=rig;follow.subtarget=leg['controller'];follow.owner_space='POSE';follow.target_space='POSE'
    # Calibrate pole angle against the actual bind knee/elbow before skinning.
    desired=Vector(leg['joint_rest']);best=None
    for angle in np.linspace(-math.pi,math.pi,65):
        ik.pole_angle=float(angle);bpy.context.view_layer.update()
        error=(rig.pose.bones[leg['lower']].head-desired).length
        if best is None or error<best[0]:best=(error,float(angle))
    coarse=best[1]
    for angle in np.linspace(coarse-math.pi/32,coarse+math.pi/32,65):
        ik.pole_angle=float(angle);bpy.context.view_layer.update()
        error=(rig.pose.bones[leg['lower']].head-desired).length
        if error<best[0]:best=(error,float(angle))
    ik.pole_angle=best[1];leg['pole_angle']=best[1];leg['bind_joint_error_m']=best[0]
    assert best[0]<.0005,(tag,'IK bind alignment',best)
    for name in [leg['controller'],leg['pole'],leg['ik_target']]:
        data.bones[name].color.palette='THEME03'
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.update()
print('IK_BIND_ALIGNMENT_PASS '+json.dumps({tag:leg['bind_joint_error_m'] for tag,leg in legs.items()}),flush=True)

# Standard closed-cage bone-heat binding, transferred without changing surfaces.
data.pose_position='REST'
cage.hide_set(False)
bpy.ops.object.select_all(action='DESELECT');cage.select_set(True);rig.select_set(True)
bpy.context.view_layer.objects.active=rig
try:bpy.ops.object.parent_set(type='ARMATURE_AUTO')
except RuntimeError as exc:print('CAGE_AUTO_WEIGHT_NOTE '+str(exc),flush=True)
deform_names=[b.name for b in data.bones if b.use_deform]
for name in deform_names:
    if name not in cage.vertex_groups:cage.vertex_groups.new(name=name)

def fallback_empty_weights(obj):
    names={g.index:g.name for g in obj.vertex_groups}
    empty=[v for v in obj.data.vertices if not any(g.weight>1e-6 for g in v.groups)]
    for v in empty:
        best=None
        for name in deform_names:
            b=data.bones[name];a=b.head_local;d=b.tail_local-a
            t=max(0,min(1,(v.co-a).dot(d)/max(d.length_squared,1e-9)))
            distance=(v.co-a-d*t).length_squared
            if best is None or distance<best[0]:best=(distance,name)
        obj.vertex_groups[best[1]].add([v.index],1,'REPLACE')
    return len(empty)
repaired_cage=fallback_empty_weights(cage)
print('CAGE_WEIGHTS_READY repaired_empty='+str(repaired_cage),flush=True)

weight_reports={}
def bind(obj):
    obj.hide_set(False)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    for name in deform_names:
        if name not in obj.vertex_groups:obj.vertex_groups.new(name=name)
    transfer=obj.modifiers.new('Interpolated cage skin weights','DATA_TRANSFER')
    transfer.object=cage;transfer.use_vert_data=True;transfer.data_types_verts={'VGROUP_WEIGHTS'}
    transfer.vert_mapping='POLYINTERP_NEAREST';transfer.layers_vgroup_select_src='ALL';transfer.layers_vgroup_select_dst='NAME'
    bpy.ops.object.modifier_apply(modifier=transfer.name)
    count=len(obj.data.vertices);weights=np.zeros((count,len(deform_names)),dtype=np.float32)
    indices={obj.vertex_groups[name].index:i for i,name in enumerate(deform_names)}
    for v in obj.data.vertices:
        for g in v.groups:
            if g.group in indices:weights[v.index,indices[g.group]]=g.weight
    positions=np.empty(count*3,dtype=np.float32);obj.data.vertices.foreach_get('co',positions);positions=positions.reshape(-1,3)
    # Protect the tusk/skull silhouette and make hoof contact truly rigid.
    skull=(positions[:,1]>1.04)&(positions[:,2]>.30)
    weights[skull]=0;weights[skull,deform_names.index('head')]=1
    jaw=skull&(positions[:,2]<.44)&(np.abs(positions[:,0])<.29)
    weights[jaw]=0;weights[jaw,deform_names.index('jaw')]=1
    rigid_counts={}
    for tag,leg in legs.items():
        sole=np.array(leg['sole_rest'])
        radius=((positions[:,:2]-sole[:2])**2).sum(axis=1)
        mask=(radius<.21**2)&(positions[:,2]<sole[2]+.18)
        weights[mask]=0;weights[mask,deform_names.index(leg['hoof'])]=1
        rigid_counts[tag]=int(mask.sum())
        assert rigid_counts[tag]>10
    sums=weights.sum(axis=1);empty=np.flatnonzero(sums<1e-7)
    for index in empty:
        point=Vector(positions[index]);best=min(deform_names,key=lambda name:(data.bones[name].head_local-point).length_squared)
        weights[index,deform_names.index(best)]=1
    top=np.argpartition(weights,-4,axis=1)[:,-4:]
    selected=np.take_along_axis(weights,top,axis=1);selected/=selected.sum(axis=1,keepdims=True)
    desired=selected*255;quantized=np.floor(desired).astype(np.int16)
    remainder=255-quantized.sum(axis=1)
    fractions=np.argsort(-(desired-quantized),axis=1)
    for rank in range(3):
        rows=np.flatnonzero(remainder>rank);quantized[rows,fractions[rows,rank]]+=1
    assert np.all(quantized.sum(axis=1)==255)
    obj.vertex_groups.clear()
    for i,name in enumerate(deform_names):
        group=obj.vertex_groups.new(name=name)
        rows,columns=np.where((top==i)&(quantized>0))
        values=quantized[rows,columns]
        for value in np.unique(values):group.add(rows[values==value].tolist(),int(value)/255,'REPLACE')
    modifier=obj.modifiers.new('Demon Boar quadruped skin','ARMATURE');modifier.object=rig
    obj.parent=rig;obj.matrix_parent_inverse=Matrix.Identity(4)
    weight_reports[obj.name]={'vertices':count,'unweighted_vertices':0,'max_influences':4,'quantized_weight_sum_units':255,'rigid_hoof_vertices':rigid_counts,'repaired_unweighted':len(empty)}
    print('MESH_BIND_PASS '+obj.name+' '+str(count),flush=True)
bind(low)
bind(high)
high.hide_set(True);high.hide_render=True
for modifier in high.modifiers:
    if modifier.type=='ARMATURE':modifier.show_viewport=False;modifier.show_render=False
cage.hide_set(True);cage.hide_render=True
data.pose_position='POSE'
for pb in rig.pose.bones:pb.rotation_mode='QUATERNION'
rig['phase']='3.2 Stage A only';rig['forward_axis']='Blender +Y / Godot -Z'
rig['root_motion']='In-place; game code controls displacement'
scene.render.engine='CYCLES';scene.cycles.samples=48;scene.cycles.use_denoising=False
scene.frame_set(1);bpy.context.view_layer.update()
(out/'rig_definition.json').write_text(json.dumps({'bones':[{'name':b.name,'parent':b.parent.name if b.parent else None,'deform':b.use_deform,'head':list(b.head_local),'tail':list(b.tail_local)} for b in data.bones],'legs':legs,'weights':weight_reports,'repaired_cage_vertices':repaired_cage,'source_normal_bake':str(normal_path.name)},indent=2),encoding='utf-8')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'rigged_base.blend'),compress=True)
print('STAGE_A_RIG_AND_WEIGHTS_READY bones='+str(len(data.bones)),flush=True)
