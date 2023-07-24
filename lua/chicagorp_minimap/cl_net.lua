local LocalTable = chicagoRPMinimap.LocalWaypoints
local SharedTable = chicagoRPMinimap.SharedWaypoints

net.Receive("chicagoRP_minimap_fetchwaypoints", function(len)
	local count = net.ReadUInt(11) -- if you manage to go above 2048 waypoints you deserve an award
	local add = net.ReadBool()

	for i = 1, count do
		if add then
			local waypoint = {}
			waypoint.Name = net.ReadString()
			waypoint.UUID = net.ReadString()
			waypoint.Owner = net.ReadString()
			waypoint.Permanent = net.ReadBool()
			waypoint.Pos = Vector(chicagoRPMinimap.ReadVector())
			waypoint.Color = Color(chicagoRPMinimap.ReadColor())

			SharedTable[waypoint.UUID] = waypoint
		else
			local UUID = net.ReadString()

			LocalTable[UUID] = nil
			SharedTable[UUID] = nil
		end
	end
end)

net.Receive("chicagoRP_minimap_transferwaypoints", function(len)
	local OriginalMap = net.ReadString()
	local NewMap = net.ReadString()

	sql.Begin()
	local waypoints = sql.Query("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'Map'='" .. OriginalMap .. "'")
	sql.Query("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Map'='" .. NewMap .. "' WHERE 'Map'='" .. OriginalMap .. "'")
	sql.Commit()

	chicagoRPMinimap.SharedWaypoints = {}

	if !waypoints then return end

	for i = 1, #waypoints do
		local waypoint = waypoints[i]
		local UUID = waypoint.UUID

		LocalTable[UUID] = nil
	end
end)

local function QuickDelete(uuid)
	LocalTable[UUID] = nil
	SharedTable[UUID] = nil

	sql.Begin()
	sql.Query("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='" .. sql.SQLStr(uuid) .. "'")
	sql.Commit()
end

net.Receive("chicagoRP_minimap_localwaypoint", function(len)
	local add = net.ReadBool()
	local isSQL = net.ReadBool()

	if isSQL and add then
		local name = net.ReadString()
		local pos = Vector(chicagoRPMinimap.ReadVector())
		local color = Color(chicagoRPMinimap.ReadColor())

		chicagoRPMinimap.CreateWaypoint(name, pos, color, false, true)
	elseif !isSQL and add then
		local name = net.ReadString()
		local pos = Vector(chicagoRPMinimap.ReadVector())
		local color = Color(chicagoRPMinimap.ReadColor())

		chicagoRPMinimap.CreateWaypoint(name, pos, color, false, false)
	end

	if !add then
		local UUID = net.ReadString()

		QuickDelete(uuid)
	end
end)