util.AddNetworkString("chicagoRP_minimap_waypoint") -- Client to Server

util.AddNetworkString("chicagoRP_minimap_fetchwaypoints") -- Server to Client
util.AddNetworkString("chicagoRP_minimap_clearwaypoints")

net.Receive("chicagoRP_minimap_waypoint", function(len, ply)
	local Time = CurTime()

	if (ply.LastWaypointNet or 0) >= Time then return end

	ply.LastWaypointNet = Time + 0.5

	local actionType = net.ReadUInt(2)
	local steamID = ply:SteamID64()

	if actionType == 1 or actionType == 2 then
		local MapName = chicagoRPMinimap.GetMapName()
		local name = sql.SQLStr(net.ReadString())
		local PosX, PosY, PosZ = chicagoRPMinimap.ReadVector()
		local r, g, b = chicagoRPMinimap.ReadColor()
		local isPermanent = net.ReadBool()

		if #name > 48 then name = string.Left(name, 48) end

		if actionType == 1 then
			local UUID = chicagoRP.uuid()

			sql.Begin()
			sql.Query("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Owner', 'Permanent', 'Map', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('" .. name .. "', '" .. UUID .. "', '" .. steamID .. "', '" .. tostring(tonumber(isPermanent)) .. "', '" .. MapName .. "', '" .. PosX .. "', '" .. PosY .. "', '" .. PosZ .. "', '" .. r .. "', '" .. g .. "', '".. b .. "', '" .. a .. "')")
			sql.Commit()
		elseif actionType == 2 then
			local UUID = sql.SQLStr(net.ReadString())

			sql.Begin()
			sql.Query("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Owner', 'Permanent', 'Map', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('" .. name .. "', '" .. UUID .. "', '" .. steamID .. "', '" .. tostring(tonumber(isPermanent)) .. "', '" .. MapName .. "', '" .. PosX .. "', '" .. PosY .. "', '" .. PosZ .. "', '" .. r .. "', '" .. g .. "', '".. b .. "', '" .. a .. "')")
			sql.Commit()
		end

		chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, PosX, PosY, PosZ, r, g, b)
	elseif actionType == 3 then
		local UUID = sql.SQLStr(net.ReadString())

		sql.Begin()
		sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. UUID .. "' and 'Owner'='" .. steamID "'")
		sql.Commit()

		chicagoRPMinimap.NetRemoveHandler(ply, UUID)
	end
end)