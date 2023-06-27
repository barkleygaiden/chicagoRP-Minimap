require("niknaks")

chicagoRPMinimap = chicagoRPMinimap or {}
local bsp = NikNaks.CurrentMap

---------------------------------
-- chicagoRPMinimap.GetAllWaypoints
---------------------------------
-- Desc:		Gets all the current waypoints.
-- State:		Shared
-- Returns:		Table - All current waypoints.
function chicagoRPMinimap.GetAllWaypoints()
	return {}
end

local oldLeaf

---------------------------------
-- chicagoRPMinimap.IsOutside
---------------------------------
-- Desc:		Returns if the vector is outside.
-- State:		Shared
-- Arg One:		Vector - Position we want to check.
-- Returns:		Vector - Position of the ceiling.
function chicagoRPMinimap.IsOutside(pos)
	local leaf = bsp:PointInLeafCache(0, pos, oldLeaf)

	oldleaf = leaf -- this shouldn't cause issues even though this is a shared function

	return leaf:IsOutsideMap()
end

---------------------------------
-- chicagoRPMinimap.GetMapSize
---------------------------------
-- Desc:		Gets the size of the map currently being played on.
-- State:		Shared
-- Returns:		Vector - Size of the map.
function chicagoRPMinimap.GetMapSize()
	return bsp:GetBrushBounds()
end

---------------------------------
-- chicagoRPMinimap.GetCeilingPos
---------------------------------
-- Desc:		Gets the position of the building's ceiling that the player is in.
-- State:		Shared
-- Arg One:		Entity - Player whose position we want to check.
-- Returns:		Vector - Position of the ceiling.
function chicagoRPMinimap.GetCeilingPos(ply)
	return vector_origin
end