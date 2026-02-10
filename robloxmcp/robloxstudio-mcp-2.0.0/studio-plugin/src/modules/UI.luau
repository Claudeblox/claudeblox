local TweenService = game:GetService("TweenService")
local State = require(script.Parent.State)

local UI = {}
UI.elements = {}

local pulseAnimation = nil
local buttonHover = false

-- Tab UI elements (indexed by connection index)
local tabButtons = {} -- { frame, label, dot, closeBtn }

local function createPulseAnimation()
	if pulseAnimation then
		pcall(function()
			pulseAnimation:Cancel()
		end)
		pulseAnimation = nil
	end

	pcall(function()
		pulseAnimation = TweenService:Create(UI.elements.statusPulse, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, -4, 0, -4),
			BackgroundTransparency = 1
		})
	end)

	return pulseAnimation
end

local function stopPulseAnimation()
	UI.elements.statusPulse.Size = UDim2.new(0, 16, 0, 16)
	UI.elements.statusPulse.Position = UDim2.new(0, 0, 0, 0)
	UI.elements.statusPulse.BackgroundTransparency = 0.7
end

local function startPulseAnimation()
	UI.elements.statusPulse.Size = UDim2.new(0, 16, 0, 16)
	UI.elements.statusPulse.Position = UDim2.new(0, 0, 0, 0)
	UI.elements.statusPulse.BackgroundTransparency = 0.7
end

UI.stopPulseAnimation = stopPulseAnimation
UI.startPulseAnimation = startPulseAnimation

-- Colors
local COLOR_GREEN = Color3.fromRGB(34, 197, 94)
local COLOR_YELLOW = Color3.fromRGB(245, 158, 11)
local COLOR_RED = Color3.fromRGB(239, 68, 68)
local COLOR_GRAY = Color3.fromRGB(156, 163, 175)
local COLOR_TAB_BG = Color3.fromRGB(31, 41, 55)
local COLOR_TAB_ACTIVE = Color3.fromRGB(59, 130, 246)
local COLOR_TAB_BAR = Color3.fromRGB(22, 30, 46)

local function getStatusDotColor(connIndex)
	local conn = State.getConnection(connIndex)
	if not conn or not conn.isActive then
		return COLOR_RED
	end
	if conn.consecutiveFailures >= conn.maxFailuresBeforeError then
		return COLOR_RED
	end
	if conn.lastHttpOk then
		return COLOR_GREEN
	end
	if conn.consecutiveFailures > 1 then
		return COLOR_YELLOW
	end
	return COLOR_YELLOW
end

-- Forward declarations
local refreshTabBar
local switchToTab

local function createTabButton(connIndex)
	local conn = State.getConnection(connIndex)
	if not conn then return end

	local isActive = (connIndex == State.activeTabIndex)

	local tabFrame = Instance.new("Frame")
	tabFrame.Size = UDim2.new(0, 80, 1, -4)
	tabFrame.Position = UDim2.new(0, 0, 0, 2)
	tabFrame.BackgroundColor3 = isActive and COLOR_TAB_ACTIVE or COLOR_TAB_BG
	tabFrame.BorderSizePixel = 0
	tabFrame.LayoutOrder = connIndex

	local tabCorner = Instance.new("UICorner")
	tabCorner.CornerRadius = UDim.new(0, 6)
	tabCorner.Parent = tabFrame

	-- Status dot
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(0, 8, 0.5, -4)
	dot.BackgroundColor3 = getStatusDotColor(connIndex)
	dot.BorderSizePixel = 0
	dot.Parent = tabFrame

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	-- Port label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -36, 1, 0)
	label.Position = UDim2.new(0, 20, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(conn.port)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 11
	label.Font = Enum.Font.Jura
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = tabFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 16, 0, 16)
	closeBtn.Position = UDim2.new(1, -20, 0.5, -8)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "x"
	closeBtn.TextColor3 = Color3.fromRGB(156, 163, 175)
	closeBtn.TextSize = 11
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = tabFrame

	-- Click tab to switch
	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, -20, 1, 0)
	clickBtn.Position = UDim2.new(0, 0, 0, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.Parent = tabFrame

	clickBtn.Activated:Connect(function()
		switchToTab(connIndex)
	end)

	closeBtn.Activated:Connect(function()
		local c = State.getConnection(connIndex)
		if c and c.isActive then
			return -- Can't close active connection
		end
		if #State.connections <= 1 then
			return -- Can't close last tab
		end
		State.removeConnection(connIndex)
		refreshTabBar()
		-- switchToTab adjusts content for the new activeTabIndex
		switchToTab(State.activeTabIndex)
	end)

	tabFrame.Parent = UI.elements.tabBar

	tabButtons[connIndex] = {
		frame = tabFrame,
		label = label,
		dot = dot,
		closeBtn = closeBtn,
	}
end

function refreshTabBar()
	-- Clear existing tab buttons
	for _, tb in pairs(tabButtons) do
		if tb.frame then
			tb.frame:Destroy()
		end
	end
	tabButtons = {}

	-- Recreate tabs
	for i = 1, #State.connections do
		createTabButton(i)
	end

	-- Update visual active state
	for i, tb in pairs(tabButtons) do
		if tb.frame then
			tb.frame.BackgroundColor3 = (i == State.activeTabIndex) and COLOR_TAB_ACTIVE or COLOR_TAB_BG
		end
	end
end

function switchToTab(index)
	if index < 1 or index > #State.connections then
		return
	end
	State.activeTabIndex = index
	local conn = State.getActiveConnection()

	-- Update tab visuals
	for i, tb in pairs(tabButtons) do
		if tb.frame then
			tb.frame.BackgroundColor3 = (i == index) and COLOR_TAB_ACTIVE or COLOR_TAB_BG
		end
	end

	-- Update content area to reflect this connection
	local el = UI.elements
	el.urlInput.Text = conn.serverUrl
	UI.updateUIState()
end

-- Called by Communication to update tab dot colors
function UI.updateTabDot(connIndex)
	local tb = tabButtons[connIndex]
	if tb and tb.dot then
		tb.dot.BackgroundColor3 = getStatusDotColor(connIndex)
	end
end

function UI.init(plugin)
	local CURRENT_VERSION = State.CURRENT_VERSION

	local screenGui = plugin:CreateDockWidgetPluginGuiAsync(
		"MCPServerInterface",
		DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 400, 500, 350, 450)
	)
	screenGui.Title = "MCP Server v" .. CURRENT_VERSION

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 8)
	mainCorner.Parent = mainFrame

	local headerFrame = Instance.new("Frame")
	headerFrame.Size = UDim2.new(1, 0, 0, 60)
	headerFrame.Position = UDim2.new(0, 0, 0, 0)
	headerFrame.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = headerFrame

	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(59, 130, 246)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(147, 51, 234))
	}
	headerGradient.Rotation = 45
	headerGradient.Parent = headerFrame

	local titleContainer = Instance.new("Frame")
	titleContainer.Size = UDim2.new(1, -70, 1, 0)
	titleContainer.Position = UDim2.new(0, 15, 0, 0)
	titleContainer.BackgroundTransparency = 1
	titleContainer.Parent = headerFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 28)
	titleLabel.Position = UDim2.new(0, 0, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "MCP Server"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = false
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.Jura
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleContainer

	local versionLabel = Instance.new("TextLabel")
	versionLabel.Size = UDim2.new(1, 0, 0, 16)
	versionLabel.Position = UDim2.new(0, 0, 0, 32)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "AI Integration \u{2022} v" .. CURRENT_VERSION
	versionLabel.TextColor3 = Color3.fromRGB(191, 219, 254)
	versionLabel.TextScaled = false
	versionLabel.TextSize = 12
	versionLabel.Font = Enum.Font.Jura
	versionLabel.TextXAlignment = Enum.TextXAlignment.Left
	versionLabel.Parent = titleContainer

	local statusContainer = Instance.new("Frame")
	statusContainer.Size = UDim2.new(0, 50, 0, 40)
	statusContainer.Position = UDim2.new(1, -60, 0, 10)
	statusContainer.BackgroundTransparency = 1
	statusContainer.Parent = headerFrame

	local statusIndicator = Instance.new("Frame")
	statusIndicator.Size = UDim2.new(0, 16, 0, 16)
	statusIndicator.Position = UDim2.new(0.5, -8, 0, 5)
	statusIndicator.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	statusIndicator.BorderSizePixel = 0
	statusIndicator.Parent = statusContainer

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(1, 0)
	statusCorner.Parent = statusIndicator

	local statusPulse = Instance.new("Frame")
	statusPulse.Size = UDim2.new(0, 16, 0, 16)
	statusPulse.Position = UDim2.new(0, 0, 0, 0)
	statusPulse.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	statusPulse.BackgroundTransparency = 0.7
	statusPulse.BorderSizePixel = 0
	statusPulse.Parent = statusIndicator

	local pulseCorner = Instance.new("UICorner")
	pulseCorner.CornerRadius = UDim.new(1, 0)
	pulseCorner.Parent = statusPulse

	local statusText = Instance.new("TextLabel")
	statusText.Size = UDim2.new(0, 50, 0, 12)
	statusText.Position = UDim2.new(0, 0, 0, 24)
	statusText.BackgroundTransparency = 1
	statusText.Text = "OFFLINE"
	statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusText.TextScaled = false
	statusText.TextSize = 8
	statusText.Font = Enum.Font.Jura
	statusText.TextXAlignment = Enum.TextXAlignment.Center
	statusText.Parent = statusContainer

	-- Tab bar (between header and content)
	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, 0, 0, 36)
	tabBar.Position = UDim2.new(0, 0, 0, 60)
	tabBar.BackgroundColor3 = COLOR_TAB_BAR
	tabBar.BorderSizePixel = 0
	tabBar.Parent = mainFrame

	local tabBarLayout = Instance.new("UIListLayout")
	tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
	tabBarLayout.Padding = UDim.new(0, 4)
	tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabBarLayout.Parent = tabBar

	local tabBarPadding = Instance.new("UIPadding")
	tabBarPadding.PaddingLeft = UDim.new(0, 6)
	tabBarPadding.PaddingRight = UDim.new(0, 6)
	tabBarPadding.Parent = tabBar

	-- "+" add tab button
	local addTabBtn = Instance.new("TextButton")
	addTabBtn.Size = UDim2.new(0, 28, 0, 28)
	addTabBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
	addTabBtn.BorderSizePixel = 0
	addTabBtn.Text = "+"
	addTabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	addTabBtn.TextSize = 16
	addTabBtn.Font = Enum.Font.GothamBold
	addTabBtn.LayoutOrder = 999
	addTabBtn.Parent = tabBar

	local addTabCorner = Instance.new("UICorner")
	addTabCorner.CornerRadius = UDim.new(0, 6)
	addTabCorner.Parent = addTabBtn

	addTabBtn.Activated:Connect(function()
		local newIndex = State.addConnection()
		if newIndex then
			refreshTabBar()
			switchToTab(newIndex)
		end
	end)

	-- Update banner (hidden by default)
	local updateBanner = Instance.new("Frame")
	updateBanner.Size = UDim2.new(1, -20, 0, 36)
	updateBanner.Position = UDim2.new(0, 10, 0, 101)
	updateBanner.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
	updateBanner.BorderSizePixel = 0
	updateBanner.Visible = false
	updateBanner.Parent = mainFrame

	local updateBannerCorner = Instance.new("UICorner")
	updateBannerCorner.CornerRadius = UDim.new(0, 6)
	updateBannerCorner.Parent = updateBanner

	local updateBannerText = Instance.new("TextLabel")
	updateBannerText.Size = UDim2.new(1, -20, 1, 0)
	updateBannerText.Position = UDim2.new(0, 10, 0, 0)
	updateBannerText.BackgroundTransparency = 1
	updateBannerText.Text = "Update available: v0.0.0"
	updateBannerText.TextColor3 = Color3.fromRGB(0, 0, 0)
	updateBannerText.TextScaled = false
	updateBannerText.TextSize = 12
	updateBannerText.Font = Enum.Font.GothamBold
	updateBannerText.TextXAlignment = Enum.TextXAlignment.Left
	updateBannerText.Parent = updateBanner

	local updateLink = Instance.new("TextButton")
	updateLink.Size = UDim2.new(0, 60, 0, 24)
	updateLink.Position = UDim2.new(1, -70, 0, 6)
	updateLink.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	updateLink.BackgroundTransparency = 0.7
	updateLink.Text = "Update"
	updateLink.TextColor3 = Color3.fromRGB(255, 255, 255)
	updateLink.TextSize = 11
	updateLink.Font = Enum.Font.GothamBold
	updateLink.Parent = updateBanner

	local updateLinkCorner = Instance.new("UICorner")
	updateLinkCorner.CornerRadius = UDim.new(0, 4)
	updateLinkCorner.Parent = updateLink

	-- Content frame (shifted down by 36px for tab bar)
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Size = UDim2.new(1, -20, 1, -116)
	contentFrame.Position = UDim2.new(0, 10, 0, 106)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 6
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(99, 102, 241)
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 243)
	contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
	contentFrame.Parent = mainFrame

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 12)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = contentFrame

	local connectionSection = Instance.new("Frame")
	connectionSection.Size = UDim2.new(1, 0, 0, 110)
	connectionSection.BackgroundColor3 = Color3.fromRGB(31, 41, 55)
	connectionSection.BorderSizePixel = 0
	connectionSection.LayoutOrder = 1
	connectionSection.Parent = contentFrame

	local connectionCorner = Instance.new("UICorner")
	connectionCorner.CornerRadius = UDim.new(0, 8)
	connectionCorner.Parent = connectionSection

	local connectionPadding = Instance.new("UIPadding")
	connectionPadding.PaddingLeft = UDim.new(0, 15)
	connectionPadding.PaddingRight = UDim.new(0, 15)
	connectionPadding.PaddingTop = UDim.new(0, 15)
	connectionPadding.PaddingBottom = UDim.new(0, 15)
	connectionPadding.Parent = connectionSection

	local connectionTitle = Instance.new("TextLabel")
	connectionTitle.Size = UDim2.new(1, 0, 0, 20)
	connectionTitle.Position = UDim2.new(0, 0, 0, 0)
	connectionTitle.BackgroundTransparency = 1
	connectionTitle.Text = "Connection Settings"
	connectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	connectionTitle.TextScaled = false
	connectionTitle.TextSize = 14
	connectionTitle.Font = Enum.Font.Jura
	connectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	connectionTitle.Parent = connectionSection

	local urlLabel = Instance.new("TextLabel")
	urlLabel.Size = UDim2.new(1, 0, 0, 16)
	urlLabel.Position = UDim2.new(0, 0, 0, 30)
	urlLabel.BackgroundTransparency = 1
	urlLabel.Text = "Server URL"
	urlLabel.TextColor3 = Color3.fromRGB(156, 163, 175)
	urlLabel.TextScaled = false
	urlLabel.TextSize = 12
	urlLabel.Font = Enum.Font.Jura
	urlLabel.TextXAlignment = Enum.TextXAlignment.Left
	urlLabel.Parent = connectionSection

	local urlInput = Instance.new("TextBox")
	urlInput.Size = UDim2.new(1, 0, 0, 32)
	urlInput.Position = UDim2.new(0, 0, 0, 50)
	urlInput.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
	urlInput.BorderSizePixel = 1
	urlInput.BorderColor3 = Color3.fromRGB(99, 102, 241)
	urlInput.Text = "http://localhost:58741"
	urlInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	urlInput.TextScaled = false
	urlInput.TextSize = 12
	urlInput.Font = Enum.Font.Jura
	urlInput.ClearTextOnFocus = false
	urlInput.PlaceholderText = "Enter server URL..."
	urlInput.PlaceholderColor3 = Color3.fromRGB(107, 114, 128)
	urlInput.Parent = connectionSection

	local urlCorner = Instance.new("UICorner")
	urlCorner.CornerRadius = UDim.new(0, 6)
	urlCorner.Parent = urlInput

	local urlPadding = Instance.new("UIPadding")
	urlPadding.PaddingLeft = UDim.new(0, 12)
	urlPadding.PaddingRight = UDim.new(0, 12)
	urlPadding.Parent = urlInput

	local statusSection = Instance.new("Frame")
	statusSection.Size = UDim2.new(1, 0, 0, 170)
	statusSection.BackgroundColor3 = Color3.fromRGB(31, 41, 55)
	statusSection.BorderSizePixel = 0
	statusSection.LayoutOrder = 2
	statusSection.Parent = contentFrame

	local statusSectionCorner = Instance.new("UICorner")
	statusSectionCorner.CornerRadius = UDim.new(0, 8)
	statusSectionCorner.Parent = statusSection

	local statusSectionPadding = Instance.new("UIPadding")
	statusSectionPadding.PaddingLeft = UDim.new(0, 15)
	statusSectionPadding.PaddingRight = UDim.new(0, 15)
	statusSectionPadding.PaddingTop = UDim.new(0, 15)
	statusSectionPadding.PaddingBottom = UDim.new(0, 15)
	statusSectionPadding.Parent = statusSection

	local statusTitle = Instance.new("TextLabel")
	statusTitle.Size = UDim2.new(1, 0, 0, 20)
	statusTitle.Position = UDim2.new(0, 0, 0, 0)
	statusTitle.BackgroundTransparency = 1
	statusTitle.Text = "Connection Status"
	statusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusTitle.TextScaled = false
	statusTitle.TextSize = 14
	statusTitle.Font = Enum.Font.Jura
	statusTitle.TextXAlignment = Enum.TextXAlignment.Left
	statusTitle.Parent = statusSection

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 20)
	statusLabel.Position = UDim2.new(0, 0, 0, 30)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Disconnected"
	statusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
	statusLabel.TextScaled = false
	statusLabel.TextSize = 13
	statusLabel.Font = Enum.Font.Jura
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Parent = statusSection

	local detailStatusLabel = Instance.new("TextLabel")
	detailStatusLabel.Size = UDim2.new(1, 0, 0, 12)
	detailStatusLabel.Position = UDim2.new(0, 0, 0, 50)
	detailStatusLabel.BackgroundTransparency = 1
	detailStatusLabel.Text = "HTTP: X  MCP: X"
	detailStatusLabel.TextColor3 = Color3.fromRGB(156, 163, 175)
	detailStatusLabel.TextScaled = false
	detailStatusLabel.TextSize = 10
	detailStatusLabel.Font = Enum.Font.Jura
	detailStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailStatusLabel.TextWrapped = true
	detailStatusLabel.Parent = statusSection

	-- Step-by-step status rows
	local stepsFrame = Instance.new("Frame")
	stepsFrame.Size = UDim2.new(1, 0, 0, 60)
	stepsFrame.Position = UDim2.new(0, 0, 0, 68)
	stepsFrame.BackgroundTransparency = 1
	stepsFrame.Parent = statusSection

	local stepsLayout = Instance.new("UIListLayout")
	stepsLayout.Padding = UDim.new(0, 6)
	stepsLayout.FillDirection = Enum.FillDirection.Vertical
	stepsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	stepsLayout.Parent = stepsFrame

	local function createStepRow(text)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 16)
		row.BackgroundTransparency = 1

		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 10, 0, 10)
		dot.Position = UDim2.new(0, 0, 0, 3)
		dot.BackgroundColor3 = Color3.fromRGB(156, 163, 175)
		dot.BorderSizePixel = 0
		dot.Parent = row

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dot

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -18, 1, 0)
		label.Position = UDim2.new(0, 18, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(209, 213, 219)
		label.TextScaled = false
		label.TextSize = 11
		label.Font = Enum.Font.Jura
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		row.Parent = stepsFrame
		return row, dot, label
	end

	local _, step1Dot, step1Label = createStepRow("1. HTTP server reachable")
	local _, step2Dot, step2Label = createStepRow("2. MCP bridge connected")
	local _, step3Dot, step3Label = createStepRow("3. Ready for commands")

	local troubleshootLabel = Instance.new("TextLabel")
	troubleshootLabel.Size = UDim2.new(1, 0, 0, 40)
	troubleshootLabel.Position = UDim2.new(0, 0, 0, 130)
	troubleshootLabel.BackgroundTransparency = 1
	troubleshootLabel.TextWrapped = true
	troubleshootLabel.Visible = false
	troubleshootLabel.Text = "HTTP is OK but MCP isn't responding. Close all node.exe in Task Manager and restart the server."
	troubleshootLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
	troubleshootLabel.TextScaled = false
	troubleshootLabel.TextSize = 11
	troubleshootLabel.Font = Enum.Font.Jura
	troubleshootLabel.TextXAlignment = Enum.TextXAlignment.Left
	troubleshootLabel.Parent = statusSection

	local connectButton = Instance.new("TextButton")
	connectButton.Size = UDim2.new(1, 0, 0, 48)
	connectButton.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
	connectButton.BorderSizePixel = 0
	connectButton.Text = "Connect"
	connectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	connectButton.TextScaled = false
	connectButton.TextSize = 16
	connectButton.Font = Enum.Font.Jura
	connectButton.LayoutOrder = 3
	connectButton.Parent = contentFrame

	local connectCorner = Instance.new("UICorner")
	connectCorner.CornerRadius = UDim.new(0, 12)
	connectCorner.Parent = connectButton

	connectButton.MouseEnter:Connect(function()
		buttonHover = true
		local conn = State.getActiveConnection()
		connectButton.BackgroundColor3 = (conn and conn.isActive) and Color3.fromRGB(220, 38, 38) or Color3.fromRGB(5, 150, 105)
	end)

	connectButton.MouseLeave:Connect(function()
		buttonHover = false
		local conn = State.getActiveConnection()
		connectButton.BackgroundColor3 = (conn and conn.isActive) and Color3.fromRGB(239, 68, 68) or Color3.fromRGB(16, 185, 129)
	end)

	updateLink.Activated:Connect(function()
		local url = "https://github.com/boshyxd/robloxstudio-mcp/releases"
		if setclipboard then
			pcall(function() setclipboard(url) end)
		end
		updateBannerText.Text = "Link copied! Visit GitHub releases"
		task.delay(3, function()
			if updateBanner.Visible then
				updateBannerText.Text = "Update available - check GitHub releases"
			end
		end)
	end)

	-- Store references
	UI.elements = {
		screenGui = screenGui,
		mainFrame = mainFrame,
		contentFrame = contentFrame,
		statusLabel = statusLabel,
		detailStatusLabel = detailStatusLabel,
		statusIndicator = statusIndicator,
		statusPulse = statusPulse,
		statusText = statusText,
		connectButton = connectButton,
		urlInput = urlInput,
		step1Dot = step1Dot,
		step1Label = step1Label,
		step2Dot = step2Dot,
		step2Label = step2Label,
		step3Dot = step3Dot,
		step3Label = step3Label,
		troubleshootLabel = troubleshootLabel,
		updateBanner = updateBanner,
		updateBannerText = updateBannerText,
		tabBar = tabBar,
	}

	-- Build initial tab(s)
	refreshTabBar()
end

function UI.updateUIState()
	local conn = State.getActiveConnection()
	if not conn then return end
	local el = UI.elements

	if conn.isActive then
		el.statusLabel.Text = "Connecting..."
		el.statusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
		el.statusIndicator.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		el.statusPulse.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		el.statusText.Text = "CONNECTING"
		if conn.consecutiveFailures == 0 then
			el.detailStatusLabel.Text = "HTTP: ...  MCP: ..."
		else
			el.detailStatusLabel.Text = "HTTP: X  MCP: X"
		end
		el.detailStatusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
		el.connectButton.Text = "Disconnect"
		el.connectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		startPulseAnimation()

		el.step1Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		el.step1Label.Text = "1. HTTP server reachable (connecting...)"
		el.step2Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		el.step2Label.Text = "2. MCP bridge connected (connecting...)"
		el.step3Dot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		el.step3Label.Text = "3. Ready for commands (connecting...)"
		conn.mcpWaitStartTime = nil
		el.troubleshootLabel.Visible = false

		if not buttonHover then
			el.connectButton.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		end

		el.urlInput.TextEditable = false
		el.urlInput.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
		el.urlInput.BorderColor3 = Color3.fromRGB(75, 85, 99)
	else
		el.statusLabel.Text = "Disconnected"
		el.statusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
		el.statusIndicator.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		el.statusPulse.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		el.statusText.Text = "OFFLINE"
		el.detailStatusLabel.Text = "HTTP: X  MCP: X"
		el.detailStatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
		el.connectButton.Text = "Connect"
		el.connectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		stopPulseAnimation()

		el.step1Dot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		el.step1Label.Text = "1. HTTP server reachable (offline)"
		el.step2Dot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		el.step2Label.Text = "2. MCP bridge connected (offline)"
		el.step3Dot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
		el.step3Label.Text = "3. Ready for commands (offline)"
		conn.mcpWaitStartTime = nil
		el.troubleshootLabel.Visible = false

		if not buttonHover then
			el.connectButton.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
		end

		el.urlInput.TextEditable = true
		el.urlInput.BackgroundColor3 = Color3.fromRGB(55, 65, 81)
		el.urlInput.BorderColor3 = Color3.fromRGB(99, 102, 241)
	end
end

return UI
