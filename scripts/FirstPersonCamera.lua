-- FirstPersonCamera.lua (StarterPlayerScripts)
-- Locks camera to first-person for horror immersion

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Lock to first-person view
player.CameraMode = Enum.CameraMode.LockFirstPerson
player.CameraMaxZoomDistance = 0.5
player.CameraMinZoomDistance = 0.5

-- Also set on character added (respawn)
player.CharacterAdded:Connect(function(character)
    player.CameraMode = Enum.CameraMode.LockFirstPerson
end)

print("[FirstPersonCamera] Locked to first-person view")
