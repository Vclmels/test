import os
import sys
import subprocess
import shutil

base_build = r"C:\Users\valentin\Downloads\How to Fish_b25127368_ElEnemigos\build"
out_modelsrc = r"d:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\modelsrc\fishing_rod"
studiomdl_exe = r"d:\steam\steamapps\common\GarrysMod\bin\studiomdl.exe"
gamedir = r"d:\steam\steamapps\common\GarrysMod\garrysmod"
addon_models = r"d:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\models\fishing"
os.makedirs(addon_models, exist_ok=True)

# Helper to create a simple box collision SMD
def make_box_smd(filepath, min_x, max_x, min_y, max_y, min_z, max_z):
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

# OBJ loader and SMD writer
def obj_to_smd(obj_path, out_smd_path, scale=1.0, center_x=True, eyelet_top=False):
    positions = []
    texcoords = []
    normals = []
    faces = []

    with open(obj_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            tag = parts[0]
            if tag == "v":
                positions.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif tag == "vt":
                texcoords.append([float(parts[1]), float(parts[2])])
            elif tag == "vn":
                normals.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif tag == "f":
                poly = []
                for item in parts[1:]:
                    vals = item.split("/")
                    v_idx = int(vals[0]) - 1
                    vt_idx = int(vals[1]) - 1 if len(vals) > 1 and vals[1] else 0
                    vn_idx = int(vals[2]) - 1 if len(vals) > 2 and vals[2] else 0
                    poly.append((v_idx, vt_idx, vn_idx))
                for i in range(1, len(poly) - 1):
                    faces.append((poly[0], poly[i], poly[i + 1]))

    if not positions:
        raise ValueError(f"No vertices found in {obj_path}")

    max_z = max(v[2] for v in positions)
    avg_x = (min(v[0] for v in positions) + max(v[0] for v in positions)) * 0.5 if center_x else 0.0
    avg_y = (min(v[1] for v in positions) + max(v[1] for v in positions)) * 0.5
    avg_z = (min(v[2] for v in positions) + max(v[2] for v in positions)) * 0.5

    transformed = []
    for x, y, z in positions:
        if eyelet_top:
            # Eyelet at top (0, 0, 0), body hangs down along -Z
            sx = x * scale
            sy = y * scale
            sz = (z - max_z) * scale
        else:
            # Centered at (0, 0, 0)
            sx = (x - avg_x) * scale
            sy = (y - avg_y) * scale
            sz = (z - avg_z) * scale
        transformed.append((sx, sy, sz))

    with open(out_smd_path, "w", encoding="utf-8") as f:
        f.write("version 1\n")
        f.write("nodes\n")
        f.write('0 "root" -1\n')
        f.write("end\n")
        f.write("skeleton\n")
        f.write("time 0\n")
        f.write("0 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000\n")
        f.write("end\n")
        f.write("triangles\n")
        for tri in faces:
            f.write("Default\n")
            for v_idx, vt_idx, vn_idx in tri:
                px, py, pz = transformed[v_idx]
                u, v = texcoords[vt_idx] if vt_idx < len(texcoords) else (0.0, 0.0)
                nx, ny, nz = normals[vn_idx] if vn_idx < len(normals) else (0.0, 0.0, 1.0)
                f.write(f"0 {px:.6f} {py:.6f} {pz:.6f} {nx:.6f} {ny:.6f} {nz:.6f} {u:.6f} {v:.6f} 1 0 1.0\n")
        f.write("end\n")

    xs = [p[0] for p in transformed]
    ys = [p[1] for p in transformed]
    zs = [p[2] for p in transformed]
    bounds = (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))
    return bounds

# 1. Compile 5 Boss Hooks
hook_configs = [
    {"name": "hook_homemade", "file": "Homemade Lure.obj", "scale": 28.0},
    {"name": "hook_amateur", "file": "Amateur Lure.obj", "scale": 28.0},
    {"name": "hook_quality", "file": "Quality Lure.obj", "scale": 28.0},
    {"name": "hook_professional", "file": "Professional Lure.obj", "scale": 28.0},
    {"name": "hook_scientific", "file": "Scientific Lure.obj", "scale": 28.0},
]

lure_src_dir = os.path.join(base_build, "FishingRod")
out_lure_smd_dir = os.path.join(out_modelsrc, "lure")
os.makedirs(out_lure_smd_dir, exist_ok=True)

print("--- COMPILING HOOKS ---")
for h in hook_configs:
    mdl_name = h["name"]
    obj_file = os.path.join(lure_src_dir, h["file"])
    ref_smd = os.path.join(out_lure_smd_dir, f"{mdl_name}_reference.smd")
    phy_smd = os.path.join(out_lure_smd_dir, f"{mdl_name}_physics.smd")
    qc_file = os.path.join(out_lure_smd_dir, f"{mdl_name}.qc")

    bounds = obj_to_smd(obj_file, ref_smd, scale=h["scale"], eyelet_top=True)
    min_x, max_x, min_y, max_y, min_z, max_z = bounds
    make_box_smd(phy_smd, min_x, max_x, min_y, max_y, min_z, max_z)

    qc_content = f"""$modelname "fishing/{mdl_name}.mdl"
$cdmaterials "models/fishing/"
$body "body" "{mdl_name}_reference.smd"
$sequence "idle" "{mdl_name}_reference.smd" fps 30
$collisionmodel "{mdl_name}_physics.smd"
{{
	$mass 0.5
	$inertia 1
	$damping 0
	$rotdamping 0
}}
$surfaceprop "metal"
$attachment "line_attach" "root" 0 0 0
"""
    with open(qc_file, "w", encoding="utf-8") as f:
        f.write(qc_content)

    cmd = [studiomdl_exe, "-game", gamedir, qc_file]
    p = subprocess.run(cmd, capture_output=True, text=True, cwd=out_lure_smd_dir)
    if p.returncode != 0:
        print(f"FAILED {mdl_name}: {p.stderr}")
    else:
        print(f"SUCCESS: fishing/{mdl_name}.mdl (bounds Z: {min_z:.2f} to {max_z:.2f})")

# 2. Compile 5 Bosses
boss_configs = [
    {"name": "boss_gaddan", "sub": "Gammelg\u00e4ddan", "file": "Gammelg\u00e4ddan.obj", "scale": 35.0, "mass": 60.0},
    {"name": "boss_piranha", "sub": "GiantPiranha", "file": "GiantPiranha.obj", "scale": 35.0, "mass": 75.0},
    {"name": "boss_goblinshark", "sub": "GoblinShark", "file": "GoblinShark.obj", "scale": 25.0, "mass": 120.0},
    {"name": "boss_whale", "sub": "BowheadWhale", "file": "BowheadWhale.obj", "scale": 10.0, "mass": 300.0},
    {"name": "boss_mutatedwhale", "sub": "MutatedBowheadWhale", "file": "MutatedBowheadWhale.obj", "scale": 12.0, "mass": 400.0},
]

out_boss_smd_dir = os.path.join(out_modelsrc, "boss")
os.makedirs(out_boss_smd_dir, exist_ok=True)

print("--- COMPILING BOSSES ---")
for b in boss_configs:
    mdl_name = b["name"]
    obj_file = os.path.join(base_build, b["sub"], b["file"])
    if not os.path.exists(obj_file):
        # fallback search
        for root, dirs, files in os.walk(base_build):
            for f in files:
                if b["file"].lower() in f.lower() or b["sub"].lower() in f.lower():
                    obj_file = os.path.join(root, f)
                    break
    ref_smd = os.path.join(out_boss_smd_dir, f"{mdl_name}_reference.smd")
    phy_smd = os.path.join(out_boss_smd_dir, f"{mdl_name}_physics.smd")
    qc_file = os.path.join(out_boss_smd_dir, f"{mdl_name}.qc")

    bounds = obj_to_smd(obj_file, ref_smd, scale=b["scale"], eyelet_top=False)
    min_x, max_x, min_y, max_y, min_z, max_z = bounds
    make_box_smd(phy_smd, min_x, max_x, min_y, max_y, min_z, max_z)

    qc_content = f"""$modelname "fishing/{mdl_name}.mdl"
$cdmaterials "models/fishing/"
$body "body" "{mdl_name}_reference.smd"
$sequence "idle" "{mdl_name}_reference.smd" fps 30
$collisionmodel "{mdl_name}_physics.smd"
{{
	$mass {b["mass"]}
	$inertia 1
	$damping 0
	$rotdamping 0
}}
$surfaceprop "flesh"
"""
    with open(qc_file, "w", encoding="utf-8") as f:
        f.write(qc_content)

    cmd = [studiomdl_exe, "-game", gamedir, qc_file]
    p = subprocess.run(cmd, capture_output=True, text=True, cwd=out_boss_smd_dir)
    if p.returncode != 0:
        print(f"FAILED {mdl_name}: {p.stderr}")
    else:
        print(f"SUCCESS: fishing/{mdl_name}.mdl (length X: {min_x:.1f} to {max_x:.1f})")

print("All compilation jobs finished.")
