-- EditorLighting.lua
-- Place in ServerScriptService
-- Makes Editor mode bright (for building) and Play mode dark (for horror)

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- In Editor: bright so you can see what you're building
-- In Play: dark for horror atmosphere
if RunService:IsRunning() then
	-- PLAY MODE - dark horror atmosphere
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	print("[EditorLighting] Play mode: dark atmosphere enabled")
else
	-- EDITOR MODE - bright for building
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(100, 100, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 80)
	print("[EditorLighting] Editor mode: bright lighting enabled")
end
