"""Create only idle/walk/run, verify contacts, and bake a clean Godot skeleton."""
import bpy, sys, json, math, struct
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion
import numpy as np

out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
definition=json.loads((out/'rig_definition.json').read_text())
legs=definition['legs'];rig=bpy.data.objects['DemonBoarRig'];low=bpy.data.objects['DemonBoar_LOD0']
scene=bpy.context.scene;scene.render.fps=30
specs={'idle':{'frames':120,'seconds':4.0,'speed_mps':0.0,'duty':1.0,'stride_m':0.0,'lift_m':0.0},'walk':{'frames':36,'seconds':1.2,'speed_mps':.65,'duty':.65,'stride_m':.507,'lift_m':.12},'run':{'frames':18,'seconds':.6,'speed_mps':2.6,'duty':.42,'stride_m':.6552,'lift_m':.19}}
offsets={'walk':{'rear.L':0,'front.L':.25,'rear.R':.5,'front.R':.75},'run':{'front.L':0,'rear.R':0,'front.R':.5,'rear.L':.5}}
inverse={pb.name:pb.bone.matrix_local.to_3x3().inverted() for pb in rig.pose.bones}
def move(name,delta):rig.pose.bones[name].location=inverse[name]@Vector(delta)
def rotate(name,axis,angle):rig.pose.bones[name].rotation_quaternion=Quaternion((inverse[name]@Vector(axis)).normalized(),angle)
def gait(phase,spec):
    duty=spec['duty'];stride=spec['stride_m'];lift=spec['lift_m']
    if phase<=duty:return stride*(.5-phase/duty),0.0,0.0,True
    u=(phase-duty)/(1-duty)
    h00=2*u**3-3*u*u+1;h10=u**3-2*u*u+u;h01=-2*u**3+3*u*u;h11=u**3-u*u
    tangent=-stride*(1-duty)/duty
    y=h00*(-stride*.5)+h10*tangent+h01*(stride*.5)+h11*tangent
    arc=math.sin(math.pi*u)**2
    return y,lift*arc,math.radians(12)*arc,False
def pose(name,phase):
    for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
    theta=2*math.pi*phase
    if name=='idle':
        breath=math.sin(theta)
        move('pelvis',(0,0,-.025+.002*breath))
        # Uniform bone expansion preserves a shear-free glTF hierarchy while
        # retaining visible chest/rib breathing and pinned foot IK.
        rig.pose.bones['chest'].scale=(1+.012*breath,)*3
        rig.pose.bones['spine_01'].scale=(1+.006*breath,)*3
        rotate('neck',(1,0,0),.008*math.sin(theta+.3))
        rotate('head',(0,0,1),.009*math.sin(theta))
        twitch=math.sin(theta*5)**2*math.exp(-((phase-.55)/.11)**2)
        rotate('ear.L',(0,1,0),.08*twitch);rotate('ear.R',(0,1,0),-.055*twitch)
    elif name=='walk':
        move('pelvis',(.009*math.sin(theta),0,-.075+.014*math.cos(theta*2)))
        rotate('pelvis',(0,1,0),.013*math.sin(theta))
        rotate('spine_01',(1,0,0),.009*math.sin(theta))
        rotate('spine_02',(0,1,0),-.009*math.sin(theta))
        rotate('chest',(1,0,0),.011*math.sin(theta+.6))
        rotate('neck',(1,0,0),-.013*math.sin(theta+.6))
        rotate('head',(1,0,0),.007*math.cos(theta*2))
    else:
        move('pelvis',(0,0,-.12+.04*math.cos(theta*2)))
        rotate('pelvis',(1,0,0),.025*math.sin(theta))
        rotate('spine_01',(1,0,0),.012*math.sin(theta+.6))
        rotate('spine_02',(1,0,0),-.009*math.sin(theta+.2))
        rotate('chest',(1,0,0),.021*math.sin(theta+.6))
        rotate('neck',(1,0,0),-.025+.018*math.sin(theta+1))
        rotate('head',(1,0,0),.011*math.sin(theta+.8))
    for i in range(1,4):rotate('tail_%02d'%i,(0,0,1),(.045 if name=='idle' else .075)*math.sin(theta+(i-1)*.4))
    rotate('mane_01',(1,0,0),.006*math.sin(theta))
    rotate('mane_02',(1,0,0),.006*math.sin(theta+.3))
    contacts={};desired={}
    for tag,leg in legs.items():
        if name=='idle':y,z,pitch,contact=0,0,0,True
        else:y,z,pitch,contact=gait((phase-offsets[name][tag])%1,specs[name])
        # Neutralize the source's protracted front stance for supported locomotion.
        center_shift=(0.0 if name=='idle' else -.22) if tag.startswith('front') else -.04
        delta=Vector((0,center_shift+y,-leg['sole_rest'][2]+z))
        move(leg['controller'],delta)
        rotate(leg['controller'],(1,0,0),pitch)
        contacts[tag]=contact;desired[tag]=Vector(leg['ankle_rest'])+delta
    return contacts,desired

rig.animation_data_create();actions={};metrics={};reference_samples={}
deform_names=[pb.name for pb in rig.pose.bones if pb.bone.use_deform]
for name,spec in specs.items():
    action=bpy.data.actions.new(name);action.use_fake_user=True
    rig.animation_data.action=action;actions[name]=action
    prior={};first=None;samples=[];maximum={'ik_target_error_m':0.0,'stance_sole_height_error_m':0.0,'stance_slip_per_frame_m':0.0,'leg_length_relative_error':0.0,'root_translation_m':0.0}
    for index in range(spec['frames']+1):
        frame=index+1;scene.frame_set(frame)
        phase=0.0 if index==spec['frames'] else index/spec['frames']
        contacts,desired=pose(name,phase);bpy.context.view_layer.update()
        for pb in rig.pose.bones:
            pb.keyframe_insert('location',frame=frame,group=pb.name)
            pb.keyframe_insert('rotation_quaternion',frame=frame,group=pb.name)
            pb.keyframe_insert('scale',frame=frame,group=pb.name)
        for tag,leg in legs.items():
            hoof=rig.pose.bones[leg['hoof']]
            maximum['ik_target_error_m']=max(maximum['ik_target_error_m'],(hoof.head-desired[tag]).length)
            sole=hoof.matrix@hoof.bone.matrix_local.inverted()@Vector(leg['sole_rest'])
            virtual=sole+Vector((0,index/30*spec['speed_mps'],0))
            if contacts[tag]:
                maximum['stance_sole_height_error_m']=max(maximum['stance_sole_height_error_m'],abs(sole.z))
                if tag in prior and prior[tag][0]:maximum['stance_slip_per_frame_m']=max(maximum['stance_slip_per_frame_m'],(virtual-prior[tag][1]).length)
            prior[tag]=(contacts[tag],virtual)
            for bone_name in [leg['upper'],leg['lower']]:
                pb=rig.pose.bones[bone_name]
                error=abs((pb.tail-pb.head).length/pb.bone.length-1)
                maximum['leg_length_relative_error']=max(maximum['leg_length_relative_error'],error)
        maximum['root_translation_m']=max(maximum['root_translation_m'],rig.pose.bones['root'].location.length)
        matrices={pb.name:np.array(pb.matrix) for pb in rig.pose.bones if pb.bone.use_deform}
        samples.append(np.array([rig.pose.bones[key].matrix@rig.data.bones[key].matrix_local.inverted() for key in deform_names],dtype=np.float32))
        if first is None:first=matrices
        if index==spec['frames']:maximum['loop_matrix_difference']=max(float(np.abs(matrices[key]-first[key]).max()) for key in matrices)
    for curve in action.fcurves:
        for key in curve.keyframe_points:key.interpolation='LINEAR'
    action['loop']=True;action['nominal_speed_mps']=spec['speed_mps'];action['root_motion']='in_place'
    metrics[name]=maximum
    reference_samples[name]=np.stack(samples)
    print('CLIP_CONTACT_METRICS '+name+' '+json.dumps(maximum),flush=True)

(out/'animation_metrics.json').write_text(json.dumps({'clips':specs,'measurements':metrics,'notes':'Slip is measured after compensating the in-place cycle with its declared travel speed. Preview actor displacement is separate from exported root motion.'},indent=2),encoding='utf-8')
np.savez_compressed(out/'reference_deformation.npz',**reference_samples)
(out/'reference_bones.json').write_text(json.dumps(deform_names),encoding='utf-8')
rig.animation_data.action=actions['idle'];scene.frame_set(1);bpy.context.view_layer.update()
scene.frame_start=1;scene.frame_end=121
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'locomotion_work.blend'),compress=True)
for name,m in metrics.items():
    assert m['ik_target_error_m']<.008,(name,'unreachable leg target',m)
    assert m['stance_sole_height_error_m']<.005,(name,'hoof contact',m)
    assert m['stance_slip_per_frame_m']<.004,(name,'stance slide',m)
    assert m['leg_length_relative_error']<.002,(name,'joint stretch',m)
    assert m['loop_matrix_difference']<1e-5 and m['root_translation_m']<1e-7,(name,'loop/root drift',m)

# Bake control/IK results into an ordinary parented deformation skeleton.
export_rig=rig.copy();export_rig.data=rig.data.copy();export_rig.name='DemonBoar_ExportRig'
bpy.data.collections['DEMON_BOAR_STAGE_A'].objects.link(export_rig)
export_rig.animation_data_clear()
for pb in export_rig.pose.bones:
    for constraint in list(pb.constraints):pb.constraints.remove(constraint)
bpy.ops.object.select_all(action='DESELECT');export_rig.select_set(True);bpy.context.view_layer.objects.active=export_rig
bpy.ops.object.mode_set(mode='EDIT')
for b in list(export_rig.data.edit_bones):
    if not b.use_deform and b.name!='root':export_rig.data.edit_bones.remove(b)
for b in export_rig.data.edit_bones:b.inherit_scale='FULL'
bpy.ops.object.mode_set(mode='OBJECT')
for pb in export_rig.pose.bones:pb.rotation_mode='QUATERNION'
export_rig.animation_data_create();baked=[]
ordered=sorted(export_rig.pose.bones,key=lambda pb:len(pb.parent_recursive))
for name,spec in specs.items():
    rig.animation_data.action=actions[name]
    action=bpy.data.actions.new('__EXPORT_'+name);baked.append(action)
    export_rig.animation_data.action=action
    for index in range(spec['frames']+1):
        frame=index+1;scene.frame_set(frame);bpy.context.view_layer.update()
        matrices={pb.name:rig.pose.bones[pb.name].matrix.copy() for pb in ordered}
        for pb in ordered:
            rest=pb.bone.matrix_local
            if pb.parent:
                local_rest=pb.parent.bone.matrix_local.inverted()@rest
                local_pose=matrices[pb.parent.name].inverted()@matrices[pb.name]
            else:local_rest=rest;local_pose=matrices[pb.name]
            pb.matrix_basis=local_rest.inverted()@local_pose
            pb.keyframe_insert('location',frame=frame,group=pb.name)
            pb.keyframe_insert('rotation_quaternion',frame=frame,group=pb.name)
            pb.keyframe_insert('scale',frame=frame,group=pb.name)
    for curve in action.fcurves:
        for key in curve.keyframe_points:key.interpolation='LINEAR'
    track=export_rig.animation_data.nla_tracks.new();track.name=name
    strip=track.strips.new(name,1,action);strip.extrapolation='NOTHING';track.mute=True
    export_rig.animation_data.action=None

original_parent=low.parent;low.parent=export_rig
armature=next(mod for mod in low.modifiers if mod.type=='ARMATURE');armature.object=export_rig
for track in export_rig.animation_data.nla_tracks:track.mute=False
# Isolate the baked runtime dependency graph so unrelated control actions cannot
# be considered by the exporter. The editable source retains all IK controls.
bpy.data.libraries.write(str(out/'runtime_export_snapshot.blend'),{export_rig,low},fake_user=False,compress=True)
low.parent=original_parent;armature.object=rig
bpy.data.objects.remove(export_rig,do_unlink=True)
for action in baked:bpy.data.actions.remove(action,do_unlink=True)
rig.animation_data.action=actions['idle'];scene.frame_set(1);bpy.context.view_layer.update()
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.wm.save_as_mainfile(filepath=str(out/'demon_boar_stage_a.blend'),compress=True)
print('STAGE_A_EDITABLE_CLIPS_AND_RUNTIME_SNAPSHOT_PASS',flush=True)
