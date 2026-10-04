AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Angry Fish"
ENT.Author = "TrueFishing"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "True Fishing"

function ENT:PhysgunPickup(ply)
	return false
end

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "FishName")
	self:NetworkVar("Float", 0, "TargetHealth")
end

function ENT:GravGunPickupAllowed(ply)
	return self.IsDead or self:GetNW2Bool("IsDead", false)
end

function ENT:GravGunPunt(ply)
	return self.IsDead or self:GetNW2Bool("IsDead", false)
end
