net.Receive("chicagoRP_minimap_fetchwaypoints", function(len)
	local SharedTable = chicagoRPMinimap.SharedWaypoints
	local count = net.ReadUInt(11) -- if you manage to go above 2048 waypoints you deserve an award
	local add = net.ReadBool()

	for i = 1, count do
		if add then
			local waypoint = {}
			waypoint.Name = net.ReadString()
			waypoint.UUID = net.ReadString()
			waypoint.Owner = net.ReadString()
			waypoint.Pos = Vector(net.ReadInt(18), net.ReadInt(18), net.ReadInt(18))
			waypoint.Color = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))

			SharedTable[waypoint.UUID] = waypoint
		else
			local UUID = net.ReadString()

			SharedTable[UUID] = nil
		end
	end
end)