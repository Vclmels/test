import os, re, glob

d = r"D:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\modelsrc\fishing_rod\fish"

TARGET = 28.0
MIN_S = 0.55
MAX_S = 1.8

def parse_smd_bounds(path):
    xs, ys, zs = [], [], []
    with open(path, "r", encoding="utf-8") as f:
        in_tri = False
        for line in f:
            s = line.strip()
            if s == "triangles":
                in_tri = True
                continue
            if not in_tri:
                continue
            parts = s.split()
            if len(parts) >= 12 and parts[0] == "0":
                try:
                    px = float(parts[1]); py = float(parts[2]); pz = float(parts[3])
                except ValueError:
                    continue
                xs.append(px); ys.append(py); zs.append(pz)
    if not xs:
        return None
    return (max(xs)-min(xs), max(ys)-min(ys), max(zs)-min(zs))

rows = []
for qc in glob.glob(os.path.join(d, "*.qc")):
    name = os.path.basename(qc)[:-3]
    smd = os.path.join(d, name + "_reference.smd")
    if not os.path.exists(smd):
        continue
    sz = parse_smd_bounds(smd)
    if not sz:
        continue
    maxd = max(sz)
    s = round(max(MIN_S, min(MAX_S, TARGET / maxd)), 3)
    rows.append((name, sz, maxd, s))

# map model file name -> scale, sorted by name
rows.sort(key=lambda r: r[0])
print("-- generated scale table (model path -> scale)")
for name, sz, maxd, s in rows:
    print(f'\t["models/fishing/{name}.mdl"] = {s},  -- len {sz[0]:.1f} w {sz[1]:.1f} h {sz[2]:.1f}')
