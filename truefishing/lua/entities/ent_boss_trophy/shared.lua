ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Boss Trophy"
ENT.Author = "How to Fish"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "RewardValue")
	self:NetworkVar("String", 0, "BossName")
end
