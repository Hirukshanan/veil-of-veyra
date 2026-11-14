"""Compare the saved rig's unchanged high geometry and image to the source."""
import bpy, sys, json, numpy as np, hashlib
from pathlib import Path
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
source=out.parents[2]/'phase3_1/demon_boar/tripo_import_01'
high=bpy.data.objects['DemonBoar_HighSource']
with bpy.data.libraries.load(str(source/'demon_boar_source.blend'),link=False) as (available,loaded):loaded.objects=available.objects
original=next(obj for obj in loaded.objects if obj.type=='MESH' and len(obj.data.vertices)==1023627)
def coords(mesh):
    result=np.empty(len(mesh.vertices)*3,dtype=np.float32);mesh.vertices.foreach_get('co',result);return result.reshape(-1,3)
matrix=np.array(json.loads((out/'preparation.json').read_text())['source_to_rig_matrix'])@np.array(original.matrix_world)
expected=coords(original.data)@matrix[:3,:3].T+matrix[:3,3]
error=float(np.abs(coords(high.data)-expected).max());assert error<1e-5,error
def loop_indices(mesh):
    data=np.empty(len(mesh.loops),dtype=np.int32);mesh.loops.foreach_get('vertex_index',data);return data
assert np.array_equal(loop_indices(original.data),loop_indices(high.data))
def uvs(mesh):
    data=np.empty(len(mesh.uv_layers.active.data)*2,dtype=np.float32);mesh.uv_layers.active.data.foreach_get('uv',data);return data
assert np.array_equal(uvs(original.data),uvs(high.data))
base_hash=hashlib.sha256((source/'textures/base_color.jpg').read_bytes()).hexdigest()
packed_hashes=[]
for obj in [high,bpy.data.objects['DemonBoar_LOD0']]:
    material=obj.data.materials[0]
    node=next(node for node in material.node_tree.nodes if node.type=='BSDF_PRINCIPLED')
    image=node.inputs['Base Color'].links[0].from_node.image
    assert image.packed_file
    packed_hashes.append(hashlib.sha256(image.packed_file.data).hexdigest())
assert all(value==base_hash for value in packed_hashes)
report={'result':'PASS','maximum_high_geometry_coordinate_error_m':error,'high_polygon_connectivity_unchanged':True,'high_uvs_unchanged':True,'original_base_color_sha256':base_hash,'both_used_packed_base_colors_identical_to_original_jpeg':True}
(out/'appearance_verification.json').write_text(json.dumps(report,indent=2))
print('APPEARANCE_PRESERVATION_PASS '+json.dumps(report),flush=True)
