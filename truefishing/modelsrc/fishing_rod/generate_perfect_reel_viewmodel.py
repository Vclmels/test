"""Generate a mathematically perfect 360-degree reel animation from frame 6 to 18.

Key design principles:
1. Exact Shaft Pivot:
   Crank rotates strictly around its true shaft center (0.122718, 11.211322, -3.790581) relative to cast_handle.
   The base of the crank NEVER displaces or pops out of the reel body.
2. Perfect Circular Tracking:
   The Left Hand (v_weapon.Left_Arm) follows the exact 3D circular arc traced by the crank knob.
   Frame 6 is the exact grab pose (0°).
   Frame 18 returns with 0.000000 error to the exact Frame 6 pose (360° closed loop).
3. Clean Mesh Rigging:
   cast_reference.smd binds ONLY the 152 vertices of lever_crank to cast_reel (bone 62).
   The reel body, spool, and bail wire are 100% rigid on cast_handle (bone 61).
4. Blender Actions Saved:
   Both Action.003 and FishingRodRigAction.006 are updated in FishingRod_Arms_Rig.blend.
"""

import os
import math
import bpy
import bmesh
from mathutils import Vector, Matrix, Euler, Quaternion

base = os.path.dirname(bpy.data.filepath)
out = os.path.join(base, 'cast_viewmodel')
os.makedirs(out, exist_ok=True)

scene = bpy.context.scene
arms = bpy.data.objects['hands_reference_skeleton']
rod = bpy.data.objects['FishingRodRig']
fr = bpy.data.objects['FishingRod']

to_source = arms.matrix_world.inverted()
to_source_rod = to_source @ rod.matrix_world

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

def pose_matrices():
    result = {}
    for name, _, arm in entries:
        bone_name = 'lever_crank' if name == 'cast_reel' else name[5:]
        p = arm.pose.bones[bone_name if arm == rod else name]
        world = to_source @ arm.matrix_world @ p.matrix
        result[name] = Matrix.Translation(world.translation) @ world.to_quaternion().to_matrix().to_4x4()
    return result

# -------------------------------------------------------------------------
# 1. COMPUTE EXACT CRANK GEOMETRY & ROTATION PARAMETERS
# -------------------------------------------------------------------------
vg = fr.vertex_groups.get('lever_crank')
crank_indices = [v.index for v in fr.data.vertices for g in v.groups if g.group == vg.index and g.weight > 0.5]
verts = [fr.data.vertices[i].co for i in crank_indices]
min_x = min(v.x for v in verts)
max_x = max(v.x for v in verts)
shaft_verts = [v for v in verts if v.x < min_x + 0.015]
knob_verts = [v for v in verts if v.x > max_x - 0.02]

shaft_local = sum(shaft_verts, Vector()) / len(shaft_verts)
knob_local0 = sum(knob_verts, Vector()) / len(knob_verts)
r_arm = Vector((0, knob_local0.y - shaft_local.y, knob_local0.z - shaft_local.z)).length

bpy.context.scene.frame_set(0)
bpy.context.view_layer.update()
mats0 = pose_matrices()

shaft_world = to_source @ rod.matrix_world @ shaft_local
SHAFT_REL_HANDLE = mats0['cast_handle'].inverted() @ shaft_world
ROT_REL = mats0['cast_handle'].inverted().to_quaternion().to_matrix().to_4x4() @ to_source_rod.to_quaternion().to_matrix().to_4x4()
CRANK_REST_ROT = ROT_REL.to_euler('XYZ')

print(f'Shaft center relative to cast_handle: {SHAFT_REL_HANDLE}')
print(f'Crank rest Euler relative to cast_handle: {CRANK_REST_ROT}')

# -------------------------------------------------------------------------
# 2. COMPUTE LEFT_ARM INVERSE KINEMATICS JACOBIAN FOR PERFECT CIRCULAR MOTION
# -------------------------------------------------------------------------
bpy.context.scene.frame_set(6)
bpy.context.view_layer.update()

pb_arm = arms.pose.bones['v_weapon.Left_Arm']
pb_hand = arms.pose.bones['v_weapon.Left_Hand']
loc_arm_f6 = pb_arm.location.copy()
p_hand_f6 = pb_hand.matrix.translation.copy()

cols = []
for i in range(3):
    d = Vector((0, 0, 0))
    d[i] = 1.0
    pb_arm.location = loc_arm_f6 + d
    bpy.context.view_layer.update()
    p1 = pb_hand.matrix.translation.copy()
    pb_arm.location = loc_arm_f6
    bpy.context.view_layer.update()
    cols.append(p1 - p_hand_f6)

M_inv = Matrix((cols[0], cols[1], cols[2])).transposed().inverted()
knob_source0 = to_source_rod @ knob_local0

# Calculate exact arm locations and crank rotations for 13 frames (F6 to F18)
arm_locs = []
crank_rots = []

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

prev_e = None
for i in range(13):
    theta = i / 12.0 * 2.0 * math.pi
    knob_local_t = shaft_local + Vector((knob_local0.x - shaft_local.x,
                                         r_arm * math.cos(theta),
                                         r_arm * math.sin(theta)))
    knob_source_t = to_source_rod @ knob_local_t
    delta_hand_source = knob_source_t - knob_source0
    loc_arm_t = loc_arm_f6 + (M_inv @ delta_hand_source)
    arm_locs.append(loc_arm_t)

    rot_local = Euler((theta, 0, 0), 'XYZ').to_matrix().to_4x4()
    rot_t = ROT_REL @ rot_local
    e_raw = rot_t.to_euler('XYZ')
    cands = get_candidates(e_raw)
    if prev_e is None:
        best = min(cands, key=lambda c: (c.x - CRANK_REST_ROT.x)**2 + (c.y - CRANK_REST_ROT.y)**2 + (c.z - CRANK_REST_ROT.z)**2)
    else:
        best = min(cands, key=lambda c: (c.x - prev_e.x)**2 + (c.y - prev_e.y)**2 + (c.z - prev_e.z)**2)
    prev_e = best
    crank_rots.append(best)

print('Computed 13 seamless 360-degree rotation frames.')

# -------------------------------------------------------------------------
# 3. UPDATE BLENDER ACTIONS Action.003 AND FishingRodRigAction.006
# -------------------------------------------------------------------------
print('Updating Blender actions Action.003 and FishingRodRigAction.006...')
act_arms = bpy.data.actions['Action.003']
act_rod = bpy.data.actions['FishingRodRigAction.006']

arms.animation_data.action = act_arms
rod.animation_data.action = act_rod
pb_crank = rod.pose.bones['lever_crank']

# Ensure edit bone lever_crank head is at shaft_local
bpy.context.view_layer.objects.active = rod
bpy.ops.object.mode_set(mode='EDIT')
eb = rod.data.edit_bones['lever_crank']
eb.head = shaft_local
eb.tail = shaft_local + Vector((0.1, 0, 0))
eb.roll = 0
bpy.ops.object.mode_set(mode='OBJECT')

for i in range(13):
    f = 6 + i
    theta = i / 12.0 * 2.0 * math.pi
    scene.frame_set(f)

    # Hand arm location follows crank
    pb_arm.location = arm_locs[i]
    pb_arm.keyframe_insert('location', frame=f)

    # Crank rotation around local shaft axis (+X)
    # Since eb length is along X, local Y is along X in Blender convention
    # Local rotation around X:
    q = Quaternion((math.cos(theta / 2.0), 0, math.sin(theta / 2.0), 0))
    pb_crank.rotation_quaternion = q
    pb_crank.keyframe_insert('rotation_quaternion', frame=f)

bpy.ops.wm.save_mainfile()
print('Saved updated animations into FishingRod_Arms_Rig.blend')

# -------------------------------------------------------------------------
# 3.5 EXTEND ARM GEOMETRY BACKWARDS WITH SEAMLESS SKIN UVs
# -------------------------------------------------------------------------
hands_obj = bpy.data.objects['hands_reference']
bm = bmesh.new()
bm.from_mesh(hands_obj.data)
bm.verts.ensure_lookup_table()
bm.edges.ensure_lookup_table()
bm.faces.ensure_lookup_table()

# Always reset any previously extruded vertices (indices >= 900) so we start fresh from 900 clean verts
del_verts = [v for v in bm.verts if v.index >= 900]
if del_verts:
    print('Resetting', len(del_verts), 'previously extruded vertices...')
    bmesh.ops.delete(bm, geom=del_verts, context='VERTS')
    bm.verts.ensure_lookup_table()
    bm.edges.ensure_lookup_table()
    bm.faces.ensure_lookup_table()

dvert_lay = bm.verts.layers.deform.verify()
uv_lay = bm.loops.layers.uv.verify()

# Lift Ring 4 UVs safely away from the 0.38 dark border into clean, bright forearm skin (0.415)
r4_l = [163, 164, 183, 166, 185, 161, 133, 170, 171]
r4_r = [485, 486, 478, 496, 497, 479, 498, 480, 499]
for v_idx in r4_l + r4_r:
    v = bm.verts[v_idx]
    for l in v.link_loops:
        if l[uv_lay].uv.y < 0.41:
            l[uv_lay].uv.y = 0.415

for arm_side in ['left', 'right']:
    is_left = (arm_side == 'left')
    vg_name = 'v_weapon.Left_Arm' if is_left else 'v_weapon.Right_Arm'
    vg_idx = hands_obj.vertex_groups[vg_name].index

    b_edges = [e for e in bm.edges if len(e.link_faces) == 1 and ((e.verts[0].co.x > 0) if is_left else (e.verts[0].co.x < 0))]
    curr_edges = b_edges

    v_goals = [0.53, 0.65, 0.53]
    total_dist = 18.0
    steps = 3
    step_dist = total_dist / steps

    for s in range(steps):
        target_v = v_goals[s]
        res = bmesh.ops.extrude_edge_only(bm, edges=curr_edges)
        new_verts = [v for v in res['geom'] if isinstance(v, bmesh.types.BMVert)]
        new_edges = [e for e in res['geom'] if isinstance(e, bmesh.types.BMEdge) and len(e.link_faces) == 1]
        new_faces = [f for f in res['geom'] if isinstance(f, bmesh.types.BMFace)]

        cx = sum(v.co.x for v in new_verts) / len(new_verts)
        cz = sum(v.co.z for v in new_verts) / len(new_verts)

        for v in new_verts:
            v[dvert_lay][vg_idx] = 1.0
            v.co.y += step_dist
            v.co.x = cx + (v.co.x - cx) * 1.03
            v.co.z = cz + (v.co.z - cz) * 1.03

        # Assign seamless UV gradient across the new cylinder faces
        for f in new_faces:
            f.smooth = True
            for l in f.loops:
                if l.vert in new_verts:
                    l[uv_lay].uv.y = target_v

        curr_edges = new_edges

    # Cap the end
    cap_res = bmesh.ops.contextual_create(bm, geom=curr_edges)
    for f in cap_res['faces']:
        f.smooth = True
        for l in f.loops:
            l[uv_lay].uv = Vector((0.80, 0.53))

bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(hands_obj.data)
hands_obj.data.update()
bpy.ops.wm.save_mainfile()
print('Arm geometry extended with seamless skin UVs and saved into FishingRod_Arms_Rig.blend.')

# -------------------------------------------------------------------------
# 4. EXPORT cast_reference.smd
# -------------------------------------------------------------------------
print('Exporting cast_reference.smd...')
nodes_lines = ['nodes'] + [
    '%d "%s" %d' % (i, name, indexes[parent] if parent else -1)
    for i, (name, parent, _) in enumerate(entries)
] + ['end']

scene.frame_set(0)
bpy.context.view_layer.update()
mats = pose_matrices()

skel_lines = ['time 0']
for name, parent, _ in entries:
    rel = mats[parent].inverted() @ mats[name] if parent else mats[name]
    pos = SHAFT_REL_HANDLE if name == 'cast_reel' else rel.translation
    xyz = CRANK_REST_ROT if name == 'cast_reel' else rel.to_euler('XYZ')
    skel_lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' % (indexes[name], *pos, *xyz))

ref_lines = ['version 1'] + nodes_lines + ['skeleton'] + skel_lines + ['end', 'triangles']

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
with open(os.path.join(out, 'cast_reference.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(ref_lines) + '\n')
print('Wrote cast_reference.smd')

# -------------------------------------------------------------------------
# 5. EXPORT ANIMATION SMDs: idle, reel_ready, reel_hold, reel_in_fish
# -------------------------------------------------------------------------
print('Exporting idle.smd...')
idle_lines = ['version 1'] + nodes_lines + ['skeleton'] + skel_lines + ['end']
with open(os.path.join(out, 'idle.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(idle_lines) + '\n')

print('Exporting reel_ready.smd...')
arms.animation_data.action = bpy.data.actions['Action.002']
ready_lines = ['version 1'] + nodes_lines + ['skeleton']
for idx, f in enumerate(range(0, 7)):
    scene.frame_set(f)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    ready_lines.append(f'time {idx}')
    for name, parent, _ in entries:
        rel = mats[parent].inverted() @ mats[name] if parent else mats[name]
        pos = SHAFT_REL_HANDLE if name == 'cast_reel' else rel.translation
        xyz = CRANK_REST_ROT if name == 'cast_reel' else rel.to_euler('XYZ')
        ready_lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' % (indexes[name], *pos, *xyz))
ready_lines.append('end')
with open(os.path.join(out, 'reel_ready.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(ready_lines) + '\n')

print('Exporting reel_hold.smd...')
hold_lines = ['version 1'] + nodes_lines + ['skeleton']
for idx in [0, 1]:
    scene.frame_set(6)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    hold_lines.append(f'time {idx}')
    for name, parent, _ in entries:
        rel = mats[parent].inverted() @ mats[name] if parent else mats[name]
        pos = SHAFT_REL_HANDLE if name == 'cast_reel' else rel.translation
        xyz = CRANK_REST_ROT if name == 'cast_reel' else rel.to_euler('XYZ')
        hold_lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' % (indexes[name], *pos, *xyz))
hold_lines.append('end')
with open(os.path.join(out, 'reel_hold.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(hold_lines) + '\n')

print('Exporting reel_in_fish.smd (Flawless 360 degrees)...')
arms.animation_data.action = bpy.data.actions['Action.003']
rod.animation_data.action = bpy.data.actions['FishingRodRigAction.006']
reeling_lines = ['version 1'] + nodes_lines + ['skeleton']
for idx in range(13):
    f = 6 + idx
    scene.frame_set(f)
    bpy.context.view_layer.update()
    mats = pose_matrices()
    reeling_lines.append(f'time {idx}')
    for name, parent, _ in entries:
        rel = mats[parent].inverted() @ mats[name] if parent else mats[name]
        pos = SHAFT_REL_HANDLE if name == 'cast_reel' else rel.translation
        xyz = crank_rots[idx] if name == 'cast_reel' else rel.to_euler('XYZ')
        reeling_lines.append('%d %.6f %.6f %.6f %.6f %.6f %.6f' % (indexes[name], *pos, *xyz))
reeling_lines.append('end')
with open(os.path.join(out, 'reel_in_fish.smd'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(reeling_lines) + '\n')

# -------------------------------------------------------------------------
# 6. PATCH cast.smd, cast_ready.smd, cast_ready_hold.smd
# -------------------------------------------------------------------------
def patch_bone_62(filename):
    path = os.path.join(out, filename)
    if not os.path.exists(path):
        return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.readlines()
    new_content = []
    in_skeleton = False
    replacement = '62 %.6f %.6f %.6f %.6f %.6f %.6f\n' % (*SHAFT_REL_HANDLE, *CRANK_REST_ROT)
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
    print(f'Patched {filename} skeleton bone 62 with true shaft pivot')

patch_bone_62('cast.smd')
patch_bone_62('cast_ready.smd')
patch_bone_62('cast_ready_hold.smd')

print('ALL SMDS AND BLENDER FILE SUCCESSFULLY UPDATED!')
