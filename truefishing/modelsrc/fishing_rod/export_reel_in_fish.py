"""Export the fish-reel-in animation from the active actions on both armatures.

Hands action:  Action.002  (hands_reference_skeleton)
Rod action:    FishingRodRigAction.006  (FishingRodRig)

Writes cast_viewmodel/reel_in_fish.smd with the same 67-bone skeleton
used by the compiled v_fishing_rod_cast.mdl.

Run with:
& "D:\\steam\\steamapps\\common\\Blender\\blender.exe" -b "FishingRod_Arms_Rig.blend" -P export_reel_in_fish.py
"""

import os
import math
import bpy
from mathutils import Matrix, Vector

base = os.path.dirname(bpy.data.filepath)
out = os.path.join(base, 'cast_viewmodel')
os.makedirs(out, exist_ok=True)

scene = bpy.context.scene
scene.render.fps = 25

arms = bpy.data.objects['hands_reference_skeleton']
rod = bpy.data.objects['FishingRodRig']

# ---- skeleton definition (matching cast_reference.smd exactly: 67 bones) ----
entries = [(b.name, b.parent.name if b.parent else None, arms) for b in arms.data.bones]
entries += [
    ('cast_root', 'v_weapon.Right_Hand', rod),
    ('cast_handle', 'cast_root', rod),
    ('cast_reel', 'cast_handle', rod),
    ('cast_rod_lower', 'cast_handle', rod),
    ('cast_rod_mid', 'cast_rod_lower', rod),
    ('cast_rod_upper', 'cast_rod_mid', rod),
    ('cast_rod_tip', 'cast_rod_upper', rod),
]
indexes = {name: i for i, (name, _, _) in enumerate(entries)}

to_source = arms.matrix_world.inverted()

def pose_matrices():
    result = {}
    for name, _, arm in entries:
        if arm == rod:
            if name == 'cast_reel':
                bone_name = 'lever_crank'
            else:
                bone_name = name[5:]
        else:
            bone_name = name

        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            result[name] = Matrix.Identity(4)
            continue
        world = to_source @ arm.matrix_world @ pb.matrix
        result[name] = Matrix.Translation(world.translation) @ world.to_quaternion().to_matrix().to_4x4()
    return result

def skeleton_frame(frame_num, time_index):
    scene.frame_set(frame_num)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    lines = [f'time {time_index}']
    for name, parent, _ in entries:
        relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
        if name == 'cast_reel':
            # Keep the exact pivot point from reference mesh so the crank does not detach from the reel
            pos = Vector((0.000000, 13.316929, -2.814963))
        else:
            pos = relative.translation
        xyz = relative.to_euler('XYZ')
        lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                     (indexes[name], *pos, *xyz))
    return lines

nodes_lines = ['nodes'] + [
    '%d "%s" %d' % (i, name, indexes[parent] if parent else -1)
    for i, (name, parent, _) in enumerate(entries)
] + ['end']

# ---- write animation SMD ----
# Sample frames 0-18 (19 frames at 25 fps = 0.76 s loop)
frames = list(range(0, 19))
lines = ['version 1'] + nodes_lines + ['skeleton']
for idx, f in enumerate(frames):
    lines.extend(skeleton_frame(f, idx))
lines.append('end')

path = os.path.join(out, 'reel_in_fish.smd')
with open(path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')
print(f'Wrote {path}  ({len(frames)} frames, {len(entries)} bones)')
