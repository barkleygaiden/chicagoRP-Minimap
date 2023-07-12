util.AddNetworkString("chicagoRP_minimap_createwaypoint")

net.Receive("chicagoRP_minimap_createwaypoint", function(len, ply)
	local Time = CurTime()

	if (ply.LastWaypointNet or 0) >= Time then return end

	ply.LastWaypointNet = Time + 0.5

	local UUID = chicagoRP.uuid()
	local SteamID = ply:SteamID64()
	local name = sql.SQLStr(net.ReadString())
	local PosX, PosY, PosZ = net.ReadInt(18), net.ReadInt(18), net.ReadInt(18)
	local r, g, b, a = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
	local isPermanent = net.ReadBool()

	sql.Begin()
	sql.Query("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'SteamID', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('" .. name .. "', '" .. UUID .. "', '" .. SteamID .. "', '" .. PosX .. "', '" .. PosY .. "', '" .. PosZ .. "', '" .. r .. "', '" .. g .. "', '".. b .. "', '" .. a .. "')")
	sql.Commit()

	-- write friends system for chicagoRP library

	net.WriteUInt(1, 11) -- Count
	net.WriteString(name)
	net.WriteString(UUID)
	net.WriteString(SteamID)
	net.WriteInt(PosX, 18)
	net.WriteInt(PosY, 18)
	net.WriteInt(PosZ, 18)
	net.WriteUInt(r, 8)
	net.WriteUInt(g, 8)
	net.WriteUInt(b, 8)
	net.WriteUInt(a, 8)
	net.Send(friends)
end)

net.Receive("chicagoRP_minimap_editwaypoint", function(len, ply)
	local Time = CurTime()

	if (ply.LastWaypointNet or 0) >= Time then return end

	ply.LastWaypointNet = Time + 0.5

	local name = net.ReadString()
	local r, g, b, a = net.WriteUInt(8), net.WriteUInt(8), net.WriteUInt(8), net.WriteUInt(8)
	local isPermanent = net.ReadBool()

	print("a")
end)