import struct, os, hashlib

base = r"D:\steam\steamapps\common\GarrysMod\garrysmod\addons\truefishing\materials\models\truefishing"
files = ["caja_albedo.vtf", "caja_normal.vtf", "caja_tapa_albedo.vtf"]

FMT = {
    0:"RGBA8888", 1:"ABGR8888", 2:"RGB888", 3:"BGR888", 4:"RGB565",
    5:"I8", 6:"IA88", 7:"P8", 8:"A8", 9:"RGB888_BLUESCREEN",
    10:"BGR888_BLUESCREEN", 11:"ARGB8888", 12:"BGRA8888", 13:"DXT1",
    14:"DXT3", 15:"DXT5", 16:"BGRX8888", 17:"BGR565", 18:"BGRX5551",
    19:"BGRA4444", 20:"DXT1_ONEBITALPHA", 21:"BGRA5551", 22:"UV88",
    23:"UVWQ8888", 24:"RGBA16161616F", 25:"RGBA16161616", 26:"UVLX8888",
}

for f in files:
    p = os.path.join(base, f)
    sz = os.path.getsize(p)
    with open(p, "rb") as fh:
        data = fh.read(64)
    sig = data[0:4]
    ver = struct.unpack_from("<II", data, 4)
    headerSize = struct.unpack_from("<I", data, 12)[0]
    w, h = struct.unpack_from("<HH", data, 16)
    flags = struct.unpack_from("<I", data, 20)[0]
    frames = struct.unpack_from("<H", data, 24)[0]
    bumpScale = struct.unpack_from("<f", data, 48)[0]
    fmt = struct.unpack_from("<I", data, 52)[0]
    mipCount = data[56]
    lowFmt = struct.unpack_from("<I", data, 57)[0]
    lowW = data[61]; lowH = data[62]

    # flags
    FL = flags
    flagbits = []
    if FL & 0x0001: flagbits.append("POINTSAMPLE")
    if FL & 0x0002: flagbits.append("TRILINEAR")
    if FL & 0x0004: flagbits.append("CLAMPS")
    if FL & 0x0008: flagbits.append("CLAMPT")
    if FL & 0x0010: flagbits.append("ANISOTROPIC")
    if FL & 0x0020: flagbits.append("HINT_DXT5")
    if FL & 0x0040: flagbits.append("PWL_CORRECTED")
    if FL & 0x0080: flagbits.append("NORMAL")
    if FL & 0x0100: flagbits.append("NOMIP")
    if FL & 0x0200: flagbits.append("NOLOD")
    if FL & 0x0400: flagbits.append("ALL_MIPS")
    if FL & 0x0800: flagbits.append("PROCEDURAL")
    if FL & 0x1000: flagbits.append("ONEBITALPHA")
    if FL & 0x2000: flagbits.append("EIGHTBITALPHA")
    if FL & 0x4000: flagbits.append("ENVMAP")
    if FL & 0x8000: flagbits.append("RENDERTARGET")
    if FL & 0x10000: flagbits.append("DEPTHRENDERTARGET")
    if FL & 0x20000: flagbits.append("NODEBUGOVERRIDE")
    if FL & 0x40000: flagbits.append("SINGLECOPY")
    if FL & 0x80000: flagbits.append("PRE_SRGB")
    if FL & 0x100000: flagbits.append("NO_DEPTH_BUFFER")
    if FL & 0x200000: flagbits.append("CLAMPU")
    if FL & 0x400000: flagbits.append("VERTEXTEXTURE")
    if FL & 0x800000: flagbits.append("SSBUMP")
    if FL & 0x1000000: flagbits.append("BORDER")
    if FL & 0x2000000: flagbits.append("NOCOMPRESS")

    print("="*60)
    print(f)
    print("  size(bytes)     :", sz)
    print("  signature       :", sig)
    print("  version         :", ver)
    print("  headerSize      :", headerSize)
    print("  dims            :", w, "x", h, "frames", frames)
    print("  imageFormat     :", FMT.get(fmt, fmt), "(", fmt, ")")
    print("  mipCount        :", mipCount)
    print("  lowResFormat    :", FMT.get(lowFmt, lowFmt), "(", lowFmt, ")", lowW, "x", lowH)
    print("  bumpScale       :", bumpScale)
    print("  flags           :", hex(flags), flagbits)

print("="*60)
# compare file hashes to detect duplicates
for f in files:
    p = os.path.join(base, f)
    h = hashlib.md5(open(p,"rb").read()).hexdigest()
    print("md5", f, h)
