import os
import sys
import subprocess
import shutil

base_build = r"C:\Users\valentin\Downloads\How to Fish_b25127368_ElEnemigos\build"
out_modelsrc = r"d:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\modelsrc\fishing_rod\fish"
os.makedirs(out_modelsrc, exist_ok=True)
studiomdl_exe = r"d:\steam\steamapps\common\GarrysMod\bin\studiomdl.exe"
gamedir = r"d:\steam\steamapps\common\GarrysMod\garrysmod"
addon_models = r"d:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\models\fishing"
os.makedirs(addon_models, exist_ok=True)

fish_list = [
    {"tag": "Angelfish", "relpath": r"Angelfish\Angelfish.obj", "mdl": "fish_angelfish", "scale": 50.0, "mass": 1.5},
    {"tag": "Anglerfish", "relpath": r"Anglerfish\Anglerfish.obj", "mdl": "fish_anglerfish", "scale": 24.0, "mass": 6.0},
    {"tag": "BingBong", "relpath": r"BingBong\BingBong.obj", "mdl": "fish_bingbong", "scale": 22.0, "mass": 5.0},
    {"tag": "Blobfish", "relpath": r"Blobfish\Blobfish.obj", "mdl": "fish_blobfish", "scale": 20.0, "mass": 4.0},
    {"tag": "Bluegill", "relpath": r"Bluegill\Bluegill.obj", "mdl": "fish_bluegill", "scale": 40.0, "mass": 1.8},
    {"tag": "BlueShark", "relpath": r"BlueShark\BlueShark.obj", "mdl": "fish_blueshark", "scale": 16.0, "mass": 35.0},
    {"tag": "Bowlfish", "relpath": r"Bowlfish\Bowlfish.obj", "mdl": "fish_bowlfish", "scale": 65.0, "mass": 1.2},
    {"tag": "Cod", "relpath": r"Cod\Cod.obj", "mdl": "fish_cod", "scale": 24.0, "mass": 4.5},
    {"tag": "BrownCrab", "relpath": r"Crab\BrownCrab.obj", "mdl": "fish_browncrab", "scale": 45.0, "mass": 2.0},
    {"tag": "RockCrab", "relpath": r"Crab\RockCrab.obj", "mdl": "fish_rockcrab", "scale": 45.0, "mass": 2.5},
    {"tag": "SpiderCrab", "relpath": r"Crab\SpiderCrab_v4.obj", "mdl": "fish_spidercrab", "scale": 12.0, "mass": 12.0},
    {"tag": "DripFish", "relpath": r"DripFish\DripFish.obj", "mdl": "fish_dripfish", "scale": 22.0, "mass": 3.0},
    {"tag": "Eel", "relpath": r"Eel\Eel.obj", "mdl": "fish_eel", "scale": 22.0, "mass": 3.5},
    {"tag": "FlyingFish", "relpath": r"FlyingFish\FlyingFish.obj", "mdl": "fish_flyingfish", "scale": 24.0, "mass": 2.0},
    {"tag": "FootSnail", "relpath": r"FootSnail\FootSnail.obj", "mdl": "fish_footsnail", "scale": 100.0, "mass": 1.0},
    {"tag": "Fry", "relpath": r"Fry\Fry.obj", "mdl": "fish_fry", "scale": 120.0, "mass": 0.5},
    {"tag": "Gar", "relpath": r"Gar\Gar.obj", "mdl": "fish_gar", "scale": 24.0, "mass": 8.0},
    {"tag": "Goby", "relpath": r"Goby\Goby.obj", "mdl": "fish_goby", "scale": 80.0, "mass": 0.8},
    {"tag": "Halibut", "relpath": r"Halibut\Halibut.obj", "mdl": "fish_halibut", "scale": 16.0, "mass": 14.0},
    {"tag": "Seahorse", "relpath": r"Horse\Horse.obj", "mdl": "fish_seahorse", "scale": 10.0, "mass": 1.0},
    {"tag": "Leech", "relpath": r"Leech\Leech.obj", "mdl": "fish_leech", "scale": 140.0, "mass": 0.5},
    {"tag": "Lobster", "relpath": r"Lobster\Lobster.obj", "mdl": "fish_lobster", "scale": 45.0, "mass": 3.5},
    {"tag": "Mackerel", "relpath": r"Mackerel\Mackerel.obj", "mdl": "fish_mackerel", "scale": 25.0, "mass": 3.0},
    {"tag": "MackerelShiny", "relpath": r"MackerelShiny\MackerelShiny.obj", "mdl": "fish_mackerelshiny", "scale": 25.0, "mass": 3.0},
    {"tag": "Needlefish", "relpath": r"Needlefish\Needlefish.obj", "mdl": "fish_needlefish", "scale": 45.0, "mass": 1.8},
    {"tag": "Oarfish", "relpath": r"Oarfish\Oarfish.obj", "mdl": "fish_oarfish", "scale": 18.0, "mass": 20.0},
    {"tag": "Parrotfish", "relpath": r"Parrotfish\Parrotfish.obj", "mdl": "fish_parrotfish", "scale": 14.0, "mass": 4.0},
    {"tag": "Perch", "relpath": r"Perch\Perch.obj", "mdl": "fish_perch", "scale": 24.0, "mass": 2.5},
    {"tag": "Pike", "relpath": r"Pike\Pike.obj", "mdl": "fish_pike", "scale": 17.0, "mass": 5.5},
    {"tag": "Piranha", "relpath": r"Piranha\Piranha.obj", "mdl": "fish_piranha", "scale": 28.0, "mass": 1.5},
    {"tag": "RedSnapper", "relpath": r"RedSnapper\RedSnapper.obj", "mdl": "fish_redsnapper", "scale": 28.0, "mass": 4.5},
    {"tag": "SeaUrchin", "relpath": r"SeaUrchin\SeaUrchin.obj", "mdl": "fish_seaurchin", "scale": 50.0, "mass": 1.2},
    {"tag": "Sengarat", "relpath": r"Sengarat\Sengarat.obj", "mdl": "fish_sengarat", "scale": 22.0, "mass": 6.0},
    {"tag": "Shrimp", "relpath": r"Shrimp\Shrimp.obj", "mdl": "fish_shrimp", "scale": 100.0, "mass": 0.5},
    {"tag": "Stonefish", "relpath": r"Stonefish\Stonefish.obj", "mdl": "fish_stonefish", "scale": 24.0, "mass": 3.5},
    {"tag": "Sunfish", "relpath": r"Sunfish\Sunfish.obj", "mdl": "fish_sunfish", "scale": 15.0, "mass": 28.0},
    {"tag": "SuperdwarfFish", "relpath": r"SuperdwarfFish\SuperdwarfFish.obj", "mdl": "fish_superdwarffish", "scale": 180.0, "mass": 0.4},
    {"tag": "Tigerfish", "relpath": r"Tigerfish\Tigerfish.obj", "mdl": "fish_tigerfish", "scale": 22.0, "mass": 9.0},
    {"tag": "TitanTriggerFish", "relpath": r"TitanTriggerFish\TitanTriggerFish.obj", "mdl": "fish_titantriggerfish", "scale": 26.0, "mass": 6.0},
    {"tag": "VoxelFish", "relpath": r"VoxelFish\VoxelFish.obj", "mdl": "fish_voxelfish", "scale": 24.0, "mass": 3.0},
    {"tag": "YellowBoxfish", "relpath": r"YellowBoxfish\YellowBoxfish.obj", "mdl": "fish_yellowboxfish", "scale": 35.0, "mass": 2.0},
    {"tag": "Clam", "relpath": r"Clam\Clam.obj", "mdl": "fish_clam", "scale": 90.0, "mass": 3.0},
]

def make_box_smd(filepath, min_x, max_x, min_y, max_y, min_z, max_z):
    min_y = min(min_y, -4.5)
    max_y = max(max_y, 4.5)
    min_z = min(min_z, -4.5)
    max_z = max(max_z, 4.5)
    v = [
        [min_x, min_y, min_z], [max_x, min_y, min_z],
        [max_x, max_y, min_z], [min_x, max_y, min_z],
        [min_x, min_y, max_z], [max_x, min_y, max_z],
        [max_x, max_y, max_z], [min_x, max_y, max_z]
    ]
    quads = [
        (0, 1, 2, 3), # -Z (bottom)
        (4, 7, 6, 5), # +Z (top)
        (0, 4, 5, 1), # -Y
        (2, 6, 7, 3), # +Y
        (0, 3, 7, 4), # -X
        (1, 5, 6, 2), # +X
    ]
    with open(filepath, "w", encoding="utf-8") as f:
        f.write('version 1\nnodes\n0 "root" -1\nend\nskeleton\ntime 0\n0 0 0 0 0 0 0\nend\ntriangles\n')
        for q in quads:
            tris = [(q[0], q[1], q[2]), (q[0], q[2], q[3])]
            for t in tris:
                f.write("phy\n")
                for idx in t:
                    px, py, pz = v[idx]
                    f.write(f"0 {px:.4f} {py:.4f} {pz:.4f} 0 0 1 0 0 1 0 1.0\n")
        f.write("end\n")

mouth_offsets = {}
compiled_count = 0

for cfg in fish_list:
    name = cfg["tag"]
    scale = cfg["scale"] * 1.5
    mass = cfg["mass"]
    mdl_name = cfg["mdl"]
    relp = cfg["relpath"]
    
    obj_path = os.path.join(base_build, relp)
    if not os.path.exists(obj_path):
        print(f"Skipping {name}: {obj_path} does not exist")
        continue

    positions, texcoords, normals, faces = [], [], [], []
    with open(obj_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if parts[0] == "v":
                positions.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif parts[0] == "vt":
                texcoords.append([float(parts[1]), float(parts[2])])
            elif parts[0] == "vn":
                normals.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif parts[0] == "f":
                poly = []
                for item in parts[1:]:
                    vals = item.split("/")
                    v_idx = int(vals[0]) - 1
                    vt_idx = int(vals[1]) - 1 if len(vals) > 1 and vals[1] else 0
                    vn_idx = int(vals[2]) - 1 if len(vals) > 2 and vals[2] else 0
                    poly.append((v_idx, vt_idx, vn_idx))
                for i in range(1, len(poly) - 1):
                    faces.append((poly[0], poly[i], poly[i + 1]))

    xs = [p[0] for p in positions]
    ys = [p[1] for p in positions]
    zs = [p[2] for p in positions]
    cx = (min(xs) + max(xs)) / 2.0
    cy = (min(ys) + max(ys)) / 2.0
    cz = (min(zs) + max(zs)) / 2.0

    scaled_positions = []
    for x, y, z in positions:
        sx = (x - cx) * scale
        sy = (y - cy) * scale
        sz = (z - cz) * scale
        scaled_positions.append([sx, sy, sz])

    mouth_x = (max(xs) - cx) * scale
    mouth_offsets[mdl_name] = round(mouth_x, 2)

    ref_smd = os.path.join(out_modelsrc, f"{mdl_name}_reference.smd")
    phy_smd = os.path.join(out_modelsrc, f"{mdl_name}_physics.smd")
    qc_file = os.path.join(out_modelsrc, f"{mdl_name}.qc")

    with open(ref_smd, "w", encoding="utf-8") as f:
        f.write('version 1\nnodes\n0 "root" -1\nend\nskeleton\ntime 0\n0 0 0 0 0 0 0\nend\ntriangles\n')
        for tri in faces:
            f.write("Default\n")
            for v_idx, vt_idx, vn_idx in tri:
                px, py, pz = scaled_positions[v_idx]
                u, v = texcoords[vt_idx] if vt_idx < len(texcoords) else (0.0, 0.0)
                nx, ny, nz = normals[vn_idx] if vn_idx < len(normals) else (0.0, 0.0, 1.0)
                f.write(f"0 {px:.6f} {py:.6f} {pz:.6f} {nx:.6f} {ny:.6f} {nz:.6f} {u:.6f} {v:.6f} 1 0 1.0\n")
        f.write("end\n")

    sxs = [p[0] for p in scaled_positions]
    sys_list = [p[1] for p in scaled_positions]
    szs = [p[2] for p in scaled_positions]
    make_box_smd(phy_smd, min(sxs)*0.9, max(sxs)*0.9, min(sys_list)*0.9, max(sys_list)*0.9, min(szs)*0.9, max(szs)*0.9)

    qc_text = f"""$modelname "fishing/{mdl_name}.mdl"
$cdmaterials "models/fishing/"
$body "body" "{mdl_name}_reference.smd"
$sequence "idle" "{mdl_name}_reference.smd" fps 30
$collisionmodel "{mdl_name}_physics.smd"
{{
    $mass {mass}
    $inertia 1
    $damping 0.1
    $rotdamping 0.1
}}
$surfaceprop "flesh"
$attachment "mouth" "root" {mouth_x:.2f} 0.00 0.00
"""
    with open(qc_file, "w", encoding="utf-8") as f:
        f.write(qc_text)

    cmd = [studiomdl_exe, "-nop4", "-game", gamedir, qc_file]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"ERROR compiling {mdl_name}:\n{res.stdout}\n{res.stderr}")
    else:
        compiled_count += 1
        src_mdl_dir = os.path.join(gamedir, "models", "fishing")
        for ext in [".mdl", ".vvd", ".dx80.vtx", ".dx90.vtx", ".phy"]:
            f_src = os.path.join(src_mdl_dir, f"{mdl_name}{ext}")
            if os.path.exists(f_src):
                shutil.copy2(f_src, os.path.join(addon_models, f"{mdl_name}{ext}"))

print(f"SUCCESS: Compiled {compiled_count} fish models!")
print("Mouth offsets calculated:")
print(mouth_offsets)
