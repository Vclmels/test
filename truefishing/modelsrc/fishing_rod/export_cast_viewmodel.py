"""Bake the two posed armatures into a single Source SMD viewmodel and animation.

blender -b FishingRod_Cast_Realistic.blend --python export_cast_viewmodel.py
"""
import os
import shutil
import math

import bpy
from mathutils import Matrix, Vector

base = os.path.dirname(bpy.data.filepath)
out = os.path.join(base, 'cast_viewmodel')
os.makedirs(out, exist_ok=True)
addon = os.path.normpath(os.path.join(base, '..', '..'))
arms = bpy.data.objects['hands_reference_skeleton']
rod = bpy.data.objects['FishingRodRig']
meshes = ((bpy.data.objects['hands_reference'], arms, 'cast_hands'),
          (bpy.data.objects['FishingRod'], rod, 'Default'))

# A shared skeleton is essential for Source: the rod root follows the right hand.
entries = [(b.name, b.parent.name if b.parent else None, arms) for b in arms.data.bones]
entries += [('cast_' + b.name,
             'cast_' + b.parent.name if b.parent else 'v_weapon.Right_Hand', rod)
            for b in rod.data.bones]
indexes = {name: i for i, (name, _, _) in enumerate(entries)}
# In Source Engine viewmodels, the native viewmodel space inherited from
# GoldSrc / CS:S has -Y as forward, +Z as up, and +X as left (-X as right).
# In the blend file, hands_reference_skeleton has scale 0.0254 (inches to meters)
# and its local space is already the exact native Source viewmodel coordinate space!
# Therefore, inverting arms.matrix_world perfectly maps all Blender world positions
# (meters) back to native Source viewmodel inches, aligning hands and rod exactly.
to_source = arms.matrix_world.inverted()

def pose_matrices():
    result = {}
    for name, _, arm in entries:
        p = arm.pose.bones[name[5:] if arm == rod else name]
        world = to_source @ arm.matrix_world @ p.matrix
        # Scale is removed from rotation; translations are directly in inches.
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
scene = bpy.context.scene
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

animation('cast.smd', range(1, 79))
animation('idle.smd', (1,))

# Switch to reel actions for reel export
reel_arms = bpy.data.actions.get('TF_Reel_Arms')
reel_rod = bpy.data.actions.get('TF_Reel_Rod')
if reel_arms and reel_rod:
    arms.animation_data.action = reel_arms
    rod.animation_data.action = reel_rod
    animation('reel.smd', range(1, 16))
    # Restore cast actions
    arms.animation_data.action = bpy.data.actions.get('TF_Cast_Arms')
    rod.animation_data.action = bpy.data.actions.get('TF_Cast_Rod')
    print('EXPORTED_REEL 15 frames')
else:
    print('WARNING: TF_Reel actions not found, skipping reel.smd')

# The CS:S hand texture is shipped with the addon, independent of mounted games.
target = os.path.join(addon, 'materials', 'models', 'fishing')
os.makedirs(target, exist_ok=True)
source = r'D:\steam\steamapps\common\GarrysMod\sourceengine\content_cstrike_dir\materials\models\weapons\v_models\hands\v_hands.vtf'
shutil.copyfile(source, os.path.join(target, 'cast_hands.vtf'))
print('EXPORTED_CAST', len(entries), len(ref), out)
