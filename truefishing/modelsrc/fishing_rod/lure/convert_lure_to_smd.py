import os
import sys

base_dir = r"d:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\modelsrc\fishing_rod\lure"
obj_path = os.path.join(base_dir, "standard_lure.obj")
smd_path = os.path.join(base_dir, "lure_reference.smd")
phys_smd_path = os.path.join(base_dir, "lure_physics.smd")
qc_path = os.path.join(base_dir, "lure.qc")

# 1. Parse OBJ
positions = []
texcoords = []
normals = []
faces = []

with open(obj_path, "r", encoding="utf-8") as f:
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
            # parse vertices in face
            poly = []
            for item in parts[1:]:
                vals = item.split("/")
                v_idx = int(vals[0]) - 1
                vt_idx = int(vals[1]) - 1 if len(vals) > 1 and vals[1] else 0
                vn_idx = int(vals[2]) - 1 if len(vals) > 2 and vals[2] else 0
                poly.append((v_idx, vt_idx, vn_idx))
            # Triangulate polygon fan
            for i in range(1, len(poly) - 1):
                faces.append((poly[0], poly[i], poly[i + 1]))

print(f"Loaded {len(positions)} verts, {len(texcoords)} UVs, {len(normals)} normals, {len(faces)} tris")

# In the OBJ:
# X is [-0.02, 0.02]
# Y is [-0.02, 0.025]
# Z is [-0.145, 0.0986] (vertical axis, top eyelet at max Z)
#
# In Source Engine:
# 1 unit = 1 inch
# Let's scale by ~30 so the lure is ~7.3 inches long (~18 cm).
# We want the eyelet at (0, 0, 0) and the lure hanging down along -Z.
max_z = max(v[2] for v in positions)
scale = 28.0  # realistic lure size in Source units (inches)

transformed_pos = []
for x, y, z in positions:
    # Eyelet at (0, 0, 0)
    sx = x * scale
    sy = y * scale
    sz = (z - max_z) * scale
    transformed_pos.append((sx, sy, sz))

# 2. Write SMD
def write_smd(filepath, triangles, is_collision=False):
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("version 1\n")
        f.write("nodes\n")
        f.write('0 "root" -1\n')
        f.write("end\n")
        f.write("skeleton\n")
        f.write("time 0\n")
        f.write("0 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000\n")
        f.write("end\n")
        f.write("triangles\n")
        
        mat = "Default" if not is_collision else "phy"
        for tri in triangles:
            f.write(f"{mat}\n")
            for v_idx, vt_idx, vn_idx in tri:
                px, py, pz = transformed_pos[v_idx]
                u, v = texcoords[vt_idx] if vt_idx < len(texcoords) else (0.0, 0.0)
                nx, ny, nz = normals[vn_idx] if vn_idx < len(normals) else (0.0, 0.0, 1.0)
                f.write(f"0 {px:.6f} {py:.6f} {pz:.6f} {nx:.6f} {ny:.6f} {nz:.6f} {u:.6f} {v:.6f} 1 0 1.0\n")
        f.write("end\n")

write_smd(smd_path, faces, is_collision=False)
write_smd(phys_smd_path, faces, is_collision=True)
print("Wrote SMDs")

# 3. Write QC
qc_content = f"""$modelname "fishing/hook.mdl"
$cdmaterials "models/fishing/"
$body "body" "lure_reference.smd"
$sequence "idle" "lure_reference.smd" fps 30
$collisionmodel "lure_physics.smd"
{{
	$mass 0.5
	$inertia 1
	$damping 0
	$rotdamping 0
}}
$surfaceprop "metal"
$attachment "line_attach" "root" 0 0 0
"""

with open(qc_path, "w", encoding="utf-8") as f:
    f.write(qc_content)

print("Wrote QC")
