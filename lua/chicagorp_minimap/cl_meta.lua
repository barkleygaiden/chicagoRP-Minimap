chicagoRPMinimap.LocalWaypoints = chicagoRPMinimap.LocalWaypoints or {}
chicagoRPMinimap.SharedWaypoints = chicagoRPMinimap.SharedWaypoints or {}

local LocalTable = chicagoRPMinimap.LocalWaypoints
local SharedTable = chicagoRPMinimap.SharedWaypoints

hook.Add("InitPostEntity", "chicagoRP_minimap_init", function()
	local MapName = chicagoRPMinimap.GetMapName()

	sql.Begin()
	sql.Query("CREATE TABLE IF NOT EXISTS 'chicagoRPMinimap_Waypoints'('Name' VARCHAR(48), 'UUID' VARCHAR(96), 'Map' VARCHAR(32), 'PosX' FLOAT(8) NOT NULL, 'PosY' FLOAT(8) NOT NULL, 'PosZ' FLOAT(8) NOT NULL, 'ColorR' TINYINT(3) UNSIGNED, 'ColorG' TINYINT(3) UNSIGNED, 'ColorB' TINYINT(3) UNSIGNED)")
	local waypoints = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'Map'='" .. MapName .. "'")
	sql.Commit()

	if !waypoints then return end

	for i = 1, #waypoints do
		local waypoint = waypoints[i]
		local UUID = waypoint.UUID

		LocalTable[UUID] = waypoint
	end
end)

local startPos = Vector(0, 0, 0)
local endPos = Vector(0, 0, -32768)

---------------------------------
-- chicagoRPMinimap.LocaltoWorld
---------------------------------
-- Desc:		Returns the world position of a specified coordinate.
-- State:		Client
-- Arg One:		Panel  - The map view panel.
-- Arg Two:		Number - The horizontal position.
-- Arg Three:	Number - The vertical position.
-- Returns:		Vector - The world position of the specified position.
function chicagoRPMinimap.LocaltoWorld(x, y)
	local panel = chicagoRPMinimap.OpenMapPanel

	chicagoRPMinimap.ResetVector(startPos)

	local mx, my = panel:ScreenToLocal(x, y) -- Pass the mouse into the panel coordinates

	startPos.x = (mx + panel.Offset.x) * panel.MapScale -- Adds the map offset and then scale it to the scale of your minimap
	startPos.y = (my + panel.Offset.y) * panel.MapScale
	startPos.z = panel.traceHeight or 10

	local tr = {}
	tr.start = startPos
	tr.endpos = endPos
	tr.mask = MASK_SOLID_BRUSHONLY

	local trace = util.TraceLine(tr)
	local worldPosition = Vector(startPos.x, startPos.y, trace.HitPos.z)

	return worldPosition
end

---------------------------------
-- chicagoRPMinimap.WorldToLocal
---------------------------------
-- Desc:		Returns the local position of a world vector.
-- State:		Client
-- Arg One:		Vector - World position.
-- Returns:		Vector - The local position of the specified world vector.
function chicagoRPMinimap.WorldToLocal(vect)
	-- blackbox
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

	local paren = string.Split(str, " (")
	str = (paren and paren[1]) or str

	local exploded = string.Explode(" ", str)

	for i = 1, #exploded do
		local word = string.upper(exploded[i])
		local letter = string.Left(letter, 2)

		shortstr = shortstr .. letter
	end

	return shortstr
end

local function NetAddHandler(typ, name, pos, color, permanent, uuid)
	if typ > 2 then typ = 1 end

	net.Start("chicagoRP_minimap_waypoint")
	net.WriteUInt(type, 2)
	net.WriteString(name) -- Name (String)
	chicagoRPMinimap.WriteVector(pos) -- Position (Float)
	chicagoRPMinimap.WriteColor(color) -- Color (Int)
	net.WriteBool(permanent) -- Permanent? (Vector)

	if uuid then
		net.WriteString(uuid)
	end

	net.SendToServer()
end

local function NetEditAllHandler(uuid, name, pos, color, permanent)
	net.Start("chicagoRP_minimap_editwaypoint")
	net.WriteString(name) -- Name (String)
	chicagoRPMinimap.WriteVector(pos) -- Position (Float)
	chicagoRPMinimap.WriteColor(color) -- Color (Int)
	net.WriteBool(permanent) -- Permanent? (Bool)
	net.WriteString(uuid)
	net.SendToServer()
end

local function NetEditValueHandler(uuid, waypoint)
	net.Start("chicagoRP_minimap_waypoint")
	net.WriteUInt(2, 2)
	net.WriteString(waypoint.Name) -- Name (String)
	chicagoRPMinimap.WriteVector(waypoint.Pos) -- Position (Float)
	chicagoRPMinimap.WriteColor(waypoint.Color) -- Color (Int)
	net.WriteBool(waypoint.Permanent) -- Permanent? (Vector)
	net.WriteString(uuid)
	net.SendToServer()
end

local function NetRemoveHandler(uuid)
	net.Start("chicagoRP_minimap_waypoint")
	net.WriteUInt(3, 2)
	net.WriteString(uuid)
	net.SendToServer()
end

local function AddLocalWaypoint(name, pos, color, uuid)
	local UUID = uuid or chicagoRP.uuid()

	if !IsColor(color) then color = Color(color) end

	local waypoint = {}
	waypoint.Name = name
	waypoint.UUID = UUID
	waypoint.Permanent = false
	waypoint.Pos = pos
	waypoint.Color = color

	LocalTable[UUID] = waypoint
end

local function AddPermanentWaypoint(name, pos, color, uuid)
	local MapName = chicagoRPMinimap.GetMapName()
	local UUID = uuid or chicagoRP.uuid()
	local r, g, b = color

	if IsColor(color) then r, g, b = color:Unpack() end

	sql.Begin()
	sql.Query("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Map', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('" .. sql.SQLStr(name) .. "', '" .. UUID .. "', '" .. MapName .. "', '" .. pos.x .. "', '" .. pos.y .. "', '" .. pos.z .. "', '" .. r .. "', '" .. g .. "', '".. b .. "')")
	sql.Commit()

	local waypoint = {}
	waypoint.Name = name
	waypoint.UUID = UUID
	waypoint.Permanent = true
	waypoint.Pos = pos
	waypoint.Color = color

	LocalTable[UUID] = waypoint
end

---------------------------------
-- chicagoRPMinimap.CreateWaypoint
---------------------------------
-- Desc:		Create a waypoint.
-- State:		Shared
-- Arg One:		String - The waypoint's name.
-- Arg Two:		Vector - The waypoint's world position.
-- Arg Three:	Color - The waypoint's color.
-- Arg Four:	Bool - Whether to make the waypoint shared with friends or not.
-- Arg Five:	Bool - Whether to make the waypoint permanent or not.
function chicagoRPMinimap.CreateWaypoint(name, pos, color, shared, permanent)
	if !string.IsValid(name) then name = "Waypoint" end
	if !shared then shared = false end
	if !permanent then permanent = false end

	if !IsColor(color) then color = Color(color) end
	if #name > 48 then name = string.Left(name, 48) end

	if shared then
		NetAddHandler(1, name, pos, color, permanent)
	elseif !shared and permanent then
		AddPermanentWaypoint(name, pos, color)
	elseif !shared and !permanent then
		AddLocalWaypoint(name, pos, color)
	end
end

local function CopyWaypointTable(tbl, permanent)
	local newWaypoint = {}
	setmetatable(newWaypoint, debug.getmetatable(tbl))
	newWaypoint.Name = tbl.Name
	newWaypoint.UUID = tbl.UUID
	newWaypoint.Permanent = permanent
	newWaypoint.Pos = tbl.Pos
	newWaypoint.Color = tbl.Color

	return newWaypoint
end

---------------------------------
-- chicagoRPMinimap.EditWaypoint
---------------------------------
-- Desc:		Edit a waypoint.
-- State:		Shared
-- Arg One:		String - The waypoint's name.
-- Arg Two:		Vector - The waypoint's world position.
-- Arg Three:	Color - The waypoint's color.
-- Arg Four:	Bool - Whether to make the waypoint shared with friends or not.
-- Arg Five:	Bool - Whether to make the waypoint permanent or not.
function chicagoRPMinimap.EditWaypoint(uuid, name, pos, color, shared, permanent)
	if !string.IsValid(uuid) then return end
	if !chicagoRPMinimap.IsWaypointOwner(LocalPlayer(), uuid) then return end

	local isLocal = chicagoRPMinimap.IsWaypointLocal(uuid) -- Clientside lua table
	local isShared = chicagoRPMinimap.IsWaypointShared(uuid) -- Serverside SQL
	local waypoint = LocalTable[uuid] or SharedTable[uuid]

	if #name > 48 then name = string.Left(name, 48) end

	-- We have to recreate the waypoint rather than editing it.
	-- Trying to update it while accounting for new shared/permanent status
	-- resulted in shitcode, so I went with the recreation approach which
	-- is also bad but is at least kinda readable.

	if isShared and shared then
		NetEditAllHandler(uuid, name, pos, color, permanent) -- Deletes and recreates waypoint
	elseif isShared and !shared then
		chicagoRPMinimap.DeleteWaypoint(uuid) -- Deletes waypoint

		if permanent then -- Recreate waypoint in client SQL table
			AddPermanentWaypoint(name, pos, color, uuid)
		else
			AddLocalWaypoint(name, pos, color, uuid)
		end
	elseif isLocal and shared then
		chicagoRPMinimap.DeleteWaypoint(uuid) -- Deletes waypoint

		chicagoRPMinimap.CreateWaypoint(name, pos, color, shared, permanent) -- Copies waypoint to serverside
	elseif isLocal and !shared then
		chicagoRPMinimap.DeleteWaypoint(uuid) -- Deletes waypoint

		if permanent then -- Recreate waypoint in client SQL table
			AddPermanentWaypoint(name, pos, color, uuid)
		else -- Recreate waypoint in client lua table
			AddLocalWaypoint(name, pos, color, uuid)
		end
	end
end

---------------------------------
-- chicagoRPMinimap.DeleteWaypoint
---------------------------------
-- Desc:		Delete a waypoint.
-- State:		Shared
-- Arg One:		String - The UUID of the waypoint we want to delete.
function chicagoRPMinimap.DeleteWaypoint(uuid)
	if !string.IsValid(uuid) then return end
	if !chicagoRPMinimap.IsWaypointOwner(LocalPlayer(), uuid) then return end

	local isLocal = chicagoRPMinimap.IsWaypointLocal(uuid)
	local isShared = chicagoRPMinimap.IsWaypointShared(uuid)

	if isLocal then
		local isPermanent = chicagoRPMinimap.IsWaypointPermanent(uuid)

		if isPermanent then
			sql.Begin()
			sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. uuid .. "'")
			sql.Commit()
		end

		LocalTable[uuid] = nil
	elseif isShared then
		NetRemoveHandler(uuid)

		SharedTable[uuid] = nil
	end
end

---------------------------------
-- chicagoRPMinimap.SetName
---------------------------------
-- Desc:		Set a waypoint's name.
-- State:		Shared
-- Arg One:		String - The UUID of the waypoint we want to edit.
-- Arg Two:		String - The name we want to set for the waypoint.
function chicagoRPMinimap.SetName(uuid, name)
	if !string.IsValid(uuid) then return end
	if !chicagoRPMinimap.IsWaypointOwner(LocalPlayer(), uuid) then return end

	local isLocalPermanent = chicagoRPMinimap.IsWaypointLocal(uuid) and chicagoRPMinimap.IsWaypointPermanent(uuid) -- Clientside SQL table
	local isShared = chicagoRPMinimap.IsWaypointShared(uuid) -- Serverside SQL
	local waypoint = LocalTable[uuid] or SharedTable[uuid]

	if #name > 48 then name = string.Left(name, 48) end

	waypoint.Name = name

	if isLocalPermanent then
		sql.Begin()
		sql.Query("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Name'='" .. name .. "' WHERE 'UUID'='" .. uuid .. "'")
		sql.Commit()
	elseif isShared then
		NetEditValueHandler(uuid, waypoint)
	end
end

---------------------------------
-- chicagoRPMinimap.SetPos
---------------------------------
-- Desc:		Set a waypoint's position.
-- State:		Shared
-- Arg One:		String - The UUID of the waypoint we want to edit.
-- Arg Two:		Vector - The position we want to set for the waypoint.
function chicagoRPMinimap.SetPos(uuid, pos)
	if !string.IsValid(uuid) then return end
	if !chicagoRPMinimap.IsWaypointOwner(LocalPlayer(), uuid) then return end

	local isLocalPermanent = chicagoRPMinimap.IsWaypointLocal(uuid) and chicagoRPMinimap.IsWaypointPermanent(uuid) -- Clientside SQL table
	local isShared = chicagoRPMinimap.IsWaypointShared(uuid) -- Serverside SQL
	local waypoint = LocalTable[uuid] or SharedTable[uuid]

	waypoint.Pos = pos

	if isLocalPermanent then
		sql.Begin()
		sql.Query("UPDATE 'chicagoRPMinimap_Waypoints' SET 'PosX'='" .. pos.x .. "', 'PosY='" .. pos.y .. "', 'PosZ'='" .. pos.z .. "' WHERE 'UUID'='" .. uuid .. "'")
		sql.Commit()
	elseif isShared then
		NetEditValueHandler(uuid, waypoint)
	end
end

---------------------------------
-- chicagoRPMinimap.SetColor
---------------------------------
-- Desc:		Set a waypoint's color.
-- State:		Shared
-- Arg One:		String - The UUID of the waypoint we want to edit.
-- Arg Two:		String - The color we want to set for the waypoint.
function chicagoRPMinimap.SetColor(uuid, color)
	if !string.IsValid(uuid) then return end
	if !chicagoRPMinimap.IsWaypointOwner(LocalPlayer(), uuid) then return end

	local isLocalPermanent = chicagoRPMinimap.IsWaypointLocal(uuid) and chicagoRPMinimap.IsWaypointPermanent(uuid) -- Clientside SQL table
	local isShared = chicagoRPMinimap.IsWaypointShared(uuid) -- Serverside SQL
	local waypoint = LocalTable[uuid] or SharedTable[uuid]

	waypoint.Color = color

	if isLocalPermanent then
		sql.Begin()
		sql.Query("UPDATE 'chicagoRPMinimap_Waypoints' SET 'ColorR'='" .. color.r .. "', 'ColorG='" .. color.g .. "', 'ColorB'='" .. color.b .. "' WHERE 'UUID'='" .. uuid .. "'")
		sql.Commit()
	elseif isShared then
		NetEditValueHandler(uuid, waypoint)
	end
end

---------------------------------
-- chicagoRPMinimap.IsWaypointOwner
---------------------------------
-- Desc:		Check if a waypoint is owned by the player.
-- State:		Shared
-- Arg One:		Entity - The player to check.
-- Arg Two:		String - The UUID of the waypoint we want to check.
function chicagoRPMinimap.IsWaypointOwner(ply, uuid)
	if !string.IsValid(uuid) then return false end

	local SharedWaypoint = SharedTable[uuid]

	return LocalTable[uuid] or (SharedWaypoint and ply:SteamID64() == SharedWaypoint.Owner)
end

---------------------------------
-- chicagoRPMinimap.IsWaypointLocal
---------------------------------
-- Desc:		Checks whether a waypoint is local or not.
-- State:		Client
-- Arg One:		String - The UUID of the waypoint we want to check.
function chicagoRPMinimap.IsWaypointLocal(uuid)
	if !string.IsValid(uuid) then return false end

	local LocalWaypoint = LocalTable[uuid]

	return istable(LocalWaypoint)
end

---------------------------------
-- chicagoRPMinimap.IsWaypointShared
---------------------------------
-- Desc:		Checks whether a waypoint is shared or not.
-- State:		Client
-- Arg One:		String - The UUID of the waypoint we want to check.
function chicagoRPMinimap.IsWaypointShared(uuid)
	if !string.IsValid(uuid) then return false end

	local SharedWaypoint = SharedTable[uuid]

	return istable(SharedWaypoint)
end

---------------------------------
-- chicagoRPMinimap.IsWaypointPermanent
---------------------------------
-- Desc:		Checks whether a waypoint is permanent or not.
-- State:		Client
-- Arg One:		String - The UUID of the waypoint we want to check.
function chicagoRPMinimap.IsWaypointPermanent(uuid)
	if !string.IsValid(uuid) then return false end

	local LocalWaypoint = LocalTable[uuid]
	local SharedWaypoint = SharedTable[uuid]

	return LocalWaypoint.Permanent or SharedWaypoint.Permanent or false
end