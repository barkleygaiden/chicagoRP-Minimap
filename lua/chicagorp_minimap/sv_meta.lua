local function NetTableHandler(tbl, count)
	for i = 1, count do
		local waypoint = tbl[i]

		net.WriteString(waypoint.Name)
		net.WriteString(waypoint.UUID)
		net.WriteString(waypoint.Owner)
		net.WriteBool(waypoint.Permanent)
		net.WriteInt(waypoint.PosX, 18)
		net.WriteInt(waypoint.PosY, 18)
		net.WriteInt(waypoint.PosZ, 18)
		net.WriteUInt(waypoint.ColorR, 8)
		net.WriteUInt(waypoint.ColorG, 8)
		net.WriteUInt(waypoint.ColorB, 8)
	end
end

function chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, permanent, PosX, PosY, PosZ, r, g, b, count)
	if !count then count = 1 end
	local friends = chicagoRP.GetFriends(ply)
	local isTable = istable(name)

	if !chicagoRP.HasFriends(ply) then return end

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
		net.WriteInt(PosX, 18)
		net.WriteInt(PosY, 18)
		net.WriteInt(PosZ, 18)
		net.WriteUInt(r, 8)
		net.WriteUInt(g, 8)
		net.WriteUInt(b, 8)
	end

	net.Send(friends)
end

function chicagoRPMinimap.NetRemoveHandler(ply, obj, count)
	if !count then count = 1 end
	local friends = chicagoRP.GetFriends(ply)
	local isTable = istable(obj)

	if !chicagoRP.HasFriends(ply) then return end

	net.Start("chicagoRP_minimap_fetchwaypoints")
	net.WriteUInt(count, 11) -- Count
	net.WriteBool(false)

	for i = 1, count do
		local UUID = (isTable and obj[i]) or obj

		net.WriteString(UUID)
	end

	net.Send(friends)
end

---------------------------------
-- chicagoRPMinimap.CreateWaypoint
---------------------------------
-- Desc:		Create a waypoint.
-- State:		Client
-- Arg One:		String - The waypoint's name.
function chicagoRPMinimap.CreateWaypoint(name, pos, color, shared, permanent)
	-- codehere
end

---------------------------------
-- chicagoRPMinimap.EditWaypoint
---------------------------------
-- Desc:		Create a waypoint.
-- State:		Client
-- Arg One:		String - The waypoint's name.
function chicagoRPMinimap.EditWaypoint(UUID, name, pos, color, shared, permanent)
	-- codehere
end

---------------------------------
-- chicagoRPMinimap.DeleteWaypoint
---------------------------------
-- Desc:		Create a waypoint.
-- State:		Client
-- Arg One:		String - The waypoint's name.
function chicagoRPMinimap.DeleteWaypoint(UUID)
	-- codehere
end

function chicagoRPMinimap.IsWaypointOwner(ply, uuid)
	local steamID = ply:SteamID64()

	sql.Begin()
	local isOwner = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. sql.SQLStr(uuid) .. "' AND 'Owner'='" .. steamID)
	sql.Commit()

	return isOwner
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