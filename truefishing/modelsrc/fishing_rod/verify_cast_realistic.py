"""Inspect arm trajectories and reel contact in the saved casting scene."""

import bpy


s = bpy.context.scene
a = bpy.data.objects["hands_reference_skeleton"]
r = bpy.data.objects["FishingRodRig"]
assert s.frame_start == 1 and s.frame_end == 78
assert a.animation_data.action.name == "TF_Realistic_Cast_Arms_Hands_Release"
assert r.animation_data.action.name == "TF_Realistic_Cast_Rod_Flex"

def xyz(p):
    return tuple(round(x, 3) for x in p)


right = []
left = []
tip = []
for frame in (1, 15, 28, 39, 44, 48, 53, 61, 78):
    s.frame_set(frame)
    R = a.matrix_world @ a.pose.bones["v_weapon.Right_Hand"].head
    L = a.matrix_world @ a.pose.bones["v_weapon.Left_Hand"].head
    C = r.matrix_world @ r.pose.bones["reel"].head
    T = r.matrix_world @ r.pose.bones["rod_tip"].tail
    right.append(R.copy())
    left.append(L.copy())
    tip.append(T.copy())
    print("FRAME", frame, "R", xyz(R), "L", xyz(L), "gap", round((L - C).length, 3), "TIP", xyz(T))

print("RIGHT TRAVEL", round(max((p - right[0]).length for p in right), 3))
print("LEFT TRAVEL", round(max((p - left[0]).length for p in left), 3))
assert max((p - right[0]).length for p in right) > .20
assert max((p - left[0]).length for p in left) > .15
assert max((p - tip[0]).length for p in tip) > .35
