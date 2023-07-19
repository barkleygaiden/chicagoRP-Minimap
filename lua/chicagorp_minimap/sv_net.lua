util.AddNetworkString("chicagoRP_minimap_createwaypoint")
util.AddNetworkString("chicagoRP_minimap_editwaypoint")
util.AddNetworkString("chicagoRP_minimap_deletewaypoint")

net.Receive("chicagoRP_minimap_createwaypoint", function(len, ply)
	local Time = CurTime()

	if (ply.LastWaypointNet or 0) >= Time then return end

	ply.LastWaypointNet = Time + 0.5

	local UUID = chicagoRP.uuid()
	local steamID = ply:SteamID64()
	local name = sql.SQLStr(net.ReadString())
	local PosX, PosY, PosZ = net.ReadInt(18), net.ReadInt(18), net.ReadInt(18)
	local r, g, b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
	local isPermanent = tostring(tonumber(net.ReadBool()))

	if #name > 64 then name = string.Left(name, 64) end

	sql.Begin()
	sql.Query("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Owner', 'Permanent', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('" .. name .. "', '" .. UUID .. "', '" .. steamID .. "', '" .. isPermanent .. "', '" .. PosX .. "', '" .. PosY .. "', '" .. PosZ .. "', '" .. r .. "', '" .. g .. "', '".. b .. "', '" .. a .. "')")
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
	local PosX, PosY, PosZ = net.ReadInt(18), net.ReadInt(18), net.ReadInt(18)
	local r, g, b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
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