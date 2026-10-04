include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

surface.CreateFont("TrueFishing_AngryFish", {
	font = "Trebuchet MS",
	size = 28,
	weight = 900,
	antialias = true,
})

surface.CreateFont("TrueFishing_AngryFishSub", {
	font = "Trebuchet MS",
	size = 20,
	weight = 700,
	antialias = true,
})

function ENT:Draw()
	self:DrawModel()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	-- Si el pez está muerto, no mostrar ningún texto encima
	if self:GetNW2Bool("IsDead", false) then
		return
	end

	local dist = self:GetPos():DistToSqr(ply:GetPos())
	if dist > 400 * 400 then return end

	local pos = self:GetPos() + Vector(0, 0, 24)
	local ang = Angle(0, ply:EyeAngles().y - 90, 90)

	cam.Start3D2D(pos, ang, 0.1)
		local hp = math.max(0, self:Health())
		local maxHp = self:GetMaxHealth() > 0 and self:GetMaxHealth() or 35
		local frac = math.Clamp(hp / maxHp, 0, 1)

		-- Fondo
		draw.RoundedBox(6, -65, -25, 130, 48, Color(20, 20, 20, 210))
		-- Título furioso con parpadeo
		local pulse = math.abs(math.sin(CurTime() * 8))
		local titleColor = Color(255, 60 + pulse * 100, 60 + pulse * 100)
		draw.SimpleText("¡PEZ RABIOSO!", "TrueFishing_AngryFish", 0, -20, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

		-- Barra de vida
		draw.RoundedBox(4, -55, 10, 110, 8, Color(50, 50, 50, 240))
		draw.RoundedBox(4, -55, 10, 110 * frac, 8, Color(230, 40, 40, 255))
	cam.End3D2D()
end
