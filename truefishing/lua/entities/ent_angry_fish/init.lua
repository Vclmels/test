AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	if not self.FishModel or self.FishModel == "" then
		self.FishModel = "models/fishing/fish_bass.mdl"
	end

	self:SetModel(self.FishModel)

	-- Escalar el modelo para que sea claramente visible y fácil de disparar
	local scale = 1.3
	self:SetModelScale(scale, 0)

	-- Usar física real del modelo (.phy) para que coincida con colisiones del motor y Gravity Gun
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then
		local mins, maxs = self:GetModelBounds()
		if mins and maxs then
			self:PhysicsInitBox(mins * scale, maxs * scale)
		else
			self:PhysicsInitBox(Vector(-10, -5, -5), Vector(10, 5, 5))
		end
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		phys = self:GetPhysicsObject()
	end

	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:Wake()
		phys:SetMaterial("flesh")
		phys:SetMass(15)
		phys:SetBuoyancyRatio(0.4)
		phys:SetDamping(0.2, 0.2)
	end

	if self.IsDead then
		self:ApplyDeadPhysics()
	end

	self:SetMaxHealth(35)
	self:SetHealth(35)

	if self.IsDead then
		self:SetColor(Color(205, 205, 215, 255))
		return
	end

	self.NextJump = CurTime() + 1.5
	self.NextAttack = CurTime() + 2.0
	self.AttackGraceEnd = CurTime() + 2.0 -- gracia inicial: sin daño mientras sube y baja del salto
	self.FirstJump = true -- el primer salto de la IA es un gran salto hacia arriba
	self.NextSound = CurTime() + 1.0

	-- Seguimiento de la muerte del jugador: si este pez mata a un jugador,
	-- desaparece con confeti pequeño después de 10 segundos (mecánica de jefes)
	self.KilledPlayer = nil
	self.KilledPlayerTime = nil

	self:SetColor(Color(255, 120, 120)) -- Tinte rojizo de pez enfurecido
end

-- IMPORTANTE: la Gravity Gun del motor (C++ de HL2, CanPickupObject -> VPhysicsIsFlesh)
-- se NIEGA a levantar cualquier objeto cuyo material fisico sea de carne (flesh,
-- bloodyflesh, alienflesh, antlion), sin importar lo que devuelvan los hooks de Lua.
-- El modelo .phy del pez trae surfaceprop "flesh", asi que al morir se cambia a un
-- material blando que no sea carne para poder agarrarlo con clic derecho.
ENT.DeadPhysMaterial = "watermelon"

function ENT:ApplyDeadPhysics()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end
	phys:EnableMotion(true)
	phys:SetMaterial(self.DeadPhysMaterial)
	phys:SetMass(8)
	phys:SetDamping(0.3, 0.4)
	phys:Wake()
end

function ENT:TraceAttack(dmginfo, tr, cmd)
	self:TakeDamageInfo(dmginfo)
end

function ENT:SetAngryTarget(ply)
	self.Target = ply
end

function ENT:OnTakeDamage(dmginfo)
	if self.IsDead then
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:ApplyForceCenter(dmginfo:GetDamageForce() * 0.4)
		end
		local ed = EffectData()
		ed:SetOrigin(dmginfo:GetDamagePosition())
		ed:SetNormal(dmginfo:GetDamageForce():GetNormalized())
		util.Effect("BloodImpact", ed)
		self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 70, math.random(110, 130))
		return
	end

	local dmg = dmginfo:GetDamage()
	self:SetHealth(self:Health() - dmg)

	self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 75, math.random(115, 135))

	local ed = EffectData()
	ed:SetOrigin(dmginfo:GetDamagePosition())
	ed:SetNormal(dmginfo:GetDamageForce():GetNormalized())
	util.Effect("BloodImpact", ed)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:ApplyForceCenter(dmginfo:GetDamageForce() * 0.4)
	end

	if self:Health() <= 0 and not self.IsDead then
		self:Die(dmginfo)
	end
end

function ENT:Die(dmginfo)
	self.IsDead = true
	self:SetNW2Bool("IsDead", true)
	self.Target = nil

	self:EmitSound("physics/flesh/flesh_bloody_break.wav", 80, math.random(95, 110))

	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetScale(1.5)
	util.Effect("BloodImpact", ed)

	util.Decal("Blood", self:GetPos() + Vector(0, 0, 10), self:GetPos() - Vector(0, 0, 50))

	-- Cambiar a tono pálido de cuerpo inerte
	self:SetColor(Color(205, 205, 215, 255))

	local attacker = dmginfo:GetAttacker()
	if IsValid(attacker) and attacker:IsPlayer() then
		TrueFishNotify(attacker, "¡Derrotaste al pez rabioso!")
		if self.CPPISetOwner then
			self:CPPISetOwner(attacker)
		end
	end

	-- Física de caída limp / cuerpo muerto
	self:ApplyDeadPhysics()

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then

		-- Impulso del impacto fatal y volteo de lado como pez muerto
		local force = dmginfo:GetDamageForce() * 0.35
		phys:SetVelocity(force + Vector(0, 0, 35))
		phys:AddAngleVelocity(Vector(math.random(-250, 250), math.random(-250, 250), math.random(-350, 350)))
	end

	-- Desaparece después de 90 segundos si nadie lo recoge (se renueva si se sostiene)
	self.DespawnTime = CurTime() + 90
end

-- Interacción con Gravity Gun cuando está muerto
function ENT:GravGunOnPickedUp(ply)
	self.IsBeingHeld = true
	self.DespawnTime = CurTime() + 90
	if self.CPPISetOwner and IsValid(ply) then
		self:CPPISetOwner(ply)
	end
end

function ENT:GravGunOnDropped(ply)
	self.IsBeingHeld = false
	self.DespawnTime = CurTime() + 90
end

-- La recogida con E fue reemplazada: ahora el pez muerto se guarda pasando la
-- caja de almacenamiento por encima (ver ENT:Think en fish_container/init.lua).

function ENT:BiteTarget(target)
	if self.IsDead then return end
	if not IsValid(target) or not target:Alive() then return end
	if CurTime() < self.AttackGraceEnd then return end -- gracia inicial: sin daño al arrancar la pelea
	if CurTime() < self.NextAttack then return end

	self.NextAttack = CurTime() + 0.75

	local dmg = DamageInfo()
	dmg:SetAttacker(self)
	dmg:SetInflictor(self)
	dmg:SetDamage(math.random(10, 16))
	dmg:SetDamageType(DMG_SLASH)
	target:TakeDamageInfo(dmg)

	target:ViewPunch(Angle(math.random(-6, 6), math.random(-6, 6), math.random(-6, 6)))
	self:EmitSound("npc/headcrab/headcrab_bite1.wav", 80, math.random(100, 120))

	-- Empujar al pez hacia atrás levemente tras morder
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		local backDir = (self:GetPos() - target:GetPos()):GetNormalized()
		phys:SetVelocity(backDir * 180 + Vector(0, 0, 120))
	end
end

function ENT:PhysicsCollide(data, phys)
	if self.IsDead then
		if data.Speed > 100 then
			self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 65, math.random(85, 105))
		end
		return
	end

	if data.HitEntity and IsValid(data.HitEntity) and data.HitEntity:IsPlayer() then
		self:BiteTarget(data.HitEntity)
	elseif data.Speed > 130 then
		self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 65, math.random(85, 105))
	end
end

function ENT:Think()
	if self.IsDead then
		if self:IsPlayerHolding() or self.IsBeingHeld then
			self.DespawnTime = CurTime() + 90
		elseif self.DespawnTime and CurTime() >= self.DespawnTime then
			SafeRemoveEntity(self)
			return
		end

		local phys = self:GetPhysicsObject()
		if IsValid(phys) and phys:GetVelocity():LengthSqr() > 5 then
			phys:Wake()
		end
		self:NextThink(CurTime() + 0.5)
		return true
	end

	-- MECÁNICA DE JEFE APLICADA A PECES NORMALES:
	-- Si este pez mató a un jugador, desaparece con confeti pequeño después de 10 segundos.
	-- La muerte queda registrada y NO se reinicia aunque el jugador reaparezca antes.
	if self.KilledPlayerTime then
		if CurTime() - self.KilledPlayerTime >= 10.0 then
			self:DespawnWithConfetti()
			return true
		end
	end

	-- Si el jefe padre fue eliminado (murió o despawneó), este esbirro también muere con confeti
	if self.BossParent ~= nil and not IsValid(self.BossParent) then
		local ed = EffectData()
		ed:SetOrigin(self:GetPos())
		ed:SetScale(1.0)
		util.Effect("truefish_confetti", ed)
		self:EmitSound("garrysmod/balloon_pop.wav", 75, math.random(105, 125))
		SafeRemoveEntity(self)
		return true
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end

	-- Adquisición de objetivo
	if not IsValid(self.Target) or not self.Target:Alive() then
		local nearest, nearestDist = nil, 999999
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

	-- IA de salto frenético y persecución
	if IsValid(self.Target) and CurTime() >= self.NextJump then
		local myPos = self:GetPos()
		local targetPos = self.Target:EyePos() - Vector(0, 0, 15)
		local dist = myPos:Distance(targetPos)

		if dist < 1600 and IsValid(phys) then
			local jumpVel
			if self.FirstJump then
				-- Primer salto de la IA: GRAN SALTO HACIA ARRIBA, sin perseguir al jugador
				self.FirstJump = nil
				jumpVel = Vector(math.random(-60, 60), math.random(-60, 60), 640)
			else
				local dir = (targetPos - myPos):GetNormalized()
				local horizDist = Vector(targetPos.x - myPos.x, targetPos.y - myPos.y, 0):Length()

				-- Potencia de salto adaptativa
				local fwdSpeed = math.Clamp(horizDist * 1.6 + 200, 240, 520)
				local upSpeed = math.Clamp((targetPos.z - myPos.z) * 1.2 + 250, 220, 480)

				jumpVel = dir * fwdSpeed + Vector(0, 0, upSpeed)
			end
			phys:SetVelocity(jumpVel)

			-- Giros y aletazos frenéticos en el aire
			phys:AddAngleVelocity(Vector(math.random(-500, 500), math.random(-500, 500), math.random(-700, 700)))

			self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 3) .. ".wav", 75, math.random(95, 115))
		end

		self.NextJump = CurTime() + math.Rand(0.65, 1.15)
	end

	-- Ataque por proximidad continua si colisiona o está muy cerca del jugador
	if IsValid(self.Target) and CurTime() >= self.NextAttack then
		local dist = self:GetPos():Distance(self.Target:GetPos())
		local eyeDist = self:GetPos():Distance(self.Target:EyePos())
		if dist < 50 or eyeDist < 55 then
			self:BiteTarget(self.Target)
		end
	end

	self:NextThink(CurTime() + 0.05)
	return true
end

-- Registrar la muerte del jugador causada por este pez.
-- Se llama desde el hook PlayerDeath con el pez como atacante.
function ENT:OnKilledPlayer(victim)
	if self.IsDead then return end
	if self.KilledPlayerTime then return end -- ya registró una muerte, no reiniciar el temporizador

	self.KilledPlayer = victim
	self.KilledPlayerTime = CurTime()
end

-- Desaparición del pez con explosión de confeti MÁS PEQUEÑA Y REDUCIDA que la de los jefes
function ENT:DespawnWithConfetti()
	if self.IsDead then return end
	self.IsDead = true

	-- Confeti reducido (escala menor a la de los jefes, que usan 2.5)
	local ed = EffectData()
	ed:SetOrigin(self:GetPos())
	ed:SetScale(0.8)
	util.Effect("truefish_confetti", ed)

	self:EmitSound("garrysmod/balloon_pop.wav", 75, math.random(100, 120))

	SafeRemoveEntity(self)
end

-- Hook global: detecta cuándo un pez rabioso mata a un jugador y registra la muerte.
-- Así la acción se ejecuta correctamente sin depender del Think del pez ni del respawn.
hook.Add("PlayerDeath", "TrueFishing_AngryFish_KillCheck", function(victim, inflictor, attacker)
	if not IsValid(attacker) then return end
	if attacker:GetClass() ~= "ent_angry_fish" then return end

	attacker:OnKilledPlayer(victim)
end)
