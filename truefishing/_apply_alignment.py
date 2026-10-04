import os, re, glob

ADDON = r"D:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing"
SRC = os.path.join(ADDON, "modelsrc", "fishing_rod", "fish")

TARGET = 28.0
MIN_S = 0.55
MAX_S = 1.8

# ---------- 1. Regenerate scale table from reference SMDs ----------
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
                    xs.append(float(parts[1])); ys.append(float(parts[2])); zs.append(float(parts[3]))
                except ValueError:
                    pass
    if not xs:
        return None
    return (max(xs)-min(xs), max(ys)-min(ys), max(zs)-min(zs))

entries = []
for qc in glob.glob(os.path.join(SRC, "*.qc")):
    name = os.path.basename(qc)[:-3]
    smd = os.path.join(SRC, name + "_reference.smd")
    if not os.path.exists(smd):
        continue
    sz = parse_smd_bounds(smd)
    if not sz:
        continue
    maxd = max(sz)
    s = round(max(MIN_S, min(MAX_S, TARGET / maxd)), 3)
    entries.append('    ["models/fishing/%s.mdl"] = %s,' % (name, s))

entries.sort()

table_body = "\n".join(entries)

new_block = (
"""-- ==========================================================================
-- NORMALIZACION AUTOMATICA DE ESCALA POR MODELO (pez colgando del anzuelo)
-- Cada pez importado traia un tamano compilado muy distinto (alevin ~3u, atun ~58u).
-- Esta tabla escala cada modelo para que su dimension dominante mida ~FISH_HANG_LENGTH
-- unidades, de modo que TODOS los peces queden parejos colgando del anzuelo.
-- La escala se aplica con SetModelScale; el offset de boca se multiplica por la escala.
-- ==========================================================================
TrueFish.FISH_HANG_LENGTH = TrueFish.FISH_HANG_LENGTH or 28

TrueFishHangScales = TrueFishHangScales or {
""" + table_body + """
}

function TrueFishGetHangScale(modelPath)
    return (modelPath and TrueFishHangScales[modelPath]) or 1.0
end
"""
)

# ---------- 2. Insert into sh_fishconfigs.lua ----------
cfg_path = os.path.join(ADDON, "lua", "autorun", "sh_fishconfigs.lua")
with open(cfg_path, "r", encoding="utf-8") as f:
    cfg = f.read()

anchor = "-- PECES RESTANTES DE 'HOW TO FISH' IMPORTADOS AL ADDON (42 PECES)"
if anchor not in cfg:
    raise SystemExit("ANCHOR NOT FOUND in sh_fishconfigs.lua")
if "TrueFishHangScales" in cfg:
    print("sh_fishconfigs.lua: already patched, skipping insert")
else:
    cfg = cfg.replace(anchor, new_block + "\n\n" + anchor, 1)
    with open(cfg_path, "w", encoding="utf-8") as f:
        f.write(cfg)
    print("sh_fishconfigs.lua: inserted scale table + helper (%d models)" % len(entries))

# ---------- 3. Patch the 3 render sites (whitespace-tolerant) ----------
def patch(path, subs):
    with open(path, "r", encoding="utf-8") as f:
        t = f.read()
    orig = t
    for pat, rep in subs:
        t, n = re.subn(pat, rep, t, flags=re.M)
        if n != 1:
            raise SystemExit("%s: expected 1 match for %r, got %d" % (path, pat, n))
    if t == orig:
        print("%s: no change" % path)
    else:
        with open(path, "w", encoding="utf-8") as f:
            f.write(t)
        print("%s: patched" % path)

hook_path = os.path.join(ADDON, "lua", "entities", "fishing_rod_hook", "init.lua")
patch(hook_path, [
    (
        r'^(\s*)local mX = \(TrueFishGetMouthOffset and TrueFishGetMouthOffset\(fish\)\) or \(\(fishMouthOffsets\[fish\] or 11\.0\) \* 1\.5\)\s*$',
        r'\1local fishMdl = TrueFishGetFishModel(fish)\n\1local scale = (TrueFishGetHangScale and TrueFishGetHangScale(fishMdl)) or 1.0\n\1local mX = ((TrueFishGetMouthOffset and TrueFishGetMouthOffset(fish)) or ((fishMouthOffsets[fish] or 11.0) * 1.5)) * scale'
    ),
    (
        r'^(\s*)self\.Fish:SetLocalPos\(Vector\(0, 0\.4, -4\.5 - mX\)\)\s*$',
        r'\1self.Fish:SetModelScale(scale, 0)\n\1self.Fish:SetLocalPos(Vector(0, 0.4, -4.5 - mX))'
    ),
])

phys_path = os.path.join(ADDON, "lua", "weapons", "fishing_rod_physics", "shared.lua")
patch(phys_path, [
    (
        r'^(\s*)local mX = \(TrueFishGetMouthOffset and TrueFishGetMouthOffset\(fishID\)\) or 16\.5\s*$',
        r'\1local scale = (TrueFishGetHangScale and TrueFishGetHangScale(fishMdl)) or 1.0\n\1local mX = ((TrueFishGetMouthOffset and TrueFishGetMouthOffset(fishID)) or 16.5) * scale'
    ),
    (
        r'^(\s*)wep\.ClientFishModel:SetPos\(fishPos\)\s*$',
        r'\1wep.ClientFishModel:SetModelScale(scale, 0)\n\1wep.ClientFishModel:SetPos(fishPos)'
    ),
])

pole_path = os.path.join(ADDON, "lua", "entities", "fishing_rod_pole", "cl_init.lua")
patch(pole_path, [
    (
        r'^(\s*)local mX = \(TrueFishGetMouthOffset and TrueFishGetMouthOffset\(fishCaught\)\) or 11\.0\s*$',
        r'\1local scale = (TrueFishGetHangScale and TrueFishGetHangScale(fishMdl)) or 1.0\n\1local mX = ((TrueFishGetMouthOffset and TrueFishGetMouthOffset(fishCaught)) or 11.0) * scale'
    ),
    (
        r'^(\s*)self\.WorldFishModel:SetPos\(fishPos\)\s*$',
        r'\1self.WorldFishModel:SetModelScale(scale, 0)\n\1self.WorldFishModel:SetPos(fishPos)'
    ),
])

print("DONE")
