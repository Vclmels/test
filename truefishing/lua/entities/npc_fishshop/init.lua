/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/
AddCSLuaFile("cl_init.lua")

ENT.Base = "base_ai" 
ENT.Type = "ai"
ENT.PrintName = "Fish Shop"
ENT.Category = "TrueFishing"
ENT.Spawnable = true

function ENT:SpawnFunction(ply, tr)
	if !tr.Hit then return end

	local ent = ents.Create("npc_fishshop")
	ent:SetPos(tr.HitPos + tr.HitNormal * 2)
	ent:SetAngles(Angle(0, ply:EyeAngles().y - 180, 0))
	ent:SetModel("models/Humans/Group01/male_07.mdl")
	ent:Spawn()
	ent:Activate()
	return ent
end

local posFile = file.Read("fish_npc_positions.txt", "DATA")

FISH_NPCS = FISH_NPCS or {}

local function SpawnFishingNPC(id, pos, angle, model)
	timer.Simple(2.5, function()
		if IsValid(FISH_NPCS[id]) then //fixes auto refresh npc spawning
			FISH_NPCS[id].IsToRemove = true
			FISH_NPCS[id]:Remove()
		end
		local ent = ents.Create("npc_fishshop")
		FISH_NPCS[id] = ent
		if !ent:IsValid() then return end
		ent:SetPos(pos)
		ent:SetAngles(Angle(0, angle, 0))
		ent:SetModel(model)
		ent:Spawn()
		print("Created Fishing NPC with id:", ent:EntIndex())
	end)
end

function CreateFishingNPC(pos, angle, model)
	posFile[game.GetMap()] = posFile[game.GetMap()] or {}
	local id = table.insert(posFile[game.GetMap()],  {pos, angle, model})
	file.Write("fish_npc_positions.txt", util.TableToJSON(posFile))
	SpawnFishingNPC(id, pos, angle, model)
	
end

function DeleteFishingNPC(ent)
	for i=1, #FISH_NPCS do
		if FISH_NPCS[i] == ent then
			FISH_NPCS[i].IsToRemove = true
			FISH_NPCS[i]:Remove()
			
			table.remove(posFile[game.GetMap()], i)
			file.Write("fish_npc_positions.txt", util.TableToJSON(posFile))
			return true
		end
	end
end

hook.Add("InitPostEntity", "TrueFishLoadNPCS", function()
	if posFile and posFile != "" then
		posFile = util.JSONToTable(posFile)
		
		local map = game.GetMap()
		if posFile[map] then
			if posFile[map][1] and type(posFile[map][1]) != "table" then // for older versions
				local pos, ang, mdl = posFile[map][1], posFile[map][2], posFile[map][3]
				posFile[map] = {}
				table.insert(posFile[map], {pos, ang, mdl})
			end
			for i=1, #posFile[map] do
				SpawnFishingNPC(i, posFile[map][i][1], posFile[map][i][2], posFile[map][i][3])
			end
		end
	else
		posFile = {[game.GetMap()] = {},}
	end
end)

local schdStay = ai_schedule.New("FishShop NPC Stay")
local NewTask = ai_task.New()
NewTask:InitEngine("TASK_WAIT_INDEFINITE", 0) NewTask.TaskID = 1
schdStay.TaskCount = table.insert(schdStay.Tasks, NewTask)

local function FindSpotAroundNPC(npc, ent)
	local pos = npc:GetPos()
	
	local min, max = ent:GetCollisionBounds()
	pos.z = pos.z + 5.5 + max.z
	local trace = {mins = min,
				   maxs = max,
				   filter = npc}

	for a=1, 1.5, 0.5 do
		for i=0, math.pi*2, math.pi/6 do
			local x, y = math.cos(i)*45*a, math.sin(i)*45*a
			pos.x = pos.x + x - 22.5*a
			pos.y = pos.y + y - 90*a		
			trace.start = pos + Vector(0, 0, 72)
			trace.endpos = pos
			local tr1 = util.TraceLine(trace)			
			
			if tr1.HitWorld or !tr1.Hit then
				tr1.HitPos.z = tr1.HitPos.z + 5
				trace.start = tr1.HitPos
				trace.endpos = tr1.HitPos
				local tr2 = util.TraceHull(trace)
				if !tr2.Hit then
					return pos
				end
			end
			
			pos.x = pos.x + 22.5*a
			pos.y = pos.y + 90*a
		end
	end


end

util.AddNetworkString("FishNPCMenu")
util.AddNetworkString("Fish_buy")
util.AddNetworkString("Fish_sell")

local CageLimitToVar = {fishing_pot_medium = "MediumFishingPot", fishing_pot_large = "LargeFishingPot", fish_container = "FishContainers"}
local CageCFGLimitToVar = {fishing_pot_medium = "MEDIUM_CAGE_LIMIT", fishing_pot_large = "LARGE_CAGE_LIMIT", fish_container = "CONTAINER_LIMIT"}

local function GearLimitReached(ply, var, id)
	local limit = CageLimitToVar[var]
	if TrueFish.CAGE_SHARED_LIMIT and (id == FISH_GEAR_MEDIUMCAGE or id == FISH_GEAR_LARGECAGE) then
		return ply.FishingEquipment and ply.FishingEquipment >= TrueFish.MEDIUM_CAGE_LIMIT
	else
		return limit and ply[limit] and ply[limit] >= TrueFish[CageCFGLimitToVar[var]]
	end
end

local function BuyFishGear(len, ply)
	local npc, id = net.ReadEntity(), net.ReadUInt(6)
	local price = TrueFish.GEAR_PRICE[id]
	if !npc:IsValid() or npc:GetClass() != "npc_fishshop" or !price or !TrueFish.GEAR_ENABLED[id] or npc:GetPos():Distance(ply:GetPos()) > 175 then return end
	if !TrueFishCanAfford(ply, price)  then
		TrueFishNotify(ply, TrueFishLocal("cant_afford"))
		return
	end 
	
	if id == FISH_GEAR_ROD then
		ply:Give(TrueFish.ROD_PHYSICS_FISHING and "fishing_rod_physics" or "fishing_rod")
	elseif id == FISH_GEAR_FISHFINDER then
		ply:Give("fish_finder")
	elseif TrueFishBosses and TrueFishBosses[id] then
		ply.EquippedBossHook = id
		local wep = ply:GetWeapon("fishing_rod_physics")
		if not IsValid(wep) then
			wep = ply:Give("fishing_rod_physics")
		end
		if IsValid(wep) then
			wep:SetNW2Int("SpecialHookID", id)
			if IsValid(wep.Hook) then
				local boss = TrueFishBosses[id]
				if boss and boss.hookModel then
					wep.Hook:SetModel(boss.hookModel)
				end
			end
		end
		ply:SelectWeapon("fishing_rod_physics")
		TrueFishGiveMoney(ply, -price)
		TrueFishNotify(ply, "¡Has equipado el " .. TrueFishGetGearName(id) .. "! (1 solo uso para pelear con el jefe)")
		ply:EmitSound("garrysmod/save_load1.wav", 75, 100)
		return
	else
		local class = TrueFishGetGearEntityName(id)
		
		if GearLimitReached(ply, class, id) then
			TrueFishNotify(ply, TrueFishLocal("fish_limit_reached", TrueFishGetGearName(id)))
			return
		end
		
		local ent = ents.Create(class)
		local pos = FindSpotAroundNPC(npc, ent)
		if !pos then
			ent:Remove()
			TrueFishNotify(ply, TrueFishLocal("fisherman_spots_full"))
			return
		end
		ent:SetPos(pos)
		ent.SID = ply:UserID()
		if id == FISH_GEAR_BAIT then
			ent.SpawnTime = CurTime()
		end
		if ent.CPPISetOwner then
			ent:CPPISetOwner(ply)
		end
		ent.Owner = ply
		ent:Spawn()
		
		local var = CageLimitToVar[class]
		if var then
			if TrueFish.CAGE_SHARED_LIMIT and (id == FISH_GEAR_MEDIUMCAGE or id == FISH_GEAR_LARGECAGE) then
				ply.FishingEquipment = ply.FishingEquipment and ply.FishingEquipment + 1 or 1
			else
				ply[var] = ply[var] and ply[var] + 1 or 1 
			end
		end	
	
	end
	
	TrueFishGiveMoney(ply, -price)
	TrueFishNotify(ply, TrueFishLocal("bought_gear", TrueFishGetGearName(id)))

end
net.Receive("Fish_buy", BuyFishGear)


local function SellFishContainer(len, ply)

	local npc = ents.GetByIndex(net.ReadUInt(13))
	if !npc:IsValid() or npc:GetClass() != "npc_fishshop" or npc:GetPos():Distance(ply:GetPos()) > 175 then return end
	
	local totalReward = 0
	local fishCount = 0
	if ply.Fishes then
		for i=1, FISH_HIGHNUMBER do
			local contFish = ply.Fishes[i]
			if contFish and TrueFish.FISH_ENABLED[i] then
				totalReward = totalReward + TrueFish.FISH_PRICE[i] * contFish
				fishCount = fishCount + contFish
				ply.Fishes[i] = 0
			end
		end
	end
	
	for k, v in pairs(ents.FindInSphere(npc:GetPos(), 330)) do
		if v:GetClass() == "fish_container" and v.Owner == ply then
			for i=1, FISH_HIGHNUMBER do
				local contFish = v.Fishes[i]
				if contFish and TrueFish.FISH_ENABLED[i] then
					totalReward = totalReward + TrueFish.FISH_PRICE[i] * contFish
					fishCount = fishCount + contFish
					v.Fishes[i] = 0
				end
			end
			v:UpdateFishes()
		end
	end
	
	if totalReward > 0 then
		TrueFishGiveMoney(ply, totalReward)
		TrueFishNotify(ply, TrueFishLocal("sold_fish", totalReward))
	end
	
	-- XP de Pesca (CatLevels) por pescado vendido
	if fishCount > 0 and CatLevels and CatLevels.AddXP then
		CatLevels:AddXP(ply, "Pesca", fishCount * 10)
		DarkRP.notify(ply, 0, 4, "¡Ganaste " .. (fishCount * 10) .. " XP de Pesca!")
	end
	
end
net.Receive("Fish_sell", SellFishContainer)

function ENT:Initialize()
	self.NextUse = 0
 
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
 
	self:SetSolid(SOLID_BBOX) 
	self:SetMoveType(MOVETYPE_STEP)
 
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_OPEN_DOORS, CAP_ANIMATEDFACE, CAP_TURN_HEAD, CAP_USE_SHOT_REGULATOR, CAP_AIM_GUN))
 
	self:SetMaxYawSpeed(5000)
		
	self:SetUseType(SIMPLE_USE)	
end
	
function ENT:SelectSchedule()
	self:StartSchedule(schdStay)
end


function ENT:AcceptInput(name, activator, caller)
	if( !caller:IsValid() || !caller:IsPlayer() || name != "Use" ) or self.NextUse > CurTime() then return end	
	self.NextUse = CurTime() + caller:Ping()*0.002
	
	net.Start("FishNPCMenu")
	net.WriteEntity(self)
	
	net.WriteUInt(FISH_HIGHNUMBER, 6)
	for i=1, FISH_HIGHNUMBER do
		net.WriteUInt(i, 6)
		net.WriteUInt(TrueFish.FISH_PRICE[i], 16)
		net.WriteBool(TrueFish.FISH_ENABLED[i])
	end
	
	net.WriteUInt(FISH_GEAR_HIGHNUMBER, 6)
	for i=1, FISH_GEAR_HIGHNUMBER do
		net.WriteUInt(i, 6)
		local gearPrice = (TrueFish.GEAR_PRICE and TrueFish.GEAR_PRICE[i]) or (TrueFishBosses and TrueFishBosses[i] and TrueFishBosses[i].price) or 100
		local gearEnabled = (TrueFish.GEAR_ENABLED and TrueFish.GEAR_ENABLED[i])
		if gearEnabled == nil then gearEnabled = true end
		net.WriteUInt(gearPrice, 16)
		net.WriteBool(gearEnabled)
	end
	
	if caller.Fishes then
		for i=1, FISH_HIGHNUMBER do
			local contFish = caller.Fishes[i]
			if contFish and contFish > 0 and TrueFish.FISH_ENABLED[i] then
				net.WriteUInt(i, 6)
				net.WriteUInt(contFish, 8)
			end
		end
	end
		
	for k, v in pairs(ents.FindInSphere(self:GetPos(), 330)) do
		if v:GetClass() == "fish_container" and v.Owner == caller then
			for i=1, FISH_HIGHNUMBER do
				local contFish = v.Fishes[i]
				if contFish and contFish > 0 and TrueFish.FISH_ENABLED[i] then
					net.WriteUInt(i, 6)
					net.WriteUInt(contFish, 8)
				end
			end
		end
	end
	
	net.WriteUInt(0, 6) // end while loop for reading clientside
	net.Send(caller)
end

function ENT:OnRemove()
	if self.IsToRemove then return end
	for i=1, #FISH_NPCS do
		if FISH_NPCS[i] == self then
			SpawnFishingNPC(i, self:GetPos(), self:GetAngles().y, self:GetModel())
			return
		end
	end
end

/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/
