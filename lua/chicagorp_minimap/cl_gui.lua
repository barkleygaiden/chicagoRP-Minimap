local ply = nil
local IsMapOpen = false

list.Set("DesktopWindows", "chicagoRP Minimap", {
    title = "Client Settings",
    icon = "icon64/chicagorp_settings.png",
    init = function(icon, window)
        client:ConCommand("chicagoRP_minimap")
    end
})

local function MinimapFrame()
    if IsValid(OpenMotherFrame) then OpenMotherFrame:Close() return end
    if !IsValid(ply) then return end
    if !enabled then return end

    local scrW = ScrW()
    local scrH = ScrH()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(scrW / 2, scrH / 2)
    motherFrame:SetTitle("chicagoRP Minimap")
    motherFrame:ParentToHUD()
    motherFrame:MakePopup()
    motherFrame:Center()

    chicagoRP.PanelFadeIn(motherFrame, 0.15)

    function motherFrame:OnClose()
    	if !IsValid(self) then return end

        chicagoRP.PanelFadeOut(self, 0.15)
        IsMapOpen = false
    end

    function motherFrame:Paint(w, h)
        BlurBackground(self)
    end

    return motherFrame
end

local cameraOrigin = Vector(0, 0, 0)
local cameraAngle = Angle(-90, 0, 0)
local plyPos = Vector(0, 0, 0)
local originAdd = Vector(0, 10, 0)

local function CreateOrigin(vect)
	plyPos = vect
	cameraOrigin = plyPos + originAdd
end

-- Cave mode (run trace to ceiling if not outside)
-- Rewrite mouse drag handler

local function MinimapPanel(parent)
	if !IsValid(parent) then return end
	local parentW, parentH = parent:GetSize()

	local panel = vgui.Create("DPanel", parent)
	panel:SetSize(parentW, parentH)
	panel:Dock(BOTTOM)
	panel:SetCursor("hand")

	CreateOrigin(ply:GetPos())
	panel.originX = plyPos.x
	panel.originY = plyPos.y

	function panel:Paint(w, h)
		local x, y = self:GetPos()
		local plyPos = ply:GetPos()

		local old = DisableClipping(true) -- Avoid issues introduced by the natural clipping of Panel rendering
		render.SetBlend(0)

		render.RenderView({
			origin = cameraOrigin,
			angles = cameraAngle,
			x = x, y = y,
			w = w, h = h
		})

		render.SetBlend(1)
		DisableClipping(old)
	end

	function panel:OnMousePressed(mousecode)
		if mousecode != MOUSE_FIRST then return end

		self:MouseCapture(true)
		self:CaptureMouse()
	end

	function panel:OnMouseReleased(mousecode)
		self:MouseCapture(false)
	end

	function panel:CaptureMouse()
		local x, y = input.GetCursorPos()
		local dx = x - self.lastX
		local dy = y - self.lastY
		local centerx, centery = self:LocalToScreen(self:GetWide() * 0.5, self:GetTall() * 0.5)

		input.SetCursorPos(centerx, centery)
		self.lastX = centerx
		self.lastY = centery

		cameraOrigin.x = cameraOrigin.x + dx
		cameraOrigin.y = cameraOrigin.y + dy
	end

	return panel
end

local NextMove = 0

hook.Add("FinishMove", "chicagoRP_minimap_move", function(ply, mv)
	local time = CurTime()

	if !IsMapOpen or (NextMove or 0) >= time then return end

	CreateOrigin(mv:GetOrigin())

	NextMove = time + 0.5
end

local function OpenMinimap()
	ply = ply or LocalPlayer()

	local motherFrame = MinimapFrame()
	local minimapPanel = MinimapPanel(motherFrame)

	IsMapOpen = true
end

concommand.Add("chicagoRP_minimap", function()
    OpenMinimap()
end)