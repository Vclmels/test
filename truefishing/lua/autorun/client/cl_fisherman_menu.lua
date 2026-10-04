/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/
-- Materiales compartidos (estilo synthwave "La Republica")
local glowMat     = Material("particle/particle_glow_05")
local matGradLeft = Material("vgui/gradient-l")
local blurMat     = Material("pp/blurscreen")

-- PALETA SYNTWAVE "LA REPUBLICA" (copiada de jobemployernpc / larepublica_logo_entity)
local PAL = {
	blackpurple = Color(23, 20, 35, 245),
	black18200  = Color(18, 30, 42, 200),
	purple      = Color(81, 56, 237, 255),
	purple_hover = Color(95, 75, 245, 255),
	cyan        = Color(0, 190, 255, 255),
	white       = Color(248, 247, 252, 255),
	grey        = Color(150, 150, 150, 255),
	pink        = Color(255, 60, 140, 255),
}

-- Fuentes synthwave (Georama, como en jobemployernpc)
surface.CreateFont("TF_Synth_Hero",     { font = "Georama", extended = false, size = ScreenScale(30), weight = 1000, antialias = true })
surface.CreateFont("TF_Synth_Title",    { font = "Georama", extended = false, size = ScreenScale(22), weight = 1000, antialias = true })
surface.CreateFont("TF_Synth_Subtitle", { font = "Georama", extended = false, size = ScreenScale(12), weight = 500,  antialias = true })
surface.CreateFont("TF_Synth_Button",   { font = "Georama", extended = false, size = ScreenScale(13), weight = 800,  antialias = true })
surface.CreateFont("TF_Synth_Small",    { font = "Georama", extended = false, size = ScreenScale(10), weight = 500,  antialias = true })

-- Desenfoque de fondo
local function DrawBlur(panel, amount)
	local x, y = panel:LocalToScreen(0, 0)
	local scrW, scrH = ScrW(), ScrH()
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(blurMat)
	for i = 1, 3 do
		blurMat:SetFloat("$blur", (i / 3) * (amount or 6))
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
	end
end

-- Rectangulo redondeado con el lado derecho inclinado (copiado de jobemployernpc)
local function GenerateSlantedRoundedRect(x, y, w, h, slant, r)
	local maxR = math.min(h / 2, w / 2)
	r = math.Clamp(r, 0, maxR)

	local L = math.sqrt(slant * slant + h * h)

	local cTL = { x = x + r, y = y + r }
	local cBL = { x = x + r, y = y + h - r }
	local cTR = { x = x + w - r * (slant + L) / h, y = y + r }
	local cBR = { x = x + w - slant - r * (L - slant) / h, y = y + h - r }

	local verts = {}
	local steps = 8

	for i = 0, steps do
		local a = math.rad(Lerp(i / steps, 180, 270))
		table.insert(verts, { x = cTL.x + math.cos(a) * r, y = cTL.y + math.sin(a) * r })
	end

	local rightNormalAngle = math.deg(math.atan2(slant, h))
	for i = 0, steps do
		local a = math.rad(Lerp(i / steps, 270, 360 + rightNormalAngle))
		table.insert(verts, { x = cTR.x + math.cos(a) * r, y = cTR.y + math.sin(a) * r })
	end

	for i = 0, steps do
		local a = math.rad(Lerp(i / steps, rightNormalAngle, 90))
		table.insert(verts, { x = cBR.x + math.cos(a) * r, y = cBR.y + math.sin(a) * r })
	end

	for i = 0, steps do
		local a = math.rad(Lerp(i / steps, 90, 180))
		table.insert(verts, { x = cBL.x + math.cos(a) * r, y = cBL.y + math.sin(a) * r })
	end

	return verts
end

-- Clipping circular (stencil) para iconos y sol
local function CircularClipStart(cx, cy, r)
	render.ClearStencil()
	render.SetStencilEnable(true)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)
	render.SetStencilFailOperation(STENCIL_REPLACE)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)
	render.SetStencilCompareFunction(STENCIL_NEVER)
	render.SetStencilReferenceValue(1)

	draw.NoTexture()
	surface.SetDrawColor(255, 255, 255, 255)
	local seg = 48
	local poly = {}
	for i = 0, seg - 1 do
		local a = math.rad((i / seg) * 360)
		table.insert(poly, { x = cx + math.cos(a) * r, y = cy + math.sin(a) * r })
	end
	surface.DrawPoly(poly)

	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilPassOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)
	render.SetStencilCompareFunction(STENCIL_EQUAL)
	render.SetStencilReferenceValue(1)
end

local function CircularClipEnd()
	render.SetStencilEnable(false)
	render.SetStencilWriteMask(0)
	render.SetStencilTestMask(0)
	render.SetStencilReferenceValue(0)
end

-- Ajusta la camara del DModelPanel segun el modelo y el tipo de objeto
local function ApplyModelCam(pnl, model, i)
	if not IsValid(pnl.Entity) then return end
	local mn, mx = pnl.Entity:GetRenderBounds()
	local center = (mx + mn) / 2
	local diag   = mn:Distance(mx)

	-- camara base: apuntar al centro desde una distancia proporcional a la caja
	pnl:SetLookAt(center)
	pnl:SetCamPos(center + Vector(1, 1, 0.6):GetNormal() * diag * 0.82)
	pnl:SetFOV(55)

	if i == FISH_GEAR_ROD then
		-- La caña es muy larga en Y. Rotamos 45° en diagonal para que ocupe
		-- bien el espacio cuadrado del icono sin verse aplastada.
		pnl.Entity:SetAngles(Angle(-20, -45, 25))
		local mn2, mx2 = pnl.Entity:GetRenderBounds()
		local c2 = (mn2 + mx2) / 2
		pnl:SetLookAt(c2)
		pnl:SetCamPos(c2 + Vector(1, 1, 0.5):GetNormal() * mn2:Distance(mx2) * 0.85)
		pnl:SetFOV(38)

	elseif i == FISH_GEAR_BAIT then
		-- Cebo: objeto pequeño, zoom un poco mas
		pnl.Entity:SetAngles(Angle(20, -30, 0))
		pnl:SetFOV(50)

	elseif i == FISH_GEAR_MEDIUMCAGE or i == FISH_GEAR_LARGECAGE then
		-- Jaulas: cubo/crate, vista ligeramente desde arriba
		pnl.Entity:SetAngles(Angle(20, 30, 0))
		pnl:SetFOV(60)

	elseif i == FISH_GEAR_CONTAINER then
		-- Contenedor azul: angulo diagonal
		pnl.Entity:SetAngles(Angle(15, -45, 0))
		pnl:SetFOV(55)

	elseif i == FISH_GEAR_FISHFINDER then
		-- Monitor: vista frontal ligera
		pnl.Entity:SetAngles(Angle(10, -20, 0))
		pnl:SetFOV(55)

	elseif i and i >= FISH_GEAR_HOOK_GADDAN then
		-- Anzuelos de jefes: objetos pequeños y alargados,
		-- rotar para que se vean de perfil con buen relleno del icono
		pnl.Entity:SetAngles(Angle(0, -60, 90))
		pnl:SetFOV(42)

	elseif model and string.find(model, "FoodNHouseholdItems") then
		pnl.Entity:SetAngles(Angle(35, 0, -90))
		pnl:SetFOV(55)

	else
		pnl.Entity:SetAngles(Angle(0, -30, 0))
	end
end

-- Modelo 3D (DModelPanel) reutilizable
local function MakeModelPanel(parent, model, mat, i, wpx, hpx)
	local pnl = vgui.Create("DModelPanel", parent)
	pnl.GearIndex = i
	function pnl:SetModel(str)
		if IsValid(self.Entity) then self.Entity:Remove() self.Entity = nil end
		if not ClientsideModel then return end
		self.Entity = ClientsideModel(str, RENDER_GROUP_OPAQUE_ENTITY)
		if not IsValid(self.Entity) then return end
		self.Entity:SetNoDraw(true)
		ApplyModelCam(self, str, self.GearIndex)
	end
	function pnl:LayoutEntity(e) self:RunAnimation() end
	pnl.OnRemove = function(s)
		if IsValid(s.Entity) then s.Entity:Remove() end
		s.Entity = nil
	end
	pnl:SetModel(model)
	if mat and IsValid(pnl.Entity) then pnl.Entity:SetMaterial(mat) end
	pnl:SetSize(wpx, hpx)
	pnl:SetMouseInputEnabled(false)
	return pnl
end

-- Icono circular (recorte stencil) para la lista derecha
local function MakeCircularIcon(parent, model, mat, i, size)
	local pnl = MakeModelPanel(parent, model, mat, i, size, size)
	local r = size / 2
	local seg = 48
	local cirPoly = {}
	for k = 0, seg - 1 do
		local a = math.rad((k / seg) * 360)
		table.insert(cirPoly, { x = r + math.cos(a) * r, y = r + math.sin(a) * r })
	end
	local oldPaint = pnl.Paint
	pnl.Paint = function(s, w, h)
		CircularClipStart(r, r, r)
		surface.SetDrawColor(30, 30, 40, 250)
		surface.DrawPoly(cirPoly)
		if oldPaint then oldPaint(s, w, h) end
		CircularClipEnd()
	end
	return pnl
end

-- Boton grande inclinado con glow (para COMPRAR / VENDER TODO)
local function MakeActionButton(parent, wpx, hpx, x, y, text, col, onClick)
	local b = vgui.Create("DButton", parent)
	b:SetPos(x, y)
	b:SetSize(wpx, hpx)
	b:SetText(text or "")
	local slant = ScreenScale(14)
	b.Paint = function(s, bw, bh)
		local active = s:IsHovered()
		local vert = GenerateSlantedRoundedRect(0, 0, bw, bh, slant, ScreenScale(8))

		if active then
			surface.SetDrawColor(PAL.cyan.r, PAL.cyan.g, PAL.cyan.b, 80)
			surface.SetMaterial(glowMat)
			surface.DrawTexturedRectRotated(bw / 2, bh / 2, bw, bh, 0)
		end

		render.ClearStencil()
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(1)
		render.SetStencilTestMask(1)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)
		draw.NoTexture()
		surface.SetDrawColor(255, 255, 255, 1)
		surface.DrawPoly(vert)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)

		local c = active and PAL.purple_hover or (col or PAL.purple)
		surface.SetDrawColor(c.r, c.g, c.b, 250)
		surface.DrawRect(0, 0, bw, bh)
		surface.SetMaterial(matGradLeft)
		surface.SetDrawColor(138, 43, 226, 160)
		surface.DrawTexturedRect(0, 0, bw * 0.5, bh)
		render.SetStencilEnable(false)

		draw.SimpleText(s:GetText(), "TF_Synth_Button", bw / 2, bh / 2, PAL.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	b.DoClick = function() if onClick then onClick() end end
	return b
end

local menu

local function FishNPCMenu(len)
	if menu and menu.Remove then menu:Remove() end

	local npc = net.ReadEntity()
	if !npc:IsValid() or npc:GetClass() != "npc_fishshop" then
		print("Fishing NPC was invalid.")
		return
	end

	local num = net.ReadUInt(6)
	for i = 1, num do
		local id = net.ReadUInt(6)
		TrueFish.FISH_PRICE[id] = net.ReadUInt(16)
		TrueFish.FISH_ENABLED[id] = net.ReadBool()
	end

	local num = net.ReadUInt(6)
	for i = 1, num do
		local id = net.ReadUInt(6)
		TrueFish.GEAR_PRICE[id] = net.ReadUInt(16)
		TrueFish.GEAR_ENABLED[id] = net.ReadBool()
	end

	local FishToSell = {}
	while true do
		local ind = net.ReadUInt(6)
		if ind == 0 then break end
		FishToSell[ind] = FishToSell[ind] and FishToSell[ind] + net.ReadUInt(8) or net.ReadUInt(8)
	end

	local TotalSalePrice = 0
	for i = 1, FISH_HIGHNUMBER do
		if FishToSell[i] then
			TotalSalePrice = TotalSalePrice + FishToSell[i] * TrueFish.FISH_PRICE[i]
		end
	end
	TotalSalePrice = math.floor(TotalSalePrice)

	-- ============================================================
	-- VENTANA PRINCIPAL
	-- ============================================================
	local w = math.Clamp(ScrW() * 0.92, 1100, 1720)
	local h = math.Clamp(ScrH() * 0.72, 500, 780)

	-- Referencias adelantadas para los cambios de vista del menu
	local fishBtn, sellAllBtn
	local ShowFishList, ShowSplash, ShowDetail

	menu = vgui.Create("DFrame")
	menu:SetTitle("")
	menu:ShowCloseButton(false)
	menu:SetDraggable(false)
	menu:SetSize(w, h)
	menu:Center()
	menu:MakePopup()
	menu:SetAlpha(0)
	menu:AlphaTo(255, 0.25)

	menu.Paint = function(s, fw, fh)
		DrawBlur(s, 8)
		draw.RoundedBox(10, 0, 0, fw, fh, PAL.blackpurple)
		-- Encabezado arriba-izquierda
		draw.SimpleText(TrueFishLocal("fish_market"), "TF_Synth_Title", fw * 0.05, fh * 0.045, PAL.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	-- Boton de cerrar (X) arriba-derecha
	local exitbtn = vgui.Create("DButton", menu)
	exitbtn:SetSize(ScreenScale(30), ScreenScale(30))
	exitbtn:SetPos(w - ScreenScale(40), h * 0.04)
	exitbtn:SetText("")
	exitbtn:SetZPos(100)
	exitbtn.Paint = function(s, bw, bh)
		local c = s:IsHovered() and PAL.red or PAL.white
		draw.SimpleText("X", "TF_Synth_Button", bw / 2, bh / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	exitbtn.DoClick = function() menu:Remove() end

	-- ============================================================
	-- PANEL DERECHO (1/3): lista con divisor brillante
	-- ============================================================
	local rightPanel = vgui.Create("DPanel", menu)
	rightPanel:SetSize(w * 0.64, h)
	rightPanel:SetPos(w * 0.36, 0)
	rightPanel.Paint = function(s, pw, ph)
		surface.SetDrawColor(PAL.black18200)
		surface.DrawRect(0, 0, pw, ph)
		-- Divisor vertical animado (purpura <-> cian)
		local time = RealTime() * 0.8
		local lv = (math.sin(time) + 1) / 2
		local c1, c2 = PAL.purple, PAL.cyan
		surface.SetDrawColor(Lerp(lv, c1.r, c2.r), Lerp(lv, c1.g, c2.g), Lerp(lv, c1.b, c2.b), 255)
		surface.DrawRect(0, 0, 4, ph)
	end

	-- Estilo compartido para las barras de scroll de las grillas y la lista de peces
	local function StyleScrollBar(sc)
		local sbar = sc:GetVBar()
		sbar:SetHideButtons(true)
		sbar.Paint = function(s, bw, bh) draw.RoundedBox(0, 0, 0, bw, bh, Color(0, 0, 0, 50)) end
		sbar.btnGrip.Paint = function(s, bw, bh) draw.RoundedBox(0, bw / 2 - 1.5, 0, 3, bh, PAL.purple) end
	end

	-- ============================================================
	-- PANEL IZQUIERDO (2/3): splash + vista previa + acciones
	-- ============================================================
	local leftW = w * 0.32
	local leftH = h * 0.76

	local leftPanel = vgui.Create("DPanel", menu)
	leftPanel:SetPos(w * 0.03, h * 0.20)
	leftPanel:SetSize(leftW, leftH)
	leftPanel.Paint = function() end

	-- Splash: logo "La Republica" con animacion de flotado + glow
	local logoMat = Material("rcd_materials/larepublicalog.png", "smooth")
	local splash = vgui.Create("DPanel", leftPanel)
	splash:SetSize(leftW, leftH)
	splash.BloomTime = 0
	splash.AnimTime = 0
	splash.Paint = function(s, pw, ph)
		s.BloomTime = s.BloomTime + FrameTime() * 3
		s.AnimTime = s.AnimTime + FrameTime() * 1.5
		local bloomIntensity = 0.5 + math.sin(s.BloomTime) * 0.5

		-- Ajustar el logo a su proporcion real (sin deformar)
		local imgW, imgH = logoMat:Width(), logoMat:Height()
		local aspect = (imgW > 0 and imgH > 0) and (imgW / imgH) or 1
		local height = ph * 0.66
		local width = height * aspect
		if width > pw * 0.80 then
			width = pw * 0.80
			height = width / aspect
		end

		local cx, cy = pw / 2, ph / 2
		local floatY = math.sin(s.AnimTime) * 10
		local floatX = math.cos(s.AnimTime * 0.7) * 5
		cx = cx + floatX
		cy = cy + floatY

		-- Logo principal
		local mainAlpha = 200 + (55 * bloomIntensity)
		surface.SetDrawColor(255, 255, 255, mainAlpha)
		surface.SetMaterial(logoMat)
		surface.DrawTexturedRect(cx - width / 2, cy - height / 2, width, height)
	end

	-- Enlace "PESCADOS" (texto estilizado sin fondo de botón).
	-- Al hacer clic en "PESCADOS" se despliega la lista de peces.
	-- Va alineado a la derecha del encabezado, a la izquierda del botón de cerrar.
	fishBtn = vgui.Create("DButton", menu)
	fishBtn:SetText("PESCADOS")
	fishBtn:SetFont("TF_Synth_Small")
	surface.SetFont("TF_Synth_Small")
	local fbW, fbH = surface.GetTextSize("PESCADOS")
	fishBtn:SetSize(fbW + ScreenScale(4), fbH + ScreenScale(4))
	fishBtn.Paint = function(s, bw, bh)
		local c = s:IsHovered() and PAL.white or PAL.cyan
		draw.SimpleText(s:GetText(), "TF_Synth_Small", bw / 2, bh / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if s:IsHovered() then
			surface.SetDrawColor(PAL.cyan.r, PAL.cyan.g, PAL.cyan.b, 220)
			surface.DrawRect(bw / 2 - fbW / 2, bh - ScreenScale(2), fbW, ScreenScale(1))
		end
	end
	fishBtn.DoClick = function() ShowFishList() end

	local bW, bH = fishBtn:GetWide(), fishBtn:GetTall()
	local btnX = w - bW - ScreenScale(48)
	local btnY = h * 0.045 + (ScreenScale(22) - bH) / 2
	fishBtn:SetPos(btnX, btnY)

	-- Detalle (vista previa + info + boton), oculto por defecto
	local detail = vgui.Create("DPanel", leftPanel)
	detail:SetSize(leftW, leftH)
	detail:SetVisible(false)
	detail.Paint = function(s, pw, ph)
		if not detail.data then return end
		draw.SimpleText(detail.data.name, "TF_Synth_Title", pw * 0.5, ph * 0.60, PAL.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText(detail.data.info, "TF_Synth_Subtitle", pw * 0.5, ph * 0.70, PAL.purple, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	local preview = MakeModelPanel(detail, TrueFishGetFishModel(1), nil, 0, leftW * 0.88, leftH * 0.48)
	preview:SetPos(leftW * 0.06, leftH * 0.04)

	local actionBtn = MakeActionButton(detail, leftW * 0.68, ScreenScale(36), leftW * 0.16, leftH * 0.80, "", PAL.purple, nil)
	actionBtn:SetVisible(false)

	-- Boton "VENDER TODO" (pie del panel izquierdo)
	sellAllBtn = MakeActionButton(leftPanel, leftW * 0.88, ScreenScale(34), leftW * 0.06, leftH - ScreenScale(44), TrueFishLocal("sell_all") .. "  $" .. TotalSalePrice, PAL.purple, function()
		net.Start("Fish_sell")
		net.WriteEntity(npc)
		net.SendToServer()
		menu:Remove()
	end)
	sellAllBtn:SetVisible(TotalSalePrice > 0)

	-- Acciones de seleccion
	local function ShowGear(id)
		ShowDetail()
		local price = (TrueFish.GEAR_PRICE and TrueFish.GEAR_PRICE[id]) or (TrueFishBosses and TrueFishBosses[id] and TrueFishBosses[id].price) or 100
		detail.data = {
			name = TrueFishGetGearName(id),
			info = "Precio: $" .. math.floor(price),
		}
		preview.GearIndex = id
		preview:SetModel(TrueFishGetGearModel(id))
		if IsValid(preview.Entity) and TrueFishGetGearMaterial(id) then preview.Entity:SetMaterial(TrueFishGetGearMaterial(id)) end
		actionBtn:SetVisible(true)
		actionBtn:SetText(TrueFishLocal("purchase_txt") .. "  $" .. math.floor(price))
		actionBtn.DoClick = function()
			net.Start("Fish_buy")
			net.WriteEntity(npc)
			net.WriteUInt(id, 6)
			net.SendToServer()
			menu:Remove()
		end
	end

	local function ShowFish(id)
		ShowDetail()
		local owned = FishToSell[id] or 0
		detail.data = {
			name = TrueFishGetFishName(id),
			info = "Recompensa: $" .. math.floor(TrueFish.FISH_PRICE[id]) .. (owned > 0 and ("   ·   Tienes x" .. owned) or ""),
		}
		preview.GearIndex = 0
		preview:SetModel(TrueFishGetFishModel(id))
		actionBtn:SetVisible(false)
	end

	-- ============================================================
	-- LISTA DERECHA: botones inclinados
	-- ============================================================
	local function AddSlantedButton(parent, model, mat, i, nameText, rightText, rightCol, onSelect)
		local line = parent:Add("DButton")
		line:Dock(TOP)
		line:SetTall(ScreenScale(46))
		line:DockMargin(ScreenScale(4), ScreenScale(2), ScreenScale(8), ScreenScale(2))
		line:SetText("")

		local iconSize = ScreenScale(30)
		local icon = MakeCircularIcon(line, model, mat, i, iconSize)
		icon:SetPos(ScreenScale(8), (line:GetTall() - iconSize) / 2)

		local slant = ScreenScale(16)
		line.Paint = function(s, wh, ht)
			local active = s:IsHovered()
			local vert = GenerateSlantedRoundedRect(0, 0, wh, ht, slant, ScreenScale(8))

			if active then
				surface.SetDrawColor(PAL.cyan.r, PAL.cyan.g, PAL.cyan.b, 70)
				surface.SetMaterial(glowMat)
				surface.DrawTexturedRectRotated(wh / 2, ht / 2, wh, ht, 0)
			end

			render.ClearStencil()
			render.SetStencilEnable(true)
			render.SetStencilWriteMask(1)
			render.SetStencilTestMask(1)
			render.SetStencilReferenceValue(1)
			render.SetStencilCompareFunction(STENCIL_ALWAYS)
			render.SetStencilPassOperation(STENCIL_REPLACE)
			render.SetStencilFailOperation(STENCIL_KEEP)
			render.SetStencilZFailOperation(STENCIL_KEEP)
			draw.NoTexture()
			surface.SetDrawColor(255, 255, 255, 1)
			surface.DrawPoly(vert)
			render.SetStencilCompareFunction(STENCIL_EQUAL)
			render.SetStencilPassOperation(STENCIL_KEEP)

			local base = active and PAL.purple_hover or PAL.purple
			surface.SetDrawColor(base.r, base.g, base.b, 240)
			surface.DrawRect(0, 0, wh, ht)
			surface.SetMaterial(matGradLeft)
			surface.SetDrawColor(138, 43, 226, active and 200 or 110)
			surface.DrawTexturedRect(0, 0, wh * 0.6, ht)
			render.SetStencilEnable(false)

			local tx = iconSize + ScreenScale(12)
			draw.SimpleText(nameText, "TF_Synth_Button", tx, ht * 0.28, PAL.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(rightText, "TF_Synth_Small", tx, ht * 0.72, rightCol or PAL.cyan, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		line.DoClick = function() if onSelect then onSelect() end end
		return line
	end

	-- ============================================================
	-- TIENDA: objetos en DOS grillas (equipo + anzuelos de jefes)
	-- ============================================================
	local colGap = ScreenScale(10)
	local colW = (rightPanel:GetWide() - ScreenScale(12) - colGap) / 2

	local function BuildGearGrid(title, idList, x)
		local col = vgui.Create("DPanel", rightPanel)
		col:SetPos(x, ScreenScale(22))
		col:SetSize(colW, h - ScreenScale(38))
		col.Paint = function() end

		local hdr = vgui.Create("DPanel", col)
		hdr:Dock(TOP)
		hdr:SetTall(ScreenScale(26))
		hdr:DockMargin(ScreenScale(10), 0, ScreenScale(8), 0)
		hdr.Paint = function(s, pw, ph)
			draw.SimpleText(title, "TF_Synth_Subtitle", 0, ph * 0.5, PAL.cyan, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local sc = vgui.Create("DScrollPanel", col)
		sc:Dock(FILL)
		sc:DockMargin(0, ScreenScale(4), 0, 0)
		sc.Paint = function() end
		StyleScrollBar(sc)

		for _, i in ipairs(idList) do
			local isEnabled = TrueFish.GEAR_ENABLED and TrueFish.GEAR_ENABLED[i]
			if isEnabled != false then
				local p = (TrueFish.GEAR_PRICE and TrueFish.GEAR_PRICE[i]) or (TrueFishBosses and TrueFishBosses[i] and TrueFishBosses[i].price) or 100
				AddSlantedButton(sc, TrueFishGetGearModel(i), TrueFishGetGearMaterial(i), i,
					TrueFishGetGearName(i), "$" .. math.floor(p), PAL.cyan, function() ShowGear(i) end)
			end
		end
	end

	local bossHookIds = {}
	if TrueFishBosses then
		for bId, _ in pairs(TrueFishBosses) do
			table.insert(bossHookIds, bId)
		end
		table.sort(bossHookIds)
	else
		bossHookIds = {7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18}
	end

	BuildGearGrid("EQUIPO", {FISH_GEAR_BAIT, FISH_GEAR_MEDIUMCAGE, FISH_GEAR_LARGECAGE, FISH_GEAR_CONTAINER, FISH_GEAR_ROD, FISH_GEAR_FISHFINDER}, ScreenScale(6))
	BuildGearGrid("ANZUELOS DE JEFES", bossHookIds, ScreenScale(6) + colW + colGap)

	-- ============================================================
	-- APARTADO SEPARADO: LISTA DE PECES DISPONIBLES
	-- ============================================================
	local fishSection = vgui.Create("DPanel", menu)
	fishSection:SetPos(0, h * 0.16)
	fishSection:SetSize(w, h * 0.84)
	fishSection:SetVisible(false)
	fishSection:SetZPos(50)
	fishSection.Paint = function(s, pw, ph)
		draw.RoundedBox(0, 0, 0, pw, ph, PAL.blackpurple)
	end

	local fsHeader = vgui.Create("DPanel", fishSection)
	fsHeader:Dock(TOP)
	fsHeader:SetTall(ScreenScale(46))
	fsHeader.Paint = function(s, pw, ph)
		draw.SimpleText("PESCADOS", "TF_Synth_Title", ScreenScale(10), ph * 0.5, PAL.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local backBtn = vgui.Create("DButton", fsHeader)
	backBtn:SetText("←  VOLVER")
	local bbW, bbH = ScreenScale(120), ScreenScale(26)
	backBtn:SetSize(bbW, bbH)
	backBtn:SetPos(w - bbW - ScreenScale(16), (ScreenScale(46) - bbH) / 2)
	backBtn.Paint = function(s, bw, bh)
		local active = s:IsHovered()
		draw.RoundedBox(bh / 2, 0, 0, bw, bh, active and PAL.purple_hover or PAL.purple)
		draw.SimpleText(s:GetText(), "TF_Synth_Small", bw / 2, bh / 2, PAL.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	backBtn.DoClick = function() ShowSplash() end

	local fishScroll = vgui.Create("DScrollPanel", fishSection)
	fishScroll:Dock(FILL)
	fishScroll:DockMargin(ScreenScale(8), ScreenScale(8), ScreenScale(8), ScreenScale(8))
	fishScroll.Paint = function() end
	StyleScrollBar(fishScroll)

	for i = 1, FISH_HIGHNUMBER do
		if TrueFish.FISH_ENABLED[i] then
			local owned = FishToSell[i] or 0
			local right = owned > 0 and ("x" .. owned .. "  ·  $" .. math.floor(TrueFish.FISH_PRICE[i])) or ("$" .. math.floor(TrueFish.FISH_PRICE[i]))
			AddSlantedButton(fishScroll, TrueFishGetFishModel(i), nil, i,
				TrueFishGetFishName(i), right, PAL.cyan, function() ShowFish(i) end)
		end
	end

	-- ============================================================
	-- Cambio de vistas (tienda / vista previa / lista de peces)
	-- ============================================================
	ShowSplash = function()
		splash:SetVisible(true)
		detail:SetVisible(false)
		fishSection:SetVisible(false)
		rightPanel:SetVisible(true)
		fishBtn:SetVisible(true)
		sellAllBtn:SetVisible(TotalSalePrice > 0)
	end

	ShowDetail = function()
		splash:SetVisible(false)
		detail:SetVisible(true)
		fishSection:SetVisible(false)
		rightPanel:SetVisible(true)
		fishBtn:SetVisible(false)
		sellAllBtn:SetVisible(false)
	end

	ShowFishList = function()
		splash:SetVisible(false)
		detail:SetVisible(false)
		fishSection:SetVisible(true)
		rightPanel:SetVisible(false)
		fishBtn:SetVisible(false)
		sellAllBtn:SetVisible(false)
	end
end

net.Receive("FishNPCMenu", FishNPCMenu)
/*-----------------------------------------------------------
Leak by Famouse
https://www.youtube.com/c/Famouse
https://discord.gg/N6JpA29 - More leaks
-------------------------------------------------------------*/
