AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_phx/games/trophy.mdl")
	if not util.IsValidModel(self:GetModel()) then
		self:SetModel("models/props_junk/watermelon01.mdl")
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(15)
		phys:SetMaterial("metal")
		phys:SetBuoyancyRatio(0.9)
		phys:SetDamping(0.2, 0.3)
	end

	self:SetUseType(SIMPLE_USE)
	self:SetColor(Color(255, 215, 60, 255))
	self:SetMaterial("models/player/shared/gold_player")
end

function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if self.Collected then return end
	self.Collected = true

	local reward = self:GetRewardValue()
	if reward <= 0 then reward = 1000 end

	TrueFishGiveMoney(activator, reward)
	TrueFishNotify(activator, "¡Recogiste el Trofeo de " .. (self:GetBossName() ~= "" and self:GetBossName() or "Jefe") .. "! +$" .. reward)

	activator:EmitSound("garrysmod/save_load1.wav", 80, 110)
	activator:EmitSound("ambient/levels/labs/coinslot1.wav", 80, 100)

	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetScale(1.2)
	util.Effect("cball_explode", ed)

	SafeRemoveEntity(self)
end
