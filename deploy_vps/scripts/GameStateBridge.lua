--[[
    GameStateBridge - SERVER Script
    Place in ServerScriptService

    Sends comprehensive game state to localhost:8585.
    computer-player reads this to generate test scripts.

    REQUIRES: HttpService enabled in Game Settings!
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local BRIDGE_URL = "http://localhost:8585"
local UPDATE_INTERVAL = 1 -- update every second

-- Track player progress
local playerProgress = {
    roomsVisited = {},
    objectsCollected = {},
    doorsOpened = {},
    deathCause = nil,
    isDead = false
}

-- Check if area is dark
local function checkIfDark()
    if Lighting.Brightness < 0.3 then
        return true
    end
    local ambient = Lighting.Ambient
    if ambient.R < 0.1 and ambient.G < 0.1 and ambient.B < 0.1 then
        return true
    end
    return false
end

-- Check flashlight state
local function getFlashlightState(character)
    local hasFlashlight = false
    local flashlightOn = false

    local player = Players:GetPlayerFromCharacter(character)
    if player then
        -- Check equipped tools
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("flashlight") or tool.Name:lower():find("torch")) then
                hasFlashlight = true
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

-- Get facing direction
local function getCameraDirection(player)
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

-- Calculate direction relative to player's look vector
local function calculateDirection(playerPosition, objectPosition, lookVector)
    -- Get horizontal direction to object (ignore Y)
    local toObject = Vector3.new(
        objectPosition.X - playerPosition.X,
        0,
        objectPosition.Z - playerPosition.Z
    )

    if toObject.Magnitude < 0.01 then
        return { relative = "here", angle = 0 }
    end

    toObject = toObject.Unit
    local lookFlat = Vector3.new(lookVector.X, 0, lookVector.Z)
    if lookFlat.Magnitude < 0.01 then
        lookFlat = Vector3.new(0, 0, -1)
    else
        lookFlat = lookFlat.Unit
    end

    -- Dot product for forward/back, cross product Y for left/right
    local dotForward = lookFlat.X * toObject.X + lookFlat.Z * toObject.Z
    local crossY = lookFlat.X * toObject.Z - lookFlat.Z * toObject.X

    -- Calculate angle in degrees (-180 to 180)
    local angle = math.deg(math.atan2(crossY, dotForward))

    -- Determine relative direction
    local relative
    if angle > 157.5 or angle < -157.5 then
        relative = "back"
    elseif angle > 112.5 then
        relative = "back-right"
    elseif angle > 67.5 then
        relative = "right"
    elseif angle > 22.5 then
        relative = "front-right"
    elseif angle > -22.5 then
        relative = "front"
    elseif angle > -67.5 then
        relative = "front-left"
    elseif angle > -112.5 then
        relative = "left"
    elseif angle > -157.5 then
        relative = "back-left"
    else
        relative = "back"
    end

    return {
        relative = relative,
        angle = math.floor(angle)
    }
end

-- Get nearby objects with positions and directions
local function getNearbyObjects(position, radius, lookVector)
    local nearby = {}
    radius = radius or 100 -- larger radius for better awareness
    lookVector = lookVector or Vector3.new(0, 0, -1)

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Terrain" then
            local distance = (obj.Position - position).Magnitude
            if distance <= radius then
                local tags = CollectionService:GetTags(obj)
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
                    or obj.Name:find("Spawn")
                    or obj.Name:find("Room")
                    or obj.Name:find("Zone")

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
                        direction = calculateDirection(position, obj.Position, lookVector),
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
                            direction = calculateDirection(position, primaryPart.Position, lookVector),
                            tags = {"Enemy"}
                        })
                    end
                end
            end
        end
    end

    table.sort(nearby, function(a, b) return a.distance < b.distance end)

    local result = {}
    for i = 1, math.min(20, #nearby) do
        table.insert(result, nearby[i])
    end
    return result
end

-- Determine current room
local function getCurrentRoom(position)
    local closestRoom = "Unknown"
    local closestDist = math.huge

    for _, folder in pairs(workspace:GetDescendants()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            if folder.Name:find("Room") or folder.Name:find("Zone") or folder.Name:find("Corridor")
               or folder.Name:find("Level") or folder.Name:find("Lab") or folder.Name:find("Storage")
               or folder.Name:find("Spawn") or folder.Name:find("Exit") then
                for _, part in pairs(folder:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local dist = (part.Position - position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestRoom = folder.Name
                        end
                    end
                end
            end
        end
    end

    -- Track visited rooms
    if closestRoom ~= "Unknown" and not table.find(playerProgress.roomsVisited, closestRoom) then
        table.insert(playerProgress.roomsVisited, closestRoom)
    end

    return closestRoom
end

-- Track when player collects something
local function setupCollectionTracking(player)
    player.CharacterAdded:Connect(function(character)
        -- Reset on respawn
        playerProgress.isDead = false
        playerProgress.deathCause = nil

        local humanoid = character:WaitForChild("Humanoid")

        -- Track death
        humanoid.Died:Connect(function()
            playerProgress.isDead = true
            -- Try to determine cause
            local nearbyEnemies = {}
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Model") and (obj.Name:find("Enemy") or obj.Name:find("Experiment")
                       or obj.Name:find("Worker") or obj.Name:find("Patient") or obj.Name:find("Prisoner")) then
                        local primaryPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart")
                        if primaryPart then
                            local dist = (primaryPart.Position - rootPart.Position).Magnitude
                            if dist < 20 then
                                playerProgress.deathCause = obj.Name
                                break
                            end
                        end
                    end
                end
            end
            if not playerProgress.deathCause then
                playerProgress.deathCause = "unknown"
            end
        end)
    end)
end

-- Track object pickups (via Touched or CollectionService)
CollectionService:GetInstanceAddedSignal("Collectible"):Connect(function(obj)
    obj.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            if not table.find(playerProgress.objectsCollected, obj.Name) then
                table.insert(playerProgress.objectsCollected, obj.Name)
            end
        end
    end)
end)

-- Track door opens
CollectionService:GetInstanceAddedSignal("Door"):Connect(function(door)
    -- Assume door has an "Opened" attribute or similar
    door:GetAttributeChangedSignal("Opened"):Connect(function()
        if door:GetAttribute("Opened") then
            if not table.find(playerProgress.doorsOpened, door.Name) then
                table.insert(playerProgress.doorsOpened, door.Name)
            end
        end
    end)
end)

-- Send state
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
            -- Basic
            playerName = player.Name,
            playerPosition = {
                x = math.floor(position.X),
                y = math.floor(position.Y),
                z = math.floor(position.Z)
            },
            cameraDirection = getCameraDirection(player),

            -- Health
            health = math.floor(health),
            maxHealth = math.floor(maxHealth),
            isAlive = health > 0,
            isDead = playerProgress.isDead,
            deathCause = playerProgress.deathCause,

            -- Environment
            isDark = checkIfDark(),
            hasFlashlight = hasFlashlight,
            flashlightOn = flashlightOn,
            currentRoom = getCurrentRoom(position),

            -- Progress tracking
            roomsVisited = playerProgress.roomsVisited,
            objectsCollected = playerProgress.objectsCollected,
            doorsOpened = playerProgress.doorsOpened,

            -- Nearby objects with positions and directions
            nearbyObjects = getNearbyObjects(position, 100, rootPart.CFrame.LookVector),

            -- Meta
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

-- Setup tracking for existing and new players
for _, player in Players:GetPlayers() do
    setupCollectionTracking(player)
end
Players.PlayerAdded:Connect(setupCollectionTracking)

-- Main loop
task.spawn(function()
    print("GameStateBridge: Started, sending to " .. BRIDGE_URL)
    print("GameStateBridge: Update interval = " .. UPDATE_INTERVAL .. "s")
    while true do
        task.wait(UPDATE_INTERVAL)
        pcall(sendState)
    end
end)
