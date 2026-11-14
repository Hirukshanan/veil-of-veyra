"""Anatomically restrict skin fields to avoid cross-limb heat-weight leakage."""
import bpy, sys, json
from pathlib import Path
import numpy as np
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
rig=bpy.data.objects['DemonBoarRig']
definition=json.loads((out/'rig_definition.json').read_text())
names=[bone.name for bone in rig.data.bones if bone.use_deform]
def smooth(value):
    value=np.clip(value,0,1);return value*value*(3-2*value)
def window(value,a,b):return smooth((value-a)/(b-a))
def pair_field(values,bones,centers):
    index=np.clip(np.searchsorted(centers,values,side='right')-1,0,len(centers)-2)
    t=smooth((values-np.take(centers,index))/(np.take(centers,index+1)-np.take(centers,index)))
    weights=np.zeros((len(values),len(names)),dtype=np.float32)
    rows=np.arange(len(values))
    weights[rows,np.array([names.index(name) for name in bones])[index]]=1-t
    weights[rows,np.array([names.index(name) for name in bones])[index+1]]=t
    return weights
def segment_distance(points,a,b):
    delta=b-a;t=np.clip(((points-a)*delta).sum(axis=1)/np.dot(delta,delta),0,1)
    return np.linalg.norm(points-a-t[:,None]*delta,axis=1)
reports={}
for object_name in ['DemonBoar_LOD0','DemonBoar_HighSource']:
    obj=bpy.data.objects[object_name];n=len(obj.data.vertices)
    points=np.empty(n*3,dtype=np.float32);obj.data.vertices.foreach_get('co',points);points=points.reshape(-1,3)
    x,y,z=points.T
    weights=pair_field(y,['pelvis','spine_01','spine_02','chest','neck','head'],[-.60,-.18,.14,.42,.78,1.08])
    for tag,leg in definition['legs'].items():
        side=tag[-1];front=tag.startswith('front')
        chain=[leg['upper'],leg['lower']]
        if not front:chain.append('rear_pastern.'+side)
        joints=[np.array(rig.data.bones[chain[0]].head_local)]
        joints.extend(np.array(rig.data.bones[name].tail_local) for name in chain)
        sole=np.array(leg['sole_rest']);joints.append(sole)
        ordered=sorted(joints,key=lambda p:p[2])
        cx=np.interp(z,[p[2] for p in ordered],[p[0] for p in ordered])
        cy=np.interp(z,[p[2] for p in ordered],[p[1] for p in ordered])
        radius=np.sqrt((x-cx)**2+(y-cy)**2)
        membership=(1-window(radius,.15,.38))*(1-window(z,joints[0][2]-.30,joints[0][2]+.08))
        lateral=np.where(z<.30,window(np.abs(x),.04,.12),window(np.abs(x),.08,.20))
        membership*=lateral
        if side=='L':membership[x>=0]=0
        else:membership[x<=0]=0
        ankle=leg['ankle_rest'][2]
        knee=rig.data.bones[leg['lower']].head_local.z
        if front:
            field=pair_field(z,[leg['hoof'],leg['lower'],leg['upper'],'shoulder.'+side],[ankle+.03,knee-.11,knee+.14,joints[0][2]+.03])
        else:
            hock=rig.data.bones[leg['lower']].tail_local.z
            field=pair_field(z,[leg['hoof'],'rear_pastern.'+side,leg['lower'],leg['upper']],[ankle+.03,hock+.035,knee-.03,knee+.17])
        weights*=1-membership[:,None];weights+=field*membership[:,None]
        # All sole vertices are rigid; blend through a broad ankle band above it.
        sole_radius=np.linalg.norm(points[:,:2]-sole[:2],axis=1)
        rigid=(1-window(z,sole[2]+.18,sole[2]+.36))*(1-window(sole_radius,.23,.38))
        weights*=1-rigid[:,None];weights[:,names.index(leg['hoof'])]+=rigid
    jaw=window(y,1.08,1.24)*(1-window(z,.42,.58))*(1-window(np.abs(x),.23,.36))
    weights*=1-jaw[:,None];weights[:,names.index('jaw')]+=jaw
    for side,sign in [('L',-1),('R',1)]:
        bone=rig.data.bones['ear.'+side]
        distance=segment_distance(points,np.array(bone.head_local),np.array(bone.tail_local))
        alpha=(1-window(distance,.045,.13))*window(z,.98,1.05)*window(sign*x,.18,.25)
        weights*=1-alpha[:,None];weights[:,names.index(bone.name)]+=alpha
    tail=(1-window(y,-1.12,-.90))*(1-window(np.abs(x),.08,.20))*(1-window(np.abs(z-.99),.10,.22))
    field=pair_field(-y,['tail_01','tail_02','tail_03'],[.98,1.22,1.43])
    weights*=1-tail[:,None];weights+=field*tail[:,None]
    mane=window(z,1.20,1.43)*(1-window(np.abs(x),.10,.18))*window(y,-.02,.10)*(1-window(y,.72,.90))
    field=pair_field(y,['mane_01','mane_02'],[.26,.61])
    weights*=1-mane[:,None];weights+=field*mane[:,None]
    if object_name=='DemonBoar_LOD0':
        # Weld only the weight graph, never the geometry or UVs. Imported UV
        # seams contain coincident vertices that must share skin transforms.
        _,seam_inverse,seam_counts=np.unique(np.round(points/1e-5).astype(np.int64),axis=0,return_inverse=True,return_counts=True)
        node_weights=np.zeros((len(seam_counts),len(names)),dtype=np.float32)
        np.add.at(node_weights,seam_inverse,weights)
        node_weights/=seam_counts[:,None]
        edges=np.empty(len(obj.data.edges)*2,dtype=np.int32)
        obj.data.edges.foreach_get('vertices',edges);edges=edges.reshape(-1,2)
        edges=np.unique(np.sort(seam_inverse[edges],axis=1),axis=0)
        edges=edges[edges[:,0]!=edges[:,1]]
        src=np.concatenate([edges[:,0],edges[:,1]])
        dst=np.concatenate([edges[:,1],edges[:,0]])
        order=np.argsort(src);src=src[order];dst=dst[order]
        starts=np.r_[0,np.flatnonzero(src[1:]!=src[:-1])+1]
        rows=src[starts];degrees=np.diff(np.r_[starts,len(src)]).astype(np.float32)
        alpha=window(z,.18,.30)*(1-window(z,.85,1.02))*.7
        node_alpha=np.bincount(seam_inverse,weights=alpha)/seam_counts
        for iteration in range(100):
            average=np.add.reduceat(node_weights[dst],starts,axis=0)/degrees[:,None]
            node_weights[rows]+=node_alpha[rows,None]*(average-node_weights[rows])
        weights=node_weights[seam_inverse]
        # Represent each torso/limb distribution with adjacent bone pairs.
        # This avoids discontinuities when a fifth weight crosses the top-four
        # cutoff, while retaining the continuous mean position on each chain.
        body_names=['pelvis','spine_01','spine_02','chest','neck','head']
        body_ids=[names.index(k) for k in body_names]
        families=[]
        for tag,leg in definition['legs'].items():
            side=tag[-1]
            family=([leg['hoof'],leg['lower'],leg['upper'],'shoulder.'+side] if tag.startswith('front') else [leg['hoof'],'rear_pastern.'+side,leg['lower'],leg['upper']])
            families.append([names.index(k) for k in family])
        masses=np.stack([weights[:,family].sum(axis=1) for family in families],axis=1)
        dominant=masses.argmax(axis=1)
        special_ids=[i for i in range(len(names)) if i not in body_ids and not any(i in family for family in families)]
        eligible=weights[:,special_ids].sum(axis=1)<1e-4
        body=weights[:,body_ids]
        body_mean=(body*np.arange(len(body_ids))).sum(axis=1)/np.maximum(body.sum(axis=1),1e-12)
        replacement=np.zeros_like(weights)
        for family_index,family in enumerate(families):
            rows=np.flatnonzero(eligible&(dominant==family_index))
            mass=masses[rows,family_index]
            subset=weights[rows][:,family]
            mean=(subset*np.arange(len(family))).sum(axis=1)/np.maximum(mass,1e-12)
            for chain,position,total in [(body_ids,body_mean[rows],1-mass),(family,mean,mass)]:
                index=np.clip(np.floor(position).astype(int),0,len(chain)-2)
                t=np.clip(position-index,0,1)
                replacement[rows,np.take(chain,index)]+=total*(1-t)
                replacement[rows,np.take(chain,index+1)]+=total*t
        weights[eligible]=replacement[eligible]
    else:
        # The untouched high-resolution geometry uses the same refined skin.
        obj.hide_set(False)
        for name in names:
            if name not in obj.vertex_groups:obj.vertex_groups.new(name=name)
        low=bpy.data.objects['DemonBoar_LOD0']
        rig.data.pose_position='REST'
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        transfer=obj.modifiers.new('Refined low surface weight transfer','DATA_TRANSFER')
        transfer.object=low;transfer.use_vert_data=True
        transfer.data_types_verts={'VGROUP_WEIGHTS'};transfer.vert_mapping='POLYINTERP_NEAREST'
        transfer.layers_vgroup_select_src='ALL';transfer.layers_vgroup_select_dst='NAME'
        bpy.ops.object.modifier_apply(modifier=transfer.name)
        weights[:]=0
        mapping={obj.vertex_groups[name].index:names.index(name) for name in names}
        for vertex in obj.data.vertices:
            for group in vertex.groups:
                if group.group in mapping:weights[vertex.index,mapping[group.group]]=group.weight
        rig.data.pose_position='POSE';obj.hide_set(True)
    # Enforce the same seam invariant on the high-source transfer as well.
    if object_name!='DemonBoar_LOD0':
        _,seam_inverse,seam_counts=np.unique(np.round(points/1e-5).astype(np.int64),axis=0,return_inverse=True,return_counts=True)
        common=np.zeros((len(seam_counts),len(names)),dtype=np.float32)
        np.add.at(common,seam_inverse,weights);common/=seam_counts[:,None]
        weights=common[seam_inverse]
    active_before=(weights>1e-5).sum(axis=1)
    top=np.argpartition(weights,-4,axis=1)[:,-4:]
    chosen=np.take_along_axis(weights,top,axis=1);chosen/=chosen.sum(axis=1,keepdims=True)
    desired=chosen*1024;quantized=np.floor(desired).astype(np.int16)
    remainder=1024-quantized.sum(axis=1);fractions=np.argsort(-(desired-quantized),axis=1)
    for rank in range(4):
        rows=np.flatnonzero(remainder>rank);quantized[rows,fractions[rows,rank]]+=1
    assert np.all(quantized.sum(axis=1)==1024)
    obj.vertex_groups.clear()
    for index,name in enumerate(names):
        group=obj.vertex_groups.new(name=name)
        rows,columns=np.where((top==index)&(quantized>0));values=quantized[rows,columns]
        for value in np.unique(values):group.add(rows[values==value].tolist(),int(value)/1024,'REPLACE')
    reports[object_name]={'vertices':n,'method':'anatomical skin fields diffused on a position-welded weight graph','maximum_influences':4,'quantized_weight_sum_units':1024,'vertices_with_more_than_four_prelimit_fields':int((active_before>4).sum()),'coincident_seam_groups':int((seam_counts>1).sum()),'seam_position_tolerance_m':1e-5}
    print('ANATOMICAL_SKIN_READY '+object_name+' '+json.dumps(reports[object_name]),flush=True)
definition['final_skin_method']='Anatomical continuous fields, replacing overly broad initial heat-weight transfers'
definition['final_weights']=reports
(out/'rig_definition.json').write_text(json.dumps(definition,indent=2),encoding='utf-8')
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'rigged_refined.blend'),compress=True)
