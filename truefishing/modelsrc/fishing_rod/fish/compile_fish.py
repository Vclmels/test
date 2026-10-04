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

fish_configs = [
    {"name": "Bass", "scale": 36.0, "mass": 4.5, "mdl": "fish_bass"},
    {"name": "Salmon", "scale": 36.0, "mass": 4.0, "mdl": "fish_salmon"},
    {"name": "Tuna", "scale": 21.0, "mass": 22.0, "mdl": "fish_tuna"},
    {"name": "Catfish", "scale": 36.0, "mass": 6.0, "mdl": "fish_catfish"},
    {"name": "Goldfish", "scale": 63.0, "mass": 1.2, "mdl": "fish_goldfish"},
    {"name": "Clownfish", "scale": 63.0, "mass": 1.2, "mdl": "fish_clownfish"},
    {"name": "Pufferfish", "scale": 30.0, "mass": 3.5, "mdl": "fish_pufferfish"},
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

for cfg in fish_configs:
    name = cfg["name"]
    scale = cfg["scale"]
    mass = cfg["mass"]
    mdl_name = cfg["mdl"]
    
    obj_path = os.path.join(base_build, name, f"{name}.obj")
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

    print(f"Compiling {mdl_name}...")
    cmd = [studiomdl_exe, "-nop4", "-game", gamedir, qc_file]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"ERROR compiling {mdl_name}:\nSTDOUT:\n{res.stdout}\nSTDERR:\n{res.stderr}")
    else:
        print(f"SUCCESS {mdl_name}")
        src_mdl_dir = os.path.join(gamedir, "models", "fishing")
        for ext in [".mdl", ".vvd", ".dx80.vtx", ".dx90.vtx", ".phy"]:
            f_src = os.path.join(src_mdl_dir, f"{mdl_name}{ext}")
            if os.path.exists(f_src):
                shutil.copy2(f_src, os.path.join(addon_models, f"{mdl_name}{ext}"))

print("ALL FISH COMPILED SUCCESSFULLY!")
