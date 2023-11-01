---------------------------------
-- chicagoRPMinimap.CreateWaypoint
---------------------------------
-- Desc:		Create a waypoint.
-- State:		Shared
-- Arg One:		Entity - The player we want set the waypoint's owner to.
-- Arg Two:		String - The waypoint's name.
-- Arg Three:	Vector - The waypoint's world position.
-- Arg Four:	Color - The waypoint's color.
-- Arg Five:	Bool - Whether to make the waypoint shared with friends or not.
-- Arg Six:		Bool - Whether to make the waypoint permanent or not.
function chicagoRPMinimap.CreateWaypoint(ply, name, pos, color, shared, permanent)
	if !string.IsValid(name) then name = "Waypoint" end -- Sets name to default if the name string is empty or nil. 
	if !shared then shared = false end -- Defaults to unshared
	if !permanent then permanent = false end -- Defaults to temporary

	if !IsColor(color) then color = Color(color) end
	if #name > 48 then name = string.Left(name, 48) end -- Limits name to 48 characters for SQL table.

	local MapName = sql.SQLStr(chicagoRPMinimap.GetMapName())
	local steamID = sql.SQLStr(ply:SteamID64())
	local UUID = sql.SQLStr(chicagoRP.uuid()) -- Generates UUID.

	if shared then -- Add waypoint to serverside SQL table, and network to owner's friends.
		local insertQuery = string.concat("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Owner', 'Permanent', 'Map', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('", name, "', '", UUID, "', '", steamID, "', '", tostring(tonumber(permanent)), "', '", MapName, "', '", pos.x, "', '", pos.y, "', '", pos.z, "', '", color.r, "', '", color.g, "', '".. color.b, "')")

		sql.Begin()
		sql.Query(insertQuery)
		sql.Commit()

		chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, permanent, pos.x, pos.y, pos.z, color.r, color.g, color.b)
	elseif !shared and permanent then
		chicagoRPMinimap.NetAddClientHandler(ply, name, true, pos.x, pos.y, pos.z, color.r, color.g, color.b) -- Adds waypoint to owner's clientside SQL table.
	elseif !shared and !permanent then
		chicagoRPMinimap.NetAddClientHandler(ply, name, false, pos.x, pos.y, pos.z, color.r, color.g, color.b) -- Adds waypoint to owner's clientside lua table.
	end
end

---------------------------------
-- chicagoRPMinimap.EditWaypoint
---------------------------------
-- Desc:		Edit a shared waypoint.
-- State:		Shared
-- Arg One:		String - The waypoint's UUID.
-- Arg Two:		Vector - The waypoint's name.
-- Arg Three:	Color - The waypoint's color.
-- Arg Four:	Bool - Whether to make the waypoint permanent or not.
function chicagoRPMinimap.EditWaypoint(uuid, name, pos, color, permanent)
	if !string.IsValid(uuid) then return end -- Checks if UUID string is empty or nil.

	local SharedWaypoint = IsWaypointShared(uuid)

	if !SharedWaypoint then return end -- This function only supports editing shared waypoints, not local ones.

	local name = name or SharedWaypoint.Name
	local PosX, PosY, PosZ = (pos.x, pos.y, pos.z) or (SharedWaypoint.PosX, SharedWaypoint.PosY, SharedWaypoint.PosZ)
	local r, g, b = (color.r, color.g, color.b) or (SharedWaypoint.ColorR, SharedWaypoint.ColorG, SharedWaypoint.ColorB)

	local updateQuery = string.concat("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Name'='", name, "', 'Permanent'='", tostring(tonumber(permanent)), "', 'PosX'='", PosX, "', 'PosY='", PosY, "', 'PosZ'='", PosZ, "', 'ColorR'='", r, "', 'ColorG'='", g, "', 'ColorB'='", b, "' WHERE 'UUID'='", UUID, "'")

	sql.Begin()
	sql.Query(updateQuery)
	sql.Commit()
end

---------------------------------
-- chicagoRPMinimap.DeleteWaypoint
---------------------------------
-- Desc:		Delete a waypoint.
-- State:		Shared
-- Arg One:		String - The UUID of the waypoint we want to delete.
-- Arg Two:		Entity - The player that owns the waypoint, only required for non-shared waypoints.
function chicagoRPMinimap.DeleteWaypoint(uuid, ply)
	if !chicagoRPMinimap.IsWaypointOwner(ply, uuid) then return end -- You are not the owner, fuck off.

	local steamID = ply:SteamID64()
	local deleteQuery = string.concat("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='", sql.SQLStr(uuid), "' and 'Owner'='", sql.SQLStr(steamID), "'")

	sql.Begin()
	sql.Query(deleteQuery)
	sql.Commit()

	chicagoRPMinimap.NetRemoveHandler(ply, uuid) -- Removes waypoint from owner's and friends shared lua table. 
	chicagoRPMinimap.NetRemoveClientHandler(ply, uuid) -- Removes waypoint from owner's clientside SQL/lua table.
end

---------------------------------
-- chicagoRPMinimap.GetSharedWaypoints
---------------------------------
-- Desc:		Gets all of a players shared waypoints, does not include waypoints from friends.
-- State:		Shared
-- Arg One:		Entity - The player whose shared waypoints we want to get, or their SteamID64.
-- Returns:		Table - All of the provided player's shared waypoints.
function chicagoRPMinimap.GetSharedWaypoints(ply)
	if !IsValid(ply) then return end

	local steamID = ply:SteamID64()
	local MapName = chicagoRPMinimap.GetMapName()
	local waypoints = {}

	local selectQuery = string.concat("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'Owner'='", steamID, "' AND 'Map'='", MapName, "'")

	sql.Begin()
	local sharedWaypoints = sql.Query(selectQuery)
	sql.Commit()

	for i = 1, #sharedWaypoints do
		local waypoint = sharedWaypoints[i]

		local newWaypoint = {}
		newWaypoint.Name = waypoint.Name
		newWaypoint.UUID = waypoint.UUID
		newWaypoint.Owner = waypoint.Owner
		newWaypoint.Permanent = waypoint.Permanent
		newWaypoint.Pos = Vector(waypoint.PosX, waypoint.PosY, waypoint.PosZ)
		newWaypoint.Color = Color(waypoint.ColorR, waypoint.ColorG, waypoint.ColorB)

		waypoints[waypoint.UUID] = newWaypoint
	end

	return waypoints
end

---------------------------------
-- chicagoRPMinimap.IsWaypointOwner
---------------------------------
-- Desc:		Checks if a waypoint is owned by the player.
-- State:		Shared
-- Arg One:		Entity - The player to check.
-- Arg Two:		String - The UUID of the waypoint we want to check.
function chicagoRPMinimap.IsWaypointOwner(ply, uuid)
	local steamID = ply:SteamID64()

	sql.Begin()
	local isOwner = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='", sql.SQLStr(uuid), "' AND 'Owner'='", steamID)
	sql.Commit()

	return (!isOwner and false) or true -- We do it this way to account for local waypoints.
end

---------------------------------
-- chicagoRPMinimap.IsWaypointShared
---------------------------------
-- Desc:		Checks whether a waypoint is shared or not.
-- State:		Server
-- Arg One:		String - The UUID of the waypoint we want to check.
local function IsWaypointShared(uuid)
	if !string.IsValid(uuid) then return end -- Checks if UUID string is empty or nil.

	local selectQuery = string.concat("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='", UUID, "'")

	sql.Begin()
	local waypoint = sql.Query(selectQuery)
	sql.Commit()

	return waypoint
end

hook.Add("InitPostEntity", "chicagoRP_minimap_init", function()
	sql.Begin()
	sql.Query("CREATE TABLE IF NOT EXISTS 'chicagoRPMinimap_Waypoints'('Name' VARCHAR(48), 'UUID' VARCHAR(96) PRIMARY KEY, 'Owner' VARCHAR(18), 'Permanent' BOOL, 'Map' VARCHAR(32), 'PosX' FLOAT(8), 'PosY' FLOAT(8), 'PosZ' FLOAT(8), 'ColorR' TINYINT(3) UNSIGNED, 'ColorG' TINYINT(3) UNSIGNED, 'ColorB' TINYINT(3) UNSIGNED)")
	sql.Query("CREATE INDEX IF NOT EXISTS 'chicagoRP_Minimap_Waypoints' ON 'chicagoRPMinimap_Waypoints' ('Owner', 'Map')")
	sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'Permanent'='0'")
	sql.Commit()
end)

hook.Add("PlayerInitialSpawn", "chicagoRP_minimap_sendwaypoints", function(ply, transition)
	local steamID = ply:SteamID64()
	local MapName = chicagoRPMinimap.GetMapName()

	timer.Simple(1, function() -- delayed because this can overflow client net channel
		if !IsValid(ply) then return end

		local selectQuery = string.concat("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'Owner'='", steamID, "' AND 'Map'='", MapName, "'")

		sql.Begin()
		local waypoints = sql.Query(selectQuery)
		sql.Commit()

		chicagoRPMinimap.NetAddHandler(ply, waypoints)
	end
end)

gameevent.Listen("player_disconnect")

hook.Add("player_disconnect", "chicagoRP_minimap_clearwaypoints", function(data)
	local ply = Player(data.userid) -- Gets disconnected player.
	local steamID = ply:SteamID64() -- Disconnected player's SteamID64.
	local MapName = chicagoRPMinimap.GetMapName()

	local selectQuery = string.concat("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'Owner'='", steamID, "' AND 'Map'='", MapName, "'")
	local deleteQuery = string.concat("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'Permanent'='0' AND 'Owner'='", steamID, "'")

	sql.Begin()
	local waypoints = sql.Query(selectQuery)
	sql.Query(deleteQuery)
	sql.Commit()

	chicagoRPMinimap.NetRemoveHandler(ply, waypoints, #waypoints) -- Remove disconnected player's waypoints from their friends shared lua table(s).
end)

concommand.Add("chicagorp_minimap_transfertomap", function(ply, cmd, args)
	if !ply:IsSuperAdmin() then return end -- You are not an admin, fuck off.
	if !args or table.IsEmpty(args) then return end -- If no args, return end.
	if !args[2] then return end -- If no second arg, return end.

	local OriginalMap = args[1]
	local NewMap = args[2]

	local updateQuery = string.concat("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Map'='", NewMap, "' WHERE 'Map'='", OriginalMap, "'")

	sql.Begin()
	sql.Query(updateQuery)
	sql.Commit()

	net.Start("chicagoRP_minimap_transferwaypoints") -- Transfers all waypoints in players table to the new map, aka clears all lua tables and does SQL transfer.
	net.WriteString(OriginalMap)
	net.WriteString(NewMap)
	net.Broadcast()
end)