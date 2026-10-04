AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_phx/misc/smallcannonball.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(15)
		phys:EnableGravity(true)
		phys:SetBuoyancyRatio(0.1)
		phys:SetDamping(0.05, 0.05)
	end

	self:SetColor(Color(255, 120, 20, 255))
	self:SetMaterial("models/player/shared/gold_player")

	util.SpriteTrail(self, 0, Color(255, 110, 20, 240), false, 24, 0, 0.75, 1 / (15 + 1) * 0.5, "trails/plasma")

	self.Damage = 40
	self.SpawnTime = CurTime()
	self.NextSmoke = CurTime()
end

function ENT:Explode(hitPos)
	if self.Exploded then return end
	self.Exploded = true

	hitPos = hitPos or self:GetPos()

	local ed = EffectData()
	ed:SetOrigin(hitPos)
	ed:SetScale(1.8)
	util.Effect("Explosion", ed)

	local ed2 = EffectData()
	ed2:SetOrigin(hitPos)
	ed2:SetScale(2.5)
	util.Effect("watersplash", ed2)

	self:EmitSound("ambient/explosions/explode_" .. math.random(1, 4) .. ".wav", 88, math.random(115, 130))
	self:EmitSound("ambient/fire/mtov_flame2.wav", 80, 100)

	local attacker = IsValid(self.Owner) and self.Owner or self
	util.BlastDamage(self, attacker, hitPos, 180, self.Damage or 40)
	util.ScreenShake(hitPos, 6, 10, 0.8, 600)
	util.Decal("Scorch", hitPos + Vector(0, 0, 10), hitPos - Vector(0, 0, 30))

	SafeRemoveEntity(self)
end

function ENT:PhysicsCollide(data, phys)
	self:Explode(data.HitPos)
end

function ENT:Think()
	if CurTime() - self.SpawnTime > 7.0 then
		self:Explode(self:GetPos())
		return
	end

	self:NextThink(CurTime() + 0.1)
	return true
end
