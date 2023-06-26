AddCSLuaFile()

AddCSLuaFile("chicagorp_minimap/sh_meta.lua")
include("chicagorp_minimap/sh_meta.lua")

local files = file.Find("chicagorp_minimap/*.lua", "LUA")

for i = 1, #files do
    local f = files[i]

    if f == "sh_meta.lua" then continue end

    if string.Left(f, 3) == "sv_" then
        if SERVER then 
            include("chicagorp_minimap/" .. f) 
        end
    elseif string.Left(f, 3) == "cl_" then
        if CLIENT then
            include("chicagorp_minimap/" .. f)
        else
            AddCSLuaFile("chicagorp_minimap/" .. f)
        end
    elseif string.Left(f, 3) == "sh_" then
        AddCSLuaFile("chicagorp_minimap/" .. f)
        include("chicagorp_minimap/" .. f)
    else
        print("chicagoRP Minimap detected unaccounted for lua file '" .. f .. "' - check prefixes!")
    end

    print("chicagoRP Minimap successfully loaded!")
end
