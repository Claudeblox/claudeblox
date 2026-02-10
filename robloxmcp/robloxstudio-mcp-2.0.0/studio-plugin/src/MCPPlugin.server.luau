--!strict
--[[
	MCPPlugin - Roblox Studio MCP Integration
	Orchestrator: wires modules together and binds plugin events.
]]

local State = require(script.modules.State)
local UI = require(script.modules.UI)
local Communication = require(script.modules.Communication)

-- Initialize UI (pass plugin global - only available in server scripts)
UI.init(plugin)

-- Create toolbar button
local toolbar = plugin:CreateToolbar("MCP Integration")
local button =
	toolbar:CreateButton("MCP Server", "Connect to MCP Server for AI Integration", "rbxassetid://10734944444")

-- Connect/Disconnect button (operates on the active tab's connection)
UI.elements.connectButton.Activated:Connect(function()
	local conn = State.getActiveConnection()
	if conn and conn.isActive then
		Communication.deactivatePlugin(State.activeTabIndex)
	else
		Communication.activatePlugin(State.activeTabIndex)
	end
end)

-- Toolbar toggle
button.Click:Connect(function()
	UI.elements.screenGui.Enabled = not UI.elements.screenGui.Enabled
end)

-- Cleanup on unload: disconnect ALL connections
plugin.Unloading:Connect(function()
	Communication.deactivateAll()
end)

-- Initial state + update check
UI.updateUIState()
Communication.checkForUpdates()
