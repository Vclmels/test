"""Build the fishing-rod backswing/cast in the supplied rigged Blender scene.

Run with blender -b FishingRod_Arms_Rig.blend --python create_cast_animation.py.
"""

import math
import os

import bpy
from mathutils import Quaternion, Vector


scene = bpy.context.scene
arms = bpy.data.objects["hands_reference_skeleton"]
rig = bpy.data.objects["FishingRodRig"]

scene.render.fps = 24
scene.frame_start = 1
scene.frame_end = 60

arm_names = (
    "v_weapon.Hands_parent",
    "v_weapon.Root36",
    "v_weapon.Right_Arm",
    "v_weapon.Right_Hand",
    "v_weapon.Root34",
    "v_weapon.Left_Arm",
    "v_weapon.Left_Hand",
)
rod_names = ("handle", "rod_lower", "rod_mid", "rod_upper", "rod_tip")
arm_bones = arms.pose.bones
rod_bones = rig.pose.bones

rest = {
    name: (
        arm_bones[name].location.copy(),
        arm_bones[name].rotation_quaternion.copy()
        if arm_bones[name].rotation_mode == "QUATERNION"
        else arm_bones[name].rotation_euler.to_quaternion(),
    )
    for name in arm_names
}

for name in arm_names:
    arm_bones[name].rotation_mode = "QUATERNION"
for name in rod_names:
    rod_bones[name].rotation_mode = "QUATERNION"

for obj in (arms, rig):
    obj.animation_data_create()
    obj.animation_data.action = None

# Frame, back/forth pitch, right shoulder, right wrist, supporting shoulder,
# supporting wrist, grip torque, and four increasingly flexible rod sections.
# Negative pitch winds the arms back; positive pitch drives the cast.
poses = (
    (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (5, -.055, -.04, -.02, -.02, 0, -.02, .015, .02, .02, .015),
    (11, -.23, -.17, -.075, -.11, -.03, -.07, .07, .09, .12, .10),
    (15, -.33, -.24, -.12, -.15, -.04, -.10, .10, .14, .18, .16),
    (18, -.27, -.18, -.06, -.10, -.03, -.08, .06, .08, .10, .08),
    (23, .12, .16, .11, .025, .025, .06, -.08, -.13, -.16, -.13),
    (27, .43, .34, .19, .20, .10, .13, -.12, -.22, -.31, -.29),
    (30, .51, .35, .14, .26, .14, .10, -.06, -.18, -.27, -.27),
    (34, .42, .29, .13, .23, .12, .075, .075, .13, .19, .19),
    (40, .30, .20, .10, .17, .10, .04, .025, .06, .075, .07),
    (48, .15, .10, .045, .08, .045, .012, -.01, -.025, -.025, -.02),
    (60, .06, .03, .01, .03, .015, 0, 0, 0, 0, 0),
)

x_axis = Vector((1, 0, 0))
z_axis = Vector((0, 0, 1))

for frame, pitch, right_arm, right_wrist, left_arm, left_wrist, handle, lower, middle, upper, tip in poses:
    scene.frame_set(frame)
    for name, (location, rotation) in rest.items():
        arm_bones[name].location = location.copy()
        arm_bones[name].rotation_quaternion = rotation.copy()

    arm_bones["v_weapon.Hands_parent"].rotation_quaternion = Quaternion(x_axis, pitch) @ rest["v_weapon.Hands_parent"][1]
    arm_bones["v_weapon.Right_Arm"].rotation_quaternion = Quaternion(z_axis, right_arm) @ rest["v_weapon.Right_Arm"][1]
    arm_bones["v_weapon.Right_Hand"].rotation_quaternion = Quaternion(x_axis, right_wrist) @ rest["v_weapon.Right_Hand"][1]
    arm_bones["v_weapon.Left_Arm"].rotation_quaternion = Quaternion(z_axis, left_arm) @ rest["v_weapon.Left_Arm"][1]
    arm_bones["v_weapon.Left_Hand"].rotation_quaternion = Quaternion(x_axis, left_wrist) @ rest["v_weapon.Left_Hand"][1]

    for name in arm_names:
        arm_bones[name].keyframe_insert(data_path="location", frame=frame, group=name)
        arm_bones[name].keyframe_insert(data_path="rotation_quaternion", frame=frame, group=name)
    for name, angle in zip(rod_names, (handle, lower, middle, upper, tip)):
        rod_bones[name].rotation_quaternion = Quaternion(x_axis, angle)
        rod_bones[name].keyframe_insert(data_path="rotation_quaternion", frame=frame, group=name)

scene.frame_set(1)
for obj, name in (
    (arms, "TF_Cast_BackSwing_Throw_Arms"),
    (rig, "TF_Cast_BackSwing_Throw_Rod"),
):
    action = obj.animation_data.action
    action.name = name
    action.use_fake_user = True
    assert tuple(action.frame_range) == (1, 60), (name, action.frame_range)

output = os.path.join(os.path.dirname(bpy.data.filepath), "FishingRod_Cast_Animated.blend")
bpy.ops.wm.save_as_mainfile(filepath=output, check_existing=False)
print("CAST_ANIMATION_SAVED", output, os.path.getsize(output))
