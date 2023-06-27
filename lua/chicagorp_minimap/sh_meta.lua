require("niknaks")

chicagoRPMinimap = chicagoRPMinimap or {}
local bsp = NikNaks.CurrentMap

sql.Begin()
sql.Query("CREATE TABLE IF NOT EXISTS `chicagoRPMinimap_Waypoints` (`Name` VARCHAR(64), 'PosX' INT(8) NOT NULL, 'PosY' INT(8) NOT NULL, 'PosZ' INT(8) NOT NULL, `Permanent` BIT(1) NOT NULL, 'ColorR' TINYINT(3) UNSIGNED, 'ColorG' TINYINT(3) UNSIGNED, 'ColorB' TINYINT(3) UNSIGNED)")
sql.Commit()

-- Name (String), this MUST be escaped with sql.SQLStr
-- Position (Ints) Vector(300.30, 2234.12, 4.41)
-- Permanent (Boolean)
-- Color (Ints)

---------------------------------
-- chicagoRPMinimap.WriteVector
---------------------------------
-- Desc:		Writes a vector using the net library.
-- State:		Shared
-- Arg One:		Vector - Vector we want to write.
function chicagoRPMinimap.WriteVector(vect)
	net.WriteFloat(vect.x)
	net.WriteFloat(vect.y)
	net.WriteFloat(vect.z)
end

---------------------------------
-- chicagoRPMinimap.ReadVector
---------------------------------
-- Desc:		Reads a vector using the net library.
-- State:		Shared
-- Returns:		Vector - Newly created vector.
function chicagoRPMinimap.ReadVector()
	return Vector(net.ReadFloat(), net.ReadFloat(), net.ReadFloat())
end

---------------------------------
-- chicagoRPMinimap.ResetVector
---------------------------------
-- Desc:		Resets a vector back to 0.
-- State:		Shared
-- Arg One:		Vector - The vector we want to reset.
function chicagoRPMinimap.ResetVector(vect)
	vect.x = 0
	vect.y = 0
	vect.z = 0
end

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