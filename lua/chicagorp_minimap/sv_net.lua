util.AddNetworkString("chicagoRP_minimap_createwaypoint")

net.Receive("chicagoRP_minimap_createwaypoint", function(len, ply)
	local Time = CurTime()

	if (ply.LastWaypointCreate or 0) >= Time then return end

	NextMove = Time + 0.5

	local name = net.ReadString()
	local r, g, b, a = net.WriteUInt(8), net.WriteUInt(8), net.WriteUInt(8), net.WriteUInt(8)
	local isShared = net.ReadBool()
	local isPermanent = net.ReadBool()

	print("a")
end)