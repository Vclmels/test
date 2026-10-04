include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local pos = self:GetPos() + Vector(0, 0, 18)
	local ang = EyeAngles()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.08)
		local pulse = math.abs(math.sin(CurTime() * 4))
		local col = Color(255, 215 + pulse * 40, 50, 240)
		local boss = self:GetBossName() ~= "" and self:GetBossName() or "Jefe"
		draw.SimpleText("★ TROFEO DE " .. string.upper(boss) .. " ★", "SegoeUI_NormalBoldScaled", 0, -20, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("[E] Reclamar Recompensa ($" .. self:GetRewardValue() .. ")", "SegoeUI_NormalSmallScaled", 0, 8, Color(255, 255, 255, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()

	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.pos = self:GetPos()
		dlight.r = 255
		dlight.g = 215
		dlight.b = 50
		dlight.brightness = 1.5
		dlight.Decay = 1000
		dlight.Size = 128
		dlight.DieTime = CurTime() + 0.1
	end
end
