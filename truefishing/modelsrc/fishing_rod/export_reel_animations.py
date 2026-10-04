"""Export all reel animations for v_fishing_rod_cast viewmodel from FishingRod_Arms_Rig.blend.

Animations:
1. reel_ready.smd: Action.002 (frames 0 to 6) - Left hand moves from idle to grip the crank
2. reel_hold.smd:  Action.002 (frame 6 loop)   - Left hand holding crank, crank at rest
3. reel_in_fish.smd: Action.003 + FishingRodRigAction.006 (frames 6 to 18 loop)
                    - Left hand turning crank + lever_crank rotating 360 degrees

Run with:
& "D:\\steam\\steamapps\\common\\Blender\\blender.exe" -b "FishingRod_Arms_Rig.blend" -P export_reel_animations.py
"""

import os
import math
import bpy
from mathutils import Matrix, Vector, Euler

base = os.path.dirname(bpy.data.filepath)
out = os.path.join(base, 'cast_viewmodel')
os.makedirs(out, exist_ok=True)

scene = bpy.context.scene
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
            bone_name = 'lever_crank' if name == 'cast_reel' else name[5:]
        else:
            bone_name = name

        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            result[name] = Matrix.Identity(4)
            continue
        world = to_source @ arm.matrix_world @ pb.matrix
        result[name] = Matrix.Translation(world.translation) @ world.to_quaternion().to_matrix().to_4x4()
    return result

def get_candidates(e):
    """Generate all equivalent Euler XYZ representations (both branches and 2pi multiples)."""
    res = []
    # Primary branch
    for kx in [-1, 0, 1]:
        for ky in [-1, 0, 1]:
            for kz in [-1, 0, 1]:
                res.append(Euler((e.x + kx*2*math.pi, e.y + ky*2*math.pi, e.z + kz*2*math.pi), 'XYZ'))
    # Secondary branch: y' = pi - y, x' = x + pi, z' = z + pi
    e2 = Euler((e.x + math.pi, math.pi - e.y, e.z + math.pi), 'XYZ')
    for kx in [-1, 0, 1]:
        for ky in [-1, 0, 1]:
            for kz in [-1, 0, 1]:
                res.append(Euler((e2.x + kx*2*math.pi, e2.y + ky*2*math.pi, e2.z + kz*2*math.pi), 'XYZ'))
    return res

nodes_lines = ['nodes'] + [
    '%d "%s" %d' % (i, name, indexes[parent] if parent else -1)
    for i, (name, parent, _) in enumerate(entries)
] + ['end']

def export_smd(filename, frame_list, setup_func):
    """Export an animation SMD given a list of frames and a per-frame setup function."""
    lines = ['version 1'] + nodes_lines + ['skeleton']
    prev_reel_euler = None

    for time_idx, f in enumerate(frame_list):
        setup_func(f)
        scene.frame_set(f)
        bpy.context.view_layer.update()
        mats = pose_matrices()

        lines.append(f'time {time_idx}')
        for name, parent, _ in entries:
            relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
            if name == 'cast_reel':
                # Preserve fixed pivot from reference model
                pos = Vector((0.000000, 13.316929, -2.814963))
                e_raw = relative.to_euler('XYZ')
                cands = get_candidates(e_raw)
                if prev_reel_euler is None:
                    target = Euler((-math.pi / 2, math.pi, 0.0), 'XYZ')
                    best = min(cands, key=lambda c: (c.x - target.x)**2 + (c.y - target.y)**2 + (c.z - target.z)**2)
                else:
                    best = min(cands, key=lambda c: (c.x - prev_reel_euler.x)**2 + (c.y - prev_reel_euler.y)**2 + (c.z - prev_reel_euler.z)**2)
                prev_reel_euler = best
                xyz = best
            else:
                pos = relative.translation
                xyz = relative.to_euler('XYZ')

            lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                         (indexes[name], *pos, *xyz))

    lines.append('end')
    filepath = os.path.join(out, filename)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'Exported {filepath}: {len(frame_list)} frames')

# 1. reel_ready.smd (frames 0 to 6, arms move to crank, rod crank at rest)
def setup_ready(f):
    arms.animation_data.action = bpy.data.actions['Action.002']
    rod.animation_data.action = bpy.data.actions['FishingRodRigAction.006']
    # keep rod crank at rest pose (frame 6)
    scene.frame_set(6)
    bpy.context.view_layer.update()

export_smd('reel_ready.smd', list(range(0, 7)), setup_ready)

# 2. reel_hold.smd (frame 6 loop, 2 frames for Source engine looping)
def setup_hold(f):
    arms.animation_data.action = bpy.data.actions['Action.002']
    rod.animation_data.action = bpy.data.actions['FishingRodRigAction.006']
    scene.frame_set(6)
    bpy.context.view_layer.update()

export_smd('reel_hold.smd', [6, 6], setup_hold)

# 3. reel_in_fish.smd (frames 6 to 18 loop, arms reeling + rod crank rotating 360)
def setup_reeling(f):
    arms.animation_data.action = bpy.data.actions['Action.003']
    rod.animation_data.action = bpy.data.actions['FishingRodRigAction.006']

export_smd('reel_in_fish.smd', list(range(6, 19)), setup_reeling)
print('ALL 3 ANIMATIONS EXPORTED SUCCESSFULLY!')
