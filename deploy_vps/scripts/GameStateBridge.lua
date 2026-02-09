--[[
    GameStateBridge - LocalScript
    Place in StarterPlayerScripts

    Sends player position and game state to localhost:8585 every second.
    computer-player reads this data to navigate the game.

    REQUIRES: HttpService enabled in Game Settings!
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local BRIDGE_URL = "http://localhost:8585"
local UPDATE_INTERVAL = 1 -- seconds

local player = Players.LocalPlayer

local function getNearbyObjects(position, radius)
    local nearby = {}
    radius = radius or 30

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Terrain" then
            local distance = (obj.Position - position).Magnitude
            if distance <= radius then
                -- Check if it's interesting (tagged or special)
                local tags = CollectionService:GetTags(obj)
                if #tags > 0 or obj.Parent.Name == "Collectibles" or obj.Name:find("Door") or obj.Name:find("Exit") then
                    table.insert(nearby, {
                        name = obj.Name,
                        class = obj.ClassName,
                        distance = math.floor(distance),
                        position = {math.floor(obj.Position.X), math.floor(obj.Position.Y), math.floor(obj.Position.Z)},
                        tags = tags
                    })
                end
            end
        end
    end

    -- Sort by distance
    table.sort(nearby, function(a, b) return a.distance < b.distance end)

    -- Return top 10
    local result = {}
    for i = 1, math.min(10, #nearby) do
        table.insert(result, nearby[i])
    end
    return result
end

local function getCurrentRoom(position)
    -- Try to find which room/zone the player is in
    for _, folder in pairs(workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            if folder.Name:find("Room") or folder.Name:find("Zone") or folder.Name:find("Corridor") or folder.Name:find("Level") then
                for _, part in pairs(folder:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local partPos = part.Position
                        local partSize = part.Size
                        -- Simple bounding box check
                        if math.abs(position.X - partPos.X) < partSize.X/2 + 5 and
                           math.abs(position.Z - partPos.Z) < partSize.Z/2 + 5 then
                            return folder.Name
                        end
                    end
                end
            end
        end
    end
    return "Unknown"
end

local function getPlayerHealth()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return humanoid.Health
        end
    end
    return 0
end

local function getCameraDirection()
    local camera = workspace.CurrentCamera
    if camera then
        local lookVector = camera.CFrame.LookVector
        return {
            x = math.floor(lookVector.X * 100) / 100,
            y = math.floor(lookVector.Y * 100) / 100,
            z = math.floor(lookVector.Z * 100) / 100
        }
    end
    return {x = 0, y = 0, z = -1}
end

local function sendState()
    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local position = rootPart.Position

    local state = {
        playerPosition = {
            x = math.floor(position.X),
            y = math.floor(position.Y),
            z = math.floor(position.Z)
        },
        cameraDirection = getCameraDirection(),
        health = getPlayerHealth(),
        currentRoom = getCurrentRoom(position),
        nearbyObjects = getNearbyObjects(position, 30),
        isAlive = getPlayerHealth() > 0,
        timestamp = os.time()
    }

    -- Try to get game-specific data
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        state.stats = {}
        for _, stat in pairs(leaderstats:GetChildren()) do
            state.stats[stat.Name] = stat.Value
        end
    end

    -- Send to bridge
    local success, err = pcall(function()
        HttpService:PostAsync(BRIDGE_URL, HttpService:JSONEncode(state), Enum.HttpContentType.ApplicationJson)
    end)

    if not success then
        warn("GameStateBridge: Failed to send state - " .. tostring(err))
    end
end

-- Main loop
task.spawn(function()
    while true do
        task.wait(UPDATE_INTERVAL)
        pcall(sendState)
    end
end)

print("GameStateBridge: Started, sending to " .. BRIDGE_URL)
