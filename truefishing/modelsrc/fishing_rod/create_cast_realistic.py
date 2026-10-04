"""Animate a first-person two-handed backswing and fishing cast.

Blender -b FishingRod_Arms_Rig.blend --python create_cast_realistic.py
Starts from the unanimated rig. Does not modify the old cast or its file.
"""

import os

import bpy
from mathutils import Matrix, Quaternion, Vector


scene = bpy.context.scene
arms = bpy.data.objects["hands_reference_skeleton"]
rod = bpy.data.objects["FishingRodRig"]
ap = arms.pose.bones
rp = rod.pose.bones
scene.render.fps = 30
scene.frame_start = 1
scene.frame_end = 78

shoulders = ("v_weapon.Root36", "v_weapon.Root34")
upper_arms = ("v_weapon.Right_Arm", "v_weapon.Left_Arm")
wrists = ("v_weapon.Right_Hand", "v_weapon.Left_Hand")
left_fingers = (
    "v_weapon.Left_Index01", "v_weapon.Left_Index02",
    "v_weapon.Left_Middle01", "v_weapon.Left_Middle02",
    "v_weapon.Left_Thumb01", "v_weapon.Left_Thumb_02",
)
right_fingers = (
    "v_weapon.Right_Index01", "v_weapon.Right_Middle01",
    "v_weapon.Right_Ring01", "v_weapon.Right_Pinky01",
)
animated_arms = shoulders + upper_arms + wrists + left_fingers + right_fingers
for name in animated_arms:
    ap[name].rotation_mode = "QUATERNION"

base = {
    name: (ap[name].location.copy(), ap[name].rotation_quaternion.copy())
    for name in animated_arms
}

for obj in (arms, rod):
    obj.animation_data_create()
    obj.animation_data.action = None

X = Vector((1, 0, 0))
Y = Vector((0, 1, 0))
Z = Vector((0, 0, 1))


def put_shoulder_at(bone, world_pos):
    """Translate the shoulder within the Source viewmodel without bending the arm."""
    p = ap[bone]
    current = arms.matrix_world @ p.head
    offset = arms.matrix_world.inverted().to_3x3() @ (world_pos - current)
    p.matrix = Matrix.Translation(offset) @ p.matrix
    bpy.context.view_layer.update()


def aim_arm(bone, wrist_bone, target):
    """Swing upper arm from shoulder so its elbow/hand reaches target."""
    p = ap[bone]
    shoulder = p.head.copy()
    hand = ap[wrist_bone].head.copy()
    goal = arms.matrix_world.inverted() @ target
    old = hand - shoulder
    new = goal - shoulder
    if old.length > 1e-5 and new.length > 1e-5:
        turn = old.rotation_difference(new)
        p.matrix = (Matrix.Translation(shoulder) @ turn.to_matrix().to_4x4()
                    @ Matrix.Translation(-shoulder) @ p.matrix)
    bpy.context.view_layer.update()


def wrist_turn(name, x=0.0, y=0.0, z=0.0):
    """Rotate about wrist joint, keeping the hand attached to the arm."""
    p = ap[name]
    h = p.head.copy()
    q = Quaternion(Z, z) @ Quaternion(Y, y) @ Quaternion(X, x)
    p.matrix = (Matrix.Translation(h) @ q.to_matrix().to_4x4()
                @ Matrix.Translation(-h) @ p.matrix)
    bpy.context.view_layer.update()


def save_bones(names, frame):
    for name in names:
        p = ap[name]
        p.keyframe_insert(data_path="location", frame=frame, group=name)
        p.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=name)


# The right palm remains on the grip. Left fingers control the line while
# winding up, release near frame 42, then fall back to the reel.
# frame, right palm XYZ, right shoulder offset XYZ, left shoulder offset XYZ,
# right-wrist pitch/roll/yaw, left-wrist pitch, finger release, rod bend amount.
poses = (
    (1,  (0, .290, -.005), (.015, .217, .035), (.08, .18, .072), (0, 0, 0), 0, 0, 0),
    (7,  (-.025, .320, .012), (.015, .217, .035), (.08, .18, .075), (-.10, -.03, -.015), -.08, .02, -.02),
    (15, (-.105, .420, .125), (.050, .205, .085), (.08, .18, .075), (-.33, -.07, -.09), -.22, .02, -.09),
    (23, (-.18, .515, .220), (.09, .19, .10), (.08, .17, .08), (-.59, -.11, -.17), -.34, .04, -.19),
    (28, (-.19, .520, .235), (.10, .19, .10), (.08, .17, .08), (-.64, -.11, -.16), -.33, .09, -.21),
    (34, (-.10, .405, .155), (.06, .205, .085), (.08, .17, .075), (-.30, -.06, -.07), -.14, .22, -.05),
    (39, (.012, .235, .018), (.01, .217, .05), (.08, .18, .075), (.08, .025, .02), .04, .70, .09),
    (44, (.100, .065, -.083), (-.06, .19, .10), (.10, .21, .095), (.28, .07, .075), .23, 1, .14),
    (48, (.125, .020, -.112), (-.065, .185, .105), (.11, .21, .10), (.34, .065, .085), .32, 1, .09),
    (53, (.097, .08, -.085), (-.04, .20, .085), (.10, .20, .08), (.28, .04, .055), .22, .75, -.05),
    (61, (.052, .165, -.045), (-.012, .217, .055), (.085, .19, .07), (.17, .025, .03), .10, .35, .02),
    (70, (.020, .245, -.012), (.005, .217, .035), (.08, .18, .072), (.09, .0, .0), .025, .09, -.012),
    (78, (.010, .270, -.006), (.015, .217, .035), (.08, .18, .072), (.04, 0, 0), 0, .08, 0),
)

rod_parts = ("rod_lower", "rod_mid", "rod_upper", "rod_tip")
for name in ("handle",) + rod_parts:
    rp[name].rotation_mode = "QUATERNION"

for frame, right_xyz, r_offset, l_offset, r_wrist, l_pitch, release, flex in poses:
    scene.frame_set(frame)
    # Re-establish the original shoulder/arm/hand pose before solving this key.
    for name, (location, rotation) in base.items():
        ap[name].location = location.copy()
        ap[name].rotation_quaternion = rotation.copy()
    for name in ("handle",) + rod_parts:
        rp[name].rotation_quaternion = (1, 0, 0, 0)
    bpy.context.view_layer.update()

    R = Vector(right_xyz)
    put_shoulder_at(shoulders[0], R + Vector(r_offset))
    aim_arm(upper_arms[0], wrists[0], R)
    wrist_turn(wrists[0], *r_wrist)

    # Rod follows right hand; left hand aims for actual reel position in
    # this frame, not a static point in the viewport.
    rp["handle"].rotation_quaternion = Quaternion(X, .015 if frame >= 39 else -.01)
    for name, strength in zip(rod_parts, (.27, .55, .86, 1.08)):
        rp[name].rotation_quaternion = Quaternion(X, flex * strength)
    bpy.context.view_layer.update()
    reel = rod.matrix_world @ rp["reel"].head
    # Thumb and index let the line go at the snap. The support hand follows
    # with the reel at cast then drifts free slightly, returning afterward.
    offset = Vector((.043, .015, .016))
    if frame >= 39:
        offset += Vector((0, -.015 * release, .016 * release))
    L = reel + offset
    put_shoulder_at(shoulders[1], L + Vector(l_offset))
    aim_arm(upper_arms[1], wrists[1], L)
    wrist_turn(wrists[1], x=l_pitch, z=-.04 * release)

    for name in left_fingers:
        angle = (-.52 if "Index" in name else -.38 if "Thumb" in name else -.20) * release
        ap[name].rotation_quaternion = Quaternion(Z, angle) @ base[name][1]
    for name in right_fingers:
        ap[name].rotation_quaternion = Quaternion(Z, .08 if frame <= 34 else .16) @ base[name][1]

    save_bones(animated_arms, frame)
    for name in ("handle",) + rod_parts:
        rp[name].keyframe_insert(data_path="rotation_quaternion", frame=frame, group=name)

scene.frame_set(1)
for obj, name in (
    (arms, "TF_Realistic_Cast_Arms_Hands_Release"),
    (rod, "TF_Realistic_Cast_Rod_Flex"),
):
    action = obj.animation_data.action
    action.name = name
    action.use_fake_user = True
    print("ACTION", name, tuple(action.frame_range))

scene["truefishing_cast_timing"] = "1-28 windup, 34-48 forward throw and release, 53-78 follow-through"
output = os.path.join(os.path.dirname(bpy.data.filepath), "FishingRod_Cast_Realistic.blend")
bpy.ops.wm.save_as_mainfile(filepath=output, check_existing=False)
print("CAST_REALISTIC_SAVED", output, os.path.getsize(output))
