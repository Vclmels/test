"""Create the reel animation and export all SMDs.

Run with:
& "D:\steam\steamapps\common\Blender\blender.exe" -b "FishingRod_Cast_Realistic.blend" -P create_reel_and_export.py
"""

import os
import math
import bpy
from mathutils import Matrix, Vector, Quaternion, Euler

base = os.path.dirname(bpy.data.filepath)
out = os.path.join(base, 'cast_viewmodel')
os.makedirs(out, exist_ok=True)

scene = bpy.context.scene
scene.render.fps = 30

arms = bpy.data.objects['hands_reference_skeleton']
rod = bpy.data.objects['FishingRodRig']

ap = arms.pose.bones
rp = rod.pose.bones

# -------------------------------------------------------------------------
# 1. CREATE REEL ACTION (if missing)
# -------------------------------------------------------------------------
arm_bones = [
    'v_weapon.Root34', 'v_weapon.Root36',
    'v_weapon.Right_Arm', 'v_weapon.Left_Arm',
    'v_weapon.Right_Hand', 'v_weapon.Left_Hand',
    'v_weapon.Right_Index01', 'v_weapon.Right_Middle01', 'v_weapon.Right_Thumb01',
    'v_weapon.Left_Index01', 'v_weapon.Left_Middle01', 'v_weapon.Left_Thumb01',
    'v_weapon.Left_Thumb_02',
]
rod_bones = ['handle', 'reel', 'rod_lower', 'rod_mid', 'rod_upper', 'rod_tip']

for b in arm_bones:
    ap[b].rotation_mode = 'QUATERNION'
for b in rod_bones:
    rp[b].rotation_mode = 'QUATERNION'

def key_arms(frame):
    for b in arm_bones:
        ap[b].keyframe_insert('rotation_quaternion', frame=frame)
        ap[b].keyframe_insert('location', frame=frame)

def key_rod(frame):
    for b in rod_bones:
        rp[b].keyframe_insert('rotation_quaternion', frame=frame)
        rp[b].keyframe_insert('location', frame=frame)

def apply_idle_pose():
    ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(8), math.radians(12), math.radians(-12)), 'XYZ').to_quaternion()
    ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(12), math.radians(-5), math.radians(8)), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-12), math.radians(22), math.radians(28)), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(18), math.radians(-25), math.radians(-8)), 'XYZ').to_quaternion()
    ap['v_weapon.Right_Index01'].rotation_quaternion = Euler((math.radians(35), 0, 0), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Index01'].rotation_quaternion = Euler((math.radians(30), 0, 0), 'XYZ').to_quaternion()
    rp['handle'].rotation_quaternion = Euler((math.radians(-22), math.radians(4), math.radians(8)), 'XYZ').to_quaternion()
    rp['reel'].rotation_quaternion = Quaternion((1, 0, 0, 0))
    for b in ['rod_lower', 'rod_mid', 'rod_upper', 'rod_tip']:
        rp[b].rotation_quaternion = Quaternion((1, 0, 0, 0))
    # Anchored shoulders
    for s in ['v_weapon.Root34', 'v_weapon.Root36']:
        ap[s].location = Vector((0, 0, 0))
        ap[s].rotation_quaternion = Quaternion((1, 0, 0, 0))

arms.animation_data_create()
rod.animation_data_create()

reel_arms = bpy.data.actions.get('TF_Reel_Arms')
reel_rod = bpy.data.actions.get('TF_Reel_Rod')
if not reel_arms:
    reel_arms = bpy.data.actions.new('TF_Reel_Arms')
if not reel_rod:
    reel_rod = bpy.data.actions.new('TF_Reel_Rod')

arms.animation_data.action = reel_arms
rod.animation_data.action = reel_rod

for f in range(1, 16):
    frac = (f - 1) / 15.0
    angle = frac * 2.0 * math.pi
    scene.frame_set(f)
    apply_idle_pose()

    crank_y = math.sin(angle) * math.radians(6)
    crank_z = math.cos(angle) * math.radians(6)
    ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-12) + crank_y, math.radians(22), math.radians(28) + crank_z), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(18) - crank_y, math.radians(-25), math.radians(-8) - crank_z), 'XYZ').to_quaternion()

    rp['reel'].rotation_quaternion = Euler((angle, 0, 0), 'XYZ').to_quaternion()

    pulse = math.sin(angle * 2.0) * math.radians(3)
    rp['rod_tip'].rotation_quaternion = Euler((pulse, 0, 0), 'XYZ').to_quaternion()

    bpy.context.view_layer.update()
    key_arms(f)
    key_rod(f)

print("REEL ACTION CREATED (15 frames)")

# Mark actions as fake users so they persist
reel_arms.use_fake_user = True
reel_rod.use_fake_user = True

# Save blend
bpy.ops.wm.save_mainfile()
print("Saved blend file")

# -------------------------------------------------------------------------
# 2. EXPORT ALL SMDs
# -------------------------------------------------------------------------
meshes = ((bpy.data.objects['hands_reference'], arms, 'cast_hands'),
          (bpy.data.objects['FishingRod'], rod, 'Default'))

entries = [(b.name, b.parent.name if b.parent else None, arms) for b in arms.data.bones]
entries += [('cast_' + b.name,
             'cast_' + b.parent.name if b.parent else 'v_weapon.Right_Hand', rod)
            for b in rod.data.bones]
indexes = {name: i for i, (name, _, _) in enumerate(entries)}
to_source = arms.matrix_world.inverted()

def pose_matrices():
    result = {}
    for name, _, arm in entries:
        p = arm.pose.bones[name[5:] if arm == rod else name]
        world = to_source @ arm.matrix_world @ p.matrix
        result[name] = Matrix.Translation(world.translation) @ world.to_quaternion().to_matrix().to_4x4()
    return result

def skeleton_frame(frame):
    bpy.context.scene.frame_set(frame)
    mats = pose_matrices()
    lines = ['time ' + str(frame - 1)]
    for name, parent, _ in entries:
        relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
        pos = relative.translation
        xyz = relative.to_euler('XYZ')
        lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                     (indexes[name], *pos, *xyz))
    return lines

nodes = ['nodes'] + ['%d "%s" %d' % (i, name, indexes[parent] if parent else -1)
                     for i, (name, parent, _) in enumerate(entries)] + ['end']

# Export reference mesh (with cast action active)
cast_arms = bpy.data.actions.get('TF_Cast_Arms')
cast_rod = bpy.data.actions.get('TF_Cast_Rod')
arms.animation_data.action = cast_arms
rod.animation_data.action = cast_rod

scene.frame_set(1)
ref = ['version 1'] + nodes + ['skeleton'] + skeleton_frame(1) + ['end', 'triangles']

for obj, arm, material in meshes:
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    uv = mesh.uv_layers.active
    assert uv, obj.name
    to_source_mesh = to_source @ evaluated.matrix_world
    normal_matrix = to_source_mesh.to_3x3().inverted().transposed()
    for triangle in mesh.loop_triangles:
        ref.append(material)
        for loop_idx in triangle.loops:
            vertex = mesh.vertices[mesh.loops[loop_idx].vertex_index]
            world = to_source_mesh @ vertex.co
            normal = (normal_matrix @ mesh.loops[loop_idx].normal).normalized()
            tex = uv.data[loop_idx].uv
            original = obj.data.vertices[vertex.index]
            influences = []
            for group in original.groups:
                bone = obj.vertex_groups[group.group].name
                bone = 'cast_' + bone if arm == rod else bone
                if bone in indexes:
                    influences.append((indexes[bone], group.weight))
            influences.sort(key=lambda pair: pair[1], reverse=True)
            influences = influences[:4]
            if not influences:
                influences = [(indexes['cast_handle' if arm == rod else 'v_weapon'], 1.0)]
            total = sum(w for _, w in influences)
            links = ' '.join('%d %.6f' % (i, w / total) for i, w in influences)
            ref.append('%d %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %d %s' %
                       (influences[0][0], *world, *normal, tex.x, tex.y,
                        len(influences), links))
    evaluated.to_mesh_clear()
ref.append('end')

with open(os.path.join(out, 'cast_reference.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(ref) + '\n')

def animation(path, frames):
    lines = ['version 1'] + nodes + ['skeleton']
    for frame in frames:
        lines.extend(skeleton_frame(frame))
    lines.append('end')
    with open(os.path.join(out, path), 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')

# Export cast and idle with cast action
animation('cast.smd', range(1, 71))
animation('idle.smd', (1,))
print('EXPORTED cast.smd (70 frames) and idle.smd')

# Export reel with reel action
arms.animation_data.action = reel_arms
rod.animation_data.action = reel_rod
animation('reel.smd', range(1, 16))
print('EXPORTED reel.smd (15 frames)')

# Restore
arms.animation_data.action = cast_arms
rod.animation_data.action = cast_rod

print('ALL EXPORTS COMPLETE:', out)
