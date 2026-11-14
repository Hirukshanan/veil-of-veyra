"""Rebuild only the review derivative from the unchanged high-resolution source.

Weld UV-split geometry before reduction, preserving per-corner UVs. This avoids
independent decimation along adjacent seam boundaries and resulting T-junctions.
"""
import bpy,bmesh,sys,json
from pathlib import Path
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
low=bpy.data.objects['DemonBoar_LOD0'];high=bpy.data.objects['DemonBoar_HighSource']
rig=bpy.data.objects['DemonBoarRig'];rig.data.pose_position='REST'
old_mesh=low.data;low.data=high.data.copy();low.vertex_groups.clear()
before=len(low.data.vertices)
bm=bmesh.new();bm.from_mesh(low.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-5)
bm.to_mesh(low.data);bm.free();low.data.update()
welded=len(low.data.vertices)
bpy.ops.object.select_all(action='DESELECT');low.hide_set(False);low.select_set(True)
bpy.context.view_layer.objects.active=low
dec=low.modifiers.new('Reduce connected review surface','DECIMATE')
low.data.calc_loop_triangles();dec.ratio=120000/len(low.data.loop_triangles);dec.use_collapse_triangulate=True
bpy.ops.object.modifier_move_up(modifier=dec.name)
bpy.ops.object.modifier_apply(modifier=dec.name)
low.data.calc_loop_triangles();assert 110000<len(low.data.loop_triangles)<125000
low.data.materials.clear();material=high.data.materials[0].copy()
material.name='DemonBoar_Preserved_Color_LOD0';low.data.materials.append(material)
nodes=material.node_tree.nodes
image=bpy.data.images.new('DemonBoar_Connected_Surface_Normal_2048',2048,2048,alpha=False)
image.colorspace_settings.name='Non-Color'
texture=nodes.new('ShaderNodeTexImage');texture.image=image;nodes.active=texture
high.hide_set(False);high.hide_render=False;low.hide_render=False;high.select_set(True)
modifiers=[mod for obj in [low,high] for mod in obj.modifiers if mod.type=='ARMATURE']
states=[(mod.show_viewport,mod.show_render) for mod in modifiers]
for mod in modifiers:mod.show_viewport=False;mod.show_render=False
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
print('CONNECTED_SURFACE_READY '+json.dumps({'source_vertices':before,'welded_vertices':welded,'export_vertices':len(low.data.vertices),'triangles':len(low.data.loop_triangles)}),flush=True)
bpy.ops.object.bake(type='NORMAL',use_selected_to_active=True,cage_extrusion=.025,max_ray_distance=.06,normal_space='TANGENT',margin=8)
path=out/'textures/normal_2048.png';image.filepath_raw=str(path);image.file_format='PNG';image.save();image.pack()
normal=nodes.new('ShaderNodeNormalMap');material.node_tree.links.new(texture.outputs['Color'],normal.inputs['Color'])
bsdf=next(node for node in nodes if node.type=='BSDF_PRINCIPLED');material.node_tree.links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
for mod,state in zip(modifiers,states):mod.show_viewport,mod.show_render=state
high.hide_render=True;high.hide_set(True);high.select_set(False);rig.data.pose_position='POSE'
report=json.loads((out/'preparation.json').read_text())
report.update({'export_triangles':len(low.data.loop_triangles),'export_vertices':len(low.data.vertices),'source_uv_split_vertices_welded_on_derivative':before-welded,'derivative_weld_distance_m':1e-5})
(out/'preparation.json').write_text(json.dumps(report,indent=2))
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'rigged_seam_repaired.blend'),compress=True)
print('CONNECTED_SURFACE_NORMAL_BAKE_PASS',flush=True)
