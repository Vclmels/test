/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/

if SERVER then
	AddCSLuaFile("shared.lua")
	util.AddNetworkString("rod_Fishing")
	util.AddNetworkString("rod_Pull")
	util.AddNetworkString("rod_End")
end

if CLIENT then
	SWEP.PrintName = "Fishing Rod"
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
SWEP.WorldModel = "models/props_junk/harpoon002a.mdl"
SWEP.ViewModel = "models/fishing/v_fishing_rod_cast.mdl"
SWEP.ViewModelFOV = 62
SWEP.UseHands = false

-- Ajuste de posición en primera persona (X: Der/Izq, Y: Adelante/Atrás, Z: Arriba/Abajo)
SWEP.ViewModelOffset = Vector(0, 0, -2)

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
end

function SWEP:DrawWorldModel()
	if !IsValid(self.WeaponModel) then self:Deploy(true) end
	local pos, ang = self.Owner:GetBonePosition(self.Owner:LookupBone("ValveBiped.Bip01_R_Hand", false))
	
	
	ang:RotateAroundAxis(ang:Right(), -55)
	pos = pos - ang:Forward()*6.5 + ang:Up()*1.8 + ang:Right()*1

	self.WeaponModel:SetPos(pos)
	self.WeaponModel:SetAngles(ang)
	self.WeaponModel:DrawModel()
	return true
end

function SWEP:Deploy(fromNotEngine)
	if CLIENT then
		if !IsValid(self.WeaponModel) then
			self.WeaponModel = ClientsideModel("models/fishing/pole.mdl", RENDERGROUP_OPAQUE)
			self.WeaponModel:DrawShadow(false)
			self.WeaponModel:SetNoDraw(true)
		end
	end

	self.DrawFishing = nil
	self.CastAnimationEnd = nil
	if IsValid(self.Owner) then
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

function SWEP:Holster()
	if CLIENT and LocalPlayer() == self.Owner then
		self.DrawFishing = nil
		self.CastAnimationEnd = nil
		if IsValid(self.WeaponModel) then
			self.WeaponModel:Remove()
			self.WeaponModel = nil
		end
	end
	if SERVER then
		if IsValid(self.Ball) then
			self.Ball:Remove()
			self.Ball = nil
		end
		self.Owner:SetMoveType(MOVETYPE_WALK)
		self.Owner.IsFishing = nil
	end
	return true
end

if CLIENT then
	hook.Remove("CalcView", "Fishing Rod")
	if IsValid(LocalPlayer()) then
		LocalPlayer().ThirdView = nil
	end

	function SWEP:Think()
		if self.CastAnimationEnd and CurTime() >= self.CastAnimationEnd then
			self.CastAnimationEnd = nil
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				local idle = vm:LookupSequence("idle")
				if idle >= 0 then
					vm:SendViewModelMatchingSequence(idle)
					vm:SetPlaybackRate(1)
					vm:SetCycle(0)
				end
			end
			return
		end

		local owner = self.Owner
		if not IsValid(owner) then return end
		local vm = owner:GetViewModel()
		if not IsValid(vm) then return end

		-- Preparar lanzamiento con click derecho si no está pescando
		if not self.DrawFishing and not owner.IsFishing then
			if owner:KeyDown(IN_ATTACK2) then
				if not self.IsHoldingReady then
					self.IsHoldingReady = true
					self.HoldingInHoldLoop = nil
					local readySeq = vm:LookupSequence("cast_ready")
					if readySeq >= 0 then
						local dur = vm:SequenceDuration(readySeq)
						self.ReadyHoldEndTime = CurTime() + (dur > 0 and dur or 0.36)
						vm:SendViewModelMatchingSequence(readySeq)
						vm:SetPlaybackRate(1)
						vm:SetCycle(0)
					end
				elseif not self.HoldingInHoldLoop then
					if CurTime() >= (self.ReadyHoldEndTime or 0) then
						self.HoldingInHoldLoop = true
						local holdSeq = vm:LookupSequence("cast_ready_hold")
						if holdSeq >= 0 then
							vm:SendViewModelMatchingSequence(holdSeq)
							vm:SetPlaybackRate(1)
							vm:SetCycle(0)
						end
					end
				else
					local holdSeq = vm:LookupSequence("cast_ready_hold")
					if holdSeq >= 0 and vm:GetSequence() ~= holdSeq then
						vm:SendViewModelMatchingSequence(holdSeq)
						vm:SetPlaybackRate(1)
						vm:SetCycle(0)
					end
				end
			elseif self.IsHoldingReady then
				self.IsHoldingReady = nil
				self.HoldingInHoldLoop = nil
				local idle = vm:LookupSequence("idle")
				if idle >= 0 then
					vm:SendViewModelMatchingSequence(idle)
					vm:SetPlaybackRate(1)
					vm:SetCycle(0)
				end
			end
		end
	end
	
	function SWEP:DrawHUD()
		if !self.DrawFishing then return end

		local left = (self.StartedFishing+self.DrawFishing-CurTime())/self.DrawFishing
		if left < 0 then return end
		left = left - 0.5
		
		local x, y = math.floor(TFScreenScale(81)), math.floor(TFScreenScale(7))

		surface.SetDrawColor(0, 0, 0, 135)
		surface.DrawRect(ScrW()*0.5-x*0.5, ScrH()*0.8, x, y)
		for i=1, y do
			surface.SetDrawColor(0, 0.5*i*y, 0, 255)
			surface.DrawLine(ScrW()*0.5-x*0.5, ScrH()*0.8+i-1, ScrW()*0.5+x*left, ScrH()*0.8+i-1)
		end
		for i=1, 4 do
			surface.SetDrawColor(125+i*10, 125+i*10, 125+i*10, 255)
			surface.DrawOutlinedRect(ScrW()*0.5-x*0.5-i, ScrH()*0.8-i, x+i*2, y+i*2)
		end
		draw.SimpleText(TrueFishLocal("fishing_hud"), "SegoeUI_NormalBoldScaled", ScrW()*0.5, ScrH()*0.8-TFScreenScale(1), Color(220, 220, 220, 255), TEXT_ALIGN_CENTER)
	end

	
	net.Receive("rod_Fishing", function()
		local owner = LocalPlayer()
		if !owner or !owner:IsValid() then return end
		local wep = owner:GetActiveWeapon()
		if !wep or !wep:IsValid() or wep:GetClass() != "fishing_rod" then return end
		
		local wait = net.ReadUInt(12)
		if wait != 0 then
			wep.DrawFishing = wait
			wep.StartedFishing = CurTime()-owner:Ping()*0.001
			local vm = owner:GetViewModel()
			if IsValid(vm) then
				local castSeq = vm:LookupSequence("cast")
				if castSeq >= 0 then
					local dur = vm:SequenceDuration(castSeq)
					wep.CastAnimationEnd = CurTime() + (dur > 0 and dur or 2.6)
					vm:SendViewModelMatchingSequence(castSeq)
					vm:SetPlaybackRate(1)
					vm:SetCycle(0)
				end
			end
		end
		
	end)

	net.Receive("rod_Pull", function()
		local ent = net.ReadEntity()
		ent.Slashing = true		
	end)

	net.Receive("rod_End", function()
		local owner = LocalPlayer()
		if !owner or !owner:IsValid() then return end
		local wep = owner:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "fishing_rod" then
			wep.CastAnimationEnd = nil
			wep.DrawFishing = nil
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
end

local emptyf = function() end//destroy click sound
SWEP.PrimaryAttack = emptyf
SWEP.SecondaryAttack = emptyf
if CLIENT then return end

function SWEP:OnRemove()
	if IsValid(self.Ball) then
		self.Ball:Remove()
	end
end

function SWEP:Think()
	if self.Owner.IsFishing then
		local ctime = CurTime()
		if self.FishingEndTime <= ctime then
			self:NoCatch()
		elseif self.FishingTimeWindow <= ctime then
			net.Start("rod_Pull")
			net.WriteEntity(self.Ball)
			net.SendPVS(self.Ball:GetPos())
			self.Owner.IsFishing = 1
			self.FishingTimeWindow = self.FishingEndTime
		end
	end
end

function SWEP:PrimaryAttack()
	
	if self.Owner.IsFishing or !self.Owner:OnGround() or self.Owner:GetVelocity() != Vector(0,0,0) then return end

	if !self.Owner.FishBait or self.Owner.FishBait == 0 then
		TrueFishNotify(self.Owner, TrueFishLocal("no_fish_bait"))
		return false
	end
	
	
	local ang = self.Owner:GetAngles()
	ang.r = 0
	ang.p = 0
	local tracedata = {start = self.Owner:GetPos()+ang:Forward()*(350+math.random(-100, 100))+ang:Right()*math.random(-120, 120)}
	tracedata.start.z = tracedata.start.z + 50
	tracedata.endpos = Vector(tracedata.start.x, tracedata.start.y, tracedata.start.z-80)
	local trace = util.TraceLine(tracedata)
	tracedata.start.z = tracedata.start.z + 50
	tracedata.endpos.z = tracedata.endpos.z - 130
	tracedata.mask = CONTENTS_SOLID + 268435488 + CONTENTS_OPAQUE
	local trace2 = util.TraceLine(tracedata)
	if !trace.Hit and trace2.HitWorld then
		self.Owner.FishBait = self.Owner.FishBait - 1
	
		tracedata.start = trace2.HitPos
		tracedata.endpos.z = tracedata.endpos.z - FISH_MAX_DEPTH
		tracedata.mask = MASK_OPAQUE
		trace = util.TraceLine(tracedata)
		self.Depth = !trace.Hit and FISH_MAX_DEPTH or math.Clamp(math.abs(trace.HitPos.z - tracedata.start.z), 15, FISH_MAX_DEPTH)

		local owner = self.Owner
		owner:SetMoveType(MOVETYPE_NONE)
		owner.IsFishing = true
		local vm = owner:GetViewModel()
		if IsValid(vm) then
			local castSeq = vm:LookupSequence("cast")
			if castSeq >= 0 then
				vm:SendViewModelMatchingSequence(castSeq)
				vm:SetPlaybackRate(1)
				vm:SetCycle(0)
			end
		end

		self.Ball = ents.Create("fishing_rod_buoy")
		self.Ball:Spawn()
		self.Ball:SetDTEntity(0, owner)
		self.Ball:SetPos(trace2.HitPos)
		

		local fish = TrueFishCalculateFish(self.Depth)
		local waitTime = TrueFish.ROD_SEPERATE_CATCH_TIME_ENABLED and TrueFish.ROD_SEPERATE_CATCH_TIME or !TrueFish.FISH_CATCH_TIME[fish] and TrueFish.ROD_SEPERATE_CATCH_TIME or math.random(TrueFish.FISH_CATCH_TIME[fish][1], TrueFish.FISH_CATCH_TIME[fish][2])
		net.Start("rod_Fishing")
		net.WriteUInt(waitTime, 12)
		net.Send(owner)
		self.FishingEndTime = CurTime() + waitTime
		self.FishingTimeWindow = self.FishingEndTime - waitTime*TrueFish.ROD_CATCH_WINDOW
		
		
	end
	
	
end

function SWEP:PlayerGetSpace()
	local space = 0
	for i=1, FISH_HIGHNUMBER do
		if self.Owner.Fishes[i] then
			space = space + self.Owner.Fishes[i]
		end
	end
	return space
end

function SWEP:NoCatch()
	self.Owner:SetMoveType(MOVETYPE_WALK)
	net.Start("rod_End")
	net.Send(self.Owner)
	self.Owner.IsFishing = false
	TrueFishNotify(self.Owner, TrueFishLocal("didnt_catch_anything"))
	self.Ball:Remove()
end

function SWEP:SecondaryAttack()
	if self.Owner.IsFishing == true then
		self:NoCatch()
		return
	end
	if self.Owner.IsFishing == 1 then
		self.Owner:SetMoveType(MOVETYPE_WALK)
		net.Start("rod_End")
		net.Send(self.Owner)
		self.Owner.IsFishing = false
		self.Ball:Remove()
		
		local fish = TrueFishCalculateFish(self.Depth)
		if math.random(1000) <= TrueFish.ROD_JUNK_CHANCE then
			fish = FISH_JUNK
		end
		
		if math.random(1000) <= TrueFish.ROD_MONEYBAG_CHANCE then // Yes, JUNK and MONEY BAG chances aren't 100% this way
			TrueFishGiveMoney(self.Owner, TrueFish.ROD_MONEYBAG_MONEY)
			TrueFishNotify(self.Owner, TrueFishLocal("money_bag_caught", TrueFish.ROD_MONEYBAG_MONEY))
			return
		end
		
		if !fish then
			TrueFishNotify(self.Owner, TrueFishLocal("didnt_catch_anything"))
			return
		end
		
		self.Owner.Fishes = self.Owner.Fishes or {}
		if TrueFish.ROD_NO_CONTAINER then
			if TrueFish.FISH_CARRY_LIMIT <= self:PlayerGetSpace() then
				TrueFishNotify(self.Owner, TrueFishLocal("carry_limit_reached", TrueFish.FISH_CARRY_LIMIT))
				return
			end
			TrueFishNotify(self.Owner, TrueFishLocal("fish_caught", TrueFishGetFishName(fish)))
			self.Owner.Fishes[fish] = self.Owner.Fishes[fish] and self.Owner.Fishes[fish]+1 or 1
			return
		end
		
		
		local dist = {}
		local distEnt = {}
		local find = ents.FindInSphere(self.Owner:GetPos(), 250)
		for i=1, #find do
			if find[i]:IsValid() and find[i]:GetClass() == "fish_container" then
				local d = self.Owner:GetPos():Distance(find[i]:GetPos())
				dist[#dist+1] = d
				distEnt[d] = find[i]
			end
		end
		
		if !dist[1] then
			TrueFishNotify(self.Owner, TrueFishLocal("empty_fish_containers_near"))
			return
		end
			
		local closest 
		for k, v in SortedPairsByValue(dist) do
			closest = distEnt[v]
			if closest:GetSpace() < TrueFish.FISH_CONTAINER_LIMIT then break end
		end
		
		if !closest then return end
		
		closest:AddFish(fish, 1)
		TrueFishNotify(self.Owner, TrueFishLocal("fish_caught", TrueFishGetFishName(fish)))
	
	end
	
end


/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/
