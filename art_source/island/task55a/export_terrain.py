"""Export height deltas from the fixed terrain grid in IslandTerrainCorrections.blend.

Edit mesh heights in Blender without moving grid points horizontally or adding vertices.
Use Blender coordinates. World Z in Godot is negative Blender Y.
"""
from pathlib import Path
import sys

import bpy


def export_patch(name, destination):
    obj = bpy.data.objects[name]
    mesh = obj.data
    first = mesh.vertices[0].co
    origin = (first.x, -first.y)
    cols, rows = obj["columns"], obj["rows"]
    spacing = obj["grid_spacing_m"]
    if len(mesh.vertices) != cols * rows:
        raise ValueError(f"{name} vertex count changed")
    baseline = mesh.attributes["baseline_height"].data
    heights = []
    for index, vertex in enumerate(mesh.vertices):
        x, y, height = vertex.co
        row, col = divmod(index, cols)
        if abs(x - (origin[0] + spacing * col)) > .0001 or abs(-y - (origin[1] + spacing * row)) > .0001:
            raise ValueError(f"{name} horizontal grid moved at index {index}")
        delta = height - baseline[index].value
        if abs(delta) > .0001 and (row in (0, rows - 1) or col in (0, cols - 1)):
            raise ValueError(f"{name} delta must reach zero at the patch boundary")
        heights.append(f"{delta:.6f}" if abs(delta) > .0000005 else "0")
    destination.write_text(
        '[gd_resource type="Resource" load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" path="res://scripts/island_height_patch.gd" id="1"]\n\n'
        '[resource]\nscript = ExtResource("1")\n'
        f'origin = Vector2({origin[0]}, {origin[1]})\n'
        f'columns = {cols}\nrows = {rows}\n'
        f'heights = PackedFloat32Array({", ".join(heights)})\n',
        encoding="utf-8",
    )


output = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
output.mkdir(parents=True, exist_ok=True)
export_patch("NorthRelief", output / "north_relief.tres")
export_patch("EasternSlope", output / "eastern_slope.tres")
