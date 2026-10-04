/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

util.AddNetworkString("SendFish")
util.AddNetworkString("FishMenu")
util.AddNetworkString("DiscardFish")
util.AddNetworkString("SendFishSpawn")
util.AddNetworkString("FishBoxOpen")
util.AddNetworkString("FishBoxDeposit")
util.AddNetworkString("FishBoxWithdraw")
util.AddNetworkString("FishBoxOpenRequest")
util.AddNetworkString("FishBoxCloseRequest")

hook.Add("PlayerAuthed", "SendFishContainers", function(ply)
	timer.Simple(20, function()
		if !ply:IsValid() then return end
		local ent = ents.FindByClass("fish_container")
		net.Start("SendFishSpawn")
		net.WriteUInt(#ent, 13)
		for k, v in pairs(ent) do
			net.WriteUInt(v:EntIndex(), 13)
			for i=1, FISH_HIGHNUMBER do
				if v.Fishes[i] and v.Fishes[i] > 0 then
					net.WriteUInt(i, 6)
					net.WriteUInt(v.Fishes[i], 8)
				end
			end
			net.WriteUInt(0, 6)
		end
		net.Send(ply)
	end)
end)


net.Receive("DiscardFish", function(len, ply)
	local ent, fish = net.ReadEntity(), net.ReadInt(16)
	if !ent:IsValid() or !ent.Fishes[fish] or !ent.Owner == ply or ent:GetPos():Distance(ply:GetPos()) > 200 then return end
	
	ent.Fishes[fish] = nil
	ent:UpdateFishes()
	
end)

local meta = FindMetaTable("Player")// slight hack for updating vars to the client - darkrp doesn't include hooks for dropPocketItem
local c_dropPocketItem = meta.dropPocketItem
function meta:dropPocketItem(item)
	local ent = c_dropPocketItem(self, item)
	
	
	if !ent or !ent:IsValid() or ent:GetClass() != "fish_container" or #ent.Fishes < 1 then return end
	
	timer.Simple(0.5, function()
		if !ent:IsValid() then return end
		ent:UpdateFishes()
	end)
	
	return ent
end
meta = nil


function ENT:AddFish(num, size, noNet)
	self.Fishes[num] = self.Fishes[num] and self.Fishes[num] + size or size//realSize or realSize
	
	if noNet then return end
	self:UpdateFishes()
end

function ENT:UpdateFishes()
	net.Start("SendFish")
	net.WriteUInt(self:EntIndex(), 13)
	for i=1, FISH_HIGHNUMBER do
		if self.Fishes[i] and self.Fishes[i] > 0 then
			net.WriteUInt(i, 6)
			net.WriteUInt(self.Fishes[i], 8)
		end
	end
	net.WriteUInt(0, 6)
	net.Broadcast()
end

function ENT:Initialize()	
	self:SetModel("models/truefishing/caja_pescados.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetPos(self:GetPos()+Vector(0, 0, 40))
	local phys = self:GetPhysicsObject()    
	self.BuoyancyRatio = 0.175
	phys:SetBuoyancyRatio(0.175)
	phys:Wake()
	//self:SetAngles(self:GetAngles()+Angle(0, 0, 180))
	self:SetUseType(SIMPLE_USE)
	self.Fishes = {}
	
end

-- Envia el estado completo de la caja (peces dentro + peces que lleva el jugador)
local function SendFishBox(ply, ent)
	net.Start("FishBoxOpen")
	net.WriteUInt(ent:EntIndex(), 13)
	net.WriteUInt(TrueFish.FISH_CONTAINER_LIMIT or 5, 8)

	-- Peces dentro de la caja
	for i = 1, FISH_HIGHNUMBER do
		local n = ent.Fishes[i]
		if n and n > 0 then
			net.WriteUInt(i, 6)
			net.WriteUInt(n, 8)
		end
	end
	net.WriteUInt(0, 6)

	-- Peces que lleva el jugador
	for i = 1, FISH_HIGHNUMBER do
		local n = ply.Fishes and ply.Fishes[i]
		if n and n > 0 then
			net.WriteUInt(i, 6)
			net.WriteUInt(n, 8)
		end
	end
	net.WriteUInt(0, 6)

	net.Send(ply)
end

function ENT:Use(activator, caller)
	if !caller:IsValid() or !caller:IsPlayer() then return end
	-- Con la caja ya abierta, un toque de E vuelve a mostrar el inventario
	if self:GetNW2Bool("BoxOpen", false) then
		SendFishBox(caller, self)
	end
end

-- Abre la tapa (bodygroup 1) y muestra el inventario
function ENT:OpenBox(ply)
	if self:GetNW2Bool("BoxOpen", false) then return end
	self:SetNW2Bool("BoxOpen", true)
	SendFishBox(ply, self)
end

-- Cierra la tapa (bodygroup 0) sin tocar los peces guardados
function ENT:CloseBox(ply)
	if not self:GetNW2Bool("BoxOpen", false) then return end
	self:SetNW2Bool("BoxOpen", false)
end

-- El cliente avisa cuando termina de mantener pulsada la E (abrir)
net.Receive("FishBoxOpenRequest", function(len, ply)
	local idx = net.ReadUInt(13)
	local ent = ents.GetByIndex(idx)
	if !IsValid(ent) or ent:GetClass() != "fish_container" then return end
	if ent:GetPos():Distance(ply:GetPos()) > 200 then return end
	ent:OpenBox(ply)
end)

-- El cliente avisa cuando termina de mantener pulsada la E (cerrar)
net.Receive("FishBoxCloseRequest", function(len, ply)
	local idx = net.ReadUInt(13)
	local ent = ents.GetByIndex(idx)
	if !IsValid(ent) or ent:GetClass() != "fish_container" then return end
	if ent:GetPos():Distance(ply:GetPos()) > 200 then return end
	ent:CloseBox(ply)
end)

-- Guardar un pez del inventario del jugador dentro de la caja
net.Receive("FishBoxDeposit", function(len, ply)
	local idx = net.ReadUInt(13)
	local fish = net.ReadUInt(6)
	local ent = ents.GetByIndex(idx)
	if !IsValid(ent) or ent:GetClass() != "fish_container" then return end
	if ent:GetPos():Distance(ply:GetPos()) > 200 then return end

	if not ply.Fishes or not ply.Fishes[fish] or ply.Fishes[fish] <= 0 then
		SendFishBox(ply, ent)
		return
	end

	local limit = TrueFish.FISH_CONTAINER_LIMIT or 5
	if ent:GetSpace() >= limit then
		TrueFishNotify(ply, "La caja esta llena (max. " .. limit .. ").")
		SendFishBox(ply, ent)
		return
	end

	ply.Fishes[fish] = ply.Fishes[fish] - 1
	if ply.Fishes[fish] <= 0 then ply.Fishes[fish] = nil end
	ent:AddFish(fish, 1)

	SendFishBox(ply, ent)
end)

-- Sacar un pez de la caja: aparece el modelo del pez muerto arriba de la caja.
net.Receive("FishBoxWithdraw", function(len, ply)
	local idx = net.ReadUInt(13)
	local fish = net.ReadUInt(6)
	local ent = ents.GetByIndex(idx)
	if !IsValid(ent) or ent:GetClass() != "fish_container" then return end
	if ent:GetPos():Distance(ply:GetPos()) > 200 then return end

	if not ent.Fishes[fish] or ent.Fishes[fish] <= 0 then
		SendFishBox(ply, ent)
		return
	end

	ent.Fishes[fish] = ent.Fishes[fish] - 1
	if ent.Fishes[fish] <= 0 then ent.Fishes[fish] = nil end
	ent:UpdateFishes()

	-- Spawnea el pez muerto arriba de la caja (el modelo del pez que se guardo)
	local topPos = ent:GetPos() + Vector(0, 0, 50)
	local dead = ents.Create("ent_angry_fish")
	dead.FishID = fish
	dead.FishModel = TrueFishGetFishModel(fish)
	dead:SetPos(topPos)
	dead.IsDead = true
	dead:SetNW2Bool("IsDead", true)
	dead.Target = nil
	dead.JustWithdrawn = CurTime()
	dead.DespawnTime = CurTime() + 90
	if dead.CPPISetOwner and IsValid(ply) then
		dead:CPPISetOwner(ply)
	end
	dead:Spawn()
	dead:SetColor(Color(205, 205, 215, 255))

	-- Material no-carne: la Gravity Gun no levanta objetos con material "flesh"
	if dead.ApplyDeadPhysics then dead:ApplyDeadPhysics() end

	local phys = dead:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocity(Vector(0, 0, 70))
		phys:AddAngleVelocity(Vector(math.random(-160, 160), math.random(-160, 160), 0))
	end

	SendFishBox(ply, ent)
end)

-- Al pasar la caja por encima de un pez muerto, o acercar el pez con la Gravity Gun, lo guarda automaticamente (max. 5).
-- Absorbe cuando la caja es cargada por un jugador, o cuando el pez está siendo sostenido (ej. con la Gravity Gun).
function ENT:Think()
	local limit = TrueFish.FISH_CONTAINER_LIMIT or 5
	if self:GetSpace() < limit then
		local myPos = self:GetPos()
		for _, fish in ipairs(ents.FindInSphere(myPos, 70)) do
			if IsValid(fish) and fish:GetClass() == "ent_angry_fish" and fish.IsDead then
				if fish.JustWithdrawn and (CurTime() - fish.JustWithdrawn) < 2.5 then
					-- recien sacado de la caja: no volver a guardarlo al instante
				elseif self:IsPlayerHolding() or fish:IsPlayerHolding() or fish.IsBeingHeld then
					local fishID = fish.FishID or FISH_BASSFISH
					self:AddFish(fishID, 1)
					self:EmitSound("garrysmod/save_load1.wav", 75, 100)
					SafeRemoveEntity(fish)
					if self:GetSpace() >= limit then break end
				end
			end
		end
	end
	self:NextThink(CurTime() + 0.25)
	return true
end

function ENT:OnRemove()
	if IsValid(self.Owner) then
		self.Owner.FishContainers = math.max(0, (self.Owner.FishContainers or 1) - 1)
	end
end

/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/