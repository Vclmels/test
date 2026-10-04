/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
------------------------------------------------------------*/

include('shared.lua')

ENT.RenderGroup = RENDERGROUP_OPAQUE

-- ============================================================
-- ABRIR CAJA MANTENIENDO PULSADA LA E
-- ============================================================
local OPEN_DURATION = 1.5 -- segundos que hay que mantener la E

local holdEnt = nil
local holdStart = 0

-- ESTADO DEL MENÚ (declarado arriba para poder cerrarlo desde el Think de la E)
local BoxFrame = nil
local BoxState = nil -- { entIndex, limit, box = {[id]=count}, inv = {[id]=count} }

local function DrawProgressCircle(x, y, radius, progress)
	local seg = 48

	-- aro de fondo
	local bg = { { x = x, y = y } }
	for i = 0, seg do
		local a = math.rad(i / seg * 360)
		bg[#bg + 1] = { x = x + math.cos(a) * radius, y = y + math.sin(a) * radius }
	end
	surface.SetDrawColor(0, 0, 0, 130)
	draw.NoTexture()
	surface.DrawPoly(bg)

	-- relleno oscuro
	local inner = { { x = x, y = y } }
	for i = 0, seg do
		local a = math.rad(i / seg * 360)
		inner[#inner + 1] = { x = x + math.cos(a) * (radius - 3), y = y + math.sin(a) * (radius - 3) }
	end
	surface.SetDrawColor(12, 12, 28, 230)
	draw.NoTexture()
	surface.DrawPoly(inner)

	-- arco azul de progreso
	local n = math.max(1, math.ceil(seg * math.Clamp(progress, 0, 1)))
	local arc = { { x = x, y = y } }
	for i = 0, n do
		local a = math.rad(-90 + 360 * math.Clamp(progress, 0, 1) * (i / n))
		arc[#arc + 1] = { x = x + math.cos(a) * (radius - 1.5), y = y + math.sin(a) * (radius - 1.5) }
	end
	surface.SetDrawColor(0, 150, 255, 255)
	draw.NoTexture()
	surface.DrawPoly(arc)
end

hook.Add("Think", "FishBoxHoldE", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then holdEnt = nil return end

	local tr = ply:GetEyeTrace()
	local ent = tr.Entity

	local canOpen = IsValid(ent)
		and ent:GetClass() == "fish_container"
		and not ent:GetNW2Bool("BoxOpen", false)
		and ply:EyePos():Distance(tr.HitPos) <= 140

	if canOpen and input.IsKeyDown(KEY_E) then
		if holdEnt ~= ent then
			holdEnt = ent
			holdStart = CurTime()
		end
		if CurTime() - holdStart >= OPEN_DURATION then
			holdEnt = nil
			net.Start("FishBoxOpenRequest")
			net.WriteUInt(ent:EntIndex(), 13)
			net.SendToServer()
		end
	else
		holdEnt = nil
	end
end)

-- ============================================================
-- MENÚ DE LA CAJA — mismo estilo que el bolsillo (bolsillo_custom_v5)
-- ============================================================
local CLR = {
	bg           = Color(23, 20, 35, 230),
	header       = Color(15, 13, 25, 240),
	purple       = Color(81, 56, 237),
	purple_hover = Color(95, 75, 245),
	purple_dim   = Color(81, 56, 237, 60),
	item_bg      = Color(30, 27, 45, 240),
	item_hover   = Color(40, 36, 60, 255),
	cyan         = Color(0, 190, 255),
	white        = Color(248, 247, 252),
	white_dim    = Color(248, 247, 252, 80),
	grey         = Color(150, 150, 150),
	red          = Color(220, 60, 60),
	red_hover    = Color(245, 80, 80),
	green        = Color(80, 220, 100),
	close_hover  = Color(255, 80, 80, 40),
}

local function FishBoxFont(name, size, weight)
	surface.CreateFont(name, {
		font      = "Georama",
		extended  = false,
		size      = size,
		weight    = weight or 500,
		antialias = true,
		shadow    = false,
	})
end

FishBoxFont("FishBox.Title",     ScreenScale(10), 900)
FishBoxFont("FishBox.Counter",   ScreenScale(7),  700)
FishBoxFont("FishBox.Section",   ScreenScale(6),  700)
FishBoxFont("FishBox.ItemName",  ScreenScale(6),  600)
FishBoxFont("FishBox.ItemCount", ScreenScale(6),  700)
FishBoxFont("FishBox.Button",    ScreenScale(5),  700)
FishBoxFont("FishBox.Empty",     ScreenScale(7),  500)
FishBoxFont("FishBox.Close",     ScreenScale(8),  700)

local SOUNDS = {
	hover = "garrysmod/ui_hover.wav",
	click = "garrysmod/ui_click.wav",
}

local blurMat = Material("pp/blurscreen")
local function DrawBlurBG(panel, amount)
	local x, y = panel:LocalToScreen(0, 0)
	local scrW, scrH = ScrW(), ScrH()
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial(blurMat)
	for i = 1, 3 do
		blurMat:SetFloat("$blur", (i / 3) * (amount or 6))
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
	end
end

-- ============================================================
-- ESTADO DEL MENÚ
-- ============================================================

local function MakeFishCard(scroll, fishID, count, actionText, actionCol, actionColHover, mode)
	local card = scroll:Add("DPanel")
	card:SetTall(ScreenScale(78))
	card.HoverAnim = 0
	card.PlayedHover = false

	card.Paint = function(s, w, h)
		local dt = FrameTime()
		local isHover = s:IsChildHovered(true) or s:IsHovered()

		if isHover and not s.PlayedHover then
			surface.PlaySound(SOUNDS.hover)
			s.PlayedHover = true
		elseif not isHover then
			s.PlayedHover = false
		end

		s.HoverAnim = Lerp(dt * 8, s.HoverAnim, isHover and 1 or 0)

		local r = Lerp(s.HoverAnim, CLR.item_bg.r, CLR.item_hover.r)
		local g = Lerp(s.HoverAnim, CLR.item_bg.g, CLR.item_hover.g)
		local b = Lerp(s.HoverAnim, CLR.item_bg.b, CLR.item_hover.b)
		draw.RoundedBox(6, 0, 0, w, h, Color(r, g, b, 240))

		local a = Lerp(s.HoverAnim, 100, 237)
		draw.RoundedBoxEx(6, 0, 0, w, 3, Color(CLR.purple.r, CLR.purple.g, CLR.purple.b, a), true, true, false, false)
	end

	-- Vista 3D del pez
	local modelPanel = vgui.Create("DModelPanel", card)
	modelPanel:SetPos(ScreenScale(8), ScreenScale(6))
	modelPanel:SetSize(ScreenScale(66), ScreenScale(66))
	modelPanel:SetModel(TrueFishGetFishModel(fishID))
	modelPanel:SetMouseInputEnabled(false)
	modelPanel:SetAlpha(0)
	modelPanel:AlphaTo(255, 0.2, 0)
	modelPanel.LayoutEntity = function(s, ent)
		if card:IsChildHovered(true) or card:IsHovered() then
			ent:SetAngles(Angle(0, RealTime() * 40, 0))
		end
	end
	timer.Simple(0, function()
		if IsValid(modelPanel) and IsValid(modelPanel.Entity) then
			local mn, mx = modelPanel.Entity:GetRenderBounds()
			local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
			if size < 1 then size = 20 end
			modelPanel:SetFOV(45)
			modelPanel:SetCamPos(Vector(size * 1.5, size * 1.5, size * 1.2))
			modelPanel:SetLookAt((mn + mx) * 0.5)
		end
	end)

	-- Nombre
	local nameLbl = vgui.Create("DLabel", card)
	nameLbl:SetPos(ScreenScale(84), ScreenScale(14))
	nameLbl:SetFont("FishBox.ItemName")
	nameLbl:SetTextColor(CLR.white)
	nameLbl:SetText(TrueFishGetFishName(fishID) or "Pez")

	-- Cantidad
	local countLbl = vgui.Create("DLabel", card)
	countLbl:SetPos(ScreenScale(84), ScreenScale(40))
	countLbl:SetFont("FishBox.ItemCount")
	countLbl:SetTextColor(CLR.cyan)
	countLbl:SetText("x" .. count)

	-- Botón de acción (Sacar / Guardar)
	local btn = vgui.Create("DButton", card)
	btn:SetSize(ScreenScale(90), ScreenScale(30))
	btn:SetText("")
	btn.ColorLerp = 0
	btn.PlayedHover = false
	btn.Paint = function(s, w, h)
		local dt = FrameTime()
		local isHover = s:IsHovered()

		if isHover and not s.PlayedHover then
			surface.PlaySound(SOUNDS.hover)
			s.PlayedHover = true
		elseif not isHover then
			s.PlayedHover = false
		end

		s.ColorLerp = Lerp(dt * 8, s.ColorLerp, isHover and 1 or 0)
		local r = Lerp(s.ColorLerp, actionCol.r, actionColHover.r)
		local g = Lerp(s.ColorLerp, actionCol.g, actionColHover.g)
		local b = Lerp(s.ColorLerp, actionCol.b, actionColHover.b)
		draw.RoundedBox(4, 0, 0, w, h, Color(r, g, b))
		draw.SimpleText(actionText, "FishBox.Button", w / 2, h / 2, Color(CLR.white.r, CLR.white.g, CLR.white.b, Lerp(s.ColorLerp, 200, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btn.DoClick = function()
		surface.PlaySound(SOUNDS.click)
		local st = BoxState
		if not st then return end
		net.Start(mode == "deposit" and "FishBoxDeposit" or "FishBoxWithdraw")
		net.WriteUInt(st.entIndex, 13)
		net.WriteUInt(fishID, 6)
		net.SendToServer()
	end

	card.PerformLayout = function(s)
		btn:SetPos(s:GetWide() - btn:GetWide() - ScreenScale(12), (s:GetTall() - btn:GetTall()) / 2)
	end

	return card
end

local function OpenBoxMenu(entIndex, limit, box, inv)
	BoxState = { entIndex = entIndex, limit = limit, box = box, inv = inv }

	if IsValid(BoxFrame) then
		BoxFrame:Remove()
		BoxFrame = nil
	end

	local frameW = math.Clamp(ScrW() * 0.55, 750, 1100)
	local frameH = math.Clamp(ScrH() * 0.70, 480, 800)
	local headerH = 60

	local frame = vgui.Create("DFrame")
	BoxFrame = frame
	frame:SetSize(frameW, frameH)
	frame:Center()
	frame:SetTitle("")
	frame:MakePopup()
	frame:SetDraggable(true)
	frame:ShowCloseButton(false)
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.2, 0)

	frame.Paint = function(s, w, h)
		DrawBlurBG(s, 5)
		draw.RoundedBox(8, 0, 0, w, h, CLR.bg)

		draw.RoundedBoxEx(8, 0, 0, w, headerH, CLR.header, true, true, false, false)

		surface.SetDrawColor(CLR.purple)
		surface.DrawRect(0, headerH - 2, w, 2)

		draw.SimpleText("CAJA DE PESCA", "FishBox.Title", 20, headerH / 2, CLR.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		local used = 0
		for _, n in pairs(box) do used = used + n end
		draw.SimpleText(string.format("%d / %d", used, limit), "FishBox.Counter", w - 55, headerH / 2, CLR.grey, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	-- Botón de cerrar
	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetSize(40, 40)
	closeBtn:SetPos(frameW - 50, 10)
	closeBtn:SetText("")
	closeBtn.Paint = function(s, w, h)
		local isHover = s:IsHovered()
		if isHover then
			draw.RoundedBox(6, 0, 0, w, h, CLR.close_hover)
		end
		local col = isHover and CLR.red_hover or CLR.grey
		draw.SimpleText("✕", "FishBox.Close", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function()
		surface.PlaySound(SOUNDS.click)
		local st = BoxState
		if st then
			net.Start("FishBoxCloseRequest")
			net.WriteUInt(st.entIndex, 13)
			net.SendToServer()
		end
		if IsValid(BoxFrame) then BoxFrame:Remove() BoxFrame = nil end
		BoxState = nil
	end

	-- Panel con scroll
	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:SetPos(16, headerH + 12)
	scroll:SetSize(frameW - 32, frameH - headerH - 28)
	scroll.Paint = function() end

	local sbar = scroll:GetVBar()
	sbar:SetWide(6)
	sbar:SetHideButtons(true)
	sbar.Paint = function() end
	sbar.btnGrip.Paint = function(s, w, h)
		draw.RoundedBox(3, 0, 0, w, h, CLR.purple_dim)
	end

	local function AddSectionLabel(text, color, topMargin)
		local lbl = scroll:Add("DPanel")
		lbl:Dock(TOP)
		lbl:DockMargin(0, topMargin, 0, ScreenScale(8))
		lbl:SetTall(ScreenScale(20))
		lbl.Paint = function(s, w, h)
			draw.SimpleText(text, "FishBox.Section", 0, h / 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		return lbl
	end

	local function AddEmptyLabel(text)
		local e = scroll:Add("DPanel")
		e:Dock(TOP)
		e:DockMargin(0, 0, 0, ScreenScale(6))
		e:SetTall(ScreenScale(36))
		e.Paint = function(s, w, h)
			draw.SimpleText(text, "FishBox.Empty", 0, h / 2, CLR.white_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		return e
	end

	-- Sección: dentro de la caja
	AddSectionLabel("EN LA CAJA", CLR.cyan, 0)

	local boxList = {}
	for id = 1, FISH_HIGHNUMBER do
		local n = box[id]
		if n and n > 0 then table.insert(boxList, { id = id, count = n }) end
	end

	if #boxList == 0 then
		AddEmptyLabel("La caja está vacía.")
	else
		for _, f in ipairs(boxList) do
			local card = MakeFishCard(scroll, f.id, f.count, "Sacar", CLR.red, CLR.red_hover, "withdraw")
			card:Dock(TOP)
			card:DockMargin(0, ScreenScale(4), ScreenScale(8), ScreenScale(4))
		end
	end

end

net.Receive("FishBoxOpen", function()
	local entIndex = net.ReadUInt(13)
	local limit = net.ReadUInt(8)

	local box = {}
	while true do
		local id = net.ReadUInt(6)
		if id == 0 then break end
		local n = net.ReadUInt(8)
		box[id] = n
	end

	local inv = {}
	while true do
		local id = net.ReadUInt(6)
		if id == 0 then break end
		local n = net.ReadUInt(8)
		inv[id] = n
	end

	OpenBoxMenu(entIndex, limit, box, inv)
end)

-- ============================================================
-- SINCRONIZACIÓN DEL CONTENIDO DE LA CAJA (overlay 3D sobre la caja)
-- ============================================================
local InfoToLoad = {}
local function GetFishs(len)
	local num = net.ReadUInt(13)
	local ent = ents.GetByIndex(num)

	if ent:IsValid() then
		ent.Fishes = {}
		while true do
			local id = net.ReadUInt(6)
			if id == 0 then break end
			local amt = net.ReadUInt(8)
			ent.Fishes[id] = amt
		end
	else
		InfoToLoad[num] = {}
		while true do
			local id = net.ReadUInt(6)
			if id == 0 then break end
			local amt = net.ReadUInt(8)
			InfoToLoad[num] = amt
		end
	end
end
net.Receive("SendFish", GetFishs)

local function GetFishesSpawn(len)
	local size = net.ReadUInt(13)

	local ent, num
	for i = 1, size do
		num = net.ReadUInt(13)
		ent = ents.GetByIndex(num)
		if ent:IsValid() then
			ent.Fishes = {}
			while true do
				local id = net.ReadUInt(6)
				if id == 0 then break end
				local amt = net.ReadUInt(8)
				ent.Fishes[id] = amt
			end
		else
			InfoToLoad[num] = {}
			while true do
				local id = net.ReadUInt(6)
				if id == 0 then break end
				local amt = net.ReadUInt(8)
				InfoToLoad[num] = amt
			end
		end
	end
end
net.Receive("SendFishSpawn", GetFishesSpawn)

function ENT:Initialize()
	local ind = self:EntIndex()
	if InfoToLoad[ind] then
		self.Fishes = InfoToLoad[ind]
		InfoToLoad[ind] = nil
	else
		self.Fishes = {}
	end
end

local textColor = Color(255, 255, 255, 255)
function ENT:Draw()
	-- Sincroniza la tapa (bodygroup 1) con el estado abierto/cerrado
	local open = self:GetNW2Bool("BoxOpen", false)
	local target = open and 1 or 0
	if self:GetBodygroup(1) ~= target then
		self:SetBodygroup(1, target)
	end

	self:DrawModel()

	-- Círculo + texto de progreso mientras se mantiene pulsada la E
	if holdEnt == self then
		local progress = math.Clamp((CurTime() - holdStart) / OPEN_DURATION, 0, 1)
		local plypos = LocalPlayer():GetPos()
		local pos = self:GetPos() + Vector(0, 0, 30)
		plypos.z = plypos.z + 15
		local faceplant = (plypos - pos):Angle()
		local camPos = pos + faceplant:Forward() * 25
		faceplant.p = 180
		faceplant.y = faceplant.y - 90
		faceplant.r = faceplant.r - 90
		cam.Start3D2D(camPos, faceplant, 0.2)
			draw.SimpleText("Abriendo...", "Trebuchet24", 0, -34, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			DrawProgressCircle(0, 0, 20, progress)
		cam.End3D2D()
	end

	if LocalPlayer():GetEyeTrace().Entity == self then
		local space = self:GetSpace()
		if space == 0 then return end
		local plypos, pos = LocalPlayer():GetPos(), self:GetPos()
		plypos.z = plypos.z + 15
		pos.z = pos.z + 15
		local faceplant = (plypos - pos):Angle()
		local camPos = pos + faceplant:Forward() * 25
		faceplant.p = 180
		faceplant.y = faceplant.y - 90
		faceplant.r = faceplant.r - 90
		cam.Start3D2D(camPos, faceplant, 0.25)
			cam.IgnoreZ(true)
			local a = -1
			local num
			for i = 1, FISH_HIGHNUMBER do
				if self.Fishes[i] and self.Fishes[i] > 0 then
					num = self.Fishes[i]
					draw.SimpleText(table.concat({ num, TrueFishGetFishName(i) }, " "), "SegoeUI_Normal", 0, a * 15, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					a = a + 1
				end
			end

			if a == -1 then
				draw.SimpleText(TrueFishLocal("empty_container_text"), "SegoeUI_Normal", 0, a * 15, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				a = a + 1
			end

			surface.SetDrawColor(200, 200, 200, 255)
			surface.DrawRect(-25, a * 15, 50 * space / TrueFish.FISH_CONTAINER_LIMIT, 5)
			surface.SetDrawColor(255, 255, 255, 200)
			surface.DrawOutlinedRect(-25, a * 15, 50, 5)
			cam.IgnoreZ(false)
		cam.End3D2D()
	end
end
ENT.DrawTranslucent = ENT.Draw

/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
------------------------------------------------------------*/
