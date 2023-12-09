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