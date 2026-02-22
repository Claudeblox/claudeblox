-- AgentControl.lua
-- Handles agent commands: GO_TO, INTERACT_WITH
-- Camera stays horizontal, follows player view
-- Place in StarterPlayerScripts as LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Settings
local CAMERA_HEIGHT = 2           -- Studs above HumanoidRootPart (eye level)
local TURN_SPEED = 180            -- Degrees per second
local MOVE_THRESHOLD = 4          -- Studs - close enough to target
local COMMAND_CHECK_INTERVAL = 0.3

-- State
local currentCommand = ""
local isExecuting = false

-- Wait for RemoteEvent (created by GameStateBridge server script)
local agentResultEvent = ReplicatedStorage:WaitForChild("AgentCommandResult", 15)

------------------------------------------------------------
-- CAMERA SYSTEM: First person, horizontal, follows player
------------------------------------------------------------

-- Override player camera mode so default controller doesn't fight us
player.CameraMode = Enum.CameraMode.Classic
player.CameraMaxZoomDistance = 0.5
player.CameraMinZoomDistance = 0.5

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Get player's forward direction (horizontal only)
	local lookVector = hrp.CFrame.LookVector
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude > 0.01 then
		flatLook = flatLook.Unit
	else
		flatLook = Vector3.new(0, 0, -1)
	end

	-- Eye position
	local eyePos = hrp.Position + Vector3.new(0, CAMERA_HEIGHT, 0)

	-- Look point: 50 studs ahead, same height (horizontal)
	local lookAtPos = eyePos + flatLook * 50

	-- Apply camera
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(eyePos, lookAtPos)
end)

------------------------------------------------------------
-- SMOOTH TURN: Turn toward target over time (not instant)
------------------------------------------------------------

local function smoothTurnToward(targetPos, timeout)
	local character = player.Character
	if not character then return false end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	timeout = timeout or 3
	local startTime = tick()

	while tick() - startTime < timeout do
		if not character or not character.Parent then return false end

		-- Calculate angle to target
		local toTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z) - hrp.Position
		if toTarget.Magnitude < 0.1 then return true end

		local targetDirection = toTarget.Unit
		local currentDirection = hrp.CFrame.LookVector
		currentDirection = Vector3.new(currentDirection.X, 0, currentDirection.Z)
		if currentDirection.Magnitude > 0.01 then
			currentDirection = currentDirection.Unit
		else
			currentDirection = Vector3.new(0, 0, -1)
		end

		-- Calculate angle difference
		local dot = currentDirection:Dot(targetDirection)
		local angle = math.acos(math.clamp(dot, -1, 1))

		if angle < math.rad(2) then
			-- Close enough, snap to exact
			hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
			return true
		end

		-- Determine turn direction (left or right)
		local cross = currentDirection:Cross(targetDirection)
		local turnDir = cross.Y > 0 and 1 or -1

		-- Turn by TURN_SPEED degrees this frame
		local dt = RunService.Heartbeat:Wait()
		local turnAmount = math.rad(TURN_SPEED * dt) * turnDir

		-- Apply rotation
		hrp.CFrame = hrp.CFrame * CFrame.Angles(0, turnAmount, 0)
	end

	return false -- Timeout
end

------------------------------------------------------------
-- WALK TO POSITION: Walk forward until reaching target
------------------------------------------------------------

local function walkToPosition(targetPos, timeout)
	local character = player.Character
	if not character then return false end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid then return false end

	timeout = timeout or 15
	local startTime = tick()

	-- Disable auto-rotate so we control direction
	local oldAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false

	-- Start moving
	humanoid:MoveTo(targetPos)

	-- Keep facing target while moving
	local moveConnection
	moveConnection = RunService.Heartbeat:Connect(function()
		if not character or not character.Parent then
			moveConnection:Disconnect()
			return
		end

		local toTarget = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z) - hrp.Position
		if toTarget.Magnitude > 1 then
			hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
		end
	end)

	-- Wait for arrival
	local arrived = false
	while tick() - startTime < timeout do
		local distance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude

		if distance < MOVE_THRESHOLD then
			arrived = true
			break
		end

		-- Re-issue MoveTo in case it got interrupted
		humanoid:MoveTo(targetPos)
		task.wait(0.2)
	end

	-- Cleanup
	moveConnection:Disconnect()
	humanoid.AutoRotate = oldAutoRotate
	humanoid:MoveTo(hrp.Position) -- Stop moving

	return arrived
end

------------------------------------------------------------
-- GO_TO: Turn toward object, then walk to it
------------------------------------------------------------

local function GoToObject(objectName)
	print("[AgentControl] GO_TO: " .. objectName)

	local character = player.Character
	if not character then
		return {success = false, error = "No character"}
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return {success = false, error = "No HumanoidRootPart"}
	end

	-- Find target object
	local target = nil
	for _, obj in workspace:GetDescendants() do
		if obj.Name == objectName then
			if obj:IsA("BasePart") then
				target = obj
				break
			elseif obj:IsA("Model") then
				target = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
				break
			end
		end
	end

	if not target then
		print("[AgentControl] Object not found: " .. objectName)
		return {success = false, error = "Object not found: " .. objectName}
	end

	local targetPos = target.Position
	local startDistance = (hrp.Position - targetPos).Magnitude
	print("[AgentControl] Target found at distance: " .. math.floor(startDistance))

	-- STEP 1: Turn toward target (camera follows)
	print("[AgentControl] Turning toward target...")
	local turned = smoothTurnToward(targetPos, 5)
	if not turned then
		return {success = false, error = "Failed to turn toward " .. objectName}
	end

	task.wait(0.2) -- Brief pause after turning

	-- STEP 2: Walk to target (camera shows path ahead)
	print("[AgentControl] Walking to target...")
	local arrived = walkToPosition(targetPos, 15)

	if arrived then
		local finalDistance = (hrp.Position - targetPos).Magnitude
		print("[AgentControl] Arrived! Distance: " .. math.floor(finalDistance))
		return {success = true, distance = finalDistance}
	else
		local currentDistance = (hrp.Position - targetPos).Magnitude
		print("[AgentControl] Failed to reach. Current distance: " .. math.floor(currentDistance))
		return {success = false, error = "Could not reach " .. objectName, distance = currentDistance}
	end
end

------------------------------------------------------------
-- INTERACT_WITH: Go to object + interact
------------------------------------------------------------

local function InteractWithObject(objectName)
	print("[AgentControl] INTERACT_WITH: " .. objectName)

	-- First, go to the object
	local goResult = GoToObject(objectName)
	if not goResult.success then
		return goResult
	end

	task.wait(0.3)

	-- Find the object for interaction
	local target = nil
	for _, obj in workspace:GetDescendants() do
		if obj.Name == objectName then
			target = obj
			break
		end
	end

	if not target then
		return {success = true, interacted = false, note = "Reached but lost object"}
	end

	-- Try ProximityPrompt
	local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		print("[AgentControl] Triggering ProximityPrompt...")
		prompt:InputHoldBegin()
		task.wait(math.max(prompt.HoldDuration, 0.1) + 0.1)
		prompt:InputHoldEnd()
		return {success = true, interacted = true, method = "ProximityPrompt"}
	end

	-- Also check parent model for ProximityPrompt
	if target.Parent and target.Parent:IsA("Model") then
		prompt = target.Parent:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			print("[AgentControl] Triggering ProximityPrompt on parent model...")
			prompt:InputHoldBegin()
			task.wait(math.max(prompt.HoldDuration, 0.1) + 0.1)
			prompt:InputHoldEnd()
			return {success = true, interacted = true, method = "ProximityPrompt"}
		end
	end

	-- Try firing interact remote
	local remotes = {"InteractRemote", "Interact", "PickupRemote", "UseRemote"}
	for _, remoteName in ipairs(remotes) do
		local remote = ReplicatedStorage:FindFirstChild(remoteName)
		if remote and remote:IsA("RemoteEvent") then
			print("[AgentControl] Firing remote: " .. remoteName)
			remote:FireServer(target)
			return {success = true, interacted = true, method = "Remote:" .. remoteName}
		end
	end

	-- No interaction method, but we reached it
	print("[AgentControl] No interaction method found")
	return {success = true, interacted = false, note = "No ProximityPrompt or Remote found"}
end

------------------------------------------------------------
-- COMMAND LOOP: Check for commands from server (via attribute)
------------------------------------------------------------

task.spawn(function()
	print("[AgentControl] Command listener started")

	while true do
		task.wait(COMMAND_CHECK_INTERVAL)

		local cmd = player:GetAttribute("AgentCommand")
		if cmd and cmd ~= "" and cmd ~= currentCommand and not isExecuting then
			currentCommand = cmd
			isExecuting = true

			print("[AgentControl] Received command: " .. cmd)

			-- Parse command
			local parts = string.split(cmd, " ")
			local action = parts[1]
			local arg = parts[2] or ""

			-- Execute
			local result = {command = cmd, success = false}

			if action == "GO_TO" and arg ~= "" then
				result = GoToObject(arg)
				result.command = cmd
			elseif action == "INTERACT_WITH" and arg ~= "" then
				result = InteractWithObject(arg)
				result.command = cmd
			else
				result.error = "Unknown command or missing argument"
			end

			-- Send result to server via RemoteEvent
			local resultJson = HttpService:JSONEncode(result)
			if agentResultEvent then
				agentResultEvent:FireServer(resultJson)
			else
				warn("[AgentControl] No AgentCommandResult RemoteEvent found!")
			end

			print("[AgentControl] Result: " .. resultJson)
			currentCommand = ""  -- Reset so same command can be re-sent
			isExecuting = false
		end
	end
end)

------------------------------------------------------------
-- INIT
------------------------------------------------------------

print("[AgentControl] Initialized - Camera: first person, horizontal")
print("[AgentControl] Commands: GO_TO <name>, INTERACT_WITH <name>")
