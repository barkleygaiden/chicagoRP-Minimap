chicagoRPMinimap.LocalWaypoints = chicagoRPMinimap.LocalWaypoints or {}

sql.Begin()
sql.Query("CREATE TABLE IF NOT EXISTS 'chicagoRPMinimap_Waypoints'('Name' VARCHAR(64), 'UUID' VARCHAR(96), 'PosX' FLOAT(8) NOT NULL, 'PosY' FLOAT(8) NOT NULL, 'PosZ' FLOAT(8) NOT NULL, 'Shared' BIT(1) NOT NULL, 'ColorR' TINYINT(3) UNSIGNED, 'ColorG' TINYINT(3) UNSIGNED, 'ColorB' TINYINT(3) UNSIGNED)")
sql.Commit()

-- Name (String), this MUST be escaped with sql.SQLStr
-- UUID (String)
-- Position (Ints), Vector(300.30, 2234.12, 4.41)
-- Color (Ints)

local startPos = Vector(0, 0, 0)
local endPos = Vector(0, 0, -32768)

---------------------------------
-- chicagoRPMinimap.GetWorldPosition
---------------------------------
-- Desc:		Returns the world position of a specified coordinate.
-- State:		Client
-- Arg One:		Panel  - The map view panel.
-- Arg Two:		Number - The horizontal position.
-- Arg Three:	Number - The vertical position.
-- Returns:		Vector - The world position of the specified position.
function chicagoRPMinimap.GetWorldPosition(x, y)
	local panel = chicagoRPMinimap.OpenMapPanel

	chicagoRPMinimap.ResetVector(startPos)

	local mx, my = panel:ScreenToLocal(x, y) -- Pass the mouse into the panel coordinates

	startPos.x = (mx + panel.Offset.x) * panel.MapScale -- Adds the map offset and then scale it to the scale of your minimap
	startPos.y = (my + panel.Offset.y) * panel.MapScale
	startPos.z = panel.traceHeight

	local tr = {}
	tr.start = startPos
	tr.endpos = endPos
	tr.mask = MASK_SOLID_BRUSHONLY

	local trace = util.TraceLine(tr)
	local worldPosition = Vector(startPos.x, startPos.y, trace.HitPos.z)

	return worldPosition
end

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
	net.WriteInt(number integer, number bitCount)
	net.WriteUInt(r, 8)
	net.WriteUInt(g, 8)
	net.WriteUInt(b, 8)
	net.WriteUInt(a, 8)
	net.WriteBool(shared)
	net.WriteBool(permanent)
end

local function AddLocalWaypoint(name, r, g, b, a)
	-- table shit
end

local function AddPermanentWaypoint(name, r, g, b, a, shared)
	local escapedName = sql.SQLStr(name)
	local UUID = chicagoRP.uuid()
	local bool = tonumber(shared)

	sql.Begin()
	sql.Query("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('" .. escapedName .. "', '" .. UUID .. "', '" .. pos.x .. "', '" .. pos.y .. "', '" .. pos.z .. "', '" .. bool .. "', '" .. r .. "', '" .. g .. "', '".. b .. "', '" .. a .. "')")
	sql.Commit()
end

---------------------------------
-- chicagoRPMinimap.CreateWaypoint
---------------------------------
-- Desc:		Create a waypoint.
-- State:		Client
-- Arg One:		String - The waypoint's name.
-- Arg Two:		Vector - The waypoint's world position.
-- Arg Three:	Color - The waypoint's color.
-- Arg Four:	Bool - Whether to make the waypoint shared with friends or not.
-- Arg Five:	Bool - Whether to make the waypoint permanent or not.
function chicagoRPMinimap.CreateWaypoint(name, pos, color, shared, permanent)
	if !string.IsValid(name) then name = "Waypoint" end
	if !shared then shared = false end
	if !permanent then permanent = false end

	local r, g, b, a = color

	if IsColor(color) then r, g, b, a = color:Unpack() end

	if shared then
		SendWaypointNet(name, pos, r, g, b, a, shared, permanent)
		AddPermanentWaypoint(name, pos, r, g, b, a, shared)
	elseif !shared and permanent then
		AddPermanentWaypoint(name, pos, r, g, b, a)
	elseif !shared and !permanent then
		AddLocalWaypoint(name, pos, r, g, b, a)
	end
end