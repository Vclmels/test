AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	local gearID = self:GetBossType()
	local bossData = (TrueFishBosses and TrueFishBosses[gearID]) or {
		name = "Piraña Gigante",
		title = "DEPREDADOR DEL RÍO",
		model = "models/fishing/boss_piranha.mdl",
		health = 320,
		damage = 25,
		reward = 1800,
		mass = 75,
	}

	self.BossData = bossData
	self.FishModel = bossData.model or "models/fishing/boss_piranha.mdl"
	self.Reward = bossData.reward or 1800

	-- Escalado de vida y daño según la cantidad de jugadores en el servidor (Reverse Engineering: BossManager::GetBossMaxHp)
	local plys = player.GetAll()
	local playerCount = math.max(1, #plys)
	local hpMulti = 0.45
	local dmgMulti = 0.20
	local scaledHp = math.floor(bossData.health + (playerCount - 1) * bossData.health * hpMulti)
	local scaledDmg = math.floor(bossData.damage + (playerCount - 1) * bossData.damage * dmgMulti)

	self.Damage = scaledDmg

	self:SetModel(self.FishModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMaterial("flesh")
		phys:SetMass(bossData.mass or 80)
		phys:SetBuoyancyRatio(0.48)
		phys:SetDamping(0.18, 0.22)
	end

	self:SetMaxHealth(scaledHp)
	self:SetHealth(scaledHp)
	self:SetMaxBossHealth(scaledHp)
	self:SetBossHealth(scaledHp)
	self:SetBossName(bossData.name or "Jefe Pez")
	self:SetBossTitle(bossData.title or "Monstruo de las Profundidades")
	self:SetIsDead(false)
	self:SetInSecondPhase(false)
	self:SetIsFlying(false)
	self:SetIsShootingLava(false)

	self.NextJump = CurTime() + 0.6
	self.NextAttack = CurTime() + 0.8
	self.NextSpecialAttack = CurTime() + 2.0
	self.NextSound = CurTime() + 1.2
	self.NextWiggle = CurTime() + 0.1
	self.RotMultiplier = 1

	-- Tabla de seguimiento de esbirros/sub-peces invocados por este jefe
	self.SummonedMinions = {}
	self.SummonerDeadSince = nil

	-- Probabilidad de soltar sub-peces al recibir daño (bosses tipo piraña)
	self.NextDamageSpawnCheck = 0

	-- Efecto dramático de aparición en el agua
	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetScale(4.0)
	util.Effect("watersplash", ed)
	self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 95, 75)
	self:EmitSound("npc/antlion/antlion_preattack" .. math.random(1, 3) .. ".wav", 95, 70)
	util.ScreenShake(self:GetPos(), 5, 10, 1.0, 800)
end

function ENT:SetBossTarget(ply)
	self.Target = ply
end

function ENT:OnTakeDamage(dmginfo)
	if self.IsDead then
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:ApplyForceCenter(dmginfo:GetDamageForce() * 0.3)
		end
		local ed = EffectData()
		ed:SetOrigin(dmginfo:GetDamagePosition())
		ed:SetNormal(dmginfo:GetDamageForce():GetNormalized())
		util.Effect("BloodImpact", ed)
		return
	end

	local dmg = dmginfo:GetDamage()
	local newHp = math.max(0, self:Health() - dmg)
	self:SetHealth(newHp)
	self:SetBossHealth(newHp)

	self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 80, math.random(80, 105))

	local ed = EffectData()
	ed:SetOrigin(dmginfo:GetDamagePosition())
	ed:SetNormal(dmginfo:GetDamageForce():GetNormalized())
	util.Effect("BloodImpact", ed)

	-- Retroalimentación visual de dolor
	self:SetColor(Color(255, 50, 50))
	timer.Simple(0.12, function()
		if IsValid(self) and not self.IsDead then
			if self:GetInSecondPhase() then
				self:SetColor(Color(255, 140, 140))
			else
				self:SetColor(Color(255, 255, 255))
			end
		end
	end)

	-- Comprobar transición a SEGUNDA FASE (50% HP) - Reverse Engineering: BowheadWhale / Piranha _inSecondPhase
	local maxHp = self:GetMaxBossHealth()
	if newHp <= (maxHp * 0.5) and not self:GetInSecondPhase() then
		self:EnterSecondPhase()
	end

	-- Sub-peces al recibir daño: Pirañas y Ballenas sueltan mini-peces agresivos al ser golpeados
	local bossType = self:GetBossType()
	if (bossType == 8 or bossType == 10 or bossType == 11) and newHp > 0 then
		if CurTime() >= (self.NextDamageSpawnCheck or 0) then
			self.NextDamageSpawnCheck = CurTime() + 2.5
			-- 30% de probabilidad de soltar 1-2 sub-peces al recibir daño
			if math.random(100) <= 30 then
				self:SpawnDamageSubFish(math.random(1, 2))
			end
		end
	end

	if newHp <= 0 then
		self:Die(dmginfo)
	end
end

-- SEGUNDA FASE DE JEFE (Furia, Habilidades Especiales, Vuelo y Lava)
function ENT:EnterSecondPhase()
	self:SetInSecondPhase(true)
	self:SetColor(Color(255, 140, 140))

	-- Grito de furia y terremoto
	self:EmitSound("npc/antlion/antlion_growl1.wav", 100, 65)
	self:EmitSound("ambient/explosions/explode_4.wav", 90, 85)
	util.ScreenShake(self:GetPos(), 8, 16, 2.0, 1500)

	local bossType = self:GetBossType()
	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetScale(4.5)
	util.Effect("watersplash", ed)

	for _, p in ipairs(player.GetAll()) do
		TrueFishNotify(p, "¡" .. string.upper(self:GetBossName()) .. " HA ENTRADO EN FASE DE FURIA!")
	end

	-- Efectos y habilidades según el tipo de jefe
	if bossType == 10 or bossType == 11 then
		-- Bowhead Whale / Mutated Whale: Lanzar salva de lava inicial inmediata y volar
		self:ShootLava(6)
		self:WhaleFly()
	elseif bossType == 8 then
		-- Piraña Gigante: Vomitar esbirros iniciales inmediatos
		self:SpawnSummons(4)
	elseif bossType == 9 or bossType == 12 then
		-- Tiburón Duende / Tiburón Azul: Embestida veloz hacia el objetivo
		local phys = self:GetPhysicsObject()
		if IsValid(phys) and IsValid(self.Target) then
			local dir = (self.Target:GetPos() - self:GetPos()):GetNormalized()
			phys:SetVelocity(dir * 550 + Vector(0, 0, 320))
		end
	elseif bossType == 19 then
		-- Cangrejo Araña
		self:SpiderCrabAttack()
	elseif bossType == 20 then
		-- Pez Globo Gigante
		self:PufferSpikesBurst(10)
	elseif bossType == 21 then
		-- Atún Colosal
		self:TunaTorpedoDash()
	elseif bossType == 22 then
		-- Bing Bong
		self:BingBongGlitch()
	elseif bossType == 23 then
		-- Albatros Gigante
		self:AlbatrossDiveBomb()
	end
end

-- HABILIDAD DE BALLENA: DISPARO DE LAVA (Reverse Engineering: BowheadWhale::ShootLava)
function ENT:ShootLava(count)
	count = count or 5
	self:SetIsShootingLava(true)

	self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 90, 70)
	self:EmitSound("npc/antlion/antlion_pounce1.wav", 95, 60)

	local target = self.Target
	local targetPos = (IsValid(target) and target:Alive()) and target:EyePos() or (self:GetPos() + self:GetForward() * 500 + Vector(0, 0, 100))

	for i = 1, count do
		timer.Simple((i - 1) * 0.22, function()
			if not IsValid(self) or self.IsDead then return end
			local mouthPos = self:GetPos() + self:GetForward() * 70 + Vector(0, 0, 30)

			local lava = ents.Create("ent_whale_lava")
			if IsValid(lava) then
				lava:SetPos(mouthPos)
				lava:SetAngles(self:GetAngles())
				lava.Owner = self
				lava.Damage = math.floor(self.Damage * 1.3)
				lava:Spawn()

				local phys = lava:GetPhysicsObject()
				if IsValid(phys) then
					local spread = VectorRand() * 60
					local dir = ((targetPos + spread) - mouthPos):GetNormalized()
					local speed = math.Clamp(mouthPos:Distance(targetPos) * 1.6 + 350, 450, 1100)
					phys:SetVelocity(dir * speed + Vector(0, 0, 180))
				end

				self:EmitSound("ambient/fire/mtov_flame2.wav", 85, math.random(90, 110))
			end
		end)
	end

	timer.Simple(count * 0.25, function()
		if IsValid(self) then
			self:SetIsShootingLava(false)
		end
	end)
end

-- HABILIDAD DE BALLENA: VUELO / SALTO MASIVO AÉREO (Reverse Engineering: BowheadWhale::Fly)
function ENT:WhaleFly()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	self:SetIsFlying(true)
	phys:Wake()

	local target = self.Target
	local targetPos = (IsValid(target) and target:Alive()) and target:GetPos() or (self:GetPos() + self:GetForward() * 400)
	local dir = (targetPos - self:GetPos()):GetNormalized()

	local inPhase2 = self:GetInSecondPhase()
	local flyUpForce = inPhase2 and 620 or 450
	local flyFwdForce = inPhase2 and 480 or 340

	phys:SetVelocity(dir * flyFwdForce + Vector(0, 0, flyUpForce))
	phys:AddAngleVelocity(Vector(math.random(-150, 150), math.random(-150, 150), math.random(-200, 200)))

	self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 95, 60)
	self:EmitSound("npc/antlion/antlion_pounce" .. math.random(1, 2) .. ".wav", 95, 65)

	timer.Simple(2.5, function()
		if IsValid(self) then
			self:SetIsFlying(false)
		end
	end)
end

-- HABILIDAD DE PIRAÑA: GENERAR ESBIRROS / MINIONS (Reverse Engineering: Piranha::SpawnSummons)
function ENT:SpawnSummons(count)
	count = count or 3
	local target = self.Target
	local targetPos = (IsValid(target) and target:Alive()) and target:GetPos() or (self:GetPos() + self:GetForward() * 300)

	self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 90, 95)
	self:EmitSound("npc/barnacle/barnacle_die1.wav", 88, 120)

	for i = 1, count do
		timer.Simple((i - 1) * 0.25, function()
			if not IsValid(self) or self.IsDead then return end
			local spawnPos = self:GetPos() + self:GetForward() * 45 + Vector(0, 0, 15)

			local mini = ents.Create("ent_angry_fish")
			if IsValid(mini) then
				mini.FishModel = "models/fishing/fish_clownfish.mdl"
				mini.FishID = FISH_DAMSELFISH
				mini:SetPos(spawnPos)
				mini:SetAngles(self:GetAngles())
				mini:Spawn()
				mini:SetColor(Color(255, 60, 60))
				mini.BossParent = self -- Referencia al jefe padre para despawn sincronizado
				if IsValid(target) then
					mini:SetAngryTarget(target)
				end

				-- Registrar el esbirro en la tabla de seguimiento del jefe
				self.SummonedMinions = self.SummonedMinions or {}
				table.insert(self.SummonedMinions, mini)

				local physM = mini:GetPhysicsObject()
				if IsValid(physM) then
					local spread = VectorRand() * 50
					local dir = ((targetPos + spread) - spawnPos):GetNormalized()
					physM:SetVelocity(dir * 380 + Vector(0, 0, 180))
					physM:AddAngleVelocity(Vector(math.random(-400, 400), math.random(-400, 400), math.random(-400, 400)))
				end

				-- Efecto de sangre / vómito
				local ed = EffectData()
				ed:SetOrigin(spawnPos)
				ed:SetScale(1.8)
				util.Effect("BloodImpact", ed)
			end
		end)
	end
end

-- SUB-PECES AL RECIBIR DAÑO: Sueltan peces agresivos cuando el jefe es golpeado (Reverse Engineering: Piranha::OnDamageSubSpawn)
function ENT:SpawnDamageSubFish(count)
	count = count or 1
	local target = self.Target
	local targetPos = (IsValid(target) and target:Alive()) and target:GetPos() or (self:GetPos() + self:GetForward() * 200)

	self:EmitSound("npc/barnacle/barnacle_die1.wav", 80, 130)

	for i = 1, count do
		local spawnPos = self:GetPos() + VectorRand() * 35 + Vector(0, 0, 10)
		local mini = ents.Create("ent_angry_fish")
		if IsValid(mini) then
			mini.FishModel = "models/fishing/fish_clownfish.mdl"
			mini.FishID = FISH_DAMSELFISH
			mini:SetPos(spawnPos)
			mini:SetAngles(self:GetAngles() + Angle(0, math.random(-90, 90), 0))
			mini:Spawn()
			mini:SetColor(Color(255, 90, 40))
			mini.BossParent = self
			if IsValid(target) then
				mini:SetAngryTarget(target)
			end

			self.SummonedMinions = self.SummonedMinions or {}
			table.insert(self.SummonedMinions, mini)

			local physM = mini:GetPhysicsObject()
			if IsValid(physM) then
				local spread = VectorRand() * 40
				local dir = ((targetPos + spread) - spawnPos):GetNormalized()
				physM:SetVelocity(dir * 320 + Vector(0, 0, 200))
				physM:AddAngleVelocity(Vector(math.random(-350, 350), math.random(-350, 350), math.random(-350, 350)))
			end

			local ed = EffectData()
			ed:SetOrigin(spawnPos)
			ed:SetScale(1.5)
			util.Effect("BloodImpact", ed)
		end
	end
end

-- HABILIDAD DE CANGREJO ARAÑA: EMBESTIDA Y CRÍAS (bossType 19)
function ENT:SpiderCrabAttack()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end
	local target = self.Target
	local targetPos = (IsValid(target) and target:Alive()) and target:GetPos() or (self:GetPos() + self:GetForward() * 300)
	local dir = (targetPos - self:GetPos()):GetNormalized()

	phys:SetVelocity(dir * 580 + Vector(0, 0, 320))
	self:EmitSound("npc/antlion/antlion_pounce" .. math.random(1, 2) .. ".wav", 90, 75)
	util.ScreenShake(self:GetPos(), 6, 12, 1.2, 800)

	if #self.SummonedMinions < 4 and math.random(100) <= 50 then
		local spawnPos = self:GetPos() + VectorRand() * 40 + Vector(0, 0, 15)
		local mini = ents.Create("ent_angry_fish")
		if IsValid(mini) then
			mini.FishModel = "models/fishing/fish_rockcrab.mdl"
			mini.FishID = FISH_ROCKCRAB
			mini:SetPos(spawnPos)
			mini:SetAngles(self:GetAngles())
			mini:Spawn()
			mini:SetColor(Color(255, 120, 120))
			mini.BossParent = self
			if IsValid(target) then mini:SetAngryTarget(target) end
			table.insert(self.SummonedMinions, mini)
		end
	end
end

-- HABILIDAD DE PEZ GLOBO GIGANTE: SALVA RADIAL DE PÚAS (bossType 20)
function ENT:PufferSpikesBurst(count)
	count = count or 8
	self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 95, 80)
	self:EmitSound("npc/antlion/antlion_shoot1.wav", 95, 85)

	local myPos = self:GetPos() + Vector(0, 0, 20)
	local step = (2 * math.pi) / count
	for i = 1, count do
		local angle = (i - 1) * step
		local dir = Vector(math.cos(angle), math.sin(angle), math.Rand(0.15, 0.45)):GetNormalized()

		local spike = ents.Create("ent_whale_lava")
		if IsValid(spike) then
			spike:SetPos(myPos + dir * 30)
			spike:SetAngles(dir:Angle())
			spike.Owner = self
			spike.Damage = math.floor(self.Damage * 0.9)
			spike:Spawn()

			spike:SetColor(Color(200, 255, 40, 255))
			spike:SetMaterial("models/shiny")

			local phys = spike:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity(dir * math.Rand(500, 750) + Vector(0, 0, 100))
			end
		end
	end
end

-- HABILIDAD DE ATÚN COLOSAL: TORPEDO DE ALTA MAR (bossType 21)
function ENT:TunaTorpedoDash()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end
	local target = self.Target
	local targetPos = (IsValid(target) and target:Alive()) and target:GetPos() or (self:GetPos() + self:GetForward() * 500)
	local dir = (targetPos - self:GetPos()):GetNormalized()

	phys:SetVelocity(dir * 880 + Vector(0, 0, 160))
	self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 95, 110)
	self:EmitSound("npc/fast_zombie/wake1.wav", 90, 90)

	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetScale(3.0)
	util.Effect("watersplash", ed)
end

-- HABILIDAD DE BING BONG: TELETRANSPORTE Y FALLA DIMENSIONAL (bossType 22)
function ENT:BingBongGlitch()
	local target = self.Target
	local targetPos = (IsValid(target) and target:Alive()) and target:GetPos() or self:GetPos()

	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetScale(2.5)
	util.Effect("cball_explode", ed)
	self:EmitSound("ambient/energy/zap" .. math.random(1, 3) .. ".wav", 95, 115)
	self:EmitSound("ambient/levels/citadel/strange_talk" .. math.random(1, 2) .. ".wav", 90, 100)

	local randomOffset = Vector(math.Rand(-180, 180), math.Rand(-180, 180), math.Rand(30, 90))
	local newPos = targetPos + randomOffset
	self:SetPos(newPos)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		local dir = (targetPos - newPos):GetNormalized()
		phys:SetVelocity(dir * 500 + Vector(0, 0, 120))
	end

	local ed2 = EffectData()
	ed2:SetOrigin(newPos)
	ed2:SetScale(2.5)
	util.Effect("cball_explode", ed2)
	util.ScreenShake(newPos, 7, 14, 1.2, 700)
end

-- HABILIDAD DE ALBATROS GIGANTE: PICADO AÉREO LETAL (bossType 23)
function ENT:AlbatrossDiveBomb()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	self:SetIsFlying(true)
	phys:Wake()

	phys:SetVelocity(Vector(0, 0, 680) + self:GetForward() * 250)
	self:EmitSound("npc/antlion/antlion_growl" .. math.random(1, 2) .. ".wav", 95, 130)
	self:EmitSound("ambient/wind/wind_hit1.wav", 90, 80)

	timer.Simple(1.2, function()
		if not IsValid(self) or self.IsDead then return end
		local p = self:GetPhysicsObject()
		if not IsValid(p) then return end

		local target = self.Target
		local targetPos = (IsValid(target) and target:Alive()) and target:GetPos() or (self:GetPos() - Vector(0, 0, 300))
		local diveDir = (targetPos - self:GetPos()):GetNormalized()

		p:SetVelocity(diveDir * 920 + Vector(0, 0, -200))
		self:EmitSound("ambient/wind/wind_hit2.wav", 95, 100)
		self:EmitSound("npc/antlion/antlion_pounce1.wav", 95, 110)

		timer.Simple(1.5, function()
			if IsValid(self) then
				self:SetIsFlying(false)
			end
		end)
	end)
end

-- SECUENCIA DE MUERTE CINEMÁTICA CON TROFEO Y EXPLOSIÓN (Reverse Engineering: BossManager::BossExplosion / OnDeath)
function ENT:Die(dmginfo)
	if self.IsDead then return end
	self.IsDead = true
	self:SetIsDead(true)
	self:SetBossHealth(0)

	local killer = dmginfo:GetAttacker()
	local ply = (IsValid(killer) and killer:IsPlayer()) and killer or self.Target

	-- Sonido épico de muerte de jefe y efectos cinemáticos
	self:EmitSound("npc/zombie/zombie_die" .. math.random(1, 3) .. ".wav", 100, 55)
	self:EmitSound("ambient/explosions/explode_4.wav", 95, 80)
	util.ScreenShake(self:GetPos(), 9, 18, 2.0, 1500)

	for i = 1, 6 do
		local ed = EffectData()
		ed:SetOrigin(self:GetPos() + Vector(math.random(-40, 40), math.random(-40, 40), math.random(10, 45)))
		ed:SetScale(3.0)
		util.Effect("BloodImpact", ed)
		util.Effect("watersplash", ed)
	end

	-- MATAR TODOS LOS ESBIRROS / SUB-PECES CON EXPLOSIÓN DE CONFETI AL MORIR EL JEFE
	self:KillAllMinionsWithConfetti()

	-- Recompensa monetaria y anuncio
	if IsValid(ply) and ply:IsPlayer() then
		local reward = self.Reward or 1800
		TrueFishGiveMoney(ply, reward)
		TrueFishNotify(ply, "¡HAS DERROTADO A " .. string.upper(self:GetBossName()) .. "!")
		TrueFishNotify(ply, "Recompensa de combate obtenida: $" .. reward)
		ply:EmitSound("garrysmod/save_load1.wav", 85, 100)
	end

	-- Generar TROFEO FÍSICO DE JEFE coleccionable (Reverse Engineering: BossManager::SpawnBossTrophy)
	local trophyPos = self:GetPos() + Vector(0, 0, 35)
	local trophy = ents.Create("ent_boss_trophy")
	if IsValid(trophy) then
		trophy:SetPos(trophyPos)
		trophy:SetAngles(Angle(0, math.random(0, 360), 0))
		trophy:SetRewardValue(math.floor(self.Reward * 0.5))
		trophy:SetBossName(self:GetBossName())
		trophy:Spawn()

		local physT = trophy:GetPhysicsObject()
		if IsValid(physT) then
			physT:SetVelocity(Vector(math.random(-60, 60), math.random(-60, 60), 160))
			physT:AddAngleVelocity(Vector(math.random(-150, 150), math.random(-150, 150), math.random(-200, 200)))
		end
	end

	-- Transición a cadáver físico inerte que flota y se balancea
	self:SetColor(Color(140, 140, 150))
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(45)
		phys:SetBuoyancyRatio(0.9)
		phys:SetDamping(0.35, 0.45)
		local force = dmginfo:GetDamageForce() * 0.35
		phys:SetVelocity(force + Vector(0, 0, 75))
		phys:AddAngleVelocity(Vector(math.random(-180, 180), math.random(-180, 180), math.random(-250, 250)))
	end

	SafeRemoveEntityDelayed(self, 180)
end

-- MATAR TODOS LOS ESBIRROS CON EXPLOSIÓN DE CONFETI (cuando el jefe muere o despawnea)
function ENT:KillAllMinionsWithConfetti()
	if not self.SummonedMinions then return end

	for _, minion in ipairs(self.SummonedMinions) do
		if IsValid(minion) then
			-- Explosión de confeti en la posición del esbirro
			local ed = EffectData()
			ed:SetOrigin(minion:GetPos())
			ed:SetScale(1.2)
			util.Effect("truefish_confetti", ed)

			minion:EmitSound("garrysmod/balloon_pop.wav", 80, math.random(100, 120))
			SafeRemoveEntity(minion)
		end
	end

	self.SummonedMinions = {}
end

-- DESPAWN DEL JEFE CON EXPLOSIÓN DE CONFETI (cuando el invocador muere por 10 segundos)
function ENT:DespawnWithConfetti()
	if self.IsDead then return end
	self.IsDead = true
	self:SetIsDead(true)
	self:SetBossHealth(0)

	-- Gran explosión de confeti en la posición del jefe
	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetScale(2.5)
	util.Effect("truefish_confetti", ed)

	-- Sonido festivo de desaparición
	self:EmitSound("garrysmod/balloon_pop.wav", 95, 85)
	self:EmitSound("ambient/explosions/explode_4.wav", 75, 120)

	-- Notificar a todos los jugadores
	for _, p in ipairs(player.GetAll()) do
		TrueFishNotify(p, "¡" .. self:GetBossName() .. " ha desaparecido porque su invocador murió!")
	end

	-- Matar todos los esbirros con confeti también
	self:KillAllMinionsWithConfetti()

	-- Eliminar el jefe
	SafeRemoveEntity(self)
end

function ENT:BiteTarget(target)
	if self.IsDead then return end
	if not IsValid(target) or not target:Alive() then return end
	if CurTime() < self.NextAttack then return end

	local inPhase2 = self:GetInSecondPhase()
	local attackCooldown = inPhase2 and 0.55 or 0.85
	self.NextAttack = CurTime() + attackCooldown

	local dmg = DamageInfo()
	dmg:SetAttacker(self)
	dmg:SetInflictor(self)
	dmg:SetDamage(self.Damage or 25)
	dmg:SetDamageType(DMG_SLASH)
	target:TakeDamageInfo(dmg)

	target:ViewPunch(Angle(math.random(-14, 14), math.random(-14, 14), math.random(-10, 10)))
	self:EmitSound("npc/headcrab/headcrab_bite1.wav", 88, math.random(75, 90))
	self:EmitSound("npc/antlion/antlion_bite" .. math.random(1, 2) .. ".wav", 88, math.random(75, 90))

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		local backDir = (self:GetPos() - target:GetPos()):GetNormalized()
		phys:SetVelocity(backDir * 230 + Vector(0, 0, 130))
	end
end

function ENT:PhysicsCollide(data, phys)
	if self.IsDead then
		if data.Speed > 100 then
			self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 70, math.random(70, 90))
		end
		return
	end

	if data.HitEntity and IsValid(data.HitEntity) and data.HitEntity:IsPlayer() then
		self:BiteTarget(data.HitEntity)
	elseif data.Speed > 130 then
		self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 70, math.random(70, 90))
	end
end

function ENT:Think()
	if self.IsDead then
		self:NextThink(CurTime() + 1.0)
		return true
	end

	-- TEMPORIZADOR DE MUERTE DEL INVOCADOR: Si el jugador que invocó al jefe muere,
	-- después de 10 segundos el jefe desaparece con explosión de confeti
	if IsValid(self.Summoner) then
		if not self.Summoner:Alive() then
			-- El invocador está muerto, empezar a contar
			if not self.SummonerDeadSince then
				self.SummonerDeadSince = CurTime()
			end

			local deadTime = CurTime() - self.SummonerDeadSince
			if deadTime >= 10.0 then
				-- ¡10 segundos muerto! Despawnear con confeti
				self:DespawnWithConfetti()
				return true
			end
		else
			-- El invocador revivió, resetear el temporizador
			self.SummonerDeadSince = nil
		end
	else
		-- El invocador se desconectó del servidor: despawnear inmediatamente
		if self.Summoner ~= nil then
			self:DespawnWithConfetti()
			return true
		end
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end

	-- Buscar objetivo más cercano
	if not IsValid(self.Target) or not self.Target:Alive() then
		local nearest, nearestDist = nil, 9999999
		for _, p in ipairs(player.GetAll()) do
			if IsValid(p) and p:Alive() then
				local d = self:GetPos():DistToSqr(p:GetPos())
				if d < nearestDist then
					nearestDist = d
					nearest = p
				end
			end
		end
		self.Target = nearest
	end

	local ctime = CurTime()
	local inPhase2 = self:GetInSecondPhase()
	local bossType = self:GetBossType()

	-- ANIMACIÓN PROCEDURAL DE NADO FÍSICO (Reverse Engineering: Fish::UpdateMovement motor torque wiggle)
	if ctime >= self.NextWiggle and IsValid(phys) then
		self.NextWiggle = ctime + (inPhase2 and 0.08 or 0.14)
		self.RotMultiplier = -self.RotMultiplier
		local wiggleForce = inPhase2 and 350 or 220
		phys:AddAngleVelocity(Vector(0, 0, self.RotMultiplier * wiggleForce))
	end

	if IsValid(self.Target) and self.Target:Alive() then
		local targetPos = self.Target:GetPos()
		local myPos = self:GetPos()
		local dist = myPos:Distance(targetPos)

		-- Ataque de mordisco a corta distancia
		local biteRange = (bossType == 10 or bossType == 11 or bossType == 17 or bossType == 18) and 160 or 95
		if dist < biteRange then
			self:BiteTarget(self.Target)
		end

		-- ATAQUES ESPECIALES DE FASE 2
		if inPhase2 and ctime >= self.NextSpecialAttack then
			if bossType == 10 or bossType == 11 then
				-- Ballena: alternar entre Disparo de Lava y Vuelo Masivo
				self.NextSpecialAttack = ctime + math.Rand(3.5, 5.5)
				if math.random(1, 2) == 1 then
					self:ShootLava(math.random(4, 6))
				else
					self:WhaleFly()
				end
			elseif bossType == 8 then
				-- Piraña: invocar esbirros periódicos
				self.NextSpecialAttack = ctime + math.Rand(4.0, 6.5)
				self:SpawnSummons(math.random(2, 3))
			elseif bossType == 19 then
				-- Cangrejo Araña: salto pesado y posibles crías
				self.NextSpecialAttack = ctime + math.Rand(3.0, 5.0)
				self:SpiderCrabAttack()
			elseif bossType == 20 then
				-- Pez Globo: salva radial de púas
				self.NextSpecialAttack = ctime + math.Rand(3.5, 5.5)
				self:PufferSpikesBurst(math.random(8, 12))
			elseif bossType == 21 then
				-- Atún Colosal: torpedo dash supersónico
				self.NextSpecialAttack = ctime + math.Rand(2.5, 4.0)
				self:TunaTorpedoDash()
			elseif bossType == 22 then
				-- Bing Bong: teletransporte anómalo y distorsión
				self.NextSpecialAttack = ctime + math.Rand(3.0, 5.0)
				self:BingBongGlitch()
			elseif bossType == 23 then
				-- Albatros: picado aéreo
				self.NextSpecialAttack = ctime + math.Rand(4.0, 6.0)
				self:AlbatrossDiveBomb()
			else
				-- Gammelgäddan / Tiburón Duende / Otros: embestida de velocidad extrema
				self.NextSpecialAttack = ctime + math.Rand(2.5, 4.0)
				if IsValid(phys) then
					local dashDir = (targetPos - myPos):GetNormalized()
					phys:SetVelocity(dashDir * 650 + Vector(0, 0, 180))
					self:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 90, 85)
				end
			end
		end

		-- SALTO Y EMBESTIDA COMBATIENTE (Reverse Engineering: AttackingFish::AttackTarget)
		if ctime >= self.NextJump and IsValid(phys) then
			local jumpRate = inPhase2 and math.Rand(0.8, 1.4) or math.Rand(1.2, 2.0)
			self.NextJump = ctime + jumpRate

			local dir = (targetPos - myPos):GetNormalized()
			local jumpStrength = math.Clamp(dist * 2.8 + (inPhase2 and 360 or 260), 340, inPhase2 and 850 or 680)
			local verticalBoost = math.Clamp(280 + (targetPos.z - myPos.z) * 1.5, 180, inPhase2 and 600 or 450)

			phys:SetVelocity(dir * jumpStrength + Vector(0, 0, verticalBoost))
			phys:AddAngleVelocity(Vector(math.random(-250, 250), math.random(-250, 250), math.random(-350, 350)))

			self:EmitSound("npc/antlion/antlion_pounce" .. math.random(1, 2) .. ".wav", 85, inPhase2 and 65 or 80)

			if self:WaterLevel() > 0 then
				local ed = EffectData()
				ed:SetOrigin(myPos)
				ed:SetScale(inPhase2 and 3.5 or 2.2)
				util.Effect("watersplash", ed)
			end
		end
	end

	-- Sonidos periódicos de furia
	if ctime >= self.NextSound then
		self.NextSound = ctime + (inPhase2 and math.Rand(2.0, 3.8) or math.Rand(3.5, 6.0))
		local pitch = inPhase2 and math.random(60, 75) or math.random(70, 85)
		self:EmitSound("npc/antlion/antlion_growl" .. math.random(1, 4) .. ".wav", 85, pitch)
	end

	self:NextThink(CurTime() + 0.1)
	return true
end
