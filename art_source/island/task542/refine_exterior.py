"""Refine only the exterior of the accepted Task 5.4.1 cave mesh."""
from pathlib import Path
import bpy
import json
import math
import sys

source = Path(sys.argv[-2])
output = Path(sys.argv[-1])
output.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(source))
obj = bpy.data.objects['Eastern ridge and chambers']
mesh = obj.data
ring_count = (len(mesh.vertices) - 9 * 45) // 66
assert ring_count == 56
original = [tuple(vertex.co) for vertex in mesh.vertices]
colors = mesh.color_attributes.new(name='ExteriorBlend', type='FLOAT_COLOR', domain='POINT')
# Blender initializes this attribute to white. The chamber shell owns rock only.
for color in colors.data:
    color.color = (0, 0, 0, 1)
inner_indices = []
outer_indices = []

for ring in range(ring_count):
    offset = ring * 66
    inner_indices.extend(range(offset, offset + 33))
    center_x = (original[offset][0] + original[offset + 25][0]) * .5
    z = -original[offset + 29][1]
    for side in range(26):
        index = offset + 33 + side
        vertex = mesh.vertices[index]
        angle = math.pi * side / 25
        ridge_center = center_x - 1.6 * math.sin((z + 12) * .045)
        width = 22.0 + 2.5 * math.sin((z + 2) * .027) + 1.7 * math.cos(angle * 3 + z * .12)
        width += 2.8 * math.exp(-((z - 43) / 14) ** 2)
        x = ridge_center + math.cos(angle) * width
        inner_height = original[offset + side][2]
        original_height = vertex.co.z
        entrance_taper = min(1, max(0, (z + 12) / 17))
        crest_height = 9.8 + entrance_taper * (6.2 + 3.5 * math.sin(z * .065 + .4))
        height = (crest_height + 1.4 * math.sin(z * .22 + angle * 3)) * math.sin(angle) ** 1.35
        vertex.co.x = x
        vertex.co.z = height - .9
        # The exposed portal tapers into the approach; the pathway remains open.
        front_weight = max(0, 1 - (z + 12) / 32)
        vertex.co.y -= (10 * math.sin(angle) - 10 * abs(math.cos(angle)) ** 1.6) * front_weight
        if ring == ring_count - 1:
            vertex.co.y -= 5.5 * math.sin(angle) ** .8
        colors.data[index].color = (1, 1, 1, 1)
        outer_indices.append(index)
    # Roof thickness is measured at shared world X positions, because the
    # widened exterior and preserved inner arch have different radii.
    for inner_side in range(1, 25):
        inner = mesh.vertices[offset + inner_side].co
        for outer_side in range(25):
            left = mesh.vertices[offset + 33 + outer_side].co
            right = mesh.vertices[offset + 34 + outer_side].co
            if right.x <= inner.x <= left.x:
                left.z = max(left.z, inner.z + 1.8)
                right.z = max(right.z, inner.z + 1.8)
                break
    for side in range(26, 33):
        index = offset + 33 + side
        fraction = (side - 25) / 8
        mesh.vertices[index].co.x = center_x + (fraction * 2 - 1) * 20
        colors.data[index].color = (1, 1, 1, 1)
        outer_indices.append(index)

# Preserve all chamber formations. Exterior spurs receive the same material blend.
roof_clearances = []
for ring in range(ring_count):
    offset = ring * 66
    for inner_side in range(1, 25):
        inner = mesh.vertices[offset + inner_side].co
        for outer_side in range(25):
            left = mesh.vertices[offset + 33 + outer_side].co
            right = mesh.vertices[offset + 34 + outer_side].co
            if right.x <= inner.x <= left.x:
                fraction = (left.x - inner.x) / (left.x - right.x)
                height = left.z + (right.z - left.z) * fraction
                roof_clearances.append(height - inner.z)
                break
assert min(roof_clearances) >= 1.79999
for index in range(ring_count * 66, len(mesh.vertices)):
    colors.data[index].color = (1, 1, 1, 1) if index < ring_count * 66 + 4 * 45 else (0, 0, 0, 1)
assert all(tuple(mesh.vertices[index].co) == original[index] for index in inner_indices)
mesh.update()
# Extend the existing closed rear face into a rounded descending rock spur.
# This adds only the exterior cap; the sealed Dragon hall remains exact.
vertices = [tuple(vertex.co) for vertex in mesh.vertices]
faces = [tuple(face.vertices) for face in mesh.polygons]
last_ring = list(range((ring_count - 1) * 66 + 33, ring_count * 66))
faces = [face for face in faces if set(face) != set(last_ring)]
exterior_colors = [tuple(color.color) for color in colors.data]
# Break the broad portal band into short weathered terraces. Both existing
# endpoint rings stay exact, preserving the accepted entry and outer silhouette.
front_faces = []
for side in range(33):
    next_side = (side + 1) % 33
    front_faces.append({side, next_side, side + 33, next_side + 33})
faces = [face for face in faces if set(face) not in front_faces]
previous_front = list(range(33))
for fraction in [.2, .4, .6, .8, 1.0]:
    row = []
    for side in range(33):
        if fraction == 1:
            row.append(side + 33)
            continue
        inner = vertices[side]
        outer = vertices[side + 33]
        point = [inner[axis] + (outer[axis] - inner[axis]) * fraction for axis in range(3)]
        relief = math.sin(fraction * math.pi) * math.sin(side * 1.53 + fraction * 8) * .46
        if side <= 25:
            point[1] += relief
            point[2] += .17 * math.sin(side * .9 + fraction * 10) * math.sin(fraction * math.pi)
        row.append(len(vertices))
        vertices.append(tuple(point))
        exterior_colors.append((fraction, fraction, fraction, 1))
    for side in range(33):
        next_side = (side + 1) % 33
        faces.append((previous_front[side], previous_front[next_side], row[next_side], row[side]))
    previous_front = row
previous = last_ring
for distance, width_factor, height_factor in [(3.5, .9, .78), (7, .65, .4), (10, .2, .03)]:
    row = []
    for index in last_ring:
        x, y, height = vertices[index]
        row.append(len(vertices))
        vertices.append((65 + (x - 65) * width_factor, y - distance, -.9 + (height + .9) * height_factor))
        exterior_colors.append((1, 1, 1, 1))
    for side in range(33):
        next_side = (side + 1) % 33
        faces.append((previous[side], previous[next_side], row[next_side], row[side]))
    previous = row
faces.append(tuple(previous))
refined_mesh = bpy.data.meshes.new('Refined exterior with preserved chamber surfaces')
refined_mesh.from_pydata(vertices, [], faces)
refined_mesh.update()
obj.data = refined_mesh
mesh = refined_mesh
colors = mesh.color_attributes.new(name='ExteriorBlend', type='FLOAT_COLOR', domain='POINT')
for index, color in enumerate(exterior_colors):
    colors.data[index].color = color
for face in mesh.polygons:
    face.use_smooth = True
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode='OBJECT')
mesh.color_attributes.active_color = colors
material = bpy.data.materials.new('Existing limestone with terrain transition')
material.diffuse_color = (.34, .33, .29, 1)
mesh.materials.clear()
mesh.materials.append(material)
bpy.ops.wm.save_as_mainfile(filepath=str(output / 'Cave_Exterior.blend'))
bpy.ops.export_scene.gltf(filepath=str(output / 'cave_exterior.glb'), export_format='GLB', use_selection=True, export_vertex_color='ACTIVE')
summary = {'interior_vertices_unchanged': len(inner_indices), 'outer_vertices_adjusted': len(outer_indices), 'vertices_before': len(original), 'vertices_after': len(mesh.vertices), 'polygons_before': 4007, 'polygons_after': len(mesh.polygons), 'triangles_before': 8162, 'triangles': sum(len(face.vertices) - 2 for face in mesh.polygons), 'interior_positions_exact': True, 'new_textures': 0}
summary['minimum_cross_section_roof_clearance_m'] = min(roof_clearances)
(output / 'geometry_verification.json').write_text(json.dumps(summary, indent=2))
print(json.dumps(summary))
