"""Run with Blender --background --python tools/prepare_charcoal.py -- SOURCE OUTPUT.

Offline preparation for Pigcraft's CC-BY-4.0 Charcoal Black Dark Dragon.
Preserves original colors/UVs, reduces mesh, and adds a modest hovering combat rig.
"""
import bpy
import sys
import math
import json
from pathlib import Path
from mathutils import Vector, Matrix

source, output = map(Path, sys.argv[sys.argv.index('--') + 1:])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
bpy.ops.object.join()
mesh = bpy.context.object
world = mesh.matrix_world.copy()
mesh.parent = None
mesh.matrix_world = Matrix.Identity(4)
# Bake the complete imported hierarchy before orienting the mesh for Godot.
conversion = Matrix.Translation((0, 0.08, 0.415405)) @ Matrix.Rotation(math.pi/2, 4, 'Z')
mesh.data.transform(Matrix.Scale(5, 4) @ conversion @ world)
mesh.name = 'CharcoalDragon'
print('MESH BOUNDS',[(min(v.co[i] for v in mesh.data.vertices),max(v.co[i] for v in mesh.data.vertices)) for i in range(3)],flush=True)
# The source is split across ten primitives; weld coincident seam vertices first.
import bmesh
bm=bmesh.new()
bm.from_mesh(mesh.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.00001)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(mesh.data)
bm.free()
bpy.context.view_layer.objects.active=mesh
mesh.select_set(True)
bpy.ops.mesh.customdata_custom_splitnormals_clear()
# All three source UV channels are duplicates; retain one for Godot's PBR material.
uvs = mesh.data.uv_layers
if len(uvs) > 1:
    reference = [tuple(v.uv) for v in uvs[0].data]
    for layer in list(uvs)[1:]:
        assert all((Vector(a)-b.uv).length < 0.00001 for a,b in zip(reference,layer.data)), 'UV channels differ: bake required'
        uvs.remove(layer)
uvs[0].name = 'UVMap'
for mat in mesh.data.materials:
    if mat and mat.use_nodes:
        for node in mat.node_tree.nodes:
            if node.type == 'UVMAP':
                node.uv_map = 'UVMap'
            if node.type == 'NORMAL_MAP':
                node.uv_map = 'UVMap'
                node.inputs['Strength'].default_value = 0.65
decimate = mesh.modifiers.new('Mobile reduction', 'DECIMATE')
decimate.ratio = 0.035
decimate.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=decimate.name)
mesh.data.validate(clean_customdata=False)
mesh.data.update()
for face in mesh.data.polygons:
    face.use_smooth = True
print('REDUCED TRIANGLES', sum(len(p.vertices)-2 for p in mesh.data.polygons), flush=True)

# Locations below use original anatomical coordinates: lateral, forward, height.
def point(x,y,z):
    return Vector((x*5,(y+0.08)*5,(z+0.415405)*5))
spec = {}
def bone(name, a, b, parent=None):
    spec[name] = (point(*a),point(*b),parent)
bone('root',(0,-0.12,0),(0,-0.12,0.1))
bone('chest',(0,-0.16,-0.02),(0,-0.04,0.12),'root')
bone('neck',(0,-0.04,0.12),(0,0.15,0.15),'chest')
bone('head',(0,0.15,0.15),(0,0.30,0.015),'neck')
bone('jaw',(0,0.265,0.015),(0,0.33,-0.045),'head')
bone('tail_01',(0,-0.19,-0.05),(0,-0.30,-0.20),'root')
bone('tail_02',(0,-0.30,-0.20),(0,-0.17,-0.27),'tail_01')
bone('tail_03',(0,-0.17,-0.27),(0,0.03,-0.25),'tail_02')
bone('tail_04',(0,0.03,-0.25),(0,0.17,-0.38),'tail_03')
for side,sign in [('L',1),('R',-1)]:
    bone('wing_'+side,(sign*.065,-.06,.10),(sign*.27,.08,.37),'chest')
    bone('wing_tip_'+side,(sign*.27,.08,.37),(sign*.44,-.08,-.30),'wing_'+side)
    bone('arm_'+side,(sign*.06,.015,.04),(sign*.09,.10,-.10),'chest')
    bone('hand_'+side,(sign*.09,.10,-.10),(sign*.09,.16,-.18),'arm_'+side)
    bone('leg_'+side,(sign*.07,-.17,-.04),(sign*.12,-.13,-.18),'root')
    bone('foot_'+side,(sign*.12,-.13,-.18),(sign*.12,-.04,-.26),'leg_'+side)
arm_data = bpy.data.armatures.new('CharcoalCombatRig')
rig = bpy.data.objects.new('CharcoalCombatRig',arm_data)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
mesh.select_set(False)
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
for name,(a,b,parent) in spec.items():
    eb = arm_data.edit_bones.new(name)
    eb.head,eb.tail = a,b
    if parent:
        eb.parent = arm_data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
groups = {n:mesh.vertex_groups.new(name=n) for n in spec}
def distance(p,a,b):
    line=b-a
    t=max(0,min(1,(p-a).dot(line)/line.length_squared))
    return (p-(a+t*line)).length
for v in mesh.data.vertices:
    x,y,z = v.co.x/5,v.co.y/5-.08,v.co.z/5-.415405
    side = 'L' if x>=0 else 'R'
    # ponytail: anatomical envelopes for this static sculpt; not a general auto-rigger.
    # Small hover/attack arcs avoid stretching the densely curled wings and tail.
    if abs(x)>.22 or (abs(x)>.115 and z>.055):
        candidates=['wing_'+side,'wing_tip_'+side,'chest']
    elif y>.23 and z<.005 and z>-.10 and abs(x)<.055:
        candidates=['jaw','head']
    elif y>.16 and z>-.08:
        candidates=['head','neck']
    elif y>-.025 and z>.09 and abs(x)<.12:
        candidates=['neck','head','chest']
    elif z<-.13 and abs(x)<.065 or y<-.245:
        candidates=['tail_01','tail_02','tail_03','tail_04','root']
    elif z<-.07 and abs(x)>.045 and abs(x)<.21:
        candidates=['arm_'+side,'hand_'+side,'leg_'+side,'foot_'+side,'root']
    else:
        candidates=['root','chest','neck','wing_'+side,'tail_01']
    nearest=sorted((distance(v.co,*spec[n][:2]),n) for n in candidates)[:3]
    weights=[1/(d+.035)**4 for d,n in nearest]
    total=sum(weights)
    for (_,name),weight in zip(nearest,weights):
        groups[name].add([v.index],weight/total,'REPLACE')
modifier=mesh.modifiers.new('Combat skin','ARMATURE')
modifier.object=rig
mesh.parent=rig
rig.animation_data_create()
bpy.context.scene.render.fps=24
clips={'idle':2.4,'hover':1.2,'windup':.85,'breath':.55,'charge':.48,'recover':.8,'hit':.24,'death':1.2}
for clip,duration in clips.items():
    action=bpy.data.actions.new(clip)
    rig.animation_data.action=action
    end=round(duration*24)+1
    for frame in range(1,end+1):
        t=(frame-1)/(end-1)
        wave=math.sin(t*math.tau)
        for pb in rig.pose.bones:
            pb.rotation_mode='XYZ'
            pb.rotation_euler=(0,0,0)
            pb.location=(0,0,0)
        def rotate(name,axis,value): rig.pose.bones[name].rotation_euler[axis]=value
        rig.pose.bones['root'].location.y=.035*wave
        for side,sign in [('L',1),('R',-1)]:
            flap=.065*wave if clip=='idle' else .13*wave
            if clip=='windup': flap=.16*t
            if clip=='breath': flap=.16+.025*wave
            if clip=='charge': flap=-.10*math.sin(t*math.pi)
            if clip=='recover': flap=-.10*(1-t)
            if clip=='death': flap=-.32*t
            rotate('wing_'+side,1,sign*flap)
            rotate('wing_tip_'+side,1,-sign*flap*.45)
            rotate('arm_'+side,0,.025*wave)
            rotate('leg_'+side,0,-.025*wave)
        rotate('tail_01',1,.025*wave)
        rotate('tail_02',1,.035*wave)
        rotate('tail_03',1,.04*wave)
        rotate('neck',0,.018*wave)
        if clip=='windup':
            rotate('neck',0,-.08*t); rotate('head',0,-.10*t); rotate('jaw',0,.16*t)
        elif clip=='breath':
            rotate('neck',0,-.08); rotate('head',0,-.10+.02*wave); rotate('jaw',0,.20)
        elif clip=='charge':
            rotate('neck',0,.10*math.sin(t*math.pi)); rotate('jaw',0,.16*math.sin(t*math.pi))
        elif clip=='recover':
            rotate('neck',0,-.05*(1-t)); rotate('jaw',0,.12*(1-t))
        elif clip=='hit':
            rotate('chest',0,-.075*math.sin(t*math.pi)); rotate('head',2,.06*math.sin(t*math.pi))
        elif clip=='death':
            rig.pose.bones['root'].location.y=-1.15*t
            rotate('root',2,.6*t); rotate('neck',0,.24*t); rotate('jaw',0,.18*t)
        for pb in rig.pose.bones:
            pb.keyframe_insert('rotation_euler',frame=frame,group=pb.name)
            pb.keyframe_insert('location',frame=frame,group=pb.name)
    track=rig.animation_data.nla_tracks.new()
    track.name=clip
    strip=track.strips.new(clip,1,action)
    strip.action_frame_start=1
    strip.action_frame_end=end
    rig.animation_data.action=None
for pb in rig.pose.bones:
    pb.rotation_euler=(0,0,0)
    pb.location=(0,0,0)
output.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='DESELECT')
mesh.select_set(True); rig.select_set(True)
bpy.context.scene.frame_set(1)
bpy.ops.export_scene.gltf(filepath=str(output),export_format='GLB',use_selection=True,
    export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,
    export_force_sampling=True,export_yup=True,export_materials='EXPORT',export_skins=True)
print('READY',json.dumps({'triangles':sum(len(p.vertices)-2 for p in mesh.data.polygons),'bones':len(spec),'clips':list(clips),'bytes':output.stat().st_size}),flush=True)
