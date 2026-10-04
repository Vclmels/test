/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

include('shared.lua')

	
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:Draw()

	local owner = self:GetDTEntity(0)
	local Hook = self:GetDTEntity(1)
	local isLocalFirstPerson = IsValid(owner) and owner == LocalPlayer() and not (owner.ShouldDrawLocalPlayer and owner:ShouldDrawLocalPlayer())

	if not isLocalFirstPerson then
		local pos, ang = self:GetPos(), self:GetAngles()
		local tipPos = pos + ang:Forward() * 98 + ang:Up() * 0.25
		local isHookActive = IsValid(Hook) and not Hook:GetNoDraw()

		if isHookActive then
			-- El renderizado del hilo activo hacia el anzuelo lo maneja de forma unificada PostDrawTranslucentRenderables en shared.lua
		else
			-- Quieto / No pescando: el hilo blanco y el anzuelo cuelgan con física pendular dinámica
			if not self.HookPhysPos then
				self.HookPhysPos = tipPos - Vector(0, 0, 14)
				self.HookPhysVel = Vector(0, 0, 0)
			end

			local dt = math.Clamp(FrameTime(), 0.001, 0.05)
			self.HookPhysVel = (self.HookPhysVel or Vector(0, 0, 0)) + Vector(0, 0, -450) * dt
			self.HookPhysVel = self.HookPhysVel * (0.94 ^ (dt * 60))
			self.HookPhysPos = self.HookPhysPos + self.HookPhysVel * dt

			local diff = self.HookPhysPos - tipPos
			local dist = diff:Length()
			if dist > 14 then
				local n = diff / dist
				self.HookPhysPos = tipPos + n * 14
				local vDot = self.HookPhysVel:Dot(n)
				if vDot > 0 then
					self.HookPhysVel = self.HookPhysVel - n * vDot
				end
			end
			local hookPos = self.HookPhysPos

			local dir = (hookPos - tipPos):GetNormalized()
			local hookAng = dir:Angle()
			hookAng:RotateAroundAxis(hookAng:Right(), -90)

			render.SetColorMaterial()
			render.DrawBeam(tipPos, hookPos, 0.35, 0, 1, Color(255, 255, 255, 230))

			local specialHook = IsValid(owner) and IsValid(owner:GetActiveWeapon()) and owner:GetActiveWeapon():GetNW2Int("SpecialHookID", 0) or 0
			local hookMdl = "models/fishing/hook.mdl"
			if specialHook > 0 and TrueFishBosses and TrueFishBosses[specialHook] then
				hookMdl = TrueFishBosses[specialHook].hookModel or "models/fishing/hook.mdl"
			end

			if not IsValid(self.WorldHookModel) then
				self.WorldHookModel = ClientsideModel(hookMdl, RENDERGROUP_OPAQUE)
				if IsValid(self.WorldHookModel) then
					self.WorldHookModel:SetNoDraw(true)
					self.CurrentWorldHookMdl = hookMdl
				end
			elseif self.CurrentWorldHookMdl ~= hookMdl then
				self.WorldHookModel:SetModel(hookMdl)
				self.CurrentWorldHookMdl = hookMdl
			end
			if IsValid(self.WorldHookModel) then
				self.WorldHookModel:SetPos(hookPos)
				self.WorldHookModel:SetAngles(hookAng)
				self.WorldHookModel:DrawModel()
			end

			-- Pez capturado colgando en tercera persona
			local wep = IsValid(owner) and owner:GetActiveWeapon()
			local fishCaught = IsValid(wep) and wep:GetNW2Int("FishCaughtID", 0) or 0
			if fishCaught > 0 then
				local fishMdl = TrueFishGetFishModel(fishCaught) or "models/fishing/fish_bass.mdl"
				if not IsValid(self.WorldFishModel) then
					self.WorldFishModel = ClientsideModel(fishMdl, RENDERGROUP_OPAQUE)
					if IsValid(self.WorldFishModel) then
						self.WorldFishModel:SetNoDraw(true)
						self.CurrentWorldFishMdl = fishMdl
					end
				elseif self.CurrentWorldFishMdl ~= fishMdl then
					self.WorldFishModel:SetModel(fishMdl)
					self.CurrentWorldFishMdl = fishMdl
				end

				if IsValid(self.WorldFishModel) then
					local scale = (TrueFishGetHangScale and TrueFishGetHangScale(fishMdl)) or 1.0
					local mX = ((TrueFishGetMouthOffset and TrueFishGetMouthOffset(fishCaught)) or 11.0) * scale
					local barbPos = LocalToWorld(Vector(0, 0.4, -4.5), Angle(0, 0, 0), hookPos, hookAng)

					-- FÍSICA DEL PEZ: péndulo independiente (misma física del cebo/anzuelo).
					-- El pez cuelga de la púa con su propia posición/velocidad, reaccionando a la cámara con inercia.
					if not self.FishPhysPos then
						self.FishPhysPos = barbPos - Vector(0, 0, mX)
						self.FishPhysVel = Vector(0, 0, 0)
					end

					-- Impulso inicial al capturar para que el pez llegue con una oscilación viva
					if not self.FishCaughtImpulse then
						self.FishCaughtImpulse = true
						self.FishPhysVel = self.FishPhysVel + (IsValid(owner) and owner:GetAimVector() or Vector(0, 0, 0)) * 20 - (IsValid(owner) and owner:GetUp() or Vector(0, 0, 1)) * 10 + (IsValid(owner) and owner:GetRight() or Vector(1, 0, 0)) * 5
					end

					local dt = math.Clamp(FrameTime(), 0.001, 0.05)
					self.FishPhysVel = self.FishPhysVel + Vector(0, 0, -520) * dt
					self.FishPhysVel = self.FishPhysVel * (0.955 ^ (dt * 60))
					self.FishPhysPos = self.FishPhysPos + self.FishPhysVel * dt

					-- Restricción de cuerda: el pez cuelga de la púa a distancia mX (boca a mX del centro)
					local fDiff = self.FishPhysPos - barbPos
					local fDist = fDiff:Length()
					if fDist > mX then
						local n = fDiff / fDist
						self.FishPhysPos = barbPos + n * mX
						local vDot = self.FishPhysVel:Dot(n)
						if vDot > 0 then
							self.FishPhysVel = self.FishPhysVel - n * vDot
						end
					end

					-- Dirección real de la cuerda (de la púa al pez)
					local ropeDir = (self.FishPhysPos - barbPos):GetNormalized()

					-- Eje largo del pez = Y; la boca está en -Y. Vertical mirando a cámara, inclinado con la cuerda.
					local fishAng = Angle(0, (IsValid(owner) and owner:EyeAngles().y or 0), 90)
					local down = Vector(0, 0, -1)
					local axis = down:Cross(ropeDir)
					local axisLen = axis:Length()
					if axisLen > 0.0001 then
						axis = axis / axisLen
						local angleDeg = math.deg(math.acos(math.Clamp(down:Dot(ropeDir), -1, 1)))
						fishAng:RotateAroundAxis(axis, angleDeg)
					end

					-- La boca queda exactamente sobre la púa: centro = púa + Right()*mX
					local fishPos = barbPos + fishAng:Right() * mX

					self.WorldFishModel:SetModelScale(scale, 0)

					self.WorldFishModel:SetPos(fishPos)
					self.WorldFishModel:SetAngles(fishAng)
					self.WorldFishModel:DrawModel()
				end
			elseif IsValid(self.WorldFishModel) then
				self.WorldFishModel:Remove()
				self.WorldFishModel = nil
				self.CurrentWorldFishMdl = nil
				self.FishPhysPos = nil
				self.FishPhysVel = nil
				self.FishCaughtImpulse = nil
			end
		end
	end

	if IsValid(owner) then
		local pos, ang = owner:GetBonePosition(owner:LookupBone("ValveBiped.Bip01_R_Hand", false))
		ang:RotateAroundAxis(ang:Right(), -55)
		pos = pos - ang:Forward()*6.5 + ang:Up()*1.8 + ang:Right()*1
		self:SetRenderOrigin(pos)
		self:SetRenderAngles(ang)
	end
	
	if isLocalFirstPerson then
		return
	end

	self:DrawModel()
end

function ENT:OnRemove()
	if IsValid(self.WorldHookModel) then
		self.WorldHookModel:Remove()
		self.WorldHookModel = nil
	end
	if IsValid(self.WorldFishModel) then
		self.WorldFishModel:Remove()
		self.WorldFishModel = nil
		self.CurrentWorldFishMdl = nil
	end
end

/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/