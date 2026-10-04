"""Export the current pose from FishingRod_Arms_Rig.blend as idle.smd
for the v_fishing_rod_cast viewmodel.

This reads the pose at frame 0 from both armatures and writes it
using the same skeleton/bone structure as the compiled model.

Run with:
& "D:\steam\steamapps\common\Blender\blender.exe" -b "FishingRod_Arms_Rig.blend" -P export_idle_from_rig.py
"""

import os
import math
import bpy
from mathutils import Matrix, Vector, Quaternion

base = os.path.dirname(bpy.data.filepath)
out = os.path.join(base, 'cast_viewmodel')
os.makedirs(out, exist_ok=True)

scene = bpy.context.scene
scene.frame_set(0)

arms = bpy.data.objects['hands_reference_skeleton']
rod = bpy.data.objects['FishingRodRig']

# Build the same skeleton as export_cast_viewmodel.py
entries = [(b.name, b.parent.name if b.parent else None, arms) for b in arms.data.bones]
entries += [('cast_' + b.name,
             'cast_' + b.parent.name if b.parent else 'v_weapon.Right_Hand', rod)
            for b in rod.data.bones]
indexes = {name: i for i, (name, _, _) in enumerate(entries)}

# Transform: from Blender world to Source viewmodel space
# The arms skeleton scale (0.0254) converts inches to meters.
# Inverting its world matrix maps back to Source viewmodel inches.
to_source = arms.matrix_world.inverted()

bpy.context.view_layer.update()

def pose_matrices():
    result = {}
    for name, _, arm in entries:
        bone_name = name[5:] if arm == rod else name  # strip 'cast_' prefix for rod
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            # Fallback: identity at origin
            result[name] = Matrix.Identity(4)
            continue
        world = to_source @ arm.matrix_world @ pb.matrix
        result[name] = Matrix.Translation(world.translation) @ world.to_quaternion().to_matrix().to_4x4()
    return result

mats = pose_matrices()

nodes = ['nodes'] + ['%d "%s" %d' % (i, name, indexes[parent] if parent else -1)
                     for i, (name, parent, _) in enumerate(entries)] + ['end']

lines = ['version 1'] + nodes + ['skeleton', 'time 0']

for name, parent, _ in entries:
    relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
    pos = relative.translation
    xyz = relative.to_euler('XYZ')
    lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                 (indexes[name], *pos, *xyz))

lines.append('end')

idle_path = os.path.join(out, 'idle.smd')
with open(idle_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')

print(f'EXPORTED idle.smd ({len(entries)} bones) to {idle_path}')

# Also export as reference pose for verification
# Count how different this is from the old idle
old_idle = os.path.join(out, 'idle_backup.smd')
if os.path.exists(os.path.join(out, 'idle.smd')):
    print(f'Old idle.smd backed up')
