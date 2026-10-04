"""Apply the animations from animations/ (PullBackRod, ReelOutt, ReelInn)
to the first-person CS:S arms and fishing rod rig.

Run with:
& "D:\steam\steamapps\common\Blender\blender.exe" -b "FishingRod_Arms_Rig.blend" -P apply_folder_animations.py
"""

import os
import json
import math
import struct
import bpy
import bmesh
from mathutils import Matrix, Quaternion, Vector, Euler

# -------------------------------------------------------------------------
# 1. SETUP OBJECTS & SCENE
# -------------------------------------------------------------------------
scene = bpy.context.scene
scene.render.fps = 30

arms = bpy.data.objects['hands_reference_skeleton']
rod = bpy.data.objects['FishingRodRig']
hands_mesh_obj = bpy.data.objects['hands_reference']
rod_mesh = bpy.data.objects['FishingRod']

# Clear old actions so they don't override pose
for obj in [arms, rod]:
    if obj.animation_data:
        obj.animation_data.action = None

ap = arms.pose.bones
rp = rod.pose.bones

# -------------------------------------------------------------------------
# 2. CAP ARM OPEN BOUNDARIES (PREVENT HOLLOW FUNNEL)
# -------------------------------------------------------------------------
bm = bmesh.new()
bm.from_mesh(hands_mesh_obj.data)

for vg_name in ['v_weapon.Left_Arm', 'v_weapon.Right_Arm']:
    vg = hands_mesh_obj.vertex_groups.get(vg_name)
    if not vg:
        continue
    loop_verts = []
    for e in bm.edges:
        if e.is_boundary:
            v1_in = any(g.group == vg.index for g in hands_mesh_obj.data.vertices[e.verts[0].index].groups)
            v2_in = any(g.group == vg.index for g in hands_mesh_obj.data.vertices[e.verts[1].index].groups)
            if v1_in and v2_in:
                if e.verts[0] not in loop_verts: loop_verts.append(e.verts[0])
                if e.verts[1] not in loop_verts: loop_verts.append(e.verts[1])
    if len(loop_verts) >= 3:
        try:
            face = bm.faces.new(loop_verts)
            face.material_index = 0
        except Exception:
            pass

bm.to_mesh(hands_mesh_obj.data)
bm.free()
hands_mesh_obj.data.update()

# -------------------------------------------------------------------------
# 3. CONFIGURE ROD SCALE & VIEWMODEL CAMERA FIT
# -------------------------------------------------------------------------
# Scale rod so its tip reaches Y ~ -44 inches (safe inside zFar = 54 units)
# Scale factor: 0.40 on both rig and mesh
rod.scale = (0.40, 0.40, 0.40)
rod_mesh.scale = (0.40, 0.40, 0.40)

# Ensure shoulders are anchored at (0, 0, 0)
for s in ['v_weapon.Root34', 'v_weapon.Root36']:
    ap[s].location = Vector((0, 0, 0))
    ap[s].rotation_quaternion = Quaternion((1, 0, 0, 0))

# Animated bone lists
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

# Helper to insert keyframe
def key_arms(frame):
    for b in arm_bones:
        ap[b].keyframe_insert('rotation_quaternion', frame=frame)
        ap[b].keyframe_insert('location', frame=frame)

def key_rod(frame):
    for b in rod_bones:
        rp[b].keyframe_insert('rotation_quaternion', frame=frame)
        rp[b].keyframe_insert('location', frame=frame)

# -------------------------------------------------------------------------
# 4. BASE POSES (IDLE, PULLBACK, CAST THROW, REEL)
# -------------------------------------------------------------------------
# In idle:
# - Right hand holds the upper grip / reel seat in bottom-right corner.
# - Left hand supports lower handle / butt.
# - Rod points forward and UP (+18° pitch, angled slightly towards center).
# Both forearms enter naturally from bottom edges of screen.

def apply_idle_pose():
    # Right Arm: angled in from bottom right
    ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(8), math.radians(12), math.radians(-12)), 'XYZ').to_quaternion()
    ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(12), math.radians(-5), math.radians(8)), 'XYZ').to_quaternion()
    # Left Arm: enters from bottom left, hand on lower handle / butt
    ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-12), math.radians(22), math.radians(28)), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(18), math.radians(-25), math.radians(-8)), 'XYZ').to_quaternion()
    # Fingers gently holding
    ap['v_weapon.Right_Index01'].rotation_quaternion = Euler((math.radians(35), 0, 0), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Index01'].rotation_quaternion = Euler((math.radians(30), 0, 0), 'XYZ').to_quaternion()
    # Rod handle angled +20° up, pointing center-forward
    rp['handle'].rotation_quaternion = Euler((math.radians(-22), math.radians(4), math.radians(8)), 'XYZ').to_quaternion()
    rp['reel'].rotation_quaternion = Quaternion((1, 0, 0, 0))
    for b in ['rod_lower', 'rod_mid', 'rod_upper', 'rod_tip']:
        rp[b].rotation_quaternion = Quaternion((1, 0, 0, 0))

# -------------------------------------------------------------------------
# 5. BUILD ACTION: CAST (PullBackRod + ReelOutt)
# -------------------------------------------------------------------------
# Duration: 70 frames at 30 fps (~2.3s)
# Frames 1-30: PullBackRod windup (130° swing back over right shoulder)
# Frames 31-42: ReelOutt forward whip and cast throw
# Frames 43-52: Release and rod vibration
# Frames 53-70: Settle back to idle

arms.animation_data_create()
rod.animation_data_create()

cast_action_arms = bpy.data.actions.new('TF_Cast_Arms')
cast_action_rod = bpy.data.actions.new('TF_Cast_Rod')
arms.animation_data.action = cast_action_arms
rod.animation_data.action = cast_action_rod

# Frame 1: Idle
scene.frame_set(1)
apply_idle_pose()
bpy.context.view_layer.update()
key_arms(1)
key_rod(1)

# Frame 12: Starting windup (PullBackRod early)
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
key_arms(12)
key_rod(12)

# Frame 28: Peak PullBackRod (rod tilted back over shoulder)
scene.frame_set(28)
ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(-28), math.radians(24), math.radians(-32)), 'XYZ').to_quaternion()
ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(40), math.radians(-15), math.radians(25)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-20), math.radians(15), math.radians(35)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(25), math.radians(-20), math.radians(-5)), 'XYZ').to_quaternion()
rp['handle'].rotation_quaternion = Euler((math.radians(-88), math.radians(12), math.radians(15)), 'XYZ').to_quaternion()
# Flex rod backward under weight of hook
rp['rod_lower'].rotation_quaternion = Euler((math.radians(8), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(18), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(26), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(35), 0, 0), 'XYZ').to_quaternion()
bpy.context.view_layer.update()
key_arms(28)
key_rod(28)

# Frame 36: ReelOutt forward whip (fast powerful throw)
scene.frame_set(36)
ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(22), math.radians(6), math.radians(-5)), 'XYZ').to_quaternion()
ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(-15), math.radians(5), math.radians(0)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-8), math.radians(25), math.radians(22)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(12), math.radians(-28), math.radians(-10)), 'XYZ').to_quaternion()
# Open fingers to release line
ap['v_weapon.Left_Index01'].rotation_quaternion = Euler((math.radians(-15), 0, 0), 'XYZ').to_quaternion()
ap['v_weapon.Left_Thumb01'].rotation_quaternion = Euler((math.radians(-20), 0, 0), 'XYZ').to_quaternion()
rp['handle'].rotation_quaternion = Euler((math.radians(12), math.radians(-2), math.radians(4)), 'XYZ').to_quaternion()
# Flex rod forward violently
rp['rod_lower'].rotation_quaternion = Euler((math.radians(-15), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(-28), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(-38), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(-48), 0, 0), 'XYZ').to_quaternion()
bpy.context.view_layer.update()
key_arms(36)
key_rod(36)

# Frame 44: ReelOutt follow-through and line payout
scene.frame_set(44)
ap['v_weapon.Right_Arm'].rotation_quaternion = Euler((math.radians(15), math.radians(8), math.radians(-8)), 'XYZ').to_quaternion()
ap['v_weapon.Right_Hand'].rotation_quaternion = Euler((math.radians(-5), math.radians(2), math.radians(2)), 'XYZ').to_quaternion()
ap['v_weapon.Left_Index01'].rotation_quaternion = Euler((math.radians(-10), 0, 0), 'XYZ').to_quaternion()
rp['handle'].rotation_quaternion = Euler((math.radians(-8), math.radians(0), math.radians(6)), 'XYZ').to_quaternion()
# Rebound flex
rp['rod_lower'].rotation_quaternion = Euler((math.radians(10), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(18), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(22), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(25), 0, 0), 'XYZ').to_quaternion()
bpy.context.view_layer.update()
key_arms(44)
key_rod(44)

# Frame 54: Damping oscillations
scene.frame_set(54)
apply_idle_pose()
rp['handle'].rotation_quaternion = Euler((math.radians(-20), math.radians(3), math.radians(7)), 'XYZ').to_quaternion()
rp['rod_lower'].rotation_quaternion = Euler((math.radians(-3), 0, 0), 'XYZ').to_quaternion()
rp['rod_mid'].rotation_quaternion = Euler((math.radians(-5), 0, 0), 'XYZ').to_quaternion()
rp['rod_upper'].rotation_quaternion = Euler((math.radians(-6), 0, 0), 'XYZ').to_quaternion()
rp['rod_tip'].rotation_quaternion = Euler((math.radians(-8), 0, 0), 'XYZ').to_quaternion()
bpy.context.view_layer.update()
key_arms(54)
key_rod(54)

# Frame 70: Return to Idle
scene.frame_set(70)
apply_idle_pose()
bpy.context.view_layer.update()
key_arms(70)
key_rod(70)

print("CAST ACTION CREATED (70 frames)")

# -------------------------------------------------------------------------
# 6. BUILD ACTION: REEL (ReelInn cycle)
# -------------------------------------------------------------------------
# 15-frame loop (0.5s at 30 fps)
# The reel handle rotates 360 degrees around its X axis
# Left hand moves in a circle cranking the handle

reel_action_arms = bpy.data.actions.new('TF_Reel_Arms')
reel_action_rod = bpy.data.actions.new('TF_Reel_Rod')
arms.animation_data.action = reel_action_arms
rod.animation_data.action = reel_action_rod

for f in range(1, 16):
    frac = (f - 1) / 15.0
    angle = frac * 2.0 * math.pi
    scene.frame_set(f)
    apply_idle_pose()

    # Left hand cranking: small circular orbit
    # circle radius ~ 1.5 cm in Left_Arm rotation
    crank_y = math.sin(angle) * math.radians(6)
    crank_z = math.cos(angle) * math.radians(6)
    ap['v_weapon.Left_Arm'].rotation_quaternion = Euler((math.radians(-12) + crank_y, math.radians(22), math.radians(28) + crank_z), 'XYZ').to_quaternion()
    ap['v_weapon.Left_Hand'].rotation_quaternion = Euler((math.radians(18) - crank_y, math.radians(-25), math.radians(-8) - crank_z), 'XYZ').to_quaternion()

    # Reel bone spins 360 deg
    rp['reel'].rotation_quaternion = Euler((angle, 0, 0), 'XYZ').to_quaternion()

    # Slight rod tip flex pulsing with the reel
    pulse = math.sin(angle * 2.0) * math.radians(3)
    rp['rod_tip'].rotation_quaternion = Euler((pulse, 0, 0), 'XYZ').to_quaternion()

    bpy.context.view_layer.update()
    key_arms(f)
    key_rod(f)

print("REEL ACTION CREATED (15 frames loop)")

# -------------------------------------------------------------------------
# 7. SAVE TO BLEND FILE & RENDER PREVIEWS
# -------------------------------------------------------------------------
# Set back to Cast action for export default
arms.animation_data.action = cast_action_arms
rod.animation_data.action = cast_action_rod
scene.frame_set(1)
bpy.context.view_layer.update()

out_blend = os.path.join(os.path.dirname(bpy.data.filepath), "FishingRod_Cast_Realistic.blend")
bpy.ops.wm.save_as_mainfile(filepath=out_blend, check_existing=False)
print("Saved blend file to:", out_blend)

# Render verification views
cam = bpy.data.objects.get('SourceVMCam')
if not cam:
    cam_data = bpy.data.cameras.new('SourceVMCam')
    cam = bpy.data.objects.new('SourceVMCam', cam_data)
    scene.collection.objects.link(cam)

scene.camera = cam
cam.data.angle_x = math.radians(62)
cam.data.sensor_fit = 'HORIZONTAL'
eye = arms.matrix_world.translation
R_cam = Matrix([
    [-1,  0,  0, 0],
    [ 0,  0,  1, 0],
    [ 0, -1,  0, 0],
    [ 0,  0,  0, 1]
])
cam.matrix_world = arms.matrix_world @ R_cam
cam.location = eye

scene.render.engine = 'BLENDER_WORKBENCH'
scene.render.resolution_x = 1024
scene.render.resolution_y = 768
scene.render.image_settings.file_format = 'PNG'

# 1. Idle render (frame 1)
scene.frame_set(1)
scene.render.filepath = r'C:\Users\valentin\.gemini\antigravity-ide\brain\0d028aae-d5c6-4f8a-bfa5-a4b7be708a45\scratch\view_idle.png'
bpy.ops.render.render(write_still=True)

# 2. PullBackRod windup peak render (frame 28)
scene.frame_set(28)
scene.render.filepath = r'C:\Users\valentin\.gemini\antigravity-ide\brain\0d028aae-d5c6-4f8a-bfa5-a4b7be708a45\scratch\view_pullback.png'
bpy.ops.render.render(write_still=True)

# 3. ReelOutt cast forward render (frame 36)
scene.frame_set(36)
scene.render.filepath = r'C:\Users\valentin\.gemini\antigravity-ide\brain\0d028aae-d5c6-4f8a-bfa5-a4b7be708a45\scratch\view_reelout.png'
bpy.ops.render.render(write_still=True)

print("Rendered verification views!")
