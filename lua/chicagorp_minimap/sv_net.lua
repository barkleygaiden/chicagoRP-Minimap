util.AddNetworkString("chicagoRP_minimap_waypoint") -- Client to Server
util.AddNetworkString("chicagoRP_minimap_editwaypoint")
util.AddNetworkString("chicagoRP_minimap_fetchwaypoints") -- Server to Client
util.AddNetworkString("chicagoRP_minimap_clearwaypoints")
util.AddNetworkString("chicagoRP_minimap_localwaypoint")

local function NetTableHandler(tbl, count)
    for i = 1, count do
        local waypoint = tbl[i]

        net.WriteString(waypoint.Name) -- Writes name (String)
        net.WriteString(waypoint.UUID) -- Writes UUID (String)
        net.WriteString(waypoint.Owner) -- Writes owner's SteamID64 (String)
        net.WriteBool(waypoint.Permanent) -- Write permanent status (Bool)
        chicagoRPMinimap.WriteVector(waypoint.PosX, waypoint.PosY, waypoint.PosZ) -- Writes position (Floats)
        chicagoRPMinimap.WriteColor(waypoint.ColorR, waypoint.ColorG, waypoint.ColorB) -- Writes color (Ints)
    end
end

function chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, permanent, PosX, PosY, PosZ, r, g, b, count)
    if !count then count = 1 end
    local friends = chicagoRP.GetFriends(ply) -- Gets the waypoint owner's friends.
    local isTable = istable(name) -- Checks whether the second arg is a table or not.

    table.insert(friends, ply) -- Insert waypoint owner into the net receiver table.

    net.Start("chicagoRP_minimap_fetchwaypoints")
    net.WriteUInt(count, 11) -- Waypoint count.
    net.WriteBool(true) -- True, because we're adding waypoints.

    if isTable then 
        NetTableHandler(name, #name) -- Table handler, see above
    else
        net.WriteString(name) -- Writes name (String)
        net.WriteString(UUID) -- Writes UUID (String)
        net.WriteString(steamID) -- Writes owner's SteamID64 (String)
        net.WriteBool(permanent) -- Write permanent status (Bool)
        chicagoRPMinimap.WriteVector(PosX, PosY, PosZ) -- Writes position (Floats)
        chicagoRPMinimap.WriteColor(r, g, b) -- Writes color (Ints)
    end

    net.Send(friends)
end

function chicagoRPMinimap.NetAddClientHandler(ply, name, permanent, PosX, PosY, PosZ, r, g, b)
    net.Start("chicagoRP_minimap_localwaypoint")
    net.WriteBool(true) -- True, because we're adding a waypoint.
    net.WriteBool(permanent) -- Write permanent status (Bool)
    net.WriteString(name) -- Writes name (String)
    chicagoRPMinimap.WriteVector(PosX, PosY, PosZ) -- Writes position (Floats)
    chicagoRPMinimap.WriteColor(r, g, b) -- Writes color (Ints)
    net.Send(ply)
end

function chicagoRPMinimap.NetRemoveHandler(ply, obj, count)
    if !count then count = 1 end
    local friends = chicagoRP.GetFriends(ply) -- Gets the waypoint owner's friends.
    local isTable = istable(obj) -- Checks whether the second arg is a table or not.

    table.insert(friends, ply) -- Insert waypoint owner into the net receiver table.

    net.Start("chicagoRP_minimap_fetchwaypoints")
    net.WriteUInt(count, 11) -- Waypoint count.
    net.WriteBool(false) -- False, because we're removing waypoints.

    for i = 1, count do
        local UUID = (isTable and obj[i]) or obj

        net.WriteString(UUID) -- Writes UUID (String)
    end

    net.Send(friends)
end

function chicagoRPMinimap.NetRemoveClientHandler(ply, uuid)
    net.Start("chicagoRP_minimap_localwaypoint")
    net.WriteBool(false) -- False, because we're removing a waypoint.
    net.WriteBool(false) -- False, because the net message deletes the waypoint in clientside SQL and lua table.
    net.WriteString(uuid) -- Writes UUID (String)
    net.Send(ply)
end

net.Receive("chicagoRP_minimap_waypoint", function(len, ply)
    local Time = CurTime()

    if (ply.LastWaypointNet or 0) >= Time then return end -- Prevents net message spam by checking last net timestamp.

    ply.LastWaypointNet = Time + 0.5

    local actionType = net.ReadUInt(2) -- Reads ActionType (Int)
    local steamID = ply:SteamID64()

    if actionType == 1 or actionType == 2 then -- Create/Edit waypoint.
        local MapName = sql.SQLStr(chicagoRPMinimap.GetMapName())
        local name = sql.SQLStr(net.ReadString()) -- Reads name (String)
        local PosX, PosY, PosZ = chicagoRPMinimap.ReadVector() -- Reads position (Floats)
        local r, g, b = chicagoRPMinimap.ReadColor() -- Reads color (Ints)
        local isPermanent = net.ReadBool() -- Read permanent status (Bool)

        if #name > 48 then name = string.Left(name, 48) end -- Limits name to 48 characters for SQL table.

        if actionType == 1 then -- Create waypoint.
            local UUID = sql.SQLStr(chicagoRP.uuid()) -- Generates UUID
            local insertQuery = string.concat("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Owner', 'Permanent', 'Map', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('", name, "', '", UUID, "', '", steamID, "', '", tostring(tonumber(isPermanent)), "', '", MapName, "', '", PosX, "', '", PosY, "', '", PosZ, "', '", r, "', '", g, "', '".. b, "')")

            sql.Begin()
            sql.Query(insertQuery)
            sql.Commit()
        elseif actionType == 2 then -- Edit waypoint.
            local UUID = sql.SQLStr(net.ReadString()) -- Reads UUID (String)

            if !chicagoRPMinimap.IsWaypointOwner(ply, UUID) then return end -- You are not the owner, fuck off.

            local updateQuery = string.concat("UPDATE 'chicagoRPMinimap_Waypoints' SET 'Name'='", name, "', 'Permanent'='", tostring(tonumber(isPermanent)), "', 'PosX'='", PosX, "', 'PosY='", PosY, "', 'PosZ'='", PosZ, "', 'ColorR'='", r, "', 'ColorG'='", g, "', 'ColorB'='", b, "' WHERE 'UUID'='", UUID, "' AND 'Owner'='", steamID, "'")

            sql.Begin()
            sql.Query(updateQuery)
            sql.Commit()
        end

        chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, isPermanent, PosX, PosY, PosZ, r, g, b)
    elseif actionType == 3 then -- Delete waypoint.
        local UUID = sql.SQLStr(net.ReadString()) -- Reads UUID (String)

        if !chicagoRPMinimap.IsWaypointOwner(ply, UUID) then return end -- You are not the owner, fuck off.

        local deleteQuery = string.concat("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='", UUID, "' and 'Owner'='", steamID, "'")

        sql.Begin()
        sql.Query(deleteQuery)
        sql.Commit()

        chicagoRPMinimap.NetRemoveHandler(ply, UUID)
    end
end)

net.Receive("chicagoRP_minimap_editwaypoint", function(len, ply)
    local Time = CurTime()

    if (ply.LastWaypointNet or 0) >= Time then return end -- Prevents net message spam by checking last net timestamp.

    ply.LastWaypointNet = Time + 0.5

    local steamID = ply:SteamID64()

    local MapName = chicagoRPMinimap.GetMapName()
    local name = sql.SQLStr(net.ReadString()) -- Reads name (String)
    local PosX, PosY, PosZ = chicagoRPMinimap.ReadVector() -- Reads position (Floats)
    local r, g, b = chicagoRPMinimap.ReadColor() -- Reads color (Ints)
    local isPermanent = net.ReadBool() -- Reads permanent status (Bool)
    local UUID = sql.SQLStr(net.ReadString()) -- Reads UUID (String)

    if #name > 48 then name = string.Left(name, 48) end -- Limits name to 48 characters for SQL table.

    if !chicagoRPMinimap.IsWaypointOwner(ply, UUID) then return end -- You are not the owner, fuck off.

    local deleteQuery = string.concat("DELETE FROM 'chicagoRPMinimap_Waypoints' WHERE 'UUID'='", UUID, "' and 'Owner'='", steamID, "'")
    local insertQuery = string.concat("INSERT INTO `chicagoRPMinimap_Waypoints`('Name', 'UUID', 'Owner', 'Permanent', 'Map', 'PosX', 'PosY', 'PosZ', 'ColorR', 'ColorG', 'ColorB') VALUES ('", name, "', '", UUID, "', '", steamID, "', '", tostring(tonumber(isPermanent)), "', '", MapName, "', '", PosX, "', '", PosY, "', '", PosZ, "', '", r, "', '", g, "', '", b, "')")

    sql.Begin()
    sql.Query()
    sql.Query()
    sql.Commit()

    chicagoRPMinimap.NetAddHandler(ply, name, UUID, steamID, isPermanent, PosX, PosY, PosZ, r, g, b)
end)