chicagoRPMinimap = chicagoRPMinimap or {}

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
-- Returns:		Vector - Position of the ceiling.
function chicagoRPMinimap.IsOutside(pos)
	local bsp = NikNaks.CurrentMap
	local leaf = bsp:PointInLeafCache(0, pos, oldLeaf)

	oldleaf = leaf -- this shouldn't cause issues even though this is a shared function

	return leaf:IsOutsideMap()
end

---------------------------------
-- chicagoRPMinimap.GetCeilingPos
---------------------------------
-- Desc:		Gets the position of the building's ceiling that the player is in.
-- State:		Shared
-- Returns:		Vector - Position of the ceiling.
function chicagoRPMinimap.GetCeilingPos(ply)
	return vector_origin
end