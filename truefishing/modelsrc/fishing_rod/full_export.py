"""COMPLETE EXPORT: Reference mesh + all animations from FishingRod_Arms_Rig.blend

This exports everything from a single blend file to ensure consistency
between the reference mesh and all animations.

Run with:
& "D:\steam\steamapps\common\Blender\blender.exe" -b "FishingRod_Arms_Rig.blend" -P full_export.py
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
hands_mesh = bpy.data.objects['hands_reference']
rod_mesh = bpy.data.objects['FishingRod']

# =========================================================================
# SKELETON DEFINITION (same as the compiled model)
# =========================================================================
entries = [(b.name, b.parent.name if b.parent else None, arms) for b in arms.data.bones]
entries += [('cast_' + b.name,
             'cast_' + b.parent.name if b.parent else 'v_weapon.Right_Hand', rod)
            for b in rod.data.bones]
indexes = {name: i for i, (name, _, _) in enumerate(entries)}

# Source coordinate transform: arms.matrix_world.inverted() maps
# Blender world (meters) to Source viewmodel inches
to_source = arms.matrix_world.inverted()

print(f"Arms world matrix:\n{arms.matrix_world}")
print(f"Rod world matrix:\n{rod.matrix_world}")
print(f"to_source:\n{to_source}")
print(f"Skeleton: {len(entries)} bones")

# =========================================================================
# HELPER FUNCTIONS
# =========================================================================
def pose_matrices():
    """Get world-space pose matrices for all bones, transformed to Source space."""
    result = {}
    for name, _, arm in entries:
        bone_name = name[5:] if arm == rod else name  # strip 'cast_' for rod bones
        pb = arm.pose.bones.get(bone_name)
        if pb is None:
            result[name] = Matrix.Identity(4)
            continue
        world = to_source @ arm.matrix_world @ pb.matrix
        result[name] = Matrix.Translation(world.translation) @ world.to_quaternion().to_matrix().to_4x4()
    return result

def skeleton_frame(frame_num, time_index=None):
    """Generate skeleton lines for a single frame."""
    bpy.context.scene.frame_set(frame_num)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    if time_index is None:
        time_index = frame_num
    lines = [f'time {time_index}']
    for name, parent, _ in entries:
        relative = mats[parent].inverted() @ mats[name] if parent else mats[name]
        pos = relative.translation
        xyz = relative.to_euler('XYZ')
        lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' %
                     (indexes[name], *pos, *xyz))
    return lines

nodes_lines = ['nodes'] + ['%d "%s" %d' % (i, name, indexes[parent] if parent else -1)
                            for i, (name, parent, _) in enumerate(entries)] + ['end']

def write_animation(filename, frames):
    """Write an animation SMD with given frames [(frame_num, time_index), ...]."""
    lines = ['version 1'] + nodes_lines + ['skeleton']
    for frame_num, time_idx in frames:
        lines.extend(skeleton_frame(frame_num, time_idx))
    lines.append('end')
    path = os.path.join(out, filename)
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'  Wrote {filename} ({len(frames)} frames)')

# =========================================================================
# ENSURE ANIMATION DATA EXISTS
# =========================================================================
arms.animation_data_create()
rod.animation_data_create()

# =========================================================================
# POSE HELPERS
# =========================================================================
arm_bones = [
    'v_weapon.Root34', 'v_weapon.Root36',
    'v_weapon.Right_Arm', 'v_weapon.Left_Arm',
    'v_weapon.Right_Hand', 'v_weapon.Left_Hand',
    'v_weapon.Right_Index01', 'v_weapon.Right_Middle01', 'v_weapon.Right_Thumb01',
    'v_weapon.Left_Index01', 'v_weapon.Left_Middle01', 'v_weapon.Left_Thumb01',
    'v_weapon.Left_Thumb_02',
]
rod_bones_list = ['handle', 'reel', 'rod_lower', 'rod_mid', 'rod_upper', 'rod_tip']

ap = arms.pose.bones
rp = rod.pose.bones

for b in arm_bones:
    if b in ap:
        ap[b].rotation_mode = 'QUATERNION'
for b in rod_bones_list:
    if b in rp:
        rp[b].rotation_mode = 'QUATERNION'

def key_arms(frame):
    for b in arm_bones:
        if b in ap:
            ap[b].keyframe_insert('rotation_quaternion', frame=frame)
            ap[b].keyframe_insert('location', frame=frame)

def key_rod(frame):
    for b in rod_bones_list:
        if b in rp:
            rp[b].keyframe_insert('rotation_quaternion', frame=frame)
            rp[b].keyframe_insert('location', frame=frame)

def apply_idle_pose():
    """Set the idle pose - this matches the visual pose the user set up in Blender."""
    # Keep shoulders anchored
    for s in ['v_weapon.Root34', 'v_weapon.Root36']:
        if s in ap:
            ap[s].location = Vector((0, 0, 0))
            ap[s].rotation_quaternion = Quaternion((1, 0, 0, 0))

    # Arms natural hold
    ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(8), math.radians(12), math.radians(-12)), 'XYZ').to_quaternion()
    ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(12), math.radians(-5), math.radians(8)), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-12), math.radians(22), math.radians(28)), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(18), math.radians(-25), math.radians(-8)), 'XYZ').to_quaternion()

    # Fingers gently holding
    ap['v_weapon.Right_Index01'].rotation_quaternion = Euler((math.radians(35), 0, 0), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Index01'].rotation_quaternion = Euler((math.radians(30), 0, 0), 'XYZ').to_quaternion()

    # Rod handle angled up, pointing center-forward
    rp['handle'].rotation_quaternion = Euler((math.radians(-22), math.radians(4), math.radians(8)), 'XYZ').to_quaternion()
    rp['reel'].rotation_quaternion = Quaternion((1, 0, 0, 0))
    for b in ['rod_lower', 'rod_mid', 'rod_upper', 'rod_tip']:
        rp[b].rotation_quaternion = Quaternion((1, 0, 0, 0))

# =========================================================================
# 1. EXPORT REFERENCE MESH (at idle pose, frame 0)
# =========================================================================
print("\n=== EXPORTING REFERENCE MESH ===")

# Clear actions to use manual/rest pose at frame 0
old_arms_action = arms.animation_data.action
old_rod_action = rod.animation_data.action

scene.frame_set(0)
bpy.context.view_layer.update()

ref = ['version 1'] + nodes_lines + ['skeleton'] + skeleton_frame(0, 0) + ['end', 'triangles']

meshes = ((hands_mesh, arms, 'cast_hands'),
          (rod_mesh, rod, 'Default'))

for obj, arm, material in meshes:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    uv = mesh.uv_layers.active
    if not uv:
        print(f"  WARNING: {obj.name} has no UV layer, skipping")
        evaluated.to_mesh_clear()
        continue

    to_source_mesh = to_source @ evaluated.matrix_world
    normal_matrix = to_source_mesh.to_3x3().inverted().transposed()

    tri_count = 0
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
                influences = [(indexes.get('cast_handle', indexes.get('v_weapon', 0)), 1.0)]
            total = sum(w for _, w in influences)
            if total < 0.001:
                total = 1.0
            links = ' '.join('%d %.6f' % (i, w / total) for i, w in influences)
            ref.append('%d %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %d %s' %
                       (influences[0][0], *world, *normal, tex.x, tex.y,
                        len(influences), links))
        tri_count += 1
    evaluated.to_mesh_clear()
    print(f'  {obj.name}: {tri_count} triangles, material={material}')

ref.append('end')

ref_path = os.path.join(out, 'cast_reference.smd')
with open(ref_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(ref) + '\n')
print(f'  Reference mesh written to {ref_path}')

# =========================================================================
# 2. EXPORT IDLE (single frame at current pose)
# =========================================================================
print("\n=== EXPORTING IDLE ===")
write_animation('idle.smd', [(0, 0)])

# =========================================================================
# 3. CREATE & EXPORT CAST ANIMATION (PullBack + Throw + Settle)
# =========================================================================
print("\n=== CREATING CAST ANIMATION ===")

cast_arms = bpy.data.actions.get('TF_Cast_Arms_Full')
if cast_arms:
    bpy.data.actions.remove(cast_arms)
cast_rod_act = bpy.data.actions.get('TF_Cast_Rod_Full')
if cast_rod_act:
    bpy.data.actions.remove(cast_rod_act)

cast_arms = bpy.data.actions.new('TF_Cast_Arms_Full')
cast_rod_act = bpy.data.actions.new('TF_Cast_Rod_Full')
arms.animation_data.action = cast_arms
rod.animation_data.action = cast_rod_act

# Frame 1: Idle
scene.frame_set(1)
apply_idle_pose()
bpy.context.view_layer.update()
key_arms(1); key_rod(1)

# Frame 12: Starting windup
scene.frame_set(12)
apply_idle_pose()
ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(-10), math.radians(18), math.radians(-20)), 'XYZ').to_quaternion()
ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(25), math.radians(-10), math.radians(15)), 'XYZ').to_quaternion()
rp['handle'].rotation_quaternion = Euler((math.radians(-55), math.radians(8), math.radians(12)), 'XYZ').to_quaternion()
rp['rod_lower'].rotation_quaternion = Euler((math.radians(5), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(10), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(15), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(20), 0, 0), 'XYZ').to_quaternion()
bpy.context.view_layer.update()
key_arms(12); key_rod(12)

# Frame 28: Peak PullBack
scene.frame_set(28)
ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(-28), math.radians(24), math.radians(-32)), 'XYZ').to_quaternion()
ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(40), math.radians(-15), math.radians(25)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-20), math.radians(15), math.radians(35)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(25), math.radians(-20), math.radians(-5)), 'XYZ').to_quaternion()
rp['handle'].rotation_quaternion = Euler((math.radians(-88), math.radians(12), math.radians(15)), 'XYZ').to_quaternion()
rp['rod_lower'].rotation_quaternion = Euler((math.radians(8), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(18), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(26), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(35), 0, 0), 'XYZ').to_quaternion()
for s in ['v_weapon.Root34', 'v_weapon.Root36']:
    ap[s].location = Vector((0, 0, 0))
    ap[s].rotation_quaternion = Quaternion((1, 0, 0, 0))
bpy.context.view_layer.update()
key_arms(28); key_rod(28)

# Frame 36: Forward whip
scene.frame_set(36)
apply_idle_pose()
ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(22), math.radians(6), math.radians(-5)), 'XYZ').to_quaternion()
ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(-15), math.radians(5), math.radians(0)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-8), math.radians(25), math.radians(22)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(12), math.radians(-28), math.radians(-10)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Index01'].rotation_quaternion = Euler((math.radians(-15), 0, 0), 'XYZ').to_quaternion()
if 'v_weapon.Left_Thumb01' in ap:
    ap['v_weapon.Left_Thumb01'].rotation_quaternion = Euler((math.radians(-20), 0, 0), 'XYZ').to_quaternion()
rp['handle'].rotation_quaternion = Euler((math.radians(12), math.radians(-2), math.radians(4)), 'XYZ').to_quaternion()
rp['rod_lower'].rotation_quaternion = Euler((math.radians(-15), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(-28), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(-38), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(-48), 0, 0), 'XYZ').to_quaternion()
bpy.context.view_layer.update()
key_arms(36); key_rod(36)

# Frame 44: Follow-through
scene.frame_set(44)
apply_idle_pose()
ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(15), math.radians(8), math.radians(-8)), 'XYZ').to_quaternion()
ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(-5), math.radians(2), math.radians(2)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Index01'].rotation_quaternion = Euler((math.radians(-10), 0, 0), 'XYZ').to_quaternion()
rp['handle'].rotation_quaternion = Euler((math.radians(-8), math.radians(0), math.radians(6)), 'XYZ').to_quaternion()
rp['rod_lower'].rotation_quaternion = Euler((math.radians(10), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(18), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(22), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(25), 0, 0), 'XYZ').to_quaternion()
bpy.context.view_layer.update()
key_arms(44); key_rod(44)

# Frame 54: Damping
scene.frame_set(54)
apply_idle_pose()
rp['handle'].rotation_quaternion = Euler((math.radians(-20), math.radians(3), math.radians(7)), 'XYZ').to_quaternion()
rp['rod_lower'].rotation_quaternion = Euler((math.radians(-3), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(-5), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(-6), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(-8), 0, 0), 'XYZ').to_quaternion()
bpy.context.view_layer.update()
key_arms(54); key_rod(54)

# Frame 70: Return to Idle
scene.frame_set(70)
apply_idle_pose()
bpy.context.view_layer.update()
key_arms(70); key_rod(70)

# Export cast animation
write_animation('cast.smd', [(f, f-1) for f in range(1, 71)])

# =========================================================================
# 4. CREATE & EXPORT REEL ANIMATION (15-frame loop)
# =========================================================================
print("\n=== CREATING REEL ANIMATION ===")

reel_arms = bpy.data.actions.get('TF_Reel_Arms_Full')
if reel_arms:
    bpy.data.actions.remove(reel_arms)
reel_rod_act = bpy.data.actions.get('TF_Reel_Rod_Full')
if reel_rod_act:
    bpy.data.actions.remove(reel_rod_act)

reel_arms = bpy.data.actions.new('TF_Reel_Arms_Full')
reel_rod_act = bpy.data.actions.new('TF_Reel_Rod_Full')
arms.animation_data.action = reel_arms
rod.animation_data.action = reel_rod_act

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
    key_arms(f); key_rod(f)

# Export reel animation
arms.animation_data.action = reel_arms
rod.animation_data.action = reel_rod_act
write_animation('reel.smd', [(f, f-1) for f in range(1, 16)])

# =========================================================================
# 5. RESTORE & SAVE
# =========================================================================
# Restore original actions
arms.animation_data.action = cast_arms
rod.animation_data.action = cast_rod_act
scene.frame_set(1)

# Mark actions with fake user
for act in [cast_arms, cast_rod_act, reel_arms, reel_rod_act]:
    act.use_fake_user = True

bpy.ops.wm.save_mainfile()
print("\n=== ALL EXPORTS COMPLETE ===")
print(f"Output directory: {out}")
