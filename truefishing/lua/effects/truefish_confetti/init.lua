-- Efecto de explosión de confeti festivo para desaparición de jefes y esbirros
function EFFECT:Init(data)
	local pos = data:GetOrigin()
	local scale = math.max(0.3, data:GetScale())
	local count = math.floor(65 * scale)

	local emitter = ParticleEmitter(pos)
	if not emitter then return end

	local colors = {
		Color(255, 45, 45),
		Color(45, 255, 80),
		Color(45, 160, 255),
		Color(255, 230, 40),
		Color(255, 45, 230),
		Color(45, 255, 240),
		Color(255, 140, 30),
		Color(255, 255, 255),
	}

	-- Partículas de confeti en cuadrícula/esparcidas flotantes
	for i = 1, count do
		local p = emitter:Add("effects/spark", pos + VectorRand() * (12 * scale))
		if p then
			local dir = (VectorRand() + Vector(0, 0, 0.4)):GetNormalized()
			local speed = math.Rand(200, 580) * scale
			p:SetVelocity(dir * speed)
			p:SetDieTime(math.Rand(2.5, 4.0))
			p:SetStartAlpha(255)
			p:SetEndAlpha(0)
			p:SetStartSize(math.Rand(7, 14) * scale)
			p:SetEndSize(math.Rand(4, 9) * scale)
			p:SetRoll(math.Rand(0, 360))
			p:SetRollDelta(math.Rand(-25, 25))
			p:SetAirResistance(130)
			p:SetGravity(Vector(math.Rand(-30, 30), math.Rand(-30, 30), -220))
			p:SetCollide(true)
			p:SetBounce(0.35)

			local col = colors[math.random(#colors)]
			p:SetColor(col.r, col.g, col.b)
		end
	end

	-- Ráfaga de destello de humo y chispas adicionales
	for i = 1, math.floor(18 * scale) do
		local smoke = emitter:Add("particle/particle_smokegrenade", pos + VectorRand() * (8 * scale))
		if smoke then
			smoke:SetVelocity(VectorRand() * (120 * scale) + Vector(0, 0, 80 * scale))
			smoke:SetDieTime(math.Rand(1.2, 2.0))
			smoke:SetStartAlpha(180)
			smoke:SetEndAlpha(0)
			smoke:SetStartSize(15 * scale)
			smoke:SetEndSize(45 * scale)
			smoke:SetRoll(math.Rand(0, 360))
			smoke:SetRollDelta(math.Rand(-3, 3))
			smoke:SetColor(240, 240, 250)
			smoke:SetAirResistance(100)
		end
	end

	emitter:Finish()

	sound.Play("garrysmod/balloon_pop.wav", pos, 95, math.random(95, 110))
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
