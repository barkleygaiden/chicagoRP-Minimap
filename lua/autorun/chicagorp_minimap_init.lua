AddCSLuaFile()

if CLIENT then
    include("chicagorp_minimap/cl_meta.lua")
else
    AddCSLuaFile("chicagorp_minimap/cl_meta.lua")
end

local files = file.Find("chicagorp_minimap/*.lua", "LUA")

for i = 1, #files do
    local f = files[i]

    if f == "cl_meta.lua" then continue end

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
