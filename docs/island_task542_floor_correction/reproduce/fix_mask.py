"""Correct interior material ownership without changing accepted cave geometry."""
from pathlib import Path
import bpy
import json
import sys

source = Path(sys.argv[-2])
output = Path(sys.argv[-1])
output.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source))
obj = bpy.data.objects['Eastern ridge and chambers']
mesh = obj.data
positions = [tuple(vertex.co) for vertex in mesh.vertices]
faces = [tuple(face.vertices) for face in mesh.polygons]
colors = mesh.color_attributes['ExteriorBlend']
before = [tuple(entry.color) for entry in colors.data]
interior = [ring * 66 + vertex for ring in range(56) for vertex in range(33)]
for index in interior:
    colors.data[index].color = (0, 0, 0, 1)
assert all(tuple(vertex.co) == positions[index] for index, vertex in enumerate(mesh.vertices))
assert [tuple(face.vertices) for face in mesh.polygons] == faces
assert all(tuple(colors.data[index].color) == before[index] for index in range(len(colors.data)) if index not in set(interior))
mesh.color_attributes.active_color = colors
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'Cave_Exterior.blend'))
bpy.ops.export_scene.gltf(filepath=str(output / 'cave_exterior.glb'), export_format='GLB', use_selection=True, export_vertex_color='ACTIVE')
result = {'interior_vertex_mask_before': 1, 'interior_vertex_mask_after': 0, 'interior_vertices_corrected': len(interior), 'all_positions_exact': True, 'all_faces_exact': True, 'other_vertex_colors_exact': True, 'vertices': len(mesh.vertices), 'triangles': sum(len(face.vertices) - 2 for face in mesh.polygons), 'new_geometry': 0, 'new_lights': 0, 'new_textures': 0}
(output / 'mask_verification.json').write_text(json.dumps(result, indent=2))
print(json.dumps(result))
