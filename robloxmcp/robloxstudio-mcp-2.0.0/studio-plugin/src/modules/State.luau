local State = {}

State.CURRENT_VERSION = "2.0.0"

State.MAX_CONNECTIONS = 5
State.BASE_PORT = 58741
State.activeTabIndex = 1

-- Default connection settings (used as template for new connections)
local function createConnection(port)
	return {
		port = port,
		serverUrl = "http://localhost:" .. tostring(port),
		isActive = false,
		pollInterval = 0.5,
		lastPoll = 0,
		consecutiveFailures = 0,
		maxFailuresBeforeError = 50,
		lastSuccessfulConnection = 0,
		currentRetryDelay = 0.5,
		maxRetryDelay = 5,
		retryBackoffMultiplier = 1.2,
		lastHttpOk = false,
		mcpWaitStartTime = nil,
		isPolling = false,
		heartbeatConnection = nil, -- RBXScriptConnection
	}
end

-- Array of connection tables (1-indexed)
State.connections = {
	createConnection(State.BASE_PORT),
}

-- Backward-compat alias: pluginState points to the first connection
-- Modules that haven't been updated yet can still use State.pluginState
State.pluginState = State.connections[1]

function State.addConnection(port)
	if #State.connections >= State.MAX_CONNECTIONS then
		return nil
	end
	port = port or (State.connections[#State.connections].port + 1)
	local conn = createConnection(port)
	table.insert(State.connections, conn)
	return #State.connections
end

function State.removeConnection(index)
	if #State.connections <= 1 then
		return false
	end
	if index < 1 or index > #State.connections then
		return false
	end
	-- Don't remove active connections
	if State.connections[index].isActive then
		return false
	end
	table.remove(State.connections, index)
	-- Adjust active tab if needed
	if State.activeTabIndex > #State.connections then
		State.activeTabIndex = #State.connections
	elseif State.activeTabIndex > index then
		State.activeTabIndex = State.activeTabIndex - 1
	end
	return true
end

function State.getActiveConnection()
	return State.connections[State.activeTabIndex]
end

function State.getConnection(index)
	return State.connections[index]
end

return State
