import os
import subprocess

base_build = r"C:\Users\valentin\Downloads\How to Fish_b25127368_ElEnemigos\build"
out_dir = r"d:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\modelsrc\fishing_rod\boss"
studiomdl_exe = r"d:\steam\steamapps\common\GarrysMod\bin\studiomdl.exe"
gamedir = r"d:\steam\steamapps\common\GarrysMod\garrysmod"
addon_models = r"d:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\models\fishing"

def make_box_smd(filepath, min_x, max_x, min_y, max_y, min_z, max_z):
    v = [
        [min_x, min_y, min_z], [max_x, min_y, min_z],
        [max_x, max_y, min_z], [min_x, max_y, min_z],
        [min_x, min_y, max_z], [max_x, min_y, max_z],
        [max_x, max_y, max_z], [min_x, max_y, max_z]
    ]
    quads = [
        (0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (2, 6, 7, 3), (0, 3, 7, 4), (1, 5, 6, 2)
    ]
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('version 1\nnodes\n0 "root" -1\nend\nskeleton\ntime 0\n0 0 0 0 0 0 0\nend\ntriangles\n')
        for q in quads:
            tris = [(q[0], q[1], q[2]), (q[0], q[2], q[3])]
            for t in tris:
                f.write('phy\n')
                for idx in t:
                    px, py, pz = v[idx]
                    f.write(f'0 {px:.4f} {py:.4f} {pz:.4f} 0 0 1 0 0 1 0 1.0\n')
        f.write('end\n')

def obj_to_smd(obj_path, out_smd_path, scale=25.0):
    positions = []
    texcoords = []
    normals = []
    faces = []
    with open(obj_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            parts = line.strip().split()
            if not parts:
                continue
            if parts[0] == 'v':
                positions.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif parts[0] == 'vt':
                texcoords.append([float(parts[1]), float(parts[2])])
            elif parts[0] == 'vn':
                normals.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif parts[0] == 'f':
                poly = []
                for item in parts[1:]:
                    vals = item.split('/')
                    v_idx = int(vals[0]) - 1
                    vt_idx = int(vals[1]) - 1 if len(vals) > 1 and vals[1] else 0
                    vn_idx = int(vals[2]) - 1 if len(vals) > 2 and vals[2] else 0
                    poly.append((v_idx, vt_idx, vn_idx))
                for i in range(1, len(poly) - 1):
                    faces.append((poly[0], poly[i], poly[i + 1]))

    avg_x = (min(v[0] for v in positions) + max(v[0] for v in positions)) * 0.5
    avg_y = (min(v[1] for v in positions) + max(v[1] for v in positions)) * 0.5
    avg_z = (min(v[2] for v in positions) + max(v[2] for v in positions)) * 0.5

    transformed = []
    for x, y, z in positions:
        sx = (x - avg_x) * scale
        sy = (y - avg_y) * scale
        sz = (z - avg_z) * scale
        transformed.append((sx, sy, sz))

    with open(out_smd_path, 'w', encoding='utf-8') as f:
        f.write('version 1\nnodes\n0 "root" -1\nend\nskeleton\ntime 0\n0 0 0 0 0 0 0\nend\ntriangles\n')
        for f1, f2, f3 in faces:
            f.write('Default\n')
            for v_idx, vt_idx, vn_idx in [f1, f2, f3]:
                px, py, pz = transformed[v_idx]
                u, v_tex = texcoords[vt_idx] if vt_idx < len(texcoords) else (0.0, 0.0)
                nx, ny, nz = normals[vn_idx] if vn_idx < len(normals) else (0.0, 0.0, 1.0)
                f.write(f'0 {px:.4f} {py:.4f} {pz:.4f} {nx:.4f} {ny:.4f} {nz:.4f} {u:.4f} {v_tex:.4f} 0 1.0\n')
        f.write('end\n')

    xs = [p[0] for p in transformed]; ys = [p[1] for p in transformed]; zs = [p[2] for p in transformed]
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)

obj_file = os.path.join(base_build, 'Albatross', 'Albatross.obj')
ref_smd = os.path.join(out_dir, 'boss_albatross_reference.smd')
phy_smd = os.path.join(out_dir, 'boss_albatross_physics.smd')
qc_file = os.path.join(out_dir, 'boss_albatross.qc')

bounds = obj_to_smd(obj_file, ref_smd, scale=25.0)
make_box_smd(phy_smd, *bounds)

qc = """$modelname "fishing/boss_albatross.mdl"
$cdmaterials "models/fishing/"
$body "body" "boss_albatross_reference.smd"
$sequence "idle" "boss_albatross_reference.smd" fps 30
$collisionmodel "boss_albatross_physics.smd"
{
	$mass 45.0
	$inertia 1
	$damping 0
	$rotdamping 0
}
$surfaceprop "flesh"
"""

with open(qc_file, 'w', encoding='utf-8') as f:
    f.write(qc)

p = subprocess.run([studiomdl_exe, '-game', gamedir, qc_file], capture_output=True, text=True, cwd=out_dir)
print('Exit code:', p.returncode)
print(p.stdout[-400:] if p.stdout else '')
if p.returncode != 0:
    print('Error:', p.stderr)
else:
    # copy resulting mdl files to addon_models if needed
    built_dir = os.path.join(gamedir, "models", "fishing")
    for ext in [".mdl", ".vvd", ".dx80.vtx", ".dx90.vtx", ".phy"]:
        src_f = os.path.join(built_dir, "boss_albatross" + ext)
        dst_f = os.path.join(addon_models, "boss_albatross" + ext)
        if os.path.exists(src_f):
            import shutil
            shutil.copy2(src_f, dst_f)
            print(f"Copied {dst_f}")
