-- EditorLighting.lua (ServerScriptService)
-- Editor: Lighting остаётся как есть (светло)
-- Play: этот скрипт затемняет

local Lighting = game:GetService("Lighting")

Lighting.Brightness = 0
Lighting.Ambient = Color3.fromRGB(0, 0, 0)
Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
print("[EditorLighting] Play mode: dark atmosphere enabled")
