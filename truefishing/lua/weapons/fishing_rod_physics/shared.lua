/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

if SERVER then
	AddCSLuaFile("shared.lua")
	util.AddNetworkString("rod_phys_Fishing")
	util.AddNetworkString("rod_phys_Pull")
	util.AddNetworkString("rod_phys_End")
	util.AddNetworkString("FishPoleStrength")
	util.AddNetworkString("rod_phys_Cast")
	util.AddNetworkString("rod_phys_CastAnim")
end

if CLIENT then
	SWEP.PrintName = "Fishing Rod (Physics based)"
	SWEP.Slot = 3
	SWEP.SlotPos = 3
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = false
end

SWEP.Author = "Tomasas"
SWEP.Instructions = "Left click to cast a line.\nRight click to try and catch a fish."
SWEP.Contact = ""
SWEP.Purpose = ""


//SWEP.AnimPrefix	 = "rpg"
SWEP.WorldModel = ""//"models/fishing/pole.mdl"
SWEP.ViewModel = "models/fishing/v_fishing_rod_cast.mdl"
SWEP.ViewModelFOV = 62
SWEP.UseHands = false

-- Ajuste de posición en primera persona (X: Der/Izq, Y: Adelante/Atrás, Z: Arriba/Abajo)
SWEP.ViewModelOffset = Vector(0, 0, -2) -- Modifica este Z para subir (+) o bajar (-) la caña y las manos

if CLIENT then
	local cv_z = CreateClientConVar("fishing_rod_offset_z", "-2", true, false, "Altura: negativo baja, positivo sube")
	local cv_x = CreateClientConVar("fishing_rod_offset_x", "0", true, false, "Horizontal: positivo derecha, negativo izquierda")
	local cv_y = CreateClientConVar("fishing_rod_offset_y", "0", true, false, "Profundidad: positivo adelante, negativo atras")

	function SWEP:GetViewModelPosition(pos, ang)
		local z = cv_z:GetFloat()
		local x = cv_x:GetFloat()
		local y = cv_y:GetFloat()

		pos = pos + ang:Right() * x
		pos = pos + ang:Forward() * y
		pos = pos + ang:Up() * z

		return pos, ang
	end

	local font = system.IsOSX() and "Trebuchet" or "Segoe UI"
	surface.CreateFont("SegoeUI_NormalSmallScaled", {
		font 		= font,
		size 		= 14,
		weight 		= 600,
		antialias 	= true
	})
end

SWEP.Category = "TrueFishing"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""

function SWEP:Initialize()
	self:SetWeaponHoldType("revolver")
	if CLIENT and self.Owner == LocalPlayer() then
		self.Owner.ReceivedFishingTip = true
		chat.AddText(Color(255,255,255), TrueFishLocal("fishing_rod_phys_tip"))
	end
end

function SWEP:DrawWorldModel()
	return true
end

function SWEP:Holster()
	if CLIENT then
		if LocalPlayer() == self.Owner then
			self.DrawFishing = nil
			self.CastAnimationEnd = nil
			self.IsHoldingReady = nil
			self.HoldingInHoldLoop = nil
			self.IsReelingAnim = nil
			self.WasFightingFish = nil
			self.HasPlayedReelReady = nil
			self.TFAnimSeq = nil
			self.TFAnimCycle = nil
			self.TFReelReadyDone = nil
			if IsValid(self.ClientHookModel) then
				self.ClientHookModel:Remove()
				self.ClientHookModel = nil
			end
			if IsValid(self.ClientFishModel) then
				self.ClientFishModel:Remove()
				self.ClientFishModel = nil
				self.CurrentFishMdl = nil
			end
		end
	end
	if SERVER then
		self.Owner.IsFishing = nil
		
		if IsValid(self.WeaponModel) then
			self.WeaponModel:Remove()
		end
		if IsValid(self.Hook) then
			self.Hook:Remove()
		end
		
	end
	return true
end

function SWEP:OnRemove()
	if CLIENT then
		if IsValid(self.ClientHookModel) then
			self.ClientHookModel:Remove()
			self.ClientHookModel = nil
		end
		if IsValid(self.ClientFishModel) then
			self.ClientFishModel:Remove()
			self.ClientFishModel = nil
			self.CurrentFishMdl = nil
		end
	end
	if SERVER then
		if IsValid(self.WeaponModel) then
			self.WeaponModel:Remove()
		end
		if IsValid(self.Hook) then
			self.Hook:Remove()
		end
	end
end

if CLIENT then
	hook.Remove("CalcView", "Fishing Rod Phys")
	if IsValid(LocalPlayer()) then
		LocalPlayer().ThirdViewPhys = nil
	end

	hook.Add("Think", "TrueFishingPhysicsCastView", function()
		local owner = LocalPlayer()
		if not IsValid(owner) then return end
		local wep = owner:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "fishing_rod_physics" then return end
		local vm = owner:GetViewModel()
		if not IsValid(vm) then return end

		if wep.CastAnimationEnd then
			if CurTime() >= wep.CastAnimationEnd then
				wep.CastAnimationEnd = nil
				local idle = vm:LookupSequence("idle")
				if idle >= 0 then
					vm:SendViewModelMatchingSequence(idle)
					vm:SetPlaybackRate(1)
					vm:SetCycle(0)
				end
			end
			return
		end

		-- Comprobar si el anzuelo ya fue lanzado o está en el agua o hay pez enganchado / capturado
		local isHookActive = wep:GetNW2Bool("IsHookActive", false) 
			or (wep:GetNW2Int("FishCaughtID", 0) > 0) 
			or (wep:GetNW2Int("HookedFishID", 0) > 0)

		if not isHookActive then
			if owner:KeyDown(IN_ATTACK2) then
				if not wep.IsHoldingReady then
					wep.IsHoldingReady = true
					wep.HoldingInHoldLoop = nil
					wep.CastHoldStart = CurTime()
					local readySeq = vm:LookupSequence("cast_ready")
					if readySeq >= 0 then
						local dur = vm:SequenceDuration(readySeq)
						wep.ReadyHoldEndTime = CurTime() + (dur > 0 and dur or 0.36)
						vm:SendViewModelMatchingSequence(readySeq)
						vm:SetPlaybackRate(1)
						vm:SetCycle(0)
					end
				elseif not wep.HoldingInHoldLoop then
					-- Esperar a que termine la animación de levantar la caña (frame 11)
					if CurTime() >= (wep.ReadyHoldEndTime or 0) then
						wep.HoldingInHoldLoop = true
						local holdSeq = vm:LookupSequence("cast_ready_hold")
						if holdSeq >= 0 then
							vm:SendViewModelMatchingSequence(holdSeq)
							vm:SetPlaybackRate(1)
							vm:SetCycle(0)
						end
					end
				else
					-- Mantener firmemente en cast_ready_hold por si el motor intenta forzar idle
					local holdSeq = vm:LookupSequence("cast_ready_hold")
					if holdSeq >= 0 and vm:GetSequence() ~= holdSeq then
						vm:SendViewModelMatchingSequence(holdSeq)
						vm:SetPlaybackRate(1)
						vm:SetCycle(0)
					end
				end
			elseif wep.IsHoldingReady then
				-- ¡Al soltar click derecho: LANZAR LA CAÑA (el anzuelo sale disparado)!
				local holdDuration = math.Clamp(CurTime() - (wep.CastHoldStart or CurTime()), 0.15, 1.2)
				local chargeRatio = holdDuration / 1.2
				wep.IsHoldingReady = nil
				wep.HoldingInHoldLoop = nil
				wep.CastHoldStart = nil

				net.Start("rod_phys_Cast")
				net.WriteFloat(chargeRatio)
				net.SendToServer()

				local castSeq = vm:LookupSequence("cast")
				if castSeq >= 0 then
					wep.CastAnimationEnd = CurTime() + 1.15
					vm:SendViewModelMatchingSequence(castSeq)
					vm:SetPlaybackRate(1)
					vm:SetCycle(0)
				end
				wep:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 65, 110)
			end
		else
			-- Si el anzuelo YA está afuera o en el agua, cancelar cualquier preparación de lanzamiento
			wep.IsHoldingReady = nil
			wep.HoldingInHoldLoop = nil
			wep.CastHoldStart = nil

			-- ANIMACIÓN DE CARRETE / CRANKING
			local isBringingFish = wep:GetNW2Int("HookedFishID", 0) > 0
			local isFishCaught = wep:GetNW2Int("FishCaughtID", 0) > 0
			if not isFishCaught then
				if owner:KeyDown(IN_ATTACK) then
					if not wep.IsReelingAnim then
						wep.IsReelingAnim = true
						wep:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 55, 140)
					end
					local reelSeq = vm:LookupSequence("reel_in_fish")
					if reelSeq >= 0 then
						if vm:GetSequence() ~= reelSeq then
							vm:SendViewModelMatchingSequence(reelSeq)
						end
						vm:SetPlaybackRate(0.85)
					end
					wep.WasFightingFish = true
				elseif isBringingFish then
					wep.IsReelingAnim = nil
					-- Si el usuario suelta el click izquierdo teniendo un pez enganchado,
					-- o cuando recién pica el pez:
					-- 1. Si no agarró todavía la palanca, reproduce 'reel_ready' (mano va a la palanca)
					-- 2. Una vez que la agarra, se queda en 'reel_hold' (agarrando la palanca)
					--    hasta que mantenga click o pesque el pez.
					local readySeq = vm:LookupSequence("reel_ready")
					local holdSeq = vm:LookupSequence("reel_hold")
					local curSeq = vm:GetSequence()

					if curSeq == readySeq then
						if vm:GetCycle() >= 0.95 and holdSeq >= 0 then
							vm:SendViewModelMatchingSequence(holdSeq)
							vm:SetPlaybackRate(1)
						end
					elseif curSeq ~= holdSeq then
						if readySeq >= 0 and not wep.HasPlayedReelReady then
							wep.HasPlayedReelReady = true
							vm:SendViewModelMatchingSequence(readySeq)
							vm:SetPlaybackRate(1.2)
						elseif holdSeq >= 0 then
							vm:SendViewModelMatchingSequence(holdSeq)
							vm:SetPlaybackRate(1)
						end
					end
					wep.WasFightingFish = true
				else
					wep.HasPlayedReelReady = nil
					if wep.WasFightingFish or wep.IsReelingAnim then
						wep.WasFightingFish = nil
						wep.IsReelingAnim = nil
						local idle = vm:LookupSequence("idle")
						if idle >= 0 and vm:GetSequence() ~= idle then
							vm:SendViewModelMatchingSequence(idle)
							vm:SetPlaybackRate(1)
							vm:SetCycle(0)
						end
					end
				end
			else
				wep.HasPlayedReelReady = nil
				if wep.WasFightingFish or wep.IsReelingAnim then
					wep.WasFightingFish = nil
					wep.IsReelingAnim = nil
					local idle = vm:LookupSequence("idle")
					if idle >= 0 and vm:GetSequence() ~= idle then
						vm:SendViewModelMatchingSequence(idle)
						vm:SetPlaybackRate(1)
						vm:SetCycle(0)
					end
				end
			end
		end
	end)

	-- =====================================================================
	-- FIX DARKRP: forzar la secuencia del viewmodel CADA FRAME.
	-- En Sandbox los SendViewModelMatchingSequence de "un solo disparo" del
	-- Think de arriba funcionan bien; en DarkRP el gamemode reinicia la
	-- secuencia del viewmodel entre frames, por eso las animaciones de tirar
	-- la caña y de girar la palanca no se reproducen. Se fuerza localmente
	-- con SetSequence justo antes de dibujar (PreDrawViewModel). El ciclo se
	-- lleva a mano para que no quede congelado aunque el motor lo resetee.
	-- =====================================================================
	local function TFAnimGetState(wep)
		if wep.CastAnimationEnd and CurTime() < wep.CastAnimationEnd then
			return "cast", 1, false
		end

		local isHookActive = wep:GetNW2Bool("IsHookActive", false)
			or (wep:GetNW2Int("FishCaughtID", 0) > 0)
			or (wep:GetNW2Int("HookedFishID", 0) > 0)

		if not isHookActive then
			if wep.IsHoldingReady then
				if wep.HoldingInHoldLoop then
					return "cast_ready_hold", 1, true
				end
				return "cast_ready", 1, false
			end
			return "idle", 1, true
		end

		if wep:GetNW2Int("FishCaughtID", 0) > 0 then
			return "idle", 1, true
		end

		if wep.IsReelingAnim then
			return "reel_in_fish", 0.85, true
		end

		if wep:GetNW2Int("HookedFishID", 0) > 0 then
			if not wep.TFReelReadyDone then
				return "reel_ready", 1.2, false
			end
			return "reel_hold", 1, true
		end

		return "idle", 1, true
	end

	hook.Add("PreDrawViewModel", "TrueFishing_Physics_VMAnim", function(vm, ply, wep)
		if not IsValid(ply) or ply ~= LocalPlayer() then return end
		if not IsValid(wep) or wep:GetClass() ~= "fishing_rod_physics" then return end
		if not IsValid(vm) then return end

		-- Resetear la transición de la palanca cuando ya no hay pez enganchado
		if wep:GetNW2Int("HookedFishID", 0) <= 0 then
			wep.TFReelReadyDone = nil
		end

		local seqName, rate, loopAnim = TFAnimGetState(wep)
		if not seqName then return end
		local seqID = vm:LookupSequence(seqName)
		if not seqID or seqID < 0 then return end

		local dur = vm:SequenceDuration(seqID)
		if not dur or dur <= 0 then dur = 1 end

		if wep.TFAnimSeq ~= seqID then
			wep.TFAnimSeq = seqID
			wep.TFAnimCycle = 0
		end

		wep.TFAnimCycle = (wep.TFAnimCycle or 0) + (FrameTime() * rate) / dur
		if wep.TFAnimCycle >= 1 then
			if loopAnim then
				wep.TFAnimCycle = wep.TFAnimCycle % 1
			else
				wep.TFAnimCycle = 1
				if seqName == "reel_ready" then
					wep.TFReelReadyDone = true
				end
			end
		end

		vm:SetSequence(seqID)
		vm:SetPlaybackRate(rate)
		vm:SetCycle(wep.TFAnimCycle)
	end)

	function SWEP:DrawHUD()
		local fishCaught = self:GetNW2Int("FishCaughtID", 0)
		local hookedFish = self:GetNW2Int("HookedFishID", 0)
		if hookedFish > 0 and (not fishCaught or fishCaught <= 0) then
			local fishName = TrueFishGetFishName(hookedFish) or "Pez"
			local ply = LocalPlayer()
			local isReeling = IsValid(ply) and ply:KeyDown(IN_ATTACK)
			local pulse = math.abs(math.sin(CurTime() * 7))
			local col = Color(255, 180 + pulse * 75, 40, 255)
			local w = math.floor(TFScreenScale(220))
			local h = math.floor(TFScreenScale(26))
			local cx, cy = ScrW() * 0.5, ScrH() * 0.82

			draw.RoundedBox(8, cx - w * 0.5, cy - h * 0.5, w, h + 16, Color(15, 15, 22, 230))
			draw.SimpleText("¡" .. string.upper(fishName) .. " ENGANCHADO!", "SegoeUI_NormalBoldScaled", cx, cy - 6, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			if isReeling then
				draw.SimpleText("Sacando pez del agua...", "SegoeUI_NormalBoldScaled", cx, cy + 12, Color(110, 255, 150, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				draw.SimpleText("Mantén [Click Izquierdo] para sacarlo del agua", "SegoeUI_NormalBoldScaled", cx, cy + 12, Color(255, 255, 255, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			return
		end

		local specialHook = self:GetNW2Int("SpecialHookID", 0)
		if specialHook > 0 and TrueFishBosses and TrueFishBosses[specialHook] then
			local bData = TrueFishBosses[specialHook]
			draw.SimpleText("Anzuelo de Jefe: " .. bData.gearName .. " (1 solo uso)", "SegoeUI_NormalSmallScaled", ScrW() * 0.5, ScrH() * 0.94, Color(255, 215, 60, 230), TEXT_ALIGN_CENTER)
		end

		if self:GetNW2Bool("IsHookActive", false) then
			local ply = LocalPlayer()
			if IsValid(ply) and ply:KeyDown(IN_ATTACK) then
				draw.SimpleText("Recogiendo anzuelo...", "SegoeUI_NormalBoldScaled", ScrW() * 0.5, ScrH() * 0.85, Color(255, 215, 60, 240), TEXT_ALIGN_CENTER)
			else
				draw.SimpleText("Mantén [Click Izquierdo] para recoger el anzuelo", "SegoeUI_NormalBoldScaled", ScrW() * 0.5, ScrH() * 0.85, Color(220, 220, 220, 180), TEXT_ALIGN_CENTER)
			end
		end
	end

	local lineColor = Color(255, 255, 255, 100)
	net.Receive("rod_phys_Fishing", function()
		local owner = LocalPlayer()
		if !owner or !owner:IsValid() then return end
		local wep = owner:GetActiveWeapon()
		if !wep or !wep:IsValid() or wep:GetClass() != "fishing_rod_physics" then return end
		
		local wait = net.ReadUInt(12)
		
		if wait != 0 then
			wep.DrawFishing = wait
			wep.IsHoldingReady = nil
			wep.HoldingInHoldLoop = nil
			wep.CastAnimationEnd = nil
			wep.StartedFishing = CurTime()-owner:Ping()*0.001
			local vm = owner:GetViewModel()
			if IsValid(vm) then
				local idle = vm:LookupSequence("idle")
				if idle >= 0 then
					vm:SendViewModelMatchingSequence(idle)
					vm:SetPlaybackRate(1)
					vm:SetCycle(0)
				end
			end
		end
	end)

	net.Receive("rod_phys_Pull", function()
		local owner = LocalPlayer()
		if !owner or !owner:IsValid() then return end
		local wep = owner:GetActiveWeapon()
		if !wep or !wep:IsValid() then return end

		local ent = net.ReadEntity()
		local nextSplash = CurTime()

		wep.ThinkSplash = function(self)
			local ctime = CurTime()
			if nextSplash < ctime and IsValid(ent) and ent:WaterLevel() > 0 then
				chat.PlaySound()
				local effectdata = EffectData()
				local pos = ent:GetPos()
				effectdata:SetOrigin(pos)
				effectdata:SetNormal(pos)
				effectdata:SetRadius(5)
				effectdata:SetScale(4)
				util.Effect("watersplash", effectdata)
				nextSplash = ctime+0.1
			end
		end
	end)

	net.Receive("rod_phys_End", function()
		local owner = LocalPlayer()
		if !owner or !owner:IsValid() then return end
		local wep = owner:GetActiveWeapon()
		if !wep or !wep:IsValid() then return end

		wep.ThinkSplash = nil
		wep.CastAnimationEnd = nil
		wep.DrawFishing = nil
		wep.IsReelingAnim = nil
		wep.WasFightingFish = nil
		wep.HasPlayedReelReady = nil
		local vm = owner:GetViewModel()
		if IsValid(vm) then
			local idle = vm:LookupSequence("idle")
			if idle >= 0 then
				vm:SendViewModelMatchingSequence(idle)
				vm:SetPlaybackRate(1)
				vm:SetCycle(0)
			end
		end
	end)

	net.Receive("rod_phys_CastAnim", function()
		local owner = LocalPlayer()
		if not IsValid(owner) then return end
		local wep = owner:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "fishing_rod_physics" then return end
		local vm = owner:GetViewModel()
		if not IsValid(vm) then return end

		local castSeq = vm:LookupSequence("cast")
		if castSeq >= 0 then
			wep.CastAnimationEnd = CurTime() + 1.15
			vm:SendViewModelMatchingSequence(castSeq)
			vm:SetPlaybackRate(1)
			vm:SetCycle(0)
		end
		wep:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 65, 110)
	end)

	hook.Add("PostDrawViewModel", "TrueFishing_Physics_VM", function(vm, ply, wep)
		if not IsValid(ply) or ply ~= LocalPlayer() then return end
		if not IsValid(wep) or wep:GetClass() ~= "fishing_rod_physics" then return end
		if not IsValid(vm) then return end

		local rawTipPos
		local bTip = vm:LookupBone("cast_rod_tip")
		local bUpper = vm:LookupBone("cast_rod_upper")
		if bTip and bUpper then
			local mTip = vm:GetBoneMatrix(bTip)
			local mUpper = vm:GetBoneMatrix(bUpper)
			if mTip and mUpper then
				local pTip = mTip:GetTranslation()
				local pUpper = mUpper:GetTranslation()
				local dir = (pTip - pUpper):GetNormalized()
				rawTipPos = pTip + dir * 11
			end
		elseif bTip then
			local mTip = vm:GetBoneMatrix(bTip)
			if mTip then
				rawTipPos = mTip:GetTranslation()
			end
		end

		if rawTipPos then
			wep.CurrentTipPos = rawTipPos

			-- Calcular la proyección corregida a espacio de mundo para que la línea coincida 100% con la anilla en pantalla
			local eyePos = EyePos()
			local eyeAng = EyeAngles()
			local worldFov = ply:GetFOV()
			local vmFov = wep.ViewModelFOV or 62
			local factor = math.tan(math.rad(worldFov * 0.5)) / math.tan(math.rad(vmFov * 0.5))

			local localPos = WorldToLocal(rawTipPos, Angle(0, 0, 0), eyePos, eyeAng)
			localPos.y = localPos.y * factor
			localPos.z = localPos.z * factor
			wep.CorrectedTipPos = LocalToWorld(localPos, Angle(0, 0, 0), eyePos, eyeAng)

			local isCaught = wep:GetNW2Int("FishCaughtID", 0) > 0
			local isHookActive = wep:GetNW2Bool("IsHookActive", false)

			-- Ocultar el anzuelo del mundo y sus hijos en 1ra persona cuando está en la caña o con pez atrapado
			local hookEnt = wep:GetNW2Entity("FishingHook")
			if IsValid(hookEnt) then
				local hideWorldHook = not isHookActive or isCaught
				hookEnt:SetNoDraw(hideWorldHook)
				if IsValid(hookEnt.Fish) then
					hookEnt.Fish:SetNoDraw(hideWorldHook)
				end
				for _, child in ipairs(hookEnt:GetChildren()) do
					if IsValid(child) then
						child:SetNoDraw(hideWorldHook)
					end
				end
			end

			-- FÍSICA PENDULAR EN PRIMERA PERSONA:
			-- Se ejecuta en reposo (anzuelo vacío) y con pez capturado (el pez cuelga y se balancea dinámicamente)
			if not isHookActive or isCaught then
				local ropeLen = isCaught and 9 or 14

				if not wep.HookPhysPos then
					wep.HookPhysPos = rawTipPos - Vector(0, 0, ropeLen)
					wep.HookPhysVel = Vector(0, 0, 0)
				end

				-- Impulso de balanceo al atrapar el pez para que la llegada tenga inercia y oscilación viva
				if isCaught and not wep.WasCaughtLastFrame then
					wep.WasCaughtLastFrame = true
					wep.HookPhysVel = (wep.HookPhysVel or Vector(0, 0, 0)) + ply:GetAimVector() * 25 - ply:GetUp() * 12 + ply:GetRight() * 6
				elseif not isCaught then
					wep.WasCaughtLastFrame = nil
				end

				local dt = math.Clamp(FrameTime(), 0.001, 0.05)
				-- Gravedad hacia abajo (con pez tiene más peso y tira hacia abajo)
				local gravity = isCaught and -520 or -450
				wep.HookPhysVel = (wep.HookPhysVel or Vector(0, 0, 0)) + Vector(0, 0, gravity) * dt
				-- Amortiguación de aire suave para que oscile naturalmente reaccionando a la cámara
				local damp = isCaught and 0.955 or 0.94
				wep.HookPhysVel = wep.HookPhysVel * (damp ^ (dt * 60))
				-- Integrar velocidad a posición
				wep.HookPhysPos = wep.HookPhysPos + wep.HookPhysVel * dt

				-- Restricción física de cuerda (longitud fija desde la punta de la caña)
				local diff = wep.HookPhysPos - rawTipPos
				local dist = diff:Length()
				if dist > ropeLen then
					local n = diff / dist
					wep.HookPhysPos = rawTipPos + n * ropeLen
					local vDot = wep.HookPhysVel:Dot(n)
					if vDot > 0 then
						wep.HookPhysVel = wep.HookPhysVel - n * vDot
					end
				end
				local hookPos = wep.HookPhysPos

				-- Inclinación física dinámica del anzuelo siguiendo el ángulo de la cuerda
				local dir = (hookPos - rawTipPos):GetNormalized()
				local hookAng = dir:Angle()
				hookAng:RotateAroundAxis(hookAng:Right(), -90)

				-- Dibujar hilo blanco fino colgante en vista de primera persona desde la anilla de la caña hasta el anzuelo
				render.SetColorMaterial()
				render.DrawBeam(rawTipPos, hookPos, 0.35, 0, 1, Color(255, 255, 255, 230))

				-- Dibujar modelo del anzuelo colgante (anzuelo base o anzuelo especial de jefe)
				local specialHook = wep:GetNW2Int("SpecialHookID", 0)
				local hookMdl = "models/fishing/hook.mdl"
				if specialHook > 0 and TrueFishBosses and TrueFishBosses[specialHook] then
					hookMdl = TrueFishBosses[specialHook].hookModel or "models/fishing/hook.mdl"
				end

				if not IsValid(wep.ClientHookModel) then
					wep.ClientHookModel = ClientsideModel(hookMdl, RENDERGROUP_VIEWMODEL)
					if IsValid(wep.ClientHookModel) then
						wep.ClientHookModel:SetNoDraw(true)
						wep.CurrentHookMdlPath = hookMdl
					end
				elseif wep.CurrentHookMdlPath ~= hookMdl then
					wep.ClientHookModel:SetModel(hookMdl)
					wep.CurrentHookMdlPath = hookMdl
				end
				if IsValid(wep.ClientHookModel) then
					wep.ClientHookModel:SetPos(hookPos)
					wep.ClientHookModel:SetAngles(hookAng)
					wep.ClientHookModel:DrawModel()
				end

				-- Dibujar el pez colgando del anzuelo con orientación completamente vertical y boca agarrando la púa
				if isCaught then
					local fishID = wep:GetNW2Int("FishCaughtID", 0)
					local fishMdl = TrueFishGetFishModel(fishID) or "models/fishing/fish_bass.mdl"
					if not IsValid(wep.ClientFishModel) then
						wep.ClientFishModel = ClientsideModel(fishMdl, RENDERGROUP_VIEWMODEL)
						if IsValid(wep.ClientFishModel) then
							wep.ClientFishModel:SetNoDraw(true)
							wep.CurrentFishMdl = fishMdl
						end
					elseif wep.CurrentFishMdl ~= fishMdl then
						wep.ClientFishModel:SetModel(fishMdl)
						wep.CurrentFishMdl = fishMdl
					end

					if IsValid(wep.ClientFishModel) then
						local scale = (TrueFishGetHangScale and TrueFishGetHangScale(fishMdl)) or 1.0
						local mX = ((TrueFishGetMouthOffset and TrueFishGetMouthOffset(fishID)) or 16.5) * scale
						-- La púa del anzuelo está en la curva inferior del modelo (Z = -4.5 en espacio local del anzuelo)
						local barbPos = LocalToWorld(Vector(0, 0.4, -4.5), Angle(0, 0, 0), hookPos, hookAng)

						-- FÍSICA DEL PEZ: péndulo independiente (misma física del cebo/anzuelo).
						-- El pez cuelga de la púa con su propia posición/velocidad, reaccionando a la cámara con inercia.
						if not wep.FishPhysPos then
							wep.FishPhysPos = barbPos - Vector(0, 0, mX)
							wep.FishPhysVel = Vector(0, 0, 0)
						end

						-- Impulso inicial al capturar para que el pez llegue con una oscilación viva
						if not wep.FishCaughtImpulse then
							wep.FishCaughtImpulse = true
							wep.FishPhysVel = wep.FishPhysVel + ply:GetAimVector() * 20 - ply:GetUp() * 10 + ply:GetRight() * 5
						end

						local dt = math.Clamp(FrameTime(), 0.001, 0.05)
						wep.FishPhysVel = wep.FishPhysVel + Vector(0, 0, -520) * dt
						wep.FishPhysVel = wep.FishPhysVel * (0.955 ^ (dt * 60))
						wep.FishPhysPos = wep.FishPhysPos + wep.FishPhysVel * dt

						-- Restricción de cuerda: el pez cuelga de la púa a distancia mX (boca a mX del centro)
						local fDiff = wep.FishPhysPos - barbPos
						local fDist = fDiff:Length()
						if fDist > mX then
							local n = fDiff / fDist
							wep.FishPhysPos = barbPos + n * mX
							local vDot = wep.FishPhysVel:Dot(n)
							if vDot > 0 then
								wep.FishPhysVel = wep.FishPhysVel - n * vDot
							end
						end

						-- Dirección real de la cuerda (de la púa al pez)
						local ropeDir = (wep.FishPhysPos - barbPos):GetNormalized()

						-- Orientación: vertical mirando a cámara, inclinada para seguir la cuerda mientras se balancea
						local fishAng = Angle(0, ply:EyeAngles().y, 90)
						local down = Vector(0, 0, -1)
						local axis = down:Cross(ropeDir)
						local axisLen = axis:Length()
						if axisLen > 0.0001 then
							axis = axis / axisLen
							local angleDeg = math.deg(math.acos(math.Clamp(down:Dot(ropeDir), -1, 1)))
							fishAng:RotateAroundAxis(axis, angleDeg)
						end

						-- La boca queda exactamente sobre la púa: centro = púa + Right()*mX (boca en -Right*mX)
						local fishPos = barbPos + fishAng:Right() * mX

						wep.ClientFishModel:SetModelScale(scale, 0)

						wep.ClientFishModel:SetPos(fishPos)
						wep.ClientFishModel:SetAngles(fishAng)
						wep.ClientFishModel:DrawModel()
					end
				else
					if IsValid(wep.ClientFishModel) then
						wep.ClientFishModel:Remove()
						wep.ClientFishModel = nil
						wep.CurrentFishMdl = nil
					end
					wep.FishPhysPos = nil
					wep.FishPhysVel = nil
					wep.FishCaughtImpulse = nil
				end
			else
				-- Al pescar lejos en el agua, resetear posición pendular
				wep.HookPhysPos = nil
				wep.HookPhysVel = nil
				wep.WasCaughtLastFrame = nil
				wep.FishPhysPos = nil
				wep.FishPhysVel = nil
				wep.FishCaughtImpulse = nil
				if IsValid(wep.ClientFishModel) then
					wep.ClientFishModel:Remove()
					wep.ClientFishModel = nil
					wep.CurrentFishMdl = nil
				end
			end
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "TrueFishing_Physics_Line", function(bDrawingDepth, bDrawingSkybox)
		if bDrawingDepth or bDrawingSkybox then return end
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep:GetClass() ~= "fishing_rod_physics" then return end

		if not wep:GetNW2Bool("IsHookActive", false) or (wep:GetNW2Int("FishCaughtID", 0) > 0) then return end
		local hookEnt = wep:GetNW2Entity("FishingHook")
		if not IsValid(hookEnt) or hookEnt:GetNoDraw() then return end

		local lineStart
		-- 1ra persona: usar la posición proyectada directamente desde la anilla de la caña
		if not (ply.ShouldDrawLocalPlayer and ply:ShouldDrawLocalPlayer()) then
			lineStart = wep.CorrectedTipPos or wep.CurrentTipPos
			if not lineStart then
				local vm = ply:GetViewModel()
				if IsValid(vm) then
					vm:SetupBones()
					local bTip = vm:LookupBone("cast_rod_tip")
					local bUpper = vm:LookupBone("cast_rod_upper")
					if bTip and bUpper then
						local mTip = vm:GetBoneMatrix(bTip)
						local mUpper = vm:GetBoneMatrix(bUpper)
						if mTip and mUpper then
							local pTip = mTip:GetTranslation()
							local pUpper = mUpper:GetTranslation()
							local dir = (pTip - pUpper):GetNormalized()
							local raw = pTip + dir * 11

							local eyePos = EyePos()
							local eyeAng = EyeAngles()
							local factor = math.tan(math.rad(ply:GetFOV() * 0.5)) / math.tan(math.rad((wep.ViewModelFOV or 62) * 0.5))
							local localPos = WorldToLocal(raw, Angle(0, 0, 0), eyePos, eyeAng)
							localPos.y = localPos.y * factor
							localPos.z = localPos.z * factor
							lineStart = LocalToWorld(localPos, Angle(0, 0, 0), eyePos, eyeAng)
						end
					end
				end
			end
		else
			-- 3ra persona: desde el extremo de la caña del modelo de mundo
			local pole = wep.WeaponModel
			if IsValid(pole) then
				local pos, ang = pole:GetPos(), pole:GetAngles()
				lineStart = pos + ang:Forward() * 98 + ang:Up() * 0.25
			else
				lineStart = ply:GetPos() + Vector(0, 0, 50)
			end
		end

		if not lineStart then return end

		-- En models/fishing/hook.mdl, el origen (0, 0, 0) es exactamente la anilla superior
		local lineEnd = hookEnt:GetPos()
		render.SetColorMaterial()
		render.DrawBeam(lineStart, lineEnd, 0.35, 0, 1, Color(255, 255, 255, 230))
	end)

	local Strength = 175
	function SWEP:Reload()
		if self.LastR and self.LastR > SysTime() then return end
		self.LastR = SysTime()+1
		local Window = vgui.Create( "DFrame" )
			Window:SetTitle( "" )
			Window:SetDraggable( false )
			Window:ShowCloseButton( false )
			Window:SetBackgroundBlur( false )
			Window:SetDrawOnTop( true )
			Window.Paint = function(self)			
				draw.RoundedBoxEx(8, 0, 0, self:GetWide(), 20, Color(47, 54, 76, 255), true, true)
				draw.SimpleText(TrueFishLocal("throw_str"), "FishingS20", self:GetWide()*0.5, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
				draw.RoundedBoxEx(8, 0, self:GetTall()-30, self:GetWide(), 30, Color(47, 54, 76, 255), false, false, true, true)
				surface.SetDrawColor(60, 64, 83, 255)
				surface.DrawRect(0, 20, self:GetWide(), self:GetTall()-50)
				
				surface.SetDrawColor(50, 50, 50, 255)
				surface.DrawOutlinedRect(0, 20, self:GetWide(), self:GetTall()-50)
			end
			
		local InnerPanel = vgui.Create( "DPanel", Window )
			InnerPanel:SetDrawBackground( false )
		
		local Text = vgui.Create( "DLabel", InnerPanel )
			Text:SetText( TrueFishLocal("throw_desc") )
			Text:SizeToContents()
			Text:SetContentAlignment( 5 )
			Text:SetTextColor( color_white )
			
		local TextEntry = vgui.Create( "DNumSlider", InnerPanel ) // y the fuck does this derma not have color editing for notches...
			TextEntry:SetMin(0)
			TextEntry:SetMax(800)
			TextEntry:SetValue(Strength)
			TextEntry:SetDark(false)
			TextEntry.TextArea:SetTextColor(Color(255, 255, 255, 255))
			
		local ButtonPanel = vgui.Create( "DPanel", Window )
			ButtonPanel:SetTall( 30 )
			ButtonPanel:SetDrawBackground( false )
			
		local Button = vgui.Create( "DButton", ButtonPanel )
			Button:SetText( "OK" )
			Button:SetColor(Color(250, 250, 250, 255))
			Button:SetFont("FishingS16")
			Button:SizeToContents()
			Button:SetTall( 20 )
			Button:SetWide( Button:GetWide() + 20 )
			Button:SetPos( 5, 5 )
			Button.DoClick = function()
				net.Start("FishPoleStrength")
				net.WriteFloat(TextEntry:GetValue())
				net.SendToServer()
				Strength = TextEntry:GetValue()
				Window:Close()
			end
			Button.Paint = function(self)
				surface.SetDrawColor(self.Hovered and Color(99, 102, 111, 255) or Color(69, 72, 81, 255))
				surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
				surface.SetDrawColor(50, 50, 50, 255)
				surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall())
			end
			
		local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
			ButtonCancel:SetText( "Cancel" )
			ButtonCancel:SetColor(Color(250, 250, 250, 255))
			ButtonCancel:SetFont("FishingS16")
			ButtonCancel:SizeToContents()
			ButtonCancel:SetTall( 20 )
			ButtonCancel:SetWide( Button:GetWide() + 20 )
			ButtonCancel:SetPos( 5, 5 )
			ButtonCancel.DoClick = function() Window:Close() end
			ButtonCancel:MoveRightOf( Button, 5 )
			ButtonCancel.Paint = Button.Paint
			
		ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )
		
		local w, h = Text:GetSize()
		w = math.max( w, 400 ) 
		
		Window:SetSize( w + 50, h + 25 + 75 + 10 )
		Window:Center()
		
		InnerPanel:StretchToParent( 5, 25, 5, 45 )
		
		Text:StretchToParent( 5, 5, 5, 35 )	
		
		TextEntry:StretchToParent( 5, nil, 5, nil )
		//TextEntry:SetSize(Window:GetWide()-10, 20)
		TextEntry:SetPos(-TextEntry:GetWide()*0.225, 25)
		//TextEntry:AlignBottom( 5 )
		
		TextEntry:RequestFocus()
		//TextEntry:SelectAllText( true )
		
		ButtonPanel:CenterHorizontal()
		ButtonPanel:AlignBottom( 2 )
		
		Window:MakePopup()
		Window:DoModal()
	end
end

local emptyf = function() end//destroy click sound
SWEP.PrimaryAttack = emptyf
SWEP.SecondaryAttack = emptyf
if CLIENT then return end

net.Receive("FishPoleStrength", function(len, ply)
	ply.HookThrowStr = math.Clamp(net.ReadFloat(), 0, 800)
end)

net.Receive("rod_phys_Cast", function(len, ply)
	if not IsValid(ply) then return end
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() ~= "fishing_rod_physics" then return end
	if wep.Owner.IsFishing or wep:GetNW2Bool("IsHookActive", false) or (wep.FishCaughtID and wep.FishCaughtID > 0) or (wep.HookedFishID and wep.HookedFishID > 0) then return end
	local charge = net.ReadFloat()
	wep:DoCast(charge)
end)

function SWEP:Think()
	if !IsValid(self.WeaponModel) or !IsValid(self.Hook) then self:Deploy(true) end
	local pos, ang = self.Owner:GetBonePosition(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand", false))
	ang:RotateAroundAxis(ang:Right(), -55)
	pos = pos - ang:Forward()*6.5 + ang:Up()*1.275 + ang:Right()*1.5
	self.WeaponModel:SetPos(pos)
	self.WeaponModel:SetAngles(ang)

	-- Monitorear vuelo del anzuelo lanzado
	if self.HookInFlight and IsValid(self.Hook) then
		local inWater = self.Hook:WaterLevel() > 0
		local ctime = CurTime()
		local timedOut = (ctime - (self.FlightStartTime or ctime)) > 3.0

		if inWater or timedOut then
			self.HookInFlight = nil
			if inWater then
				local ed = EffectData()
				ed:SetOrigin(self.Hook:GetPos())
				ed:SetScale(2)
				util.Effect("watersplash", ed)
				self.Hook:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 75, 100)
			end

			local dist = self.Hook:GetPos():Distance(self.Owner:GetPos())
			self:AdjustRope(dist + 20)

			local tr = util.TraceLine({
				start = self.Hook:GetPos(),
				endpos = self.Hook:GetPos() - Vector(0, 0, FISH_MAX_DEPTH + 100),
				mask = MASK_SOLID_BRUSHONLY
			})
			self.Depth = tr.Hit and math.Clamp(math.abs(tr.HitPos.z - self.Hook:GetPos().z), 15, FISH_MAX_DEPTH) or FISH_MAX_DEPTH

			self.FishingEndTime = nil
			self.FishingTimeWindow = nil
		end
	end

	-- TEMPORIZADOR DE ESCAPE (15s): el pez enganchado se escapa si no se recoge a tiempo
	if SERVER and self.HookedFishID and self.HookedFishID > 0 and self.FishEscapeTime and CurTime() >= self.FishEscapeTime then
		local escFish = self.HookedFishID
		self.FishEscapeTime = nil
		self:SetNW2Float("FishEscapeTime", 0)
		self.HookedFishID = nil
		self:SetNW2Int("HookedFishID", 0)
		if IsValid(self.Hook) then
			self.Hook:RemoveFish()
			self.Hook:SetNoDraw(true)
			local physEsc = self.Hook:GetPhysicsObject()
			if IsValid(physEsc) then physEsc:EnableMotion(false) end
			self.Hook:SetPos(self.Owner:GetPos())
		end
		self.Owner.IsFishing = false
		self:SetNW2Bool("IsHookActive", false)
		self:AdjustRope(10)
		net.Start("rod_phys_End")
		net.Send(self.Owner)
		self.Owner:EmitSound("ambient/water/water_splash1.wav", 70, 110)
		TrueFishNotify(self.Owner, "¡El " .. (TrueFishGetFishName(escFish) or "pez") .. " se escapó del anzuelo!")
		return
	end

	-- VENTANA DE CAPTURA (10s): el pez cuelga del anzuelo.
	-- Con [E] se SUELTA el pez enfurecido y arranca la pelea (en vez de guardarlo).
	if SERVER and self.FishCaughtID and self.FishCaughtID > 0 then
		if self.FishEscapeTime and CurTime() >= self.FishEscapeTime then
			self:ReleaseAngryFish()
			return
		end
		-- Soltar con [E] (IN_USE) sin depender del raycast sobre el anzuelo
		if self.Owner:KeyDown(IN_USE) then
			self:ReleaseAngryFish()
			return
		end
		return
	end

	-- Cuando el anzuelo está lanzado: el usuario se puede quedar todo el tiempo que quiera en el agua.
	-- La única forma de recogerlo es manteniendo presionado Click Izquierdo (IN_ATTACK).
	if SERVER and self.Owner.IsFishing and not self.HookInFlight and not (self.FishCaughtID and self.FishCaughtID > 0) then
		if IsValid(self.Hook) and IsValid(self.Owner) then
			local ply = self.Owner
			local hookPos = self.Hook:GetPos()
			local inWater = self.Hook:WaterLevel() > 0
			local phys = self.Hook:GetPhysicsObject()

			-- Comprobación periódica de picada de pez (mientras está en el agua y aún no hay pez enganchado)
			if inWater and not (self.HookedFishID and self.HookedFishID > 0) then
				local specialHook = self:GetNW2Int("SpecialHookID", 0)
				self.NextBiteCheck = self.NextBiteCheck or (CurTime() + (specialHook > 0 and 1.2 or 0.8))
				if CurTime() >= self.NextBiteCheck then
					local isReeling = ply:KeyDown(IN_ATTACK)
					local chance = (specialHook > 0) and 100 or (isReeling and 15 or 8)
					self.NextBiteCheck = CurTime() + (specialHook > 0 and 1.0 or (isReeling and 0.45 or 1.2))

					if math.random(100) <= chance then
						if specialHook > 0 then
							-- ¡PICADA DEL JEFE GARANTIZADA!
							-- Ni bien muerde: SE SUELTA DE LA CAÑA INMEDIATAMENTE, EL ANZUELO ESPECIAL SE ROMPE Y EL JEFE SALE DISPARADO POR LOS AIRES FUERA DEL AGUA
							local bData = TrueFishBosses and TrueFishBosses[specialHook]
							local spawnPos = hookPos + Vector(0, 0, 25)

							-- Erupción de agua gigante, temblor sísmico y sonido ensordecedor de monstruo marino
							local ed = EffectData()
							ed:SetOrigin(hookPos)
							ed:SetScale(5.5)
							util.Effect("watersplash", ed)

							self.Hook:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 100, 65)
							self.Hook:EmitSound("npc/antlion/antlion_growl" .. math.random(1, 4) .. ".wav", 100, 60)
							ply:EmitSound("ambient/explosions/explode_4.wav", 85, 90)
							ply:EmitSound("physics/metal/metal_box_break1.wav", 95, 80)
							ply:EmitSound("physics/wood/wood_crate_break" .. math.random(1, 5) .. ".wav", 90, 100)

							util.ScreenShake(hookPos, 10, 18, 2.0, 1600)
							util.ScreenShake(ply:GetPos(), 6, 12, 1.2, 700)

							-- Spawnea el jefe en el agua e IMPULSA al jefe fuera del agua por el aire hacia el jugador
							local boss = ents.Create("ent_boss_fish")
							if IsValid(boss) then
								boss:SetBossType(specialHook)
								boss:SetPos(spawnPos)
								boss:SetAngles(Angle(0, (ply:GetPos() - hookPos):Angle().y, 0))
								boss:Spawn()
								boss:SetBossTarget(ply)
							boss.Summoner = ply

								local physB = boss:GetPhysicsObject()
								if IsValid(physB) then
									local jumpDir = (ply:EyePos() - spawnPos):GetNormalized()
									physB:SetVelocity(jumpDir * 450 + Vector(0, 0, 580))
									physB:AddAngleVelocity(Vector(math.random(-250, 250), math.random(-250, 250), math.random(-350, 350)))
								end
							end

							-- Notificaciones al jugador
							local bossName = bData and bData.name or "JEFE"
							TrueFishNotify(ply, "¡EL " .. string.upper(bossName) .. " DESTROZÓ EL ANZUELO Y SALIÓ DISPARADO DEL AGUA!")
							TrueFishNotify(ply, "¡EL ANZUELO ESPECIAL SE HA ROTO! ¡PREPÁRATE PARA LUCHAR!")

							-- El anzuelo se suelta de la caña, el anzuelo especial se destruye y la caña vuelve a su estado base
							self:SetNW2Int("SpecialHookID", 0)
							ply.EquippedBossHook = nil

							self.HookInFlight = nil
							self.Owner.IsFishing = false
							self:SetNW2Bool("IsHookActive", false)
							self.HookedBossID = nil
							self.HookedFishID = nil
							self:SetNW2Int("HookedBossID", 0)
							self:SetNW2Int("HookedFishID", 0)

							if IsValid(self.Hook) then
								self.Hook:SetModel("models/fishing/hook.mdl")
								self.Hook:RemoveFish()
								self.Hook:SetNoDraw(true)
								if IsValid(phys) then
									phys:EnableMotion(false)
									phys:SetVelocityInstantaneous(Vector(0, 0, 0))
								end
								self.Hook:SetPos(ply:GetPos())
							end

							self:AdjustRope(10)

							net.Start("rod_phys_End")
							net.Send(ply)

							return
						else
							local fish = TrueFishCalculateFish(self.Depth) or FISH_BASSFISH
							if math.random(1000) <= TrueFish.ROD_JUNK_CHANCE then
								fish = FISH_JUNK
							end

							-- Salpicadura violenta y sonido de picada en la posición del anzuelo dentro del agua
							local ed = EffectData()
							ed:SetOrigin(hookPos)
							ed:SetScale(2.5)
							util.Effect("watersplash", ed)
							self.Hook:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 85, 100)
							ply:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 75, 120)

						-- El pez muerde y se engancha al anzuelo en su posición actual dentro del agua
						self.HookedFishID = fish
						self:SetNW2Int("HookedFishID", fish)
						self:SetNW2Bool("IsHookActive", true)
						-- TEMPORIZADOR DE ESCAPE: 15 segundos para recogerlo antes de que se escape
						self.FishEscapeTime = CurTime() + 15
						self:SetNW2Float("FishEscapeTime", self.FishEscapeTime)

							self.Hook:AddFish(fish)
							self.Hook:SetNoDraw(false)
							if IsValid(self.Hook.Fish) then
								self.Hook.Fish:SetNoDraw(false)
							end
						end
					end
				end
			end

			-- Recogida con Click Izquierdo (IN_ATTACK)
			if ply:KeyDown(IN_ATTACK) then
				local eyePos = ply:EyePos()
				local aim = ply:GetAimVector()
				local right = ply:GetRight()
				local up = ply:GetUp()
				local targetPos = eyePos + aim * 36 + right * 10 - up * 12
				local diff = targetPos - hookPos
				local dist = diff:Length()
				local dir = diff:GetNormalized()

				if IsValid(phys) then
					phys:Wake()

					-- ESTABILIZACIÓN DEL ANZUELO: bloquea pitch/roll y conserva solo el yaw
					-- para que el pez colgado no se ponga horizontal ni se suelte del anzuelo
					local stabAng = self.Hook:GetAngles()
					self.Hook:SetAngles(Angle(0, stabAng.y, 0))
					phys:SetAngles(Angle(0, stabAng.y, 0))
					phys:SetAngleVelocity(Vector(0, 0, 0))

					if self.HookedFishID and self.HookedFishID > 0 then
						-- PEZ ENGANCHADO: Arrastrar lentamente hacia el jugador saliendo del agua
						if inWater then
							-- Velocidad suave en el agua (~115 u/s) con flotabilidad hacia arriba
							phys:SetVelocity(dir * 115 + Vector(0, 0, 24))

							-- Salpicaduras periódicas mientras el pez avanza por el agua
							self.NextReelSplash = self.NextReelSplash or 0
							if CurTime() >= self.NextReelSplash then
								self.NextReelSplash = CurTime() + 0.35
								local ed = EffectData()
								ed:SetOrigin(hookPos)
								ed:SetScale(1.3)
								util.Effect("watersplash", ed)
								self.Hook:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 65, 115)
							end
						else
							-- El pez ya salió del agua: arrastrar por el aire hacia las manos del jugador
							phys:SetVelocity(dir * 135 + Vector(0, 0, 18))
						end

						-- Movimiento dinámico de la cola del pez mientras se arrastra
						if IsValid(self.Hook.Fish) then
							local wiggle = math.sin(CurTime() * 18) * 16
							-- Roll +90 mantiene el pez vertical (boca arriba); el yaw oscila de lado a lado
							self.Hook.Fish:SetLocalAngles(Angle(0, wiggle, 90))
						end
					else
						-- ANZUELO VACÍO (sin pez):
						if inWater then
							phys:SetVelocity(dir * 140 + Vector(0, 0, 18))

							self.NextReelSplash = self.NextReelSplash or 0
							if CurTime() >= self.NextReelSplash then
								self.NextReelSplash = CurTime() + 0.5
								local ed = EffectData()
								ed:SetOrigin(hookPos)
								ed:SetScale(0.8)
								util.Effect("watersplash", ed)
								self.Hook:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 60, 120)
							end
						else
							phys:SetVelocity(dir * 220 + Vector(0, 0, 35))
						end
					end

					-- SISTEMA ANTI-ATASCO (Reverse Engineering: How to Fish FishingRod::TeleportIfStuck)
					self.LastHookCheckPos = self.LastHookCheckPos or hookPos
					self.HookStuckTimer = self.HookStuckTimer or 0
					if hookPos:DistToSqr(self.LastHookCheckPos) < 9.0 then
						self.HookStuckTimer = self.HookStuckTimer + 0.1
						if self.HookStuckTimer >= 1.0 then
							-- Desatascar anzuelo impulsándolo suavemente hacia el jugador
							phys:SetVelocity(dir * 260 + Vector(0, 0, 95))
							self.HookStuckTimer = 0
						end
					else
						self.LastHookCheckPos = hookPos
						self.HookStuckTimer = 0
					end

					-- MODULACIÓN DINÁMICA DE AUDIO DE CARRETE (Reverse Engineering: FishingRod ReelAudio pitch & volume)
					self.NextReelSound = self.NextReelSound or 0
					if CurTime() >= self.NextReelSound then
						self.NextReelSound = CurTime() + 0.28
						local reelVel = phys:GetVelocity():Length()
						local pitchMod = math.Clamp(125 + math.floor(reelVel * 0.12), 110, 160)
						local volMod = math.Clamp(40 + math.floor(reelVel * 0.1), 45, 65)
						ply:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", volMod, pitchMod)
					end

					self:AdjustRope(dist + 6)
				end

				-- AL LLEGAR A LAS MANOS DEL JUGADOR
				if dist < 65 then
					if self.HookedFishID and self.HookedFishID > 0 then
						local fish = self.HookedFishID
						self.HookedFishID = nil
						self:SetNW2Int("HookedFishID", 0)

						if fish == FISH_JUNK then
							ply.Fishes = ply.Fishes or {}
							ply.Fishes[fish] = (ply.Fishes[fish] or 0) + 1
							TrueFishNotify(ply, "¡Pescaste basura!")
							self.Owner.IsFishing = false
							self:SetNW2Bool("IsHookActive", false)
							if IsValid(self.Hook) then
								self.Hook:RemoveFish()
								self.Hook:SetNoDraw(true)
								if IsValid(phys) then phys:EnableMotion(false) end
								self.Hook:SetPos(ply:GetPos())
							end
							self:AdjustRope(10)
							net.Start("rod_phys_End")
							net.Send(ply)
						else
							-- VENTANA DE CAPTURA (10s): el pez llega a las manos colgado del anzuelo
							-- El jugador tiene 10 segundos para reclamarlo con [E]; si no, se enfurece y ataca
							self.FishCaughtID = fish
							self:SetNW2Int("FishCaughtID", fish)
							self.FishEscapeTime = CurTime() + 10
							self:SetNW2Float("FishEscapeTime", self.FishEscapeTime)
							self.HookedFishID = nil
							self:SetNW2Int("HookedFishID", 0)
							self:SetNW2Bool("IsHookActive", false)
							self.Owner.IsFishing = true
							if IsValid(self.Hook) then
								self.Hook:SetNoDraw(true)
								if IsValid(phys) then phys:EnableMotion(false) end
								self.Hook:SetPos(ply:GetPos())
							end
							self:AdjustRope(10)
							TrueFishNotify(ply, "¡Presiona [E] para reclamar el " .. (TrueFishGetFishName(fish) or "pez") .. "! (10 segundos)")
						end
					else
						-- Anzuelo vacío: finaliza recogida y vuelve a pose de reposo
						self.HookInFlight = nil
						self.Owner.IsFishing = false
						self:SetNW2Bool("IsHookActive", false)

						if IsValid(self.Hook) then
							self.Hook:SetNoDraw(true)
							if IsValid(phys) then phys:EnableMotion(false) end
							self.Hook:SetPos(ply:GetPos())
						end
						self:AdjustRope(10)

						net.Start("rod_phys_End")
						net.Send(ply)
						ply:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 60, 100)
					end
				end
			else
				-- Si NO está presionando IN_ATTACK y hay un pez enganchado en el agua:
				if self.HookedFishID and self.HookedFishID > 0 then
					if IsValid(phys) then
						phys:Wake()
						if inWater then
							phys:SetVelocity(phys:GetVelocity() * 0.92 + Vector(0, 0, 6))

							self.NextFishIdleSplash = self.NextFishIdleSplash or 0
							if CurTime() >= self.NextFishIdleSplash then
								self.NextFishIdleSplash = CurTime() + 1.2
								local ed = EffectData()
								ed:SetOrigin(hookPos)
								ed:SetScale(1.1)
								util.Effect("watersplash", ed)
								self.Hook:EmitSound("ambient/water/water_splash" .. math.random(1, 3) .. ".wav", 65, 110)
							end
						end
					end

					if IsValid(self.Hook.Fish) then
						local struggle = math.sin(CurTime() * 12) * 14
						self.Hook.Fish:SetLocalAngles(Angle(0, struggle, 90))
					end
				end
			end
		end
	end

	-- Cuando no está pescando: el anzuelo permanece oculto en reposo
	if not self.Owner.IsFishing and IsValid(self.Hook) then
		if not self.Hook:GetNoDraw() then
			self.Hook:SetNoDraw(true)
			local phys = self.Hook:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
			end
			self.Hook:SetPos(self.Owner:GetPos())
			self:SetNW2Bool("IsHookActive", false)
		end
	end
end

function SWEP:AdjustRope(len)
	if not IsValid(self.WeaponModel) or not IsValid(self.Hook) then return end
	constraint.RemoveConstraints(self.WeaponModel, "Rope")
	-- El material vacío "" y SetNoDraw evitan que el motor dibuje una cuerda estirada desde la cintura en primera persona
	local _, rope = constraint.Rope(self.WeaponModel, self.Hook, 0, 0, Vector(98, 0, 0.25), Vector(0, 0, 20), len, 0, 0, 0, "", false)
	if IsValid(rope) then
		rope:SetNoDraw(true)
		rope:Remove()
	end
end

function SWEP:Deploy(fromNotEngine)
	if SERVER then
		-- Asignar cebo inicial si no tiene para que siempre pueda lanzar y probar
		if not self.Owner.FishBait or self.Owner.FishBait <= 0 then
			self.Owner.FishBait = 25
		end

		if self.Owner.EquippedBossHook and self.Owner.EquippedBossHook > 0 then
			self:SetNW2Int("SpecialHookID", self.Owner.EquippedBossHook)
		end

		if !IsValid(self.WeaponModel) then
			self.WeaponModel = ents.Create("fishing_rod_pole")
			self.WeaponModel:SetDTEntity(0, self.Owner)
			self.WeaponModel:Spawn()
			self.WeaponModel:GetPhysicsObject():SetMass(50000)
			self:Think()
		end
		if !IsValid(self.Hook) then
			self.Hook = ents.Create("fishing_rod_hook")
			self.Hook:Spawn()
		end
		self.Hook:SetModelScale(1.0, 0)
		self.Hook:SetNoDraw(true)
		local phys = self.Hook:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end
		self.Hook:SetPos(self.Owner:GetPos())
		self:AdjustRope(10)
		self:SetNW2Entity("FishingHook", self.Hook)
		self:SetNW2Bool("IsHookActive", false)
		self.HookedFishID = nil
		self.FishCaughtID = nil
		self.FishEscapeTime = nil
		self:SetNW2Int("HookedFishID", 0)
		self:SetNW2Int("FishCaughtID", 0)
		self:SetNW2Float("FishEscapeTime", 0)
		if IsValid(self.WeaponModel) and IsValid(self.Hook) then
			self.WeaponModel:SetDTEntity(1, self.Hook)
		end
	end

	self.DrawFishing = nil
	self.CastAnimationEnd = nil
	if IsValid(self.Owner) then
		self.Owner:DrawViewModel(true)
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			local idle = vm:LookupSequence("idle")
			if idle >= 0 then
				vm:SendViewModelMatchingSequence(idle)
				vm:SetPlaybackRate(1)
				vm:SetCycle(0)
			end
		end
	end

	return true
end



function SWEP:DoCast(chargeRatio)
	if self.Owner.IsFishing or not self.Owner:OnGround() or self.HookedFishID or self.FishCaughtID then return end

	-- Si no tiene cebo, darle automáticamente para que nunca se bloquee el lanzamiento
	if not self.Owner.FishBait or self.Owner.FishBait <= 0 then
		self.Owner.FishBait = 25
	end

	self.HookedFishID = nil
	self.FishCaughtID = nil
	self.FishEscapeTime = nil
	self:SetNW2Int("HookedFishID", 0)
	self:SetNW2Int("FishCaughtID", 0)
	self:SetNW2Float("FishEscapeTime", 0)

	chargeRatio = math.Clamp(chargeRatio or 0.8, 0.2, 1.0)
	local baseStr = self.Owner.HookThrowStr or 175
	local throwStr = baseStr * (0.8 + chargeRatio * 0.7)

	self.Owner.FishBait = math.max(0, self.Owner.FishBait - 1)

	if not IsValid(self.WeaponModel) or not IsValid(self.Hook) then
		self:Deploy(true)
	end

	local eyePos = self.Owner:EyePos()
	local aim = self.Owner:GetAimVector()
	local right = self.Owner:GetRight()
	local startPos = eyePos + aim * 30 + right * 8 + Vector(0, 0, 2)

	local specialHook = self:GetNW2Int("SpecialHookID", 0)
	local hookMdl = "models/fishing/hook.mdl"
	if specialHook > 0 and TrueFishBosses and TrueFishBosses[specialHook] then
		hookMdl = TrueFishBosses[specialHook].hookModel or "models/fishing/hook.mdl"
	end
	self.Hook:SetModel(hookMdl)

	self.Hook:SetPos(startPos)
	self.Hook:SetAngles(aim:Angle())
	self.Hook:SetNoDraw(false)

	local phys = self.Hook:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:Wake()
		local throwDir = (aim + Vector(0, 0, 0.22)):GetNormalized()
		local vel = throwDir * (throwStr * 3.2 + 300)
		phys:SetVelocityInstantaneous(vel)
	end

	self:AdjustRope(2000)

	self.Owner.IsFishing = true
	self.HookInFlight = true
	self.FlightStartTime = CurTime()

	self:SetNW2Entity("FishingHook", self.Hook)
	self:SetNW2Bool("IsHookActive", true)

	net.Start("rod_phys_CastAnim")
	net.Send(self.Owner)
end

function SWEP:PrimaryAttack()
	-- El click izquierdo NO lanza el anzuelo (sólo se lanza manteniendo presionado y soltando el click derecho)
	return
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:CollectFish()
	if not SERVER then return end
	local fish = self.FishCaughtID
	if not fish or fish <= 0 then return end

	local ply = self.Owner
	local fishName = TrueFishGetFishName(fish) or "Pez"

	ply.Fishes = ply.Fishes or {}
	if TrueFish.ROD_NO_CONTAINER then
		local playerSpace = 0
		for i = 1, FISH_HIGHNUMBER do
			if ply.Fishes[i] then
				playerSpace = playerSpace + ply.Fishes[i]
			end
		end

		if TrueFish.FISH_CARRY_LIMIT <= playerSpace then
			TrueFishNotify(ply, TrueFishLocal("carry_limit_reached", TrueFish.FISH_CARRY_LIMIT))
		else
			ply.Fishes[fish] = (ply.Fishes[fish] or 0) + 1
			TrueFishNotify(ply, "¡Pescaste un " .. fishName .. "!")
		end
	else
		-- Intentar depositar en contenedor cercano
		local find = ents.FindInSphere(ply:GetPos(), 250)
		local closest
		for _, ent in ipairs(find) do
			if IsValid(ent) and ent:GetClass() == "fish_container" and ent:GetSpace() < TrueFish.FISH_CONTAINER_LIMIT then
				closest = ent
				break
			end
		end

		if closest then
			closest:AddFish(fish, 1)
			TrueFishNotify(ply, "¡Pescaste un " .. fishName .. " y se guardó en el contenedor!")
		else
			-- Si no hay contenedor cerca, guardarlo en el inventario del jugador
			ply.Fishes[fish] = (ply.Fishes[fish] or 0) + 1
			TrueFishNotify(ply, "¡Pescaste un " .. fishName .. "!")
		end
	end

	ply:EmitSound("garrysmod/save_load1.wav", 75, 100)

	if IsValid(self.Hook) then
		self.Hook:RemoveFish()
		self.Hook:SetNoDraw(true)
		local phys = self.Hook:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
		self.Hook:SetPos(ply:GetPos())
	end

	self.HookedFishID = nil
	self.FishCaughtID = nil
	self.FishEscapeTime = nil
	self:SetNW2Int("HookedFishID", 0)
	self:SetNW2Int("FishCaughtID", 0)
	self:SetNW2Float("FishEscapeTime", 0)
	self:SetNW2Bool("IsHookActive", false)
	self.Owner.IsFishing = false

	net.Start("rod_phys_End")
	net.Send(ply)
end

function SWEP:ReleaseAngryFish(fishID)
	if not SERVER then return end
	local fish = fishID or self.FishCaughtID or self.HookedFishID
	local ply = self.Owner
	if not IsValid(ply) then return end

	local spawnPos = IsValid(self.Hook) and self.Hook:GetPos() or (ply:EyePos() + ply:GetAimVector() * 40)
	local fishMdl = (fish and TrueFishGetFishModel(fish)) or "models/fishing/fish_bass.mdl"
	if fish == FISH_JUNK then
		fishMdl = "models/fishing/fish_bass.mdl"
	end

	if IsValid(self.Hook) then
		self.Hook:RemoveFish()
		self.Hook:SetNoDraw(true)
		local phys = self.Hook:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end
		self.Hook:SetPos(ply:GetPos())
	end

	self.HookedFishID = nil
	self.FishCaughtID = nil
	self.FishEscapeTime = nil
	self:SetNW2Int("HookedFishID", 0)
	self:SetNW2Int("FishCaughtID", 0)
	self:SetNW2Float("FishEscapeTime", 0)
	self:SetNW2Bool("IsHookActive", false)
	self.Owner.IsFishing = false

	self:AdjustRope(10)

	net.Start("rod_phys_End")
	net.Send(ply)

	-- Spawnea la entidad del pez rabioso que salta y ataca al jugador
	local angry = ents.Create("ent_angry_fish")
	if IsValid(angry) then
		angry.FishModel = fishMdl
		angry.FishID = fish
		angry:SetPos(spawnPos)
		angry:SetAngles(ply:EyeAngles())
		angry:Spawn()
		angry:SetAngryTarget(ply)

		-- Salto inicial GRANDE HACIA ARRIBA: el pez se impulsa al aire para que
		-- el jugador NO reciba daño en el primer contacto (tiempo de reacción).
		local phys = angry:GetPhysicsObject()
		if IsValid(phys) then
			local scatter = Vector(math.random(-80, 80), math.random(-80, 80), 0)
			phys:SetVelocity(Vector(0, 0, 720) + scatter)
			phys:AddAngleVelocity(Vector(math.random(-500, 500), math.random(-500, 500), math.random(-700, 700)))
		end
	end

	local fishName = (fish and TrueFishGetFishName(fish)) or "pez"
	ply:EmitSound("npc/headcrab/headcrab_attack1.wav", 85, math.random(90, 105))
	ply:EmitSound("ambient/water/water_splash1.wav", 80, 120)
	TrueFishNotify(ply, "¡SACASTE UN " .. string.upper(fishName) .. " PERO ESTÁ ENFURECIDO Y TE ATACA! ¡PELEA CON ÉL!")
end

function SWEP:Holster()
	if SERVER then
		if self.FishCaughtID and self.FishCaughtID > 0 then
			self:ReleaseAngryFish()
		elseif self.HookedFishID and self.HookedFishID > 0 then
			if IsValid(self.Hook) then self.Hook:RemoveFish() end
			self.HookedFishID = nil
			self:SetNW2Int("HookedFishID", 0)
		end
		if self.Owner and self.Owner.IsFishing then
			self.Owner.IsFishing = false
			self:SetNW2Bool("IsHookActive", false)
			if IsValid(self.Hook) then
				self.Hook:SetNoDraw(true)
				local phys = self.Hook:GetPhysicsObject()
				if IsValid(phys) then phys:EnableMotion(false) end
				self.Hook:SetPos(self.Owner:GetPos())
			end
			self:AdjustRope(10)
			net.Start("rod_phys_End")
			net.Send(self.Owner)
		end
	end
	if CLIENT then
		if IsValid(self.ClientHookModel) then self.ClientHookModel:Remove() self.ClientHookModel = nil end
		if IsValid(self.ClientFishModel) then self.ClientFishModel:Remove() self.ClientFishModel = nil end
		self.HookPhysPos = nil
		self.HookPhysVel = nil
		self.WasCaughtLastFrame = nil
	end
	return true
end

function SWEP:OnRemove()
	if SERVER then
		if self.FishCaughtID and self.FishCaughtID > 0 then
			self:ReleaseAngryFish()
		elseif self.HookedFishID and self.HookedFishID > 0 then
			if IsValid(self.Hook) then self.Hook:RemoveFish() end
			self.HookedFishID = nil
			self:SetNW2Int("HookedFishID", 0)
		end
		if IsValid(self.Hook) then
			self.Hook:Remove()
		end
		if IsValid(self.WeaponModel) then
			self.WeaponModel:Remove()
		end
	end
	if CLIENT then
		if IsValid(self.ClientHookModel) then self.ClientHookModel:Remove() self.ClientHookModel = nil end
		if IsValid(self.ClientFishModel) then self.ClientFishModel:Remove() self.ClientFishModel = nil end
		self.HookPhysPos = nil
		self.HookPhysVel = nil
		self.WasCaughtLastFrame = nil
	end
end



/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/
