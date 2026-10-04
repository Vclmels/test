/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()
	self:SetModel("models/fishing/hook.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(0.5)
		phys:Wake()
	end
end

local fishMouthOffsets = {
	[1] = 4.65,  -- clownfish
	[2] = 4.88,  -- goldfish
	[3] = 9.11,  -- salmon
	[4] = 19.23, -- tuna
	[5] = 8.67,  -- pufferfish
	[6] = 10.61, -- catfish
	[7] = 11.07, -- bass
	[8] = 5.0,   -- junk
}

function ENT:AddFish(fish)
	if IsValid(self.Fish) then self.Fish:Remove() end
	
	-- Usar prop_dynamic_override para evitar la física de Havok y la flotabilidad del agua.
	-- prop_physics crea un objeto de colisión sujeto a trigger_water que peleaba con SetParent
	-- y despegaba el pez, dejándolo horizontal y separado del anzuelo.
	self.Fish = ents.Create("prop_dynamic_override")
	if not IsValid(self.Fish) then
		self.Fish = ents.Create("prop_dynamic")
	end
	if not IsValid(self.Fish) then
		self.Fish = ents.Create("prop_physics")
	end
	self.Fish.FishID = fish
	self.Fish:SetModel(TrueFishGetFishModel(fish))
	self.Fish:Spawn()
	self.Fish:SetSolid(SOLID_NONE)
	self.Fish:SetMoveType(MOVETYPE_NONE)
	local phys = self.Fish:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end
	self.Fish:SetParent(self)
	local fishMdl = TrueFishGetFishModel(fish)
	local scale = (TrueFishGetHangScale and TrueFishGetHangScale(fishMdl)) or 1.0
	local mX = ((TrueFishGetMouthOffset and TrueFishGetMouthOffset(fish)) or ((fishMouthOffsets[fish] or 11.0) * 1.5)) * scale
	-- El eje LARGO del pez es +Y (la boca está en +Y, no en +X).
	-- Con roll = +90 el eje +Y (boca) apunta hacia ARRIBA (+Z) => pez VERTICAL con la cabeza arriba.
	-- El centro queda mX por debajo de la púa (Z = -4.5 - mX) para que la boca coincida con el anzuelo.
	self.Fish:SetModelScale(scale, 0)
	self.Fish:SetLocalPos(Vector(0, 0.4, -4.5 - mX))
	self.Fish:SetLocalAngles(Angle(0, 0, 90))
end

function ENT:AddMoneyBag()
	if IsValid(self.Fish) then self.Fish:Remove() end
	
	self.Fish = ents.Create("prop_physics")
	self.Fish:SetModel("models/props_c17/BriefCase001a.mdl")
	self.Fish:PhysicsInit(SOLID_NONE)
	self.Fish:SetPos(self:GetPos() - self:GetUp()*20)
	self.Fish:SetParent(self)
	self.Fish:Spawn()
end

function ENT:RemoveFish()
	if IsValid(self.Fish) then
		self.Fish:Remove()
	end
end

ENT.NextUse = 0
function ENT:Use(user, caller)
	local ctime = CurTime()
	if !IsValid(self.Fish) or ctime < self.NextUse then return end
	self.NextUse = ctime + 1
	
	-- Si el usuario tiene la caña física con el pez capturado, soltarlo con [E] para pelear
	if IsValid(caller) and caller:IsPlayer() then
		local wep = caller:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "fishing_rod_physics" then
			if wep.FishCaughtID and wep.FishCaughtID > 0 then
				wep:ReleaseAngryFish()
			end
			return
		end
	end

	local fish = self.Fish.FishID
	
	if !fish then
		TrueFishGiveMoney(caller, TrueFish.ROD_MONEYBAG_MONEY)
		TrueFishNotify(caller, TrueFishLocal("money_bag_caught", TrueFish.ROD_MONEYBAG_MONEY))
		self.Fish:Remove()
		return
	end
	
	
	caller.Fishes = caller.Fishes or {}
	if TrueFish.ROD_NO_CONTAINER then
		local playerSpace = 0
		for i=1, FISH_HIGHNUMBER do
			if caller.Fishes[i] then
				playerSpace = playerSpace + caller.Fishes[i]
			end
		end
	
		if TrueFish.FISH_CARRY_LIMIT <= playerSpace then
			TrueFishNotify(caller, TrueFishLocal("carry_limit_reached", TrueFish.FISH_CARRY_LIMIT))
			return
		end
		TrueFishNotify(caller, TrueFishLocal("fish_caught", TrueFishGetFishName(fish)))
		caller.Fishes[fish] = caller.Fishes[fish] and caller.Fishes[fish]+1 or 1
		self.Fish:Remove()
		return
	end
	
	
	local dist = {}
	local distEnt = {}
	local find = ents.FindInSphere(self:GetPos(), 250)
	for i=1, #find do
		if find[i]:IsValid() and find[i]:GetClass() == "fish_container" then
			local d = caller:GetPos():Distance(find[i]:GetPos())
			dist[#dist+1] = d
			distEnt[d] = find[i]
		end
	end
	
	if !dist[1] then
		TrueFishNotify(caller, TrueFishLocal("empty_fish_containers_near"))
		return
	end
		
	local closest 
	for k, v in SortedPairsByValue(dist) do
		closest = distEnt[v]
		if closest:GetSpace() < TrueFish.FISH_CONTAINER_LIMIT then break end
	end
	
	if !closest then return end
	
	closest:AddFish(fish, 1)
	self.Fish:Remove()
	TrueFishNotify(caller, TrueFishLocal("fish_caught", TrueFishGetFishName(fish)))
end

function ENT:Think()
	self:GetPhysicsObject():Wake()
	self:NextThink(CurTime()+1)
	return true

end

function ENT:OnRemove()
	self:RemoveFish()
end
/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/