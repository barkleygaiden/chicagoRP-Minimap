local function NetTableHandler(tbl, count)
	for i = 1, count do
		local waypoint = tbl[i]

		net.WriteString(waypoint.Name)
		net.WriteString(waypoint.UUID)
		net.WriteString(waypoint.Owner)
		net.WriteBool(waypoint.Permanent)
		chicagoRPMinimap.WriteVector(waypoint.PosX, waypoint.PosY, waypoint.PosZ)
		chicagoRPMinimap.WriteColor(waypoint.ColorR, waypoint.ColorG, waypoint.ColorB)
	end
end

function chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, permanent, PosX, PosY, PosZ, r, g, b, count)
	if !count then count = 1 end
	local friends = chicagoRP.GetFriends(ply)
	local isTable = istable(name)

	table.insert(friends, ply) -- Insert player

	net.Start("chicagoRP_minimap_fetchwaypoints")
	net.WriteUInt(count, 11) -- Count
	net.WriteBool(true)

	if isTable then 
		NetTableHandler(name, #name)
	else
		net.WriteString(name)
		net.WriteString(UUID)
		net.WriteString(steamID)
		net.WriteBool(permanent)
		chicagoRPMinimap.WriteVector(PosX, PosY, PosZ)
		chicagoRPMinimap.WriteColor(r, g, b)
	end

	net.Send(friends)
end

function chicagoRPMinimap.NetAddClientHandler(ply, name, permanent, PosX, PosY, PosZ, r, g, b)
	net.Start("chicagoRP_minimap_localwaypoint")
	net.WriteBool(true)
	net.WriteBool(permanent)
	net.WriteString(name)
	chicagoRPMinimap.WriteVector(PosX, PosY, PosZ)
	chicagoRPMinimap.WriteColor(r, g, b)
	net.Send(ply)
end

function chicagoRPMinimap.NetRemoveHandler(ply, obj, count)
	if !count then count = 1 end
	local friends = chicagoRP.GetFriends(ply)
	local isTable = istable(obj)

	table.insert(friends, ply) -- Insert player

	net.Start("chicagoRP_minimap_fetchwaypoints")
	net.WriteUInt(count, 11) -- Count
	net.WriteBool(false)

	for i = 1, count do
		local UUID = (isTable and obj[i]) or obj

		net.WriteString(UUID)
	end

	net.Send(friends)
end

function chicagoRPMinimap.NetRemoveClientHandler(ply, uuid)
	net.Start("chicagoRP_minimap_localwaypoint")
	net.WriteBool(false)
	net.WriteBool(false)
	net.WriteString(uuid)
	net.Send(ply)
end

---------------------------------
-- chicagoRPMinimap.CreateWaypoint
---------------------------------
-- Desc:		Create a waypoint.
-- State:		Client
-- State:		Shared
-- Arg One:		String - The waypoint's name.
-- Arg Two:		Vector - The waypoint's world position.
-- Arg Three:	Color - The waypoint's color.
-- Arg Four:	Bool - Whether to make the waypoint shared with friends or not.
-- Arg Five:	Bool - Whether to make the waypoint permanent or not.
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
-- Desc:		Create a waypoint.
-- State:		Client
-- Arg One:		String - The waypoint's name.
function chicagoRPMinimap.EditWaypoint(uuid, name, pos, color, shared, permanent)
	-- codehere
end

---------------------------------
-- chicagoRPMinimap.DeleteWaypoint
---------------------------------
-- Desc:		Delete a waypoint.
-- State:		Shared
-- Arg One:		String - The UUID of the waypoint we want to delete.
-- Arg Two:		Entity - The player that owns the waypoint.
function chicagoRPMinimap.DeleteWaypoint(uuid, ply)
	if !chicagoRPMinimap.IsWaypointOwner(ply, uuid) then return end

	local steamID = ply:SteamID64()

	sql.Begin()
	sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. sql.SQLStr(uuid) .. "' and 'Owner'='" .. sql.SQLStr(steamID) .. "'")
	sql.Commit()

	chicagoRPMinimap.NetRemoveHandler(ply, uuid)
	chicagoRPMinimap.NetRemoveClientHandler(ply, uuid)
end

function chicagoRPMinimap.IsWaypointOwner(ply, uuid)
	local steamID = ply:SteamID64()

	sql.Begin()
	local isOwner = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. sql.SQLStr(uuid) .. "' AND 'Owner'='" .. steamID)
	sql.Commit()

	return (!isOwner and false) or true -- We do it this way to account for local waypoints
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