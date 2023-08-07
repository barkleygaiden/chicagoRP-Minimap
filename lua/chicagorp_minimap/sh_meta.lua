require("niknaks")

chicagoRPMinimap = chicagoRPMinimap or {}

---------------------------------
-- chicagoRPMinimap.WriteVector
---------------------------------
-- Desc:		Writes a vector using the net library.
-- State:		Shared
-- Arg One:		Vector - Vector we want to write.
function chicagoRPMinimap.WriteVector(x, y, z)
	if isvector(x) then x, y, z = x.x, x.y, x.z end

	net.WriteFloat(math.Round(x, 2))
	net.WriteFloat(math.Round(y, 2))
	net.WriteFloat(math.Round(z, 2))
end

---------------------------------
-- chicagoRPMinimap.ReadVector
---------------------------------
-- Desc:		Reads a vector using the net library.
-- State:		Shared
-- Returns:		Numbers - Vector values from net message.
function chicagoRPMinimap.ReadVector()
	return math.Round(net.ReadFloat(), 2), math.Round(net.ReadFloat(), 2), math.Round(net.ReadFloat(), 2)
end

---------------------------------
-- chicagoRPMinimap.WriteColor
---------------------------------
-- Desc:		Writes a color using the net library.
-- State:		Shared
-- Arg One:		Number - Color (R) we want to write.
-- Arg Two:		Number - Color (G) we want to write.
-- Arg Three:	Number - Color (B) we want to write.
function chicagoRPMinimap.WriteColor(r, g, b)
	if IsColor(r) then r, g, b = r:Unpack() end

	net.WriteUInt(r, 8)
	net.WriteUInt(g, 8)
	net.WriteUInt(b, 8)
end

---------------------------------
-- chicagoRPMinimap.ReadColor
---------------------------------
-- Desc:		Reads a color using the net library.
-- State:		Shared
-- Returns:		Numbers - Color values from net message.
function chicagoRPMinimap.ReadColor()
	return net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
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
-- chicagoRPMinimap.CreatePVS
---------------------------------
-- Desc:		Create PVS object.
-- State:		Shared
-- Returns:		PVS - A new PVS object.
function chicagoRPMinimap.CreatePVS()
	local bsp = NikNaks.CurrentMap

	return bsp:CreatePVS()
end

local oldLeaf = nil

---------------------------------
-- chicagoRPMinimap.IsOutside
---------------------------------
-- Desc:		Returns if the vector is outside.
-- State:		Shared
-- Arg One:		Vector - Position we want to check.
-- Returns:		Vector - Position of the ceiling.
function chicagoRPMinimap.IsOutside(pos)
	local bsp = NikNaks.CurrentMap
	local leaf = bsp:PointInLeafCache(0, pos, oldLeaf)

	oldleaf = leaf -- this shouldn't cause issues even though this is a shared function

	return leaf:IsOutsideMap()
end

---------------------------------
-- chicagoRPMinimap.GetMapName
---------------------------------
-- Desc:		Gets the name of the map currently being played on.
-- State:		Shared
-- Returns:		String - Name of the map.
function chicagoRPMinimap.GetMapName()
	local bsp = NikNaks.CurrentMap

	return bsp:GetMapName()
end

---------------------------------
-- chicagoRPMinimap.GetMapSize
---------------------------------
-- Desc:		Gets the size of the map currently being played on.
-- State:		Shared
-- Returns:		Vector - Size of the map.
function chicagoRPMinimap.GetMapSize()
	local bsp = NikNaks.CurrentMap

	return bsp:WorldMin(), bsp:WorldMax()
end

---------------------------------
-- chicagoRPMinimap.GetStaticProps
---------------------------------
-- Desc:		Get all prop_statics in the current map.
-- State:		Shared
-- Returns:		Table - All prop_statics.
function chicagoRPMinimap.GetStaticProps()
	local bsp = NikNaks.CurrentMap

	return bsp:GetStaticProps()
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