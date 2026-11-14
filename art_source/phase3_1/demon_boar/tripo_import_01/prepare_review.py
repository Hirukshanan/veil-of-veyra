"""Local-only Phase 3.1 review of the supplied GLB; no mesh changes or rigging."""
import bpy, sys, json, struct, hashlib, math
from pathlib import Path
from mathutils import Vector
import numpy as np

out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
source=out/'demon_Boar.glb'
blob=source.read_bytes()
json_length=struct.unpack_from('<I',blob,12)[0]
gltf=json.loads(blob[20:20+json_length])
assert not any(item.get('uri','').startswith(('http:','https:')) for item in gltf.get('images',[])+gltf.get('buffers',[]))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(source))
scene=bpy.context.scene
scene.frame_set(1)
collection=bpy.data.collections.new('DEMON_BOAR_IMPORTED_SOURCE')
scene.collection.children.link(collection)
for obj in list(scene.objects):
    collection.objects.link(obj)
    for old in list(obj.users_collection):
        if old!=collection: old.objects.unlink(obj)

# Explicitly bind the original embedded JPEG: this importer can leave an empty
# image node. These are byte-identical source texture bytes, not a repaint.
texture_repairs=0
replacement=bpy.data.images.load(str(out/'textures'/'base_color.jpg'),check_existing=False)
assert replacement.size[0]>0 and replacement.size[1]>0, 'Original JPEG did not decode'
replacement.colorspace_settings.name='sRGB'
replacement.pack()
for mat in bpy.data.materials:
    if not mat.use_nodes: continue
    for node in mat.node_tree.nodes:
        if node.type=='TEX_IMAGE':
            node.image=replacement
            texture_repairs+=1
assert texture_repairs==1, 'Expected one supplied base-color texture node'

meshes=[]; corners=[]
for obj in collection.objects:
    if obj.type!='MESH': continue
    mesh=obj.data; mesh.calc_loop_triangles()
    coords=np.empty(len(mesh.vertices)*3,dtype=np.float32)
    mesh.vertices.foreach_get('co',coords)
    assert np.isfinite(coords).all(), 'Non-finite geometry'
    meshes.append({'name':obj.name,'vertices':len(mesh.vertices),'triangles':len(mesh.loop_triangles),'uv_layers':len(mesh.uv_layers),'degenerate_triangles':sum(tri.area<1e-12 for tri in mesh.loop_triangles),'material_slots':len(obj.material_slots)})
    corners.extend(obj.matrix_world@Vector(corner) for corner in obj.bound_box)
assert corners, 'No mesh geometry imported'
minimum=Vector(tuple(min(p[i] for p in corners) for i in range(3)))
maximum=Vector(tuple(max(p[i] for p in corners) for i in range(3)))
center=(minimum+maximum)*.5
dimensions=maximum-minimum
span=max(dimensions)
assert span>0 and all(math.isfinite(value) for value in dimensions)
textures=[]
used_images={node.image for mat in bpy.data.materials if mat.use_nodes for node in mat.node_tree.nodes if node.type=='TEX_IMAGE' and node.image and node.image.users>0}
for image in used_images:
    if not image.packed_file: image.pack()
    textures.append({'name':image.name,'width':image.size[0],'height':image.size[1],'packed':bool(image.packed_file)})
print('BOUND_TEXTURE_STATE '+json.dumps(textures),flush=True)
report={'phase':'3.1 supplied-source review only','input_sha256':hashlib.sha256(blob).hexdigest(),'input_bytes':len(blob),'source_meshes':len(gltf.get('meshes',[])),'source_materials':len(gltf.get('materials',[])),'source_textures':len(gltf.get('textures',[])),'source_skins':len(gltf.get('skins',[])),'source_animations':len(gltf.get('animations',[])),'meshes':meshes,'total_vertices':sum(m['vertices'] for m in meshes),'total_triangles':sum(m['triangles'] for m in meshes),'degenerate_triangles':sum(m['degenerate_triangles'] for m in meshes),'dimensions_imported_units':list(dimensions),'bounds_minimum':list(minimum),'bounds_maximum':list(maximum),'armature_objects':sum(obj.type=='ARMATURE' for obj in collection.objects),'animation_actions':len(bpy.data.actions),'textures':textures,'finite_geometry':True,'mesh_edits_performed':False,'rigging_performed':False,'animation_work_performed':False,'network_processing_performed':False,'game_integration_performed':False}
assert textures and all(texture['packed'] for texture in textures), 'Source texture must be loaded and packed'
report['source_texture_reload_count']=texture_repairs
(out/'inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')

# A separate review studio leaves the imported objects and their transforms intact.
studio=bpy.data.collections.new('REVIEW_STUDIO_ONLY')
scene.collection.children.link(studio)
def move_to_studio(obj):
    studio.objects.link(obj)
    for old in list(obj.users_collection):
        if old!=studio: old.objects.unlink(obj)

bpy.ops.mesh.primitive_plane_add(size=span*200,location=(center.x,center.y,minimum.z-span*.003))
floor=bpy.context.object; floor.name='Review ground'; move_to_studio(floor)
mat=bpy.data.materials.new('Review ground matte'); mat.use_nodes=True
bs=mat.node_tree.nodes.get('Principled BSDF')
bs.inputs['Base Color'].default_value=(.025,.030,.038,1)
bs.inputs['Roughness'].default_value=.9
floor.data.materials.append(mat)
for name,offset,power,size,color in [
    ('Neutral key',(-1.4,-1.7,2),250,1.2,(1,1,1)),
    ('Soft fill',(1.8,-.4,1),130,1.5,(.86,.92,1)),
    ('Silhouette rim',(.6,1.5,1.9),240,.9,(1,.91,.82)),
]:
    light=bpy.data.lights.new(name,'AREA'); light.energy=span*span*power; light.shape='DISK'; light.size=span*size; light.color=color
    obj=bpy.data.objects.new(name,light); studio.objects.link(obj)
    obj.location=center+Vector(offset)*span
    obj.rotation_euler=(center-obj.location).to_track_quat('-Z','Y').to_euler()
world=bpy.data.worlds.new('Neutral review world'); world.use_nodes=True
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.09,.11,.14,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.3
scene.world=world
camera=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera'))
studio.objects.link(camera); scene.camera=camera
camera.location=center+Vector((1.7,-2,.9)).normalized()*span*1.9
camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='PERSP'; camera.data.lens=52
camera.data.clip_start=span*.001; camera.data.clip_end=span*500
scene.render.engine='CYCLES'; scene.cycles.device='CPU'; scene.cycles.samples=48; scene.cycles.use_denoising=False
scene.render.resolution_x=1200; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='AgX'
scene['phase_scope']='Phase 3.1 imported source review; no new rigging, animation, optimization or gameplay integration'
scene['source_glb_sha256']=report['input_sha256']
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(out/'demon_boar_source.blend'),compress=True)
print('IMPORTED_SOURCE_READY '+json.dumps({k:report[k] for k in ['total_vertices','total_triangles','source_skins','source_animations','armature_objects','animation_actions']}),flush=True)
(out/'previews').mkdir(exist_ok=True)
scene.render.filepath=str(out/'previews'/'three_quarter.png')
bpy.ops.render.render(write_still=True)
print('ACTUAL_MODEL_RENDER_PASS three_quarter',flush=True)
