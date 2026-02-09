--[[
    GameStateBridge - SERVER Script (NOT LocalScript!)
    Place in ServerScriptService

    Sends player position and game state to localhost:8585 every second.
    computer-player reads this data to navigate the game.

    REQUIRES: HttpService enabled in Game Settings!

    NOTE: HTTP requests can ONLY be made from server scripts, not LocalScripts!
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local BRIDGE_URL = "http://localhost:8585"
local UPDATE_INTERVAL = 1 -- seconds

local function getNearbyObjects(position, radius)
    local nearby = {}
    radius = radius or 30

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "Terrain" then
            local distance = (obj.Position - position).Magnitude
            if distance <= radius then
                local tags = CollectionService:GetTags(obj)
                if #tags > 0 or obj.Name:find("Door") or obj.Name:find("Exit") or obj.Name:find("Collect") then
                    table.insert(nearby, {
                        name = obj.Name,
                        class = obj.ClassName,
                        distance = math.floor(distance),
                        tags = tags
                    })
                end
            end
        end
    end

    table.sort(nearby, function(a, b) return a.distance < b.distance end)

    local result = {}
    for i = 1, math.min(10, #nearby) do
        table.insert(result, nearby[i])
    end
    return result
end

local function getCurrentRoom(position)
    for _, folder in pairs(workspace:GetChildren()) do
        if folder:IsA("Folder") or folder:IsA("Model") then
            if folder.Name:find("Room") or folder.Name:find("Zone") or folder.Name:find("Corridor") or folder.Name:find("Level") then
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
        local position = rootPart.Position

        local state = {
            playerName = player.Name,
            playerPosition = {
                x = math.floor(position.X),
                y = math.floor(position.Y),
                z = math.floor(position.Z)
            },
            health = health,
            isAlive = health > 0,
            currentRoom = getCurrentRoom(position),
            nearbyObjects = getNearbyObjects(position, 30),
            timestamp = os.time()
        }

        local success, err = pcall(function()
            HttpService:PostAsync(BRIDGE_URL, HttpService:JSONEncode(state), Enum.HttpContentType.ApplicationJson)
        end)

        if success then
            -- Data sent successfully
        else
            warn("GameStateBridge: Failed to send - " .. tostring(err))
        end
    end
end

-- Main loop
task.spawn(function()
    print("GameStateBridge: Started, sending to " .. BRIDGE_URL)
    while true do
        task.wait(UPDATE_INTERVAL)
        pcall(sendState)
    end
end)
