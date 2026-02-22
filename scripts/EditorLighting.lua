-- EditorLighting.lua (ServerScriptService)
-- Editor: Lighting остаётся ЯРКИМ (world-builder ставит яркие параметры)
-- Play: этот скрипт делает ТЕМНО для horror атмосферы

local Lighting = game:GetService("Lighting")

-- Horror darkness for gameplay (slightly brighter for stream visibility)
Lighting.ClockTime = 0
Lighting.Brightness = 0.3
Lighting.Ambient = Color3.fromRGB(20, 20, 25)
Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 20)
Lighting.ExposureCompensation = 0

-- Darken Atmosphere if it exists
local Atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if Atmosphere then
    Atmosphere.Density = 0.8
    Atmosphere.Offset = 1
end

print("[EditorLighting] Play mode: horror darkness enabled")
