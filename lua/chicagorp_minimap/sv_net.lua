util.AddNetworkString("chicagoRP_minimap_createwaypoint") -- Client to Server
util.AddNetworkString("chicagoRP_minimap_editwaypoint")
util.AddNetworkString("chicagoRP_minimap_deletewaypoint")

util.AddNetworkString("chicagoRP_minimap_fetchwaypoints") -- Server to Client
util.AddNetworkString("chicagoRP_minimap_clearwaypoints")

net.Receive("chicagoRP_minimap_createwaypoint", function(len, ply)
	local Time = CurTime()

	if (ply.LastWaypointNet or 0) >= Time then return end

	ply.LastWaypointNet = Time + 0.5

	local UUID = chicagoRP.uuid()
	local MapName = chicagoRPMinimap.GetMapName()
	local steamID = ply:SteamID64()
	local name = sql.SQLStr(net.ReadString())
	local PosX, PosY, PosZ = chicagoRPMinimap.ReadVector()
	local r, g, b = chicagoRPMinimap.ReadColor()
	local isPermanent = tostring(tonumber(net.ReadBool()))

	if #name > 48 then name = string.Left(name, 48) end

	sql.Begin()
	sql.Query("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Owner', 'Permanent', 'Map', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('" .. name .. "', '" .. UUID .. "', '" .. steamID .. "', '" .. isPermanent .. "', '" .. MapName .. "', '" .. PosX .. "', '" .. PosY .. "', '" .. PosZ .. "', '" .. r .. "', '" .. g .. "', '".. b .. "', '" .. a .. "')")
	sql.Commit()

	chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, PosX, PosY, PosZ, r, g, b)
end)

net.Receive("chicagoRP_minimap_editwaypoint", function(len, ply)
	local Time = CurTime()

	if (ply.LastWaypointNet or 0) >= Time then return end

	ply.LastWaypointNet = Time + 0.5

	local UUID = sql.SQLStr(net.ReadString())
	local steamID = ply:SteamID64()
	local name = sql.SQLStr(net.ReadString())
	local PosX, PosY, PosZ = chicagoRPMinimap.ReadVector()
	local r, g, b = chicagoRPMinimap.ReadColor()
	local isPermanent = tostring(tonumber(net.ReadBool()))

	sql.Begin()
	sql.Query("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Name'='" .. name .. "', 'PosX'='" .. PosX .. "', 'PosY='" .. PosY .. "', 'PosZ'='" .. PosZ .. "', 'ColorR'='" .. r .. "', 'ColorG'='" .. g .. "', 'ColorB'='" .. b .. "' WHERE 'UUID'='" .. UUID .. "' AND 'Owner'='" .. steamID .. "'")
	sql.Commit()

	chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, PosX, PosY, PosZ, r, g, b)
end)

net.Receive("chicagoRP_minimap_deletewaypoint", function(len, ply)
	local Time = CurTime()

	if (ply.LastWaypointNet or 0) >= Time then return end

	ply.LastWaypointNet = Time + 0.5

	local UUID = sql.SQLStr(net.ReadString())
	local steamID = ply:SteamID64()

	sql.Begin()
	sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. UUID .. "' and 'Owner'='" .. steamID "'")
	sql.Commit()

	chicagoRPMinimap.NetRemoveHandler(ply, UUID)
end)