"""Export only the baked runtime rig and independently reimport its animations."""
import bpy, sys, json, struct, hashlib
from pathlib import Path
import numpy as np
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps=30
with bpy.data.libraries.load(str(out/'runtime_export_snapshot.blend'),link=False) as (available,loaded):loaded.objects=list(available.objects)
for obj in loaded.objects:
    if obj:bpy.context.scene.collection.objects.link(obj)
assert len(bpy.data.actions)==8
rig=next(obj for obj in bpy.context.scene.objects if obj.type=='ARMATURE')
bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=rig
settings={'filepath':str(out/'demon_boar_stage_b.glb'),'export_format':'GLB','use_selection':True,'export_animations':True,'export_animation_mode':'NLA_TRACKS','export_force_sampling':True,'export_frame_range':False,'export_frame_step':1,'export_anim_slide_to_zero':True,'export_def_bones':True,'export_skins':True,'export_all_influences':False,'export_cameras':False,'export_lights':False,'export_extras':True,'export_apply':True}
bpy.ops.export_scene.gltf(**settings)
blob=(out/'demon_boar_stage_b.glb').read_bytes();length=struct.unpack_from('<I',blob,12)[0]
gltf=json.loads(blob[20:20+length])
names=[animation.get('name') for animation in gltf.get('animations',[])]
assert set(names)==set(json.loads((out/'animation_metrics.json').read_text())['clips']) and len(names)==8
assert len(gltf.get('skins',[]))==1 and not gltf.get('cameras')
for animation in gltf['animations']:
    assert all(abs(gltf['accessors'][sampler['input']]['min'][0])<1e-7 for sampler in animation['samplers'])
assert all('bufferView' in image for image in gltf['images'])
summary={'animations':names,'skin_joints':len(gltf['skins'][0]['joints']),'glb_bytes':len(blob),'in_place':True,'forward':'-Z in Godot','all_clips_start_at_zero':True,'embedded_images':len(gltf['images']),'settings':settings,'sha256':hashlib.sha256(blob).hexdigest()}
(out/'export_summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')

# Independent importer comparison uses deformation matrices, which are invariant
# to the importer's bone display orientations and head/tail heuristics.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps=30
bpy.ops.import_scene.gltf(filepath=str(out/'demon_boar_stage_b.glb'))
arm=next(obj for obj in bpy.context.scene.objects if obj.type=='ARMATURE')
bone_names=json.loads((out/'reference_bones.json').read_text())
reference=np.load(out/'reference_deformation.npz')
tracks={track.name:track for track in arm.animation_data.nla_tracks}
comparison={}
for name in names:
    track=tracks[name]
    action=track.strips[0].action
    for other in arm.animation_data.nla_tracks:other.mute=True
    arm.animation_data.action=action
    start=action.frame_range[0]
    maximum=0.0
    for index,expected in enumerate(reference[name]):
        bpy.context.scene.frame_set(int(start+index));bpy.context.view_layer.update()
        world=arm.matrix_world
        actual=np.array([world@arm.pose.bones[key].matrix@arm.data.bones[key].matrix_local.inverted()@world.inverted() for key in bone_names])
        maximum=max(maximum,float(np.abs(actual-expected).max()))
    comparison[name]={'maximum_deformation_matrix_error':maximum,'imported_frame_range':list(action.frame_range),'sampled_frames':len(reference[name])}
    print('GLB_ROUNDTRIP_CLIP '+name+' '+json.dumps(comparison[name]),flush=True)
report={'clips':comparison,'maximum_allowed_matrix_error':.0001,'result':'PASS' if all(item['maximum_deformation_matrix_error']<.0001 for item in comparison.values()) else 'FAIL'}
(out/'roundtrip_verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
assert report['result']=='PASS',report
print('STAGE_B_GLB_ROUNDTRIP_PASS '+json.dumps(summary),flush=True)
