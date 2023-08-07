local ply = nil
local IsMapOpen = false

chicagoRPMinimap.OpenMapPanel = nil

list.Set("DesktopWindows", "chicagoRP Minimap", {
    title = "Client Settings",
    icon = "icon64/chicagorp_settings.png",
    init = function(icon, window)
        client:ConCommand("chicagoRP_minimap")
    end
})

-- OVERVIEW WORK (the dilla):
-- How to hide all non-map entities?
-- disabling area portals temporarily?
-- does niknaks' clientside PVS actually show/hide entities?

local pvs = nil
local viewAngle = Angle(-90, 0, 0)

local function GenerateMaterial(pos, w, h)
    if !w then w = 512 end
    if !h then h = 512 end

    local mat = nil
    local uuid = chicagoRP.uuid()

    pvs:AddPVS(pos) -- Adds origin position to PVS

    hook.Add("PostRender", uuid, function()   
        local rt = GetRenderTargetEx(uuid, w, h, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, TEXTUREFLAGS_EIGHTBITALPHA, 0, IMAGE_FORMAT_RGBA8888)

        render.PushRenderTarget(rt)
        render.OverrideAlphaWriteEnable(true, true)
        render.SetBlend(0) -- Hide entities (temporary solution, this also hides prop_static and prop_dynamic)
        render.ClearDepth()
        render.Clear(0, 0, 0, 0)

		local view = {
			origin = pos,
			angles = viewAngle,
			drawviewmodel = false,
			x = 0, y = 0,
			w = w, h = h
		}

		render.RenderView(view)

        render.OverrideAlphaWriteEnable(false)
        render.SetBlend(1) -- Unhide entities
        render.PopRenderTarget()

        mat = CreateMaterial(uuid, "VertexLitGeneric", {
            ["$basetexture"] = "color/black",
            ["$model"] = 1,
            ["$translucent"] = 1
        })

        mat:SetTexture("$basetexture", rt)

        hook.Remove("PostRender", uuid)
    end)

    pvs:RemovePVS(pos) -- Deletes origin position from PVS

    return mat
end

local function DisablePropFade() -- we need niknaks for this, and have to read/edit the map lump
	return {}
end

local function EnablePropFade() -- we need niknaks for this, and have to read/edit the map lump
	return {}
end

local function GenerateChunkMaterials(...) -- Generates/Regenerates chunk materials
	pvs = pvs or chicagoRPMinimap.CreatePVS()
	local plyPos = LocalPlayer():GetPos()

	pvs:AddPVS(plyPos) -- Adds player position to PVS

	DisablePropFade() -- Disable static prop fade, this should be done right before material generation

	for i = 1, #{} do -- Input table please
		GenerateMaterial(pos)
	end

	pvs:RemovePVS(plyPos) -- Deletes player position from PVS, making it empty

	EnablePropFade() -- Reenable static prop fade
end

local function CalculateRenderFOV(...) -- AKA, FOV of render.RenderView with the provided vector origin
	-- what does this actually return?

	-- needs to take the current view origin, then calculate how much we need to add or subtract from the surrounding vieworigin.z's 
end

local function FindLayers(pos) -- Find rooms that are underground, inside buildings, etc (aka, any sizable spot with a roof over it)
	-- how does this find all sizable spots with ceilings over them without having false positives?

	-- search across pos with chunk size for any sizable ceiling spots

	-- use niknaks leaf functions?
end

local function CalculateChunks() -- Calculates render.RenderView positions, finds rooms with FindLayers, etc
	local worldMin, worldMax = chicagoRPMinimap.GetMapSize()

	local chunkCount = 0 -- We have to account for negative x/y maxs :vomit:

	-- Start at leftmost and rightmost position
	-- so lowest worldMin.x and lowest worldMax.y

	-- Scenarios:
	-- worldMin.x = 0, worldMin.y = -100, worldMax.x = 10, worldMax.y = 250
	-- worldMin.x = -3453, worldMin.y = -9876, worldMax.x = 345, worldMax.y = 7658

	-- One large problem is that changing a chunks vieworigin.z will
	-- cause all surrounding chunks to intersect. As such, we need to
	-- find way to index surrounding chunks

	-- We should build chunks like so imo:
	-- first chunk, then above, then right, repeat

	for i = 0, chunkCount do
		-- aaaaa
	end
end

local function WaypointDropdown(parent, onwaypoint, mouseX, mouseY, uuid)
	if !IsValid(parent) then return end

	local dropdown = DermaMenu(false, parent)
	dropdown:NoClipping(true)

	local addWaypoint = Menu:AddOption("Add Waypoint")
	addWaypoint:SetIcon("icon16/add.png")
	addWaypoint:SetIsCheckable(false)

	function addWaypoint:DoClick()
		chicagoRPMinimap.WaypointCreation(mouseX, mouseY)
	end

	if onwaypoint then addWaypoint:SetDisabled(true) end

	local removeWaypoint = Menu:AddOption("Add Waypoint")
	removeWaypoint:SetIcon("icon16/add.png")
	removeWaypoint:SetIsCheckable(false)

	function removeWaypoint:DoClick()
		chicagoRPMinimap.DeleteWaypoint(uuid)
	end

	if !onwaypoint then removeWaypoint:SetDisabled(true) end

	dropdown:Open()

	return dropdown
end

function chicagoRPMinimap.WaypointButton(parent, x, y, w, h, waypoint)
	if !IsValid(parent) then return end

	local button = vgui.Create("DButton", parent)
	button:SetSize(w, h)
	button:SetPos(x, y)

	local concatname = chicagoRPMinimap.ShortenWaypointName(waypoint.Name)

	function button:Init()
		self.IsWaypoint = true
		self.UUID = waypoint.UUID
	end

	function button:Paint(w, h)
		draw.RoundedBox(4, 0, 0, 0, w, h, waypoint.Color)
		draw.SimpleText(concatname, "DermaDefault", 0, 0, color_white)
	end

	function button:DoClick()
		WaypointDropdown(parent, true, input.GetCursorPos(), self.UUID)
	end

	return button
end

function chicagoRPMinimap.WaypointCreation(mouseX, mouseY)
	local dialogBox = vgui.Create("DDialogBox")
	dialogBox:SetIcon("icon16/map_add.png")
	dialogBox:SetTitle("Create Waypoint")
	dialogBox:SetText("")
	dialogBox:SetWide(280) -- Carefully selected for color switch alignment

	local nameInput = dialogBox:Add("DTextEntry")
	nameInput:SetPlaceholderText("Waypoint name")
	nameInput:DockMargin(0, 4, 0, 0)

	function nameInput:AllowInput(str)
		if #str > 48 then return true end
	end

	local localCheckbox = dialogBox:Add("DCheckBoxLabel")
	localCheckbox:SetText("Friends can see")
	localCheckbox:SetValue(false)
	localCheckbox:SizeToContents()

	local permanentCheckbox = dialogBox:Add("DCheckBoxLabel")
	permanentCheckbox:SetText("Permanent")
	permanentCheckbox:SetValue(false)
	permanentCheckbox:SizeToContents()

	local colorMixer = dialog:Add("DColorMixer")

	function dialogBox:OnAccept()
		local name = nameInput:GetText()
		local pos = chicagoRPMinimap.LocalToWorld(mouseX, mouseY)
		local color = colorMixer:GetColor()
		local shared = localCheckbox:GetChecked()
		local permanent = permanentCheckbox:GetChecked()

		chicagoRPMinimap.CreateWaypoint(name, pos, waypointColor, shared, permanent)
	end

	return dialogBox
end

local function MinimapFrame()
    if IsValid(chicagoRPMinimap.OpenMapPanel) then chicagoRPMinimap.OpenMapPanel:Close() return end
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

hook.Add("PostDrawOpaqueRenderables", "chicagoRP_minimap_waypointdraw", function()
	-- how to translate world vector coords to 2d screen coords?
end)

local function OpenMinimap()
	ply = ply or LocalPlayer()

	local motherFrame = MinimapFrame()
	local minimapPanel = MinimapPanel(motherFrame)

	IsMapOpen = true
end

concommand.Add("chicagoRP_minimap", function()
    OpenMinimap()
end)