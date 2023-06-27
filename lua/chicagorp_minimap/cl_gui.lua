local ply = nil
local IsMapOpen = false

list.Set("DesktopWindows", "chicagoRP Minimap", {
    title = "Client Settings",
    icon = "icon64/chicagorp_settings.png",
    init = function(icon, window)
        client:ConCommand("chicagoRP_minimap")
    end
})

-- we need creation menu too

local function WaypointButton(parent, pos, name, color)

local function WaypointDropdown(parent, onwaypoint)
	local dropdown = DermaMenu(false, parent)
	dropdown:NoClipping(true)

	local addWaypoint = Menu:AddOption("Add Waypoint")
	addWaypoint:SetIcon("icon16/add.png")
	addWaypoint:SetIsCheckable(false)

	function addWaypoint:DoClick()
		-- code here
		dropdown:Remove()
	end

	local removeWaypoint = Menu:AddOption("Add Waypoint")
	removeWaypoint:SetIcon("icon16/add.png")
	removeWaypoint:SetIsCheckable(false)

	function removeWaypoint:DoClick()
		-- code here
		dropdown:Remove()
	end

	if !onwaypoint then removeWaypoint:SetDisabled(true) end

	dropdown:Open()

	return dropdown
end

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
local plyPos = Vector(0, 0, 0)
local originAdd = Vector(0, 10, 0)

local function CreateOrigin(vect)
	plyPos = vect
	cameraOrigin = plyPos + originAdd
end

-- Add ortho to render.RenderView
-- Zoom functionality (somewhat done, needs to be rewritten to use ortho)
-- Translating coordinates from Minimap panel to real world, and vise versa (kinda done, test ingame)
-- Cave mode (run trace to ceiling if not outside)
-- Waypoint system (aim for basic ones, add/remove and done via sql, unfilled circles drawn in hudpaint/postopaquerenderables hook)
-- DButton brotha

local cameraAngle = Angle(-90, 0, 0)
local worldPosition = Vector(0, 0, 0)

local function MinimapPanel(parent)
	if !IsValid(parent) then return end
	local parentW, parentH = parent:GetSize()

	local panel = vgui.Create("DPanel", parent)
	panel:SetSize(parentW, parentH)
	panel:Dock(BOTTOM)
	panel:SetCursor("hand")

	function panel:Init()
		local plyPos = ply:GetPos()

		CreateOrigin(plyPos)
		self.originX = plyPos.x
		self.originY = plyPos.y
	end

	function panel:Paint(w, h)
		local x, y = self:GetPos()

		local old = DisableClipping(true) -- Avoid issues introduced by the natural clipping of Panel rendering
		render.SetBlend(0)

		render.RenderView({
			origin = cameraOrigin,
			angles = cameraAngle,
			drawviewmodel = false,
			x = x, y = y,
			w = w, h = h
		})

		render.SetBlend(1)
		DisableClipping(old)
	end

	function panel:OnMousePressed(mousecode)
		if mousecode == MOUSE_LEFT then
			self.cursorX, self.cursorY = input.GetCursorPos() -- Position before dragging starts

			self:MouseCapture(true)
			self:CaptureMouse()
		elseif mousecode == MOUSE_RIGHT then
			WaypointDropdown(panel)
		end
	end

	function panel:OnMouseReleased(mousecode)
		self:MouseCapture(false)
	end

	function panel:CaptureMouse()
		local x, y = input.GetCursorPos() -- New cursor position
		local newX = x - self.originX -- Gets new horizontal value
		local newY = y - self.originY -- Gets new vertical value

		cameraOrigin.x = cameraOrigin.x + newX -- Moves origin
		cameraOrigin.y = cameraOrigin.y + newY -- Moves origin

		input.SetCursorPos(self.originX, self.originY) -- Recenters cursor at the original position
	end

	local mapMin, mapMax = chicagoRPMinimap.GetMapSize()

	function panel:OnMouseWheeled(delta)
		local calcZ = cameraOrigin.z + (delta * -1)
		cameraOrigin.z = math.Clamp(calcZ, mapMin.z, mapMax.z)
	end

	function panel:GetWorldPosition()
		chicagoRPMinimap.ResetVector(worldPosition)

		local mx, my = self:ScreenToLocal(gui.MouseX(), gui.MouseY()) -- Pass the mouse into the panel coordinates

		worldPosition.x = (mx + self.Offset.x) * self.MapScale -- Adds the map offset and then scale it to the scale of your minimap
		worldPosition.y = (my + self.Offset.y) * self.MapScale

		return worldPosition
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