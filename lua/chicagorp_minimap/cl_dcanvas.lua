local PANEL = {}

--- Creates a new DCanvas control.
-- @param parent (Panel) The parent panel to attach the DCanvas to.
-- @return (DCanvas) The created DCanvas control.
function PANEL:Init()
    self.center = Vector(0, 0)
    self.zoom = 1
    self.targetZoom = 1
    self.enableZoom = true
    self.enablePan = true

    self.dragging = false
    self.dragStart = Vector(0, 0)
    self.velocity = Vector(0, 0)

    self.smoothZoomSpeed = 10
    self.smoothPanSpeed = 60

    self:SetPaintBackgroundEnabled(false)

    self.minZoom = 0.01
    self.maxZoom = 1
    self.zoomStep = 0.1
end

function PANEL:SetZoomStep(zoomStep)
    self.zoomStep = zoomStep
end

function PANEL:SetMinMaxZoom(minZoom, maxZoom)
    self.minZoom = minZoom
    self.maxZoom = maxZoom
end

function PANEL:OnMousePressed(mouseCode)
    if !(mouseCode == MOUSE_LEFT and self.enablePan) then return end

    self.dragging = true
    self.dragStart = Vector(gui.MouseX(), gui.MouseY())
    self.velocity = Vector(0, 0)
end

function PANEL:OnMouseReleased(mouseCode)
    if mouseCode != MOUSE_LEFT then return end

    self.dragging = false
end

function PANEL:OnMouseWheeled(delta)
    if !self.enableZoom then return end

    local zoomDelta = self.zoomStep * delta
    self.targetZoom = math.Clamp(self.targetZoom - zoomDelta, self.minZoom, self.maxZoom)
end

--- Gets the center position of the DCanvas.
-- @return (number, number) The x and y coordinates of the center position.
function PANEL:GetCenter()
    return self.center.x, self.center.y
end

--- Sets the center position of the DCanvas.
-- @param gbX (number) The x coordinate of the new center position.
-- @param gbY (number) The y coordinate of the new center position.
function PANEL:SetCenter(gbX, gbY)
    self.center = Vector(gbX, gbY)
end

--- Converts global coordinates to local coordinates.
-- @param gbX (number) The x coordinate in global space.
-- @param gbY (number) The y coordinate in global space.
-- @return (number, number) The corresponding x and y coordinates in local space.
function PANEL:ToScreen(gbX, gbY)
    local x = (gbX - self.center.x) / self.zoom + self:GetWide() / 2
    local y = (gbY - self.center.y) / self.zoom + self:GetTall() / 2

    return x, y
end

--- Converts local coordinates to global coordinates.
-- @param loX (number) The x coordinate in local space.
-- @param loY (number) The y coordinate in local space.
-- @return (number, number) The corresponding x and y coordinates in global space.
function PANEL:ToAbsolute(loX, loY)
    local x = (loX - self:GetWide() / 2) * self.zoom + self.center.x
    local y = (loY - self:GetTall() / 2) * self.zoom + self.center.y

    return x, y
end

--- Sets the zoom level of the DCanvas.
-- @param zoom (number) The new zoom level.
function PANEL:SetZoom(zoom)
    self.targetZoom = math.Clamp(zoom, 0.0001, 1)
end

--- Gets the current zoom level of the DCanvas.
-- @return (number) The current zoom level.
function PANEL:GetZoom()
    return self.zoom
end

--- Enables or disables mouse wheel zooming.
-- @param enable (boolean) Whether to enable or disable mouse wheel zooming.
function PANEL:EnableZoom(enable)
    self.enableZoom = enable
end

--- Enables or disables panning by mouse click and drag.
-- @param enable (boolean) Whether to enable or disable panning.
function PANEL:EnablePan(enable)
    self.enablePan = enable
end

--- Gets the visible bounds of the DCanvas in local coordinates.
-- @return (Vector, Vector) The top-left and bottom-right local coordinates of the visible bounds.
function PANEL:GetBounds()
    local w, h = self:GetSize()
    local tlx, tly = self:ToScreen(-w / 2, -h / 2)
    local brx, bry = self:ToScreen(w / 2, h / 2)

    return Vector(tlx, tly), Vector(brx, bry)
end

function PANEL:Think()
    local zoomDelta = self.targetZoom - self.zoom -- Smooth zooming

    if math.abs(zoomDelta) > 0.001 then
        self.zoom = self.zoom + zoomDelta * FrameTime() * self.smoothZoomSpeed
    else
        self.zoom = self.targetZoom
    end

    -- Handle panning with velocity
    if self.dragging then
        local mousePos = Vector(gui.MouseX(), gui.MouseY())
        local dragDelta = mousePos - self.dragStart
        local panDelta = dragDelta * self.zoom
        self.center = self.center - panDelta
        self.dragStart = mousePos

        -- Update velocity
        self.velocity = self.velocity * 0.8 + dragDelta * FrameTime() * self.smoothPanSpeed
    else
        -- Apply velocity
        local panDelta = self.velocity * self.zoom
        self.center = self.center - panDelta

        -- Decay velocity
        self.velocity = self.velocity * 0.95
    end
end

vgui.Register("chicagoRP_DCanvas", PANEL, "EditablePanel")