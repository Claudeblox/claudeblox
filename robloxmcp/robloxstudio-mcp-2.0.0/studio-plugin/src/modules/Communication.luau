local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local State = require(script.Parent.State)
local Utils = require(script.Parent.Utils)
local UI = require(script.Parent.UI)
local QueryHandlers = require(script.Parent.QueryHandlers)
local PropertyHandlers = require(script.Parent.PropertyHandlers)
local InstanceHandlers = require(script.Parent.InstanceHandlers)
local ScriptHandlers = require(script.Parent.ScriptHandlers)
local MetadataHandlers = require(script.Parent.MetadataHandlers)

local Communication = {}

-- Route map: endpoint -> handler function
local routeMap = {
	-- Query handlers
	["/api/file-tree"] = QueryHandlers.getFileTree,
	["/api/search-files"] = QueryHandlers.searchFiles,
	["/api/place-info"] = QueryHandlers.getPlaceInfo,
	["/api/services"] = QueryHandlers.getServices,
	["/api/search-objects"] = QueryHandlers.searchObjects,
	["/api/instance-properties"] = QueryHandlers.getInstanceProperties,
	["/api/instance-children"] = QueryHandlers.getInstanceChildren,
	["/api/search-by-property"] = QueryHandlers.searchByProperty,
	["/api/class-info"] = QueryHandlers.getClassInfo,
	["/api/project-structure"] = QueryHandlers.getProjectStructure,
	-- Property handlers
	["/api/set-property"] = PropertyHandlers.setProperty,
	["/api/mass-set-property"] = PropertyHandlers.massSetProperty,
	["/api/mass-get-property"] = PropertyHandlers.massGetProperty,
	["/api/set-calculated-property"] = PropertyHandlers.setCalculatedProperty,
	["/api/set-relative-property"] = PropertyHandlers.setRelativeProperty,
	-- Instance handlers
	["/api/create-object"] = InstanceHandlers.createObject,
	["/api/mass-create-objects"] = InstanceHandlers.massCreateObjects,
	["/api/mass-create-objects-with-properties"] = InstanceHandlers.massCreateObjectsWithProperties,
	["/api/delete-object"] = InstanceHandlers.deleteObject,
	["/api/smart-duplicate"] = InstanceHandlers.smartDuplicate,
	["/api/mass-duplicate"] = InstanceHandlers.massDuplicate,
	-- Script handlers
	["/api/get-script-source"] = ScriptHandlers.getScriptSource,
	["/api/set-script-source"] = ScriptHandlers.setScriptSource,
	["/api/edit-script-lines"] = ScriptHandlers.editScriptLines,
	["/api/insert-script-lines"] = ScriptHandlers.insertScriptLines,
	["/api/delete-script-lines"] = ScriptHandlers.deleteScriptLines,
	-- Metadata handlers
	["/api/get-attribute"] = MetadataHandlers.getAttribute,
	["/api/set-attribute"] = MetadataHandlers.setAttribute,
	["/api/get-attributes"] = MetadataHandlers.getAttributes,
	["/api/delete-attribute"] = MetadataHandlers.deleteAttribute,
	["/api/get-tags"] = MetadataHandlers.getTags,
	["/api/add-tag"] = MetadataHandlers.addTag,
	["/api/remove-tag"] = MetadataHandlers.removeTag,
	["/api/get-tagged"] = MetadataHandlers.getTagged,
	["/api/get-selection"] = MetadataHandlers.getSelection,
	["/api/execute-luau"] = MetadataHandlers.executeLuau,
}

local function processRequest(request)
	local endpoint = request.endpoint
	local data = request.data or {}

	local handler = routeMap[endpoint]
	if handler then
		return handler(data)
	else
		return { error = "Unknown endpoint: " .. tostring(endpoint) }
	end
end

local function sendResponse(conn, requestId, responseData)
	pcall(function()
		HttpService:RequestAsync({
			Url = conn.serverUrl .. "/response",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				requestId = requestId,
				response = responseData,
			}),
		})
	end)
end

-- Get the status color for a connection (used by tab dots)
function Communication.getConnectionStatus(connIndex)
	local conn = State.getConnection(connIndex)
	if not conn then
		return "disconnected"
	end
	if not conn.isActive then
		return "disconnected"
	end
	if conn.consecutiveFailures >= conn.maxFailuresBeforeError then
		return "error"
	end
	if conn.lastHttpOk then
		return "connected"
	end
	return "connecting"
end

local function pollForRequests(connIndex)
	local conn = State.getConnection(connIndex)
	if not conn or not conn.isActive then
		return
	end

	if conn.isPolling then
		return
	end

	conn.isPolling = true

	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = conn.serverUrl .. "/poll",
			Method = "GET",
			Headers = {
				["Content-Type"] = "application/json",
			},
		})
	end)

	conn.isPolling = false

	-- Update tab dot for this connection regardless of which tab is active
	UI.updateTabDot(connIndex)

	if success and (result.Success or result.StatusCode == 503) then
		conn.consecutiveFailures = 0
		conn.currentRetryDelay = 0.5
		conn.lastSuccessfulConnection = tick()

		local data = HttpService:JSONDecode(result.Body)
		local mcpConnected = data.mcpConnected == true
		conn.lastHttpOk = true

		-- Only update detailed status UI if this is the active tab
		if connIndex == State.activeTabIndex then
			local el = UI.elements
			el.step1Dot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
			el.step1Label.Text = "1. HTTP server reachable (OK)"

			if mcpConnected and not el.statusLabel.Text:find("Connected") then
				el.statusLabel.Text = "Connected"
				el.statusLabel.TextColor3 = Color3.fromRGB(34, 197, 94)
				el.statusIndicator.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
				el.statusPulse.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
				el.statusText.Text = "ONLINE"
				el.detailStatusLabel.Text = "HTTP: OK  MCP: OK"
				el.detailStatusLabel.TextColor3 = Color3.fromRGB(34, 197, 94)
				el.step2Dot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
				el.step2Label.Text = "2. MCP bridge connected (OK)"
				el.step3Dot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
				el.step3Label.Text = "3. Ready for commands (OK)"
				conn.mcpWaitStartTime = nil
				el.troubleshootLabel.Visible = false
				UI.stopPulseAnimation()
			elseif not mcpConnected then
				el.statusLabel.Text = "Waiting for MCP server"
				el.statusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
				el.statusIndicator.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.statusPulse.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.statusText.Text = "WAITING"
				el.detailStatusLabel.Text = "HTTP: OK  MCP: ..."
				el.detailStatusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
				el.step2Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.step2Label.Text = "2. MCP bridge connected (waiting...)"
				el.step3Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.step3Label.Text = "3. Ready for commands (waiting...)"
				if not conn.mcpWaitStartTime then
					conn.mcpWaitStartTime = tick()
				end
				local elapsed = tick() - (conn.mcpWaitStartTime or tick())
				el.troubleshootLabel.Visible = elapsed > 8
				UI.startPulseAnimation()
			end
		end

		if data.request and mcpConnected then
			task.spawn(function()
				local response = processRequest(data.request)
				sendResponse(conn, data.requestId, response)
			end)
		end
	elseif conn.isActive then
		conn.consecutiveFailures = conn.consecutiveFailures + 1

		if conn.consecutiveFailures > 1 then
			conn.currentRetryDelay =
				math.min(conn.currentRetryDelay * conn.retryBackoffMultiplier, conn.maxRetryDelay)
		end

		-- Only update detailed status UI if this is the active tab
		if connIndex == State.activeTabIndex then
			local el = UI.elements
			if conn.consecutiveFailures >= conn.maxFailuresBeforeError then
				el.statusLabel.Text = "Server unavailable"
				el.statusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
				el.statusIndicator.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
				el.statusPulse.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
				el.statusText.Text = "ERROR"
				el.detailStatusLabel.Text = "HTTP: X  MCP: X"
				el.detailStatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
				el.step1Dot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
				el.step1Label.Text = "1. HTTP server reachable (error)"
				el.step2Dot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
				el.step2Label.Text = "2. MCP bridge connected (error)"
				el.step3Dot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
				el.step3Label.Text = "3. Ready for commands (error)"
				conn.mcpWaitStartTime = nil
				el.troubleshootLabel.Visible = false
				UI.stopPulseAnimation()
			elseif conn.consecutiveFailures > 5 then
				local waitTime = math.ceil(conn.currentRetryDelay)
				el.statusLabel.Text = "Retrying (" .. waitTime .. "s)"
				el.statusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
				el.statusIndicator.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.statusPulse.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.statusText.Text = "RETRY"
				el.detailStatusLabel.Text = "HTTP: ...  MCP: ..."
				el.detailStatusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
				el.step1Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.step1Label.Text = "1. HTTP server reachable (retrying...)"
				el.step2Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.step2Label.Text = "2. MCP bridge connected (retrying...)"
				el.step3Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.step3Label.Text = "3. Ready for commands (retrying...)"
				conn.mcpWaitStartTime = nil
				el.troubleshootLabel.Visible = false
				UI.startPulseAnimation()
			elseif conn.consecutiveFailures > 1 then
				el.statusLabel.Text = "Connecting (attempt " .. conn.consecutiveFailures .. ")"
				el.statusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
				el.statusIndicator.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.statusPulse.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.statusText.Text = "CONNECTING"
				el.detailStatusLabel.Text = "HTTP: ...  MCP: ..."
				el.detailStatusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
				el.step1Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.step1Label.Text = "1. HTTP server reachable (connecting...)"
				el.step2Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.step2Label.Text = "2. MCP bridge connected (connecting...)"
				el.step3Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
				el.step3Label.Text = "3. Ready for commands (connecting...)"
				conn.mcpWaitStartTime = nil
				el.troubleshootLabel.Visible = false
				UI.startPulseAnimation()
			end
		end
	end
end

function Communication.activatePlugin(connIndex)
	connIndex = connIndex or State.activeTabIndex
	local conn = State.getConnection(connIndex)
	if not conn then
		return
	end

	-- Read URL from the input box if this is the active tab
	if connIndex == State.activeTabIndex then
		conn.serverUrl = UI.elements.urlInput.Text
		-- Update port from URL
		local portStr = conn.serverUrl:match(":(%d+)$")
		if portStr then
			conn.port = tonumber(portStr)
		end
	end

	conn.isActive = true
	conn.consecutiveFailures = 0
	conn.currentRetryDelay = 0.5
	UI.elements.screenGui.Enabled = true

	if connIndex == State.activeTabIndex then
		UI.updateUIState()
	end

	UI.updateTabDot(connIndex)

	pcall(function()
		HttpService:RequestAsync({
			Url = conn.serverUrl .. "/ready",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				pluginReady = true,
				timestamp = tick(),
			}),
		})
	end)

	if not conn.heartbeatConnection then
		conn.heartbeatConnection = RunService.Heartbeat:Connect(function()
			local now = tick()
			local currentInterval = conn.consecutiveFailures > 5 and conn.currentRetryDelay
				or conn.pollInterval
			if now - conn.lastPoll > currentInterval then
				conn.lastPoll = now
				pollForRequests(connIndex)
			end
		end)
	end
end

function Communication.deactivatePlugin(connIndex)
	connIndex = connIndex or State.activeTabIndex
	local conn = State.getConnection(connIndex)
	if not conn then
		return
	end

	conn.isActive = false

	if connIndex == State.activeTabIndex then
		UI.updateUIState()
	end

	UI.updateTabDot(connIndex)

	pcall(function()
		HttpService:RequestAsync({
			Url = conn.serverUrl .. "/disconnect",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				timestamp = tick(),
			}),
		})
	end)

	if conn.heartbeatConnection then
		conn.heartbeatConnection:Disconnect()
		conn.heartbeatConnection = nil
	end

	conn.consecutiveFailures = 0
	conn.currentRetryDelay = 0.5
end

function Communication.deactivateAll()
	for i = 1, #State.connections do
		if State.connections[i].isActive then
			Communication.deactivatePlugin(i)
		end
	end
end

function Communication.checkForUpdates()
	task.spawn(function()
		local success, result = pcall(function()
			local response = HttpService:RequestAsync({
				Url = "https://registry.npmjs.org/robloxstudio-mcp/latest",
				Method = "GET",
				Headers = {
					["Accept"] = "application/json",
				},
			})
			return response
		end)

		if success and result.Success then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(result.Body)
			end)

			if ok and data and data.version then
				local latestVersion = data.version
				if Utils.compareVersions(State.CURRENT_VERSION, latestVersion) < 0 then
					UI.elements.updateBannerText.Text = "Update available: v" .. latestVersion
					UI.elements.updateBanner.Visible = true
					UI.elements.contentFrame.Position = UDim2.new(0, 10, 0, 146)
					UI.elements.contentFrame.Size = UDim2.new(1, -20, 1, -156)
				end
			end
		end
	end)
end

return Communication
