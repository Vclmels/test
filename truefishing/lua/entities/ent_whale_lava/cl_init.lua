include("shared.lua")

function ENT:Initialize()
	self.PixVis = util.GetPixelVisibleHandle()
end

function ENT:Draw()
	self:DrawModel()

	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.pos = self:GetPos()
		dlight.r = 255
		dlight.g = 120
		dlight.b = 30
		dlight.brightness = 3
		dlight.Decay = 1000
		dlight.Size = 256
		dlight.DieTime = CurTime() + 0.1
	end
end
