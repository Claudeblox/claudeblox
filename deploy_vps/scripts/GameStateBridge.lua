--[[
    GameStateBridge - SERVER Script (NOT LocalScript!)
    Place in ServerScriptService

    Sends player position and game state to localhost:8585 every second.
    level-runner and computer-player read this data to navigate.

    REQUIRES: HttpService enabled in Game Settings!

    DATA SENT:
    - playerPosition (x, y, z)
    - cameraDirection (x, y, z)
    - health
    - isAlive
    - currentRoom
    - nearbyObjects (with positions!)
    - isDark
    - hasFlashlight
    - flashlightOn
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local BRIDGE_URL = "http://localhost:8585"
local UPDATE_INTERVAL = 0.5 -- faster updates for smooth gameplay

-- Check if area is dark
local function checkIfDark()
    -- Check Lighting brightness
    if Lighting.Brightness < 0.3 then
        return true
    end

    -- Check ambient light
    local ambient = Lighting.Ambient
    if ambient.R < 0.1 and ambient.G < 0.1 and ambient.B < 0.1 then
        return true
    end

    return false
end

-- Check if player has flashlight and if it's on
local function getFlashlightState(character)
    local hasFlashlight = false
    local flashlightOn = false

    -- Check backpack and character for flashlight tool
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        -- Check equipped tools
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("flashlight") or tool.Name:lower():find("torch")) then
                hasFlashlight = true
                -- Check if light inside is enabled
                local light = tool:FindFirstChildWhichIsA("Light", true)
                if light and light.Enabled then
                    flashlightOn = true
                end
            end
        end

        -- Check backpack
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("flashlight") or tool.Name:lower():find("torch")) then
                hasFlashlight = true
            end
        end
    end

    return hasFlashlight, flashlightOn
end

-- Get camera direction from player
local function getCameraDirection(player)
    -- Server can't directly access camera, but we can get character facing direction
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local lookVector = rootPart.CFrame.LookVector
            return {
                x = math.floor(lookVector.X * 100) / 100,
                y = math.floor(lookVector.Y * 100) / 100,
                z = math.floor(lookVector.Z * 100) / 100
            }
        end
    end
    return {x = 0, y = 0, z = -1}
end

local function getNearbyObjects(position, radius)
    local nearby = {}
    radius = radius or 50 -- increased radius for better awareness

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Terrain" then
            local distance = (obj.Position - position).Magnitude
            if distance <= radius then
                local tags = CollectionService:GetTags(obj)
                -- Include objects with tags, or named like important things
                local isImportant = #tags > 0
                    or obj.Name:find("Door")
                    or obj.Name:find("Exit")
                    or obj.Name:find("Collect")
                    or obj.Name:find("Key")
                    or obj.Name:find("Card")
                    or obj.Name:find("Generator")
                    or obj.Name:find("Button")
                    or obj.Name:find("Lever")
                    or obj.Name:find("Enemy")
                    or obj.Name:find("Entity")
                    or obj.Name:find("Experiment")
                    or obj.Name:find("Worker")
                    or obj.Name:find("Patient")
                    or obj.Name:find("Prisoner")

                if isImportant then
                    table.insert(nearby, {
                        name = obj.Name,
                        class = obj.ClassName,
                        distance = math.floor(distance),
                        position = {
                            x = math.floor(obj.Position.X),
                            y = math.floor(obj.Position.Y),
                            z = math.floor(obj.Position.Z)
                        },
                        tags = tags
                    })
                end
            end
        end
    end

    -- Also check for enemy models
    for _, model in pairs(workspace:GetDescendants()) do
        if model:IsA("Model") then
            local isEnemy = model.Name:find("Enemy")
                or model.Name:find("Entity")
                or model.Name:find("Experiment")
                or model.Name:find("Worker")
                or model.Name:find("Patient")
                or model.Name:find("Prisoner")
                or CollectionService:HasTag(model, "Enemy")

            if isEnemy then
                local primaryPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
                if primaryPart then
                    local distance = (primaryPart.Position - position).Magnitude
                    if distance <= radius then
                        table.insert(nearby, {
                            name = model.Name,
                            class = "Enemy",
                            distance = math.floor(distance),
                            position = {
                                x = math.floor(primaryPart.Position.X),
                                y = math.floor(primaryPart.Position.Y),
                                z = math.floor(primaryPart.Position.Z)
                            },
                            tags = {"Enemy"}
                        })
                    end
                end
            end
        end
    end

    table.sort(nearby, function(a, b) return a.distance < b.distance end)

    local result = {}
    for i = 1, math.min(15, #nearby) do
        table.insert(result, nearby[i])
    end
    return result
end

local function getCurrentRoom(position)
    for _, folder in pairs(workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            if folder.Name:find("Room") or folder.Name:find("Zone") or folder.Name:find("Corridor") or folder.Name:find("Level") or folder.Name:find("Lab") or folder.Name:find("Storage") then
                for _, part in pairs(folder:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local partPos = part.Position
                        local partSize = part.Size
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

local function sendState()
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if not character then continue end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local health = humanoid and humanoid.Health or 0
        local maxHealth = humanoid and humanoid.MaxHealth or 100
        local position = rootPart.Position

        local hasFlashlight, flashlightOn = getFlashlightState(character)

        local state = {
            playerName = player.Name,
            playerPosition = {
                x = math.floor(position.X),
                y = math.floor(position.Y),
                z = math.floor(position.Z)
            },
            cameraDirection = getCameraDirection(player),
            health = math.floor(health),
            maxHealth = math.floor(maxHealth),
            isAlive = health > 0,
            isDark = checkIfDark(),
            hasFlashlight = hasFlashlight,
            flashlightOn = flashlightOn,
            currentRoom = getCurrentRoom(position),
            nearbyObjects = getNearbyObjects(position, 50),
            timestamp = os.time()
        }

        local success, err = pcall(function()
            HttpService:PostAsync(BRIDGE_URL, HttpService:JSONEncode(state), Enum.HttpContentType.ApplicationJson)
        end)

        if not success then
            warn("GameStateBridge: Failed to send - " .. tostring(err))
        end
    end
end

-- Main loop
task.spawn(function()
    print("GameStateBridge: Started, sending to " .. BRIDGE_URL)
    print("GameStateBridge: Update interval = " .. UPDATE_INTERVAL .. "s")
    while true do
        task.wait(UPDATE_INTERVAL)
        pcall(sendState)
    end
end)
