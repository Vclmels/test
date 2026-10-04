ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Boss Fish"
ENT.Author = "How to Fish Reverse Engineering"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "BossType")
	self:NetworkVar("Int", 1, "MaxBossHealth")
	self:NetworkVar("Int", 2, "BossHealth")
	self:NetworkVar("String", 0, "BossName")
	self:NetworkVar("String", 1, "BossTitle")
	self:NetworkVar("Bool", 0, "IsDead")
	self:NetworkVar("Bool", 1, "InSecondPhase")
	self:NetworkVar("Bool", 2, "IsFlying")
	self:NetworkVar("Bool", 3, "IsShootingLava")
end
