"""Rebuild the entire v_fishing_rod_cast viewmodel from FishingRod_Arms_Rig.blend.

Fixes:
1. Re-exports cast_reference.smd from FishingRod_Arms_Rig.blend so that:
   - lever_crank (crank only) is bound to cast_reel (bone 62)
   - handle (rod handle + reel body + bail wire) is bound to cast_handle (bone 61)
   This permanently eliminates the old broken mesh binding where the bail wire / reel body spun and broke the model!
2. Exports idle.smd at rest frame (frame 0).
3. Exports reel_ready.smd (frames 0 to 6, arms move to crank, crank at rest).
4. Exports reel_hold.smd (frame 6 loop, hand holding crank, crank at rest).
5. Exports reel_in_fish.smd (frames 6 to 18 loop, hand cranking + crank 360 rotation).
6. Updates cast.smd, cast_ready.smd, cast_ready_hold.smd with the new crank pivot.
7. Deletes obsolete reel.smd.
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

# Compute exact rest transform for cast_reel from FishingRod_Arms_Rig.blend
bpy.context.scene.frame_set(0)
bpy.context.view_layer.update()
_mats0 = pose_matrices()
_rel_crank0 = _mats0['cast_handle'].inverted() @ _mats0['cast_reel']
CRANK_PIVOT_POS = _rel_crank0.translation.copy()
CRANK_REST_ROT = _rel_crank0.to_euler('XYZ')
print(f'Detected Crank Pivot: {CRANK_PIVOT_POS}, Crank Rest Rot: {CRANK_REST_ROT}')

nodes_lines = ['nodes'] + [
    '%d "%s" %d' % (i, name, indexes[parent] if parent else -1)
    for i, (name, parent, _) in enumerate(entries)
] + ['end']

def skeleton_frame(frame_num, time_index, prev_eulers=None):
    scene.frame_set(frame_num)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    lines = [f'time {time_index}']
    for name, parent, _ in entries:
        relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
        if name == 'cast_reel':
            pos = CRANK_PIVOT_POS
        else:
            pos = relative.translation
        xyz = relative.to_euler('XYZ')
        lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                     (indexes[name], *pos, *xyz))
    return lines

# -------------------------------------------------------------------------
# 1. EXPORT cast_reference.smd FROM FishingRod_Arms_Rig.blend
# -------------------------------------------------------------------------
print('Exporting cast_reference.smd...')
scene.frame_set(0)
bpy.context.view_layer.update()
ref_lines = ['version 1'] + nodes_lines + ['skeleton'] + skeleton_frame(0, 0) + ['end', 'triangles']

meshes = [
    (bpy.data.objects['hands_reference'], arms, 'cast_hands'),
    (bpy.data.objects['FishingRod'], rod, 'Default')
]

for obj, arm, material in meshes:
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    uv = mesh.uv_layers.active
    assert uv, obj.name
    to_source_mesh = to_source @ evaluated.matrix_world
    normal_matrix = to_source_mesh.to_3x3().inverted().transposed()

    for triangle in mesh.loop_triangles:
        ref_lines.append(material)
        for loop_idx in triangle.loops:
            vertex = mesh.vertices[mesh.loops[loop_idx].vertex_index]
            world = to_source_mesh @ vertex.co
            normal = (normal_matrix @ mesh.loops[loop_idx].normal).normalized()
            tex = uv.data[loop_idx].uv
            original = obj.data.vertices[vertex.index]
            influences = []

            for group in original.groups:
                raw_bone = obj.vertex_groups[group.group].name
                if arm == rod:
                    if raw_bone == 'lever_crank':
                        bone = 'cast_reel'
                    else:
                        bone = 'cast_' + raw_bone
                else:
                    bone = raw_bone
                if bone in indexes:
                    influences.append((indexes[bone], group.weight))

            influences = [(idx, w) for idx, w in influences if w > 0.0001]
            influences.sort(key=lambda pair: pair[1], reverse=True)
            influences = influences[:4]
            total = sum(w for _, w in influences)
            if not influences or total <= 0:
                influences = [(indexes['cast_handle' if arm == rod else 'v_weapon'], 1.0)]
                total = 1.0
            links = ' '.join('%d %.6f' % (i, w / total) for i, w in influences)
            ref_lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %d %s' %
                             (influences[0][0], *world, *normal, tex.x, tex.y,
                              len(influences), links))
    evaluated.to_mesh_clear()

ref_lines.append('end')
ref_path = os.path.join(out, 'cast_reference.smd')
with open(ref_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(ref_lines) + '\n')
print(f'Wrote {ref_path} ({len(ref_lines)} lines)')

# -------------------------------------------------------------------------
# 2. EXPORT idle.smd (rest pose)
# -------------------------------------------------------------------------
print('Exporting idle.smd...')
arms.animation_data.action = bpy.data.actions['Action.002']
rod.animation_data.action = bpy.data.actions['FishingRodRigAction.006']
idle_lines = ['version 1'] + nodes_lines + ['skeleton'] + skeleton_frame(0, 0) + ['end']
idle_path = os.path.join(out, 'idle.smd')
with open(idle_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(idle_lines) + '\n')
print(f'Wrote {idle_path}')

# -------------------------------------------------------------------------
# 3. EXPORT reel_ready.smd (Action.002, frames 0 to 6)
# -------------------------------------------------------------------------
print('Exporting reel_ready.smd...')
arms.animation_data.action = bpy.data.actions['Action.002']
rod.animation_data.action = bpy.data.actions['FishingRodRigAction.006']
ready_lines = ['version 1'] + nodes_lines + ['skeleton']
for idx, f in enumerate(range(0, 7)):
    scene.frame_set(f)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    ready_lines.append(f'time {idx}')
    for name, parent, _ in entries:
        relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
        pos = CRANK_PIVOT_POS if name == 'cast_reel' else relative.translation
        xyz = CRANK_REST_ROT if name == 'cast_reel' else relative.to_euler('XYZ')
        ready_lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                           (indexes[name], *pos, *xyz))
ready_lines.append('end')
with open(os.path.join(out, 'reel_ready.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(ready_lines) + '\n')

# -------------------------------------------------------------------------
# 4. EXPORT reel_hold.smd (frame 6 loop)
# -------------------------------------------------------------------------
print('Exporting reel_hold.smd...')
hold_lines = ['version 1'] + nodes_lines + ['skeleton']
for idx in [0, 1]:
    scene.frame_set(6)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    hold_lines.append(f'time {idx}')
    for name, parent, _ in entries:
        relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
        pos = CRANK_PIVOT_POS if name == 'cast_reel' else relative.translation
        xyz = CRANK_REST_ROT if name == 'cast_reel' else relative.to_euler('XYZ')
        hold_lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                          (indexes[name], *pos, *xyz))
hold_lines.append('end')
with open(os.path.join(out, 'reel_hold.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(hold_lines) + '\n')

# -------------------------------------------------------------------------
# 5. EXPORT reel_in_fish.smd (Action.003 + FishingRodRigAction.006, frames 6 to 18)
# -------------------------------------------------------------------------
print('Exporting reel_in_fish.smd...')
arms.animation_data.action = bpy.data.actions['Action.003']
rod.animation_data.action = bpy.data.actions['FishingRodRigAction.006']

def get_candidates(e):
    res = []
    for kx in [-1, 0, 1]:
        for ky in [-1, 0, 1]:
            for kz in [-1, 0, 1]:
                res.append(Euler((e.x + kx*2*math.pi, e.y + ky*2*math.pi, e.z + kz*2*math.pi), 'XYZ'))
    e2 = Euler((e.x + math.pi, math.pi - e.y, e.z + math.pi), 'XYZ')
    for kx in [-1, 0, 1]:
        for ky in [-1, 0, 1]:
            for kz in [-1, 0, 1]:
                res.append(Euler((e2.x + kx*2*math.pi, e2.y + ky*2*math.pi, e2.z + kz*2*math.pi), 'XYZ'))
    return res

reeling_lines = ['version 1'] + nodes_lines + ['skeleton']
prev_crank_rot = None

for idx, f in enumerate(range(6, 19)):
    scene.frame_set(f)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    reeling_lines.append(f'time {idx}')
    for name, parent, _ in entries:
        relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
        if name == 'cast_reel':
            pos = CRANK_PIVOT_POS
            e_raw = relative.to_euler('XYZ')
            cands = get_candidates(e_raw)
            if prev_crank_rot is None:
                best = min(cands, key=lambda c: (c.x - CRANK_REST_ROT.x)**2 + (c.y - CRANK_REST_ROT.y)**2 + (c.z - CRANK_REST_ROT.z)**2)
            else:
                best = min(cands, key=lambda c: (c.x - prev_crank_rot.x)**2 + (c.y - prev_crank_rot.y)**2 + (c.z - prev_crank_rot.z)**2)
            prev_crank_rot = best
            xyz = best
        else:
            pos = relative.translation
            xyz = relative.to_euler('XYZ')
        reeling_lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                             (indexes[name], *pos, *xyz))
reeling_lines.append('end')
with open(os.path.join(out, 'reel_in_fish.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(reeling_lines) + '\n')

# -------------------------------------------------------------------------
# 6. UPDATE cast.smd, cast_ready.smd, cast_ready_hold.smd (fix bone 62 pivot)
# -------------------------------------------------------------------------
def patch_bone_62(filename):
    path = os.path.join(out, filename)
    if not os.path.exists(path):
        return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.readlines()
    new_content = []
    in_skeleton = False
    replacement = '62 %.6f %.6f %.6f %.6f %.6f %.6f\n' % (*CRANK_PIVOT_POS, *CRANK_REST_ROT)
    for l in content:
        if l.strip() == 'skeleton':
            in_skeleton = True
            new_content.append(l)
        elif l.strip() == 'end':
            in_skeleton = False
            new_content.append(l)
        elif in_skeleton and l.startswith('62 '):
            new_content.append(replacement)
        else:
            new_content.append(l)
    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(new_content)
    print(f'Patched {filename} with new crank pivot')

patch_bone_62('cast.smd')
patch_bone_62('cast_ready.smd')
patch_bone_62('cast_ready_hold.smd')

# -------------------------------------------------------------------------
# 7. DELETE OBSOLETE reel.smd
# -------------------------------------------------------------------------
obsolete_reel = os.path.join(out, 'reel.smd')
if os.path.exists(obsolete_reel):
    os.remove(obsolete_reel)
    print(f'Deleted obsolete {obsolete_reel}')

print('ALL SMDS REBUILT SUCCESSFULLY!')
