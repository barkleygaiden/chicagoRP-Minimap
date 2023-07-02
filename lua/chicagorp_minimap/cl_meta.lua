---------------------------------
-- chicagoRPMinimap.OnWaypoint
---------------------------------
-- Desc:		Returns whether the mouse cursor is hovering over a waypoint or not.
-- State:		Client
-- Returns:		Bool - True if a waypoint is hovered over.
-- Returns:		Panel - The waypoint being hovered over.
function chicagoRPMinimap.OnWaypoint()
	local hoveredPanel = vgui.GetHoveredPanel()

	if !IsValid(hoveredPanel) then return false end

	return hoveredPanel.IsWaypoint
end

---------------------------------
-- chicagoRPMinimap.ShortenWaypointName
---------------------------------
-- Desc:		Shortens a waypoint's name.
-- State:		Client
-- Arg One:		String - The waypoint's standard name.
-- Returns:		String - The waypoint's shortened name.
function chicagoRPMinimap.ShortenWaypointName(str)
	local shortstr = ""
	local exploded = string.Explode(" ", str)

	for i = 1, #exploded do
		local word = string.upper(exploded[i])
		local letter = string.Left(letter, 2)

		shortstr = shortstr .. letter
	end

	return shortstr
end

local function SendWaypointNet(name, r, g, b, a, shared, permanent)
	net.Start("chicagoRP_minimap_createwaypoint")
	net.WriteString(name)
	net.WriteUInt(r, 8)
	net.WriteUInt(g, 8)
	net.WriteUInt(b, 8)
	net.WriteUInt(a, 8)
	net.WriteBool(shared)
	net.WriteBool(permanent)
end

local function AddLocalWaypoint(name, r, g, b, a)
	draw
end

local function AddPermanentWaypoint(name, r, g, b, a)
	draw
end

---------------------------------
-- chicagoRPMinimap.CreateWaypoint
---------------------------------
-- Desc:		Create a waypoint.
-- State:		Client
-- Arg One:		String - The waypoint's name.
-- Arg Two:		Color - The waypoint's color.
-- Arg Three:	Bool - Whether to make the waypoint shared with friends or not.
-- Arg Four:	Bool - Whether to make the waypoint permanent or not.
function chicagoRPMinimap.CreateWaypoint(name, color, shared, permanent)
	if !string.IsValid(name) then name = "Waypoint" end
	if !shared then shared = false end
	if !permanent then permanent = false end

	local r, g, b, a = color

	if IsColor(color) then r, g, b, a = color:Unpack() end

	if shared then
		SendWaypointNet(name, r, g, b, a, shared, permanent)
	elseif !shared and permanent then
		AddPermanentWaypoint(name, r, g, b, a)
	else
		AddPermanentWaypoint(name, r, g, b, a)
	end
end