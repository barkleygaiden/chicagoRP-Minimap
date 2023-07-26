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
	if !string.IsValid(name) then name = "Waypoint" end
	if !shared then shared = false end
	if !permanent then permanent = false end

	if !IsColor(color) then color = Color(color) end
	if #name > 48 then name = string.Left(name, 48) end

	local MapName = sql.SQLStr(chicagoRPMinimap.GetMapName())
	local steamID = sql.SQLStr(ply:SteamID64())
	local UUID = sql.SQLStr(chicagoRP.uuid())

	if shared then
		sql.Begin()
		sql.Query("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Owner', 'Permanent', 'Map', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('" .. name .. "', '" .. UUID .. "', '" .. steamID .. "', '" .. tostring(tonumber(permanent)) .. "', '" .. MapName .. "', '" .. pos.x .. "', '" .. pos.y .. "', '" .. pos.z .. "', '" .. color.r .. "', '" .. color.g .. "', '".. color.b .. "')")
		sql.Commit()

		chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, permanent, pos.x, pos.y, pos.z, color.r, color.g, color.b)
	elseif !shared and permanent then
		chicagoRPMinimap.NetAddClientHandler(ply, name, true, pos.x, pos.y, pos.z, color.r, color.g, color.b)
	elseif !shared and !permanent then
		chicagoRPMinimap.NetAddClientHandler(ply, name, false, pos.x, pos.y, pos.z, color.r, color.g, color.b)
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
	if !uuid or !string.IsValid(uuid) then return end

	local SharedWaypoint = IsWaypointShared(uuid)

	if !SharedWaypoint then return end

	local name = name or SharedWaypoint.Name
	local PosX, PosY, PosZ = (pos.x, pos.y, pos.z) or (SharedWaypoint.PosX, SharedWaypoint.PosY, SharedWaypoint.PosZ)
	local r, g, b = (color.r, color.g, color.b) or (SharedWaypoint.ColorR, SharedWaypoint.ColorG, SharedWaypoint.ColorB)

	sql.Begin()
	sql.Query("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Name'='" .. name .. "', 'Permanent'='" .. tostring(tonumber(permanent)) .. "', 'PosX'='" .. PosX .. "', 'PosY='" .. PosY .. "', 'PosZ'='" .. PosZ .. "', 'ColorR'='" .. r .. "', 'ColorG'='" .. g .. "', 'ColorB'='" .. b .. "' WHERE 'UUID'='" .. UUID .. "'")
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
	if !chicagoRPMinimap.IsWaypointOwner(ply, uuid) then return end

	local steamID = ply:SteamID64()

	sql.Begin()
	sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. sql.SQLStr(uuid) .. "' and 'Owner'='" .. sql.SQLStr(steamID) .. "'")
	sql.Commit()

	chicagoRPMinimap.NetRemoveHandler(ply, uuid)
	chicagoRPMinimap.NetRemoveClientHandler(ply, uuid)
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
	local isOwner = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. sql.SQLStr(uuid) .. "' AND 'Owner'='" .. steamID)
	sql.Commit()

	return (!isOwner and false) or true -- We do it this way to account for local waypoints
end

---------------------------------
-- chicagoRPMinimap.IsWaypointShared
---------------------------------
-- Desc:		Checks whether a waypoint is shared or not.
-- State:		Server
-- Arg One:		String - The UUID of the waypoint we want to check.
local function IsWaypointShared(uuid)
	if !uuid or !string.IsValid(uuid) then return end

	sql.Begin()
	local waypoint = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. UUID .. "'")
	sql.Commit()

	return waypoint
end

hook.Add("InitPostEntity", "chicagoRP_minimap_init", function()
	sql.Begin()
	sql.Query("CREATE TABLE IF NOT EXISTS 'chicagoRPMinimap_Waypoints'('Name' VARCHAR(48), 'UUID' VARCHAR(96), 'Owner' VARCHAR(18), 'Permanent' BOOL, 'Map' VARCHAR(32), 'PosX' FLOAT(8), 'PosY' FLOAT(8), 'PosZ' FLOAT(8), 'ColorR' TINYINT(3) UNSIGNED, 'ColorG' TINYINT(3) UNSIGNED, 'ColorB' TINYINT(3) UNSIGNED)")
	sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'Permanent'='0'")
	sql.Commit()
end)

hook.Add("PlayerInitialSpawn", "chicagoRP_minimap_sendwaypoints", function(ply, _)
	local steamID = ply:SteamID64()
	local MapName = chicagoRPMinimap.GetMapName()

	sql.Begin()
	local waypoints = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'Owner'='" .. steamID .. "' AND 'Map'='" .. MapName .. "'")
	sql.Commit()

	chicagoRPMinimap.NetAddHandler(ply, waypoints)
end)

gameevent.Listen("player_disconnect")

hook.Add("player_disconnect", "chicagoRP_minimap_removewaypoints", function(data)
	local ply = Player(data.userid)
	local steamID = ply:SteamID64()

	sql.Begin()
	local waypoints = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'Owner'='" .. steamID .. "' AND 'Map'='" .. MapName .. "'")
	sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'Permanent'='0' AND 'Owner'='" .. steamID .. "'")
	sql.Commit()

	chicagoRPMinimap.NetRemoveHandler(ply, waypoints, #waypoints)
end)

concommand.Add("chicagorp_minimap_transfertomap", function(ply, cmd, args)
	if !ply:IsSuperAdmin() then return end
	if !args or table.IsEmpty(args) then return end
	if !args[2] then return end

	local OriginalMap = args[1]
	local NewMap = args[2]

	sql.Begin()
	sql.Query("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Map'='" .. NewMap .. "' WHERE 'Map'='" .. OriginalMap .. "'")
	sql.Commit()

	net.Start("chicagoRP_minimap_transferwaypoints") -- Clears all waypoints
	net.WriteString(OriginalMap)
	net.WriteString(NewMap)
	net.Broadcast()
end)