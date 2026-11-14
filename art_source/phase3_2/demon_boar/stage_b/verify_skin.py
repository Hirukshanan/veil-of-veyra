"""Independent saved-file skin, contact-geometry and deformation sampling."""
import bpy, sys, json, hashlib, math
from pathlib import Path
import numpy as np
from mathutils import Vector
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
rig=bpy.data.objects['DemonBoarRig'];low=bpy.data.objects['DemonBoar_LOD0'];high=bpy.data.objects['DemonBoar_HighSource']
definition=json.loads((out/'rig_definition.json').read_text())
metrics=json.loads((out/'animation_metrics.json').read_text())
assert set(action.name for action in bpy.data.actions)==set(metrics['clips'])
assert len(rig.data.bones)==41 and sum(b.use_deform for b in rig.data.bones)==30
weights={}
for obj in [low,high]:
    maximum=0.;influences=0;empty=0
    for vertex in obj.data.vertices:
        valid=[group.weight for group in vertex.groups if group.weight>0]
        empty+=not valid;influences=max(influences,len(valid));maximum=max(maximum,abs(sum(valid)-1))
        assert all(math.isfinite(weight) and weight>=0 for weight in valid)
    assert empty==0 and influences<=4 and maximum<1e-6
    weights[obj.name]={'vertices':len(obj.data.vertices),'unweighted':empty,'maximum_influences':influences,'maximum_weight_sum_error':maximum}
    obj.data.calc_loop_triangles()
    assert not any(tri.area<1e-12 for tri in obj.data.loop_triangles)

count=len(low.data.vertices)
rest=np.empty(count*3,dtype=np.float32);low.data.vertices.foreach_get('co',rest);rest=rest.reshape(-1,3)
edge_indices=np.empty(len(low.data.edges)*2,dtype=np.int32);low.data.edges.foreach_get('vertices',edge_indices);edge_indices=edge_indices.reshape(-1,2)
lengths=np.linalg.norm(rest[edge_indices[:,0]]-rest[edge_indices[:,1]],axis=1)
relevant=lengths>.015
# Regression: UV-split duplicates must not tear apart during any keyed pose.
_,seam_first,seam_inverse,seam_counts=np.unique(np.round(rest/1e-5).astype(np.int64),axis=0,return_index=True,return_inverse=True,return_counts=True)
duplicates=np.flatnonzero(seam_counts[seam_inverse]>1)
representatives=seam_first[seam_inverse[duplicates]]
seams={}
sampled={}
for clip,spec in metrics['clips'].items():
    rig.animation_data.action=bpy.data.actions[clip]
    data=[]
    for fraction in [0,.25,.5,.75]:
        frame=1+int(round(spec['frames']*fraction))
        bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
        evaluated=low.evaluated_get(bpy.context.evaluated_depsgraph_get())
        mesh=evaluated.to_mesh()
        points=np.empty(len(mesh.vertices)*3,dtype=np.float32);mesh.vertices.foreach_get('co',points);points=points.reshape(-1,3)
        assert np.isfinite(points).all()
        deformed=np.linalg.norm(points[edge_indices[:,0]]-points[edge_indices[:,1]],axis=1)
        ratios=deformed[relevant]/lengths[relevant]
        data.append({'frame':frame,'minimum_z_m':float(points[:,2].min()),'edge_stretch_p99':float(np.percentile(ratios,99)),'edge_stretch_max':float(ratios.max()),'long_edges_over_2x':int((ratios>2).sum())})
        evaluated.to_mesh_clear()
    sampled[clip]=data
    worst_gap=0.0
    for frame in range(1,spec['frames']+2):
        bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
        evaluated=low.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh()
        points=np.empty(count*3,dtype=np.float32);mesh.vertices.foreach_get('co',points);points=points.reshape(-1,3)
        if len(duplicates):
            worst_gap=max(worst_gap,float(np.linalg.norm(points[duplicates]-points[representatives],axis=1).max()))
        evaluated.to_mesh_clear()
    assert worst_gap<.00005,(clip,'UV seam opens under skinning',worst_gap)
    seams[clip]={'sampled_frames':spec['frames']+1,'maximum_coincident_seam_gap_m':worst_gap,'coincident_seam_groups':int((seam_counts>1).sum())}
report={'result':'PASS','editable_control_bones':41,'runtime_deform_bones':30,'weights':weights,'sampled_skin_deformation':sampled,'high_source_vertices_preserved':len(high.data.vertices)==1023627,'original_source_glb_sha256':hashlib.sha256((out.parents[2]/'phase3_1'/'demon_boar'/'tripo_import_01'/'demon_Boar.glb').read_bytes()).hexdigest(),'sha256':{name:hashlib.sha256((out/name).read_bytes()).hexdigest() for name in ['demon_boar_stage_b.blend','demon_boar_stage_b.glb']},'notes':'Edge samples are diagnostics for visual review, not a blanket anatomical-quality certification.'}
report['animated_uv_seam_regression']=seams
loop_edges=np.empty(len(low.data.loops),dtype=np.int32);low.data.loops.foreach_get('edge_index',loop_edges)
edge_uses=np.bincount(loop_edges,minlength=len(low.data.edges))
report['surface_topology']={'boundary_edges':int((edge_uses==1).sum()),'loose_edges':int((edge_uses==0).sum()),'nonmanifold_edges':int((edge_uses>2).sum()),'note':'UVs remain per-corner; exported UV-split vertices inherit the shared geometric skin weights.'}
(out/'skin_verification.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('SAVED_STAGE_A_SKIN_PASS '+json.dumps({'weights':weights,'sampled_skin_deformation':sampled}),flush=True)
