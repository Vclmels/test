include("shared.lua")

local font = system.IsOSX() and "Trebuchet" or "Segoe UI"
surface.CreateFont("SegoeUI_NormalBoldScaled", {
	font 		= font,
	size 		= 22,
	weight 		= 800,
	antialias 	= true
})
surface.CreateFont("SegoeUI_NormalSmallScaled", {
	font 		= font,
	size 		= 14,
	weight 		= 600,
	antialias 	= true
})

local bossLerpHp = 1.0
local whaleAtmoFrac = 0.0

function ENT:Initialize()
	self.SpawnTime = CurTime()
end

function ENT:Draw()
	self:DrawModel()

	local isMutatedWhale = self:GetBossType() == 11 or string.find(self:GetModel() or "", "boss_mutatedwhale")

	-- Resplandor volcánico abisal masivo para la Ballena Mutante (último jefe)
	if isMutatedWhale and not self:GetIsDead() then
		local dlightW = DynamicLight(self:EntIndex() + 1000)
		if dlightW then
			local inP2 = self:GetInSecondPhase()
			local pulse = math.abs(math.sin(CurTime() * (inP2 and 6 or 3)))
			dlightW.pos = self:GetPos() + Vector(0, 0, 45)
			dlightW.r = 255
			dlightW.g = inP2 and (40 + pulse * 40) or 25
			dlightW.b = 10
			dlightW.brightness = inP2 and 3.8 or 2.6
			dlightW.Decay = 1000
			dlightW.Size = inP2 and (850 + pulse * 150) or 650
			dlightW.DieTime = CurTime() + 0.1
		end
	end

	-- Efecto de aura ardiente en segunda fase genérica
	if self:GetInSecondPhase() and not self:GetIsDead() then
		local dlight = DynamicLight(self:EntIndex())
		if dlight then
			dlight.pos = self:GetPos() + Vector(0, 0, 20)
			dlight.r = 255
			dlight.g = 80
			dlight.b = 20
			dlight.brightness = 2.5
			dlight.Decay = 1000
			dlight.Size = 320
			dlight.DieTime = CurTime() + 0.1
		end
	end
end

-- ==========================================================================
-- ATMÓSFERA TERRORÍFICA: BALLENA MUTANTE (ÚLTIMO JEFE)
-- Genera una niebla roja con blanco en forma de domo perimetral que sigue al
-- jugador, post-procesamiento tétrico, cenizas/humo flotante y audio abisal.
-- ==========================================================================

local atmoSound = nil
local nextRoarSound = 0
local nextEmbers = 0
local nextMist = 0
local particleEmitter = nil

local function UpdateAtmoSound(ply, frac)
	if frac > 0.03 and IsValid(ply) and ply:Alive() then
		if not atmoSound then
			atmoSound = CreateSound(ply, "ambient/atmosphere/underground_hall_loop1.wav")
			if atmoSound then
				atmoSound:PlayEx(0.01, 80)
			end
		end
		if atmoSound then
			atmoSound:ChangeVolume(math.Clamp(frac * 0.70, 0.01, 0.70), 0.15)
			atmoSound:ChangePitch(math.Clamp(75 + frac * 8, 70, 88), 0.15)
		end
	else
		if atmoSound then
			atmoSound:Stop()
			atmoSound = nil
		end
	end
end

local function UpdateAtmosphereParticles(ply, frac)
	if frac < 0.05 or not IsValid(ply) or not ply:Alive() then return end

	local ct = CurTime()
	local plyPos = ply:GetPos()

	if not particleEmitter or not particleEmitter:IsValid() then
		particleEmitter = ParticleEmitter(plyPos, false)
	end
	if not particleEmitter then return end

	-- 1. Cenizas y ascuas incandescentes flotando hacia arriba alrededor del jugador
	if ct >= nextEmbers then
		nextEmbers = ct + math.Rand(0.04, 0.08)
		local spawnOffset = Vector(math.Rand(-380, 380), math.Rand(-380, 380), math.Rand(-20, 75))
		local p = particleEmitter:Add("sprites/light_glow02_add", plyPos + spawnOffset)
		if p then
			p:SetVelocity(Vector(math.Rand(-30, 30), math.Rand(-30, 30), math.Rand(35, 85)))
			p:SetDieTime(math.Rand(1.8, 3.2))
			p:SetStartAlpha(math.floor(240 * frac))
			p:SetEndAlpha(0)
			p:SetStartSize(math.Rand(3, 7))
			p:SetEndSize(0)
			p:SetRoll(math.Rand(0, 360))
			p:SetRollDelta(math.Rand(-2, 2))
			-- Alternar entre brasa ardiente roja/anaranjada y ceniza blanca luminosa
			if math.random() > 0.45 then
				p:SetColor(255, math.random(55, 110), 18)
			else
				p:SetColor(245, 235, 225)
			end
			p:SetAirResistance(45)
			p:SetGravity(Vector(0, 0, 18))
		end
	end

	-- 2. Volutas de niebla roja y blanca que cruzan a baja altura frente al jugador
	if ct >= nextMist then
		nextMist = ct + math.Rand(0.12, 0.22)
		local spawnOffset = Vector(math.Rand(-480, 480), math.Rand(-480, 480), math.Rand(-10, 45))
		local smokeIndex = math.random(1, 4)
		local smokeMat = "particle/smokesprites_000" .. smokeIndex
		local p = particleEmitter:Add(smokeMat, plyPos + spawnOffset)
		if p then
			p:SetVelocity(Vector(math.Rand(-35, 35), math.Rand(-35, 35), math.Rand(6, 18)))
			p:SetDieTime(math.Rand(3.2, 5.2))
			local maxAlpha = math.random(26, 48) * frac
			p:SetStartAlpha(maxAlpha)
			p:SetEndAlpha(0)
			p:SetStartSize(math.Rand(75, 140))
			p:SetEndSize(math.Rand(210, 340))
			p:SetRoll(math.Rand(0, 360))
			p:SetRollDelta(math.Rand(-0.25, 0.25))
			-- 50% niebla blanca ascuosa, 50% niebla roja carmesí profunda
			if math.random() > 0.5 then
				p:SetColor(185, 35, 35)
			else
				p:SetColor(230, 220, 220)
			end
			p:SetAirResistance(30)
		end
	end
end

-- Think global de la atmósfera
hook.Add("Think", "TrueFish_MutatedWhale_AtmosphereThink", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local activeWhale = nil
	local closestDist = 4200 * 4200
	for _, ent in ipairs(ents.FindByClass("ent_boss_fish")) do
		if IsValid(ent) and not ent:GetIsDead() then
			local bType = ent:GetBossType()
			local bModel = ent:GetModel() or ""
			if bType == 11 or string.find(bModel, "boss_mutatedwhale") then
				local d = ent:GetPos():DistToSqr(ply:GetPos())
				if d < closestDist then
					closestDist = d
					activeWhale = ent
				end
			end
		end
	end

	local targetFrac = 0
	if IsValid(activeWhale) then
		local d = math.sqrt(closestDist)
		if d < 3000 then
			targetFrac = 1.0
		elseif d < 4200 then
			targetFrac = math.Clamp(1.0 - (d - 3000) / 1200, 0, 1)
		end

		if activeWhale:GetInSecondPhase() then
			targetFrac = math.min(1.2, targetFrac * 1.15)
		end
	end

	whaleAtmoFrac = Lerp(FrameTime() * 1.4, whaleAtmoFrac, targetFrac)
	if whaleAtmoFrac < 0.001 then
		whaleAtmoFrac = 0
		if particleEmitter and particleEmitter:IsValid() then
			particleEmitter:Finish()
			particleEmitter = nil
		end
	end

	UpdateAtmoSound(ply, whaleAtmoFrac)

	if whaleAtmoFrac > 0.05 then
		UpdateAtmosphereParticles(ply, whaleAtmoFrac)

		-- Rugidos y ecos abisales lejanos periódicos
		if CurTime() >= nextRoarSound and whaleAtmoFrac > 0.35 then
			nextRoarSound = CurTime() + math.random(14, 25)
			local roars = {
				"ambient/atmosphere/cave_hit1.wav",
				"ambient/atmosphere/cave_hit2.wav",
				"ambient/atmosphere/cave_hit3.wav",
				"npc/antlion/antlion_growl1.wav",
				"npc/antlion/antlion_growl2.wav"
			}
			ply:EmitSound(roars[math.random(#roars)], 65, math.random(52, 72))
		end
	end
end)

-- DOMO DE NIEBLA: Mundo
hook.Add("SetupWorldFog", "TrueFish_MutatedWhale_WorldFog", function()
	if whaleAtmoFrac <= 0.001 then return end

	local pulse = math.sin(CurTime() * 1.4) * 0.5 + 0.5
	local pulse2 = math.cos(CurTime() * 0.9) * 0.5 + 0.5
	local blend = pulse * 0.65 + pulse2 * 0.35

	-- Mezcla dinámica entre rojo carmesí oscuro y humo/niebla blanco-ceniza
	local r = Lerp(blend, 155, 215)
	local g = Lerp(blend, 22, 135)
	local b = Lerp(blend, 22, 135)

	-- El domo de niebla envuelve al jugador a su alrededor (comienza cerca y termina a ~1450u)
	local fogStart = Lerp(whaleAtmoFrac, 1500, 70)
	local fogEnd = Lerp(whaleAtmoFrac, 6000, 1450 + math.sin(CurTime() * 0.8) * 90)
	local fogDensity = Lerp(whaleAtmoFrac, 0, 0.96)

	render.FogMode(MATERIAL_FOG_LINEAR)
	render.FogStart(fogStart)
	render.FogEnd(fogEnd)
	render.FogMaxDensity(fogDensity)
	render.FogColor(r, g, b)

	return true
end)

-- DOMO DE NIEBLA: Skybox
hook.Add("SetupSkyboxFog", "TrueFish_MutatedWhale_SkyFog", function(scale)
	if whaleAtmoFrac <= 0.001 then return end

	local pulse = math.sin(CurTime() * 1.4) * 0.5 + 0.5
	local pulse2 = math.cos(CurTime() * 0.9) * 0.5 + 0.5
	local blend = pulse * 0.65 + pulse2 * 0.35

	local r = Lerp(blend, 130, 185)
	local g = Lerp(blend, 18, 110)
	local b = Lerp(blend, 18, 110)

	local fogStart = Lerp(whaleAtmoFrac, 1500, 60) * scale
	local fogEnd = Lerp(whaleAtmoFrac, 6000, 1250) * scale
	local fogDensity = Lerp(whaleAtmoFrac, 0, 0.98)

	render.FogMode(MATERIAL_FOG_LINEAR)
	render.FogStart(fogStart)
	render.FogEnd(fogEnd)
	render.FogMaxDensity(fogDensity)
	render.FogColor(r, g, b)

	return true
end)

-- POST-PROCESAMIENTO CINEMÁTICO TERRORÍFICO
hook.Add("RenderScreenspaceEffects", "TrueFish_MutatedWhale_ScreenEffects", function()
	if whaleAtmoFrac <= 0.001 then return end

	local cm = {
		["$pp_colour_addr"] = 0.07 * whaleAtmoFrac,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = -0.04 * whaleAtmoFrac,
		["$pp_colour_contrast"] = 1.0 + 0.22 * whaleAtmoFrac,
		["$pp_colour_colour"] = 1.0 - 0.38 * whaleAtmoFrac,
		["$pp_colour_mulr"] = 0.08 * whaleAtmoFrac,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0,
	}
	DrawColorModify(cm)
end)

hook.Add("ShutDown", "TrueFish_MutatedWhale_Cleanup", function()
	if atmoSound then
		atmoSound:Stop()
		atmoSound = nil
	end
	if particleEmitter and particleEmitter:IsValid() then
		particleEmitter:Finish()
		particleEmitter = nil
	end
end)

-- Barra de vida cinemática para el jefe en pantalla
hook.Add("HUDPaint", "TrueFish_BossHealthBarHUD", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local sw, sh = ScrW(), ScrH()

	local activeBoss = nil
	local closestDist = 3000 * 3000
	for _, ent in ipairs(ents.FindByClass("ent_boss_fish")) do
		if IsValid(ent) and not ent:GetIsDead() then
			local d = ent:GetPos():DistToSqr(ply:GetPos())
			if d < closestDist then
				closestDist = d
				activeBoss = ent
			end
		end
	end

	if not IsValid(activeBoss) then
		bossLerpHp = 1.0
		return
	end

	local maxHp = math.max(1, activeBoss:GetMaxBossHealth())
	local curHp = math.Clamp(activeBoss:GetBossHealth(), 0, maxHp)
	local hpFrac = curHp / maxHp
	bossLerpHp = Lerp(FrameTime() * 5, bossLerpHp, hpFrac)

	local inPhase2 = activeBoss:GetInSecondPhase()
	local w = math.floor(math.Clamp(sw * 0.42, 380, 650))
	local h = 26
	local x = math.floor((sw - w) * 0.5)
	local y = 65

	local bossName = activeBoss:GetBossName()
	if not bossName or bossName == "" then bossName = "JEFE LEGENDARIO" end
	local bossTitle = activeBoss:GetBossTitle()
	if not bossTitle or bossTitle == "" then bossTitle = "MONSTRUO DEL ABISMO" end

	-- Fondo oscuro estilizado con borde dorado/carmesí o flameante si está en fase 2
	local pulse = math.abs(math.sin(CurTime() * (inPhase2 and 10 or 4)))
	local borderColor = inPhase2 and Color(255, 60 + pulse * 100, 20, 240) or Color(220, 50, 50, 180)

	draw.RoundedBox(6, x - 4, y - 24, w + 8, h + 32, Color(12, 14, 20, 240))
	surface.SetDrawColor(borderColor)
	surface.DrawOutlinedRect(x - 4, y - 24, w + 8, h + 32, inPhase2 and 2 or 1)

	-- Nombre y título del jefe
	local titleText = inPhase2 and (bossTitle .. " [ ¡FASE DE FURIA! ]") or bossTitle
	local titleColor = inPhase2 and Color(255, 120 + pulse * 80, 40) or Color(220, 200, 200, 190)

	draw.SimpleText(string.upper(bossName), "SegoeUI_NormalBoldScaled", sw * 0.5, y - 13, Color(255, 220, 70), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(titleText, "SegoeUI_NormalSmallScaled", sw * 0.5, y - 2, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	-- Contenedor de la barra de vida
	draw.RoundedBox(4, x, y + 8, w, h, Color(25, 28, 38, 255))

	-- Barra de retraso de daño (blanco/amarillo tenue)
	local lagW = math.floor(w * math.Clamp(bossLerpHp, 0, 1))
	if lagW > 0 then
		draw.RoundedBox(4, x, y + 8, lagW, h, Color(255, 230, 140, 200))
	end

	-- Barra de vida principal (degradado rojo carmesí / fuego)
	local fillW = math.floor(w * math.Clamp(hpFrac, 0, 1))
	if fillW > 0 then
		local barColor = inPhase2 and Color(245, 65 + pulse * 35, 20, 255) or Color(215, 35, 35, 255)
		draw.RoundedBox(4, x, y + 8, fillW, h, barColor)
		-- Brillo superior en la barra
		surface.SetDrawColor(255, 255, 255, 55)
		surface.DrawRect(x + 1, y + 9, fillW - 2, math.floor(h * 0.4))
	end

	-- Marco de la barra de vida
	surface.SetDrawColor(inPhase2 and Color(255, 100, 30, 255) or Color(180, 40, 40, 255))
	surface.DrawOutlinedRect(x, y + 8, w, h, 1)

	-- Texto de porcentaje y valores numéricos de vida
	local hpText = curHp .. " / " .. maxHp .. " HP (" .. math.floor(hpFrac * 100) .. "%)"
	draw.SimpleText(hpText, "SegoeUI_NormalSmallScaled", sw * 0.5, y + 8 + h * 0.5, Color(255, 255, 255, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
