local LocalTable = chicagoRPMinimap.LocalWaypoints
local SharedTable = chicagoRPMinimap.SharedWaypoints

net.Receive("chicagoRP_minimap_fetchwaypoints", function(len)
	local count = net.ReadUInt(11) -- Waypoint count, if you manage to go above 2048 waypoints you deserve an award.
	local add = net.ReadBool() -- Whether to add the waypoints or remove them.

	for i = 1, count do
		if add then
			local waypoint = {}
			waypoint.Name = net.ReadString() -- Reads name (String)
			waypoint.UUID = net.ReadString() -- Reads UUID (String)
			waypoint.Owner = net.ReadString() -- Reads owner's SteamID64 (String)
			waypoint.Permanent = net.ReadBool() -- Reads permanent status (Bool)
			waypoint.Pos = Vector(chicagoRPMinimap.ReadVector()) -- Reads position (Vector)
			waypoint.Color = Color(chicagoRPMinimap.ReadColor()) -- Reads color (Color)

			SharedTable[waypoint.UUID] = waypoint

			chicagoRPMinimap.WaypointButton(chicagoRPMinimap.OpenMapPanel, x, y, w, h, waypoint) -- Broken currently, FIX PLEASE!!!
		else
			local UUID = net.ReadString()

			LocalTable[UUID] = nil
			SharedTable[UUID] = nil
		end
	end
end)

net.Receive("chicagoRP_minimap_transferwaypoints", function(len)
	local originalMap = net.ReadString()
	local newMap = net.ReadString()

	local selectQuery = string.concat("SELECT * FROM 'chicagoRPMinimap_Waypoints' WHERE 'Map'='", originalMap, "'")
	local updateQuery = string.concat("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Map'='", newMap, "' WHERE 'Map'='", originalMap, "'")

	sql.Begin()
	local waypoints = sql.Query(selectQuery)
	sql.Query(updateQuery)
	sql.Commit()

	chicagoRPMinimap.SharedWaypoints = {} -- Clears shared lua table.

	if !waypoints then return end -- Return end if we have no waypoints, or if an SQL error occured.

	for i = 1, #waypoints do
		local waypoint = waypoints[i] -- Waypoint stats.
		local UUID = waypoint.UUID -- Waypoint UUID.

		LocalTable[UUID] = nil
	end
end)

local function QuickDelete(uuid)
	LocalTable[UUID] = nil
	SharedTable[UUID] = nil

	local deleteQuery = string.concat("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='", sql.SQLStr(uuid), "'")

	sql.Begin()
	sql.Query(deleteQuery)
	sql.Commit()
end

net.Receive("chicagoRP_minimap_localwaypoint", function(len)
	local add = net.ReadBool() -- Whether to add the waypoints or remove them.
	local isSQL = net.ReadBool() -- Whether waypoint is SQL (permanent) or not.

	if isSQL and add then
		local name = net.ReadString() -- Reads name (String)
		local pos = Vector(chicagoRPMinimap.ReadVector()) -- Reads position (Vector)
		local color = Color(chicagoRPMinimap.ReadColor()) -- Reads color (Color)

		chicagoRPMinimap.CreateWaypoint(name, pos, color, false, true) -- Adds waypoint to clientside SQL table.
	elseif !isSQL and add then
		local name = net.ReadString() -- Reads name (String)
		local pos = Vector(chicagoRPMinimap.ReadVector()) -- Reads position (Vector)
		local color = Color(chicagoRPMinimap.ReadColor()) -- Reads color (Color)

		chicagoRPMinimap.CreateWaypoint(name, pos, color, false, false) -- Adds waypoint to clientside lua table.
	end

	if !add then
		local UUID = net.ReadString() -- Reads UUID (String)

		QuickDelete(uuid) -- Deletes waypoint.
	end
end)