import io, sys

def patch(path, edits):
    with io.open(path, "r", encoding="utf-8", newline="") as f:
        src = f.read()
    for old, new in edits:
        n = src.count(old)
        if n != 1:
            print("ERROR: %d occurrences for:\n%r" % (n, old[:160]))
            sys.exit(1)
        src = src.replace(old, new)
    with io.open(path, "w", encoding="utf-8", newline="") as f:
        f.write(src)
    print("OK", path)

# ---- 1) Config: max 5 fish in container ----
patch(
    r"lua/autorun/sh_fishconfigs.lua",
    [(
        "FISH_CONTAINER_LIMIT = 15,",
        "FISH_CONTAINER_LIMIT = 5,",
    )],
)

# ---- 2) Server: fish_container/init.lua ----
add_nets = (
    'util.AddNetworkString("SendFish")\n'
    'util.AddNetworkString("FishMenu")\n'
    'util.AddNetworkString("DiscardFish")\n'
    'util.AddNetworkString("SendFishSpawn")\n'
)
add_nets_new = (
    'util.AddNetworkString("SendFish")\n'
    'util.AddNetworkString("FishMenu")\n'
    'util.AddNetworkString("DiscardFish")\n'
    'util.AddNetworkString("SendFishSpawn")\n'
    'util.AddNetworkString("FishBoxOpen")\n'
    'util.AddNetworkString("FishBoxDeposit")\n'
    'util.AddNetworkString("FishBoxWithdraw")\n'
)

old_use = (
    'function ENT:Use(activator, caller)\n'
    '\tif (!caller:IsValid() or !caller:IsPlayer()) then return end\t\n'
    '\t\n'
    '\tlocal tracedata, pos = {}, self:GetPos()\n'
    '\ttracedata.start = pos\n'
    '\ttracedata.endpos = pos-Vector(0, 0, 90)\n'
    '\ttracedata.filter = self\n'
    '\tlocal trace = util.TraceLine(tracedata)\n'
    '\t\n'
    '\tnet.Start("FishMenu")\n'
    '\tnet.WriteEntity(self)\n'
    '\tnet.WriteBit(!self.IsHookedToEntity and trace.Hit and !trace.HitWorld and trace.Entity:IsValid())\n'
    '\tnet.WriteBit(self.IsHookedToEntity)\n'
    '\tnet.WriteBit(TrueFish.FISH_CONTAINER_OWNER_DISCARD and caller == self.Owner or !TrueFish.FISH_CONTAINER_OWNER_DISCARD)\n'
    '\tnet.Send(caller)\n'
    'end\n'
)

new_use = (
    '-- Envia el estado completo de la caja (peces dentro + peces que lleva el jugador)\n'
    'local function SendFishBox(ply, ent)\n'
    '\tnet.Start("FishBoxOpen")\n'
    '\tnet.WriteUInt(ent:EntIndex(), 13)\n'
    '\tnet.WriteUInt(TrueFish.FISH_CONTAINER_LIMIT or 5, 8)\n'
    '\n'
    '\t-- Peces dentro de la caja\n'
    '\tfor i = 1, FISH_HIGHNUMBER do\n'
    '\t\tlocal n = ent.Fishes[i]\n'
    '\t\tif n and n > 0 then\n'
    '\t\t\tnet.WriteUInt(i, 6)\n'
    '\t\t\tnet.WriteUInt(n, 8)\n'
    '\t\tend\n'
    '\tend\n'
    '\tnet.WriteUInt(0, 6)\n'
    '\n'
    '\t-- Peces que lleva el jugador\n'
    '\tfor i = 1, FISH_HIGHNUMBER do\n'
    '\t\tlocal n = ply.Fishes and ply.Fishes[i]\n'
    '\t\tif n and n > 0 then\n'
    '\t\t\tnet.WriteUInt(i, 6)\n'
    '\t\t\tnet.WriteUInt(n, 8)\n'
    '\t\tend\n'
    '\tend\n'
    '\tnet.WriteUInt(0, 6)\n'
    '\n'
    '\tnet.Send(ply)\n'
    'end\n'
    '\n'
    'function ENT:Use(activator, caller)\n'
    '\tif !caller:IsValid() or !caller:IsPlayer() then return end\n'
    '\tSendFishBox(caller, self)\n'
    'end\n'
    '\n'
    '-- Guardar un pez del inventario del jugador dentro de la caja\n'
    'net.Receive("FishBoxDeposit", function(len, ply)\n'
    '\tlocal idx = net.ReadUInt(13)\n'
    '\tlocal fish = net.ReadUInt(6)\n'
    '\tlocal ent = ents.GetByIndex(idx)\n'
    '\tif !IsValid(ent) or ent:GetClass() != "fish_container" then return end\n'
    '\tif ent:GetPos():Distance(ply:GetPos()) > 200 then return end\n'
    '\n'
    '\tif not ply.Fishes or not ply.Fishes[fish] or ply.Fishes[fish] <= 0 then\n'
    '\t\tSendFishBox(ply, ent)\n'
    '\t\treturn\n'
    '\tend\n'
    '\n'
    '\tlocal limit = TrueFish.FISH_CONTAINER_LIMIT or 5\n'
    '\tif ent:GetSpace() >= limit then\n'
    '\t\tTrueFishNotify(ply, "La caja esta llena (max. " .. limit .. ").")\n'
    '\t\tSendFishBox(ply, ent)\n'
    '\t\treturn\n'
    '\tend\n'
    '\n'
    '\tply.Fishes[fish] = ply.Fishes[fish] - 1\n'
    '\tif ply.Fishes[fish] <= 0 then ply.Fishes[fish] = nil end\n'
    '\tent:AddFish(fish, 1)\n'
    '\n'
    '\tSendFishBox(ply, ent)\n'
    'end)\n'
    '\n'
    '-- Sacar un pez de la caja y devolverlo al inventario del jugador\n'
    'net.Receive("FishBoxWithdraw", function(len, ply)\n'
    '\tlocal idx = net.ReadUInt(13)\n'
    '\tlocal fish = net.ReadUInt(6)\n'
    '\tlocal ent = ents.GetByIndex(idx)\n'
    '\tif !IsValid(ent) or ent:GetClass() != "fish_container" then return end\n'
    '\tif ent:GetPos():Distance(ply:GetPos()) > 200 then return end\n'
    '\n'
    '\tif not ent.Fishes[fish] or ent.Fishes[fish] <= 0 then\n'
    '\t\tSendFishBox(ply, ent)\n'
    '\t\treturn\n'
    '\tend\n'
    '\n'
    '\tlocal limit = TrueFish.FISH_CARRY_LIMIT or 20\n'
    '\tlocal carried = 0\n'
    '\tif ply.Fishes then\n'
    '\t\tfor i = 1, FISH_HIGHNUMBER do\n'
    '\t\t\tcarried = carried + (ply.Fishes[i] or 0)\n'
    '\t\tend\n'
    '\tend\n'
    '\tif carried >= limit then\n'
    '\t\tTrueFishNotify(ply, "No podes cargar mas peces.")\n'
    '\t\tSendFishBox(ply, ent)\n'
    '\t\treturn\n'
    '\tend\n'
    '\n'
    '\tent.Fishes[fish] = ent.Fishes[fish] - 1\n'
    '\tif ent.Fishes[fish] <= 0 then ent.Fishes[fish] = nil end\n'
    '\tent:UpdateFishes()\n'
    '\tply.Fishes = ply.Fishes or {}\n'
    '\tply.Fishes[fish] = (ply.Fishes[fish] or 0) + 1\n'
    '\n'
    '\tSendFishBox(ply, ent)\n'
    'end)\n'
)

patch(
    r"lua/entities/fish_container/init.lua",
    [
        (add_nets, add_nets_new),
        (old_use, new_use),
    ],
)
