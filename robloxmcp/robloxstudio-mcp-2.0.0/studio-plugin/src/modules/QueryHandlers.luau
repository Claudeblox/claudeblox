local Utils = require(script.Parent.Utils)
local safeCall = Utils.safeCall
local getInstancePath = Utils.getInstancePath
local getInstanceByPath = Utils.getInstanceByPath
local readScriptSource = Utils.readScriptSource

local QueryHandlers = {}

QueryHandlers.getFileTree = function(requestData)
	local path = requestData.path or ""
	local startInstance = getInstanceByPath(path)

	if not startInstance then
		return { error = "Path not found: " .. path }
	end

	local function buildTree(instance, depth)
		if depth > 10 then
			return { name = instance.Name, className = instance.ClassName, children = {} }
		end

		local node = {
			name = instance.Name,
			className = instance.ClassName,
			path = getInstancePath(instance),
			children = {},
		}

		if instance:IsA("LuaSourceContainer") then
			node.hasSource = true
			node.scriptType = instance.ClassName
		end

		for _, child in ipairs(instance:GetChildren()) do
			table.insert(node.children, buildTree(child, depth + 1))
		end

		return node
	end

	return {
		tree = buildTree(startInstance, 0),
		timestamp = tick(),
	}
end

QueryHandlers.searchFiles = function(requestData)
	local query = requestData.query
	local searchType = requestData.searchType or "name"

	if not query then
		return { error = "Query is required" }
	end

	local results = {}

	local function searchRecursive(instance)
		local match = false

		if searchType == "name" then
			match = instance.Name:lower():find(query:lower()) ~= nil
		elseif searchType == "type" then
			match = instance.ClassName:lower():find(query:lower()) ~= nil
		elseif searchType == "content" and instance:IsA("LuaSourceContainer") then
			match = readScriptSource(instance):lower():find(query:lower()) ~= nil
		end

		if match then
			table.insert(results, {
				name = instance.Name,
				className = instance.ClassName,
				path = getInstancePath(instance),
				hasSource = instance:IsA("LuaSourceContainer"),
			})
		end

		for _, child in ipairs(instance:GetChildren()) do
			searchRecursive(child)
		end
	end

	searchRecursive(game)

	return {
		results = results,
		query = query,
		searchType = searchType,
		count = #results,
	}
end

QueryHandlers.getPlaceInfo = function(requestData)
	return {
		placeName = game.Name,
		placeId = game.PlaceId,
		gameId = game.GameId,
		jobId = game.JobId,
		workspace = {
			name = workspace.Name,
			className = workspace.ClassName,
		},
	}
end

QueryHandlers.getServices = function(requestData)
	local serviceName = requestData.serviceName

	if serviceName then
		local service = safeCall(game.GetService, game, serviceName)
		if service then
			return {
				service = {
					name = service.Name,
					className = service.ClassName,
					path = getInstancePath(service),
					childCount = #service:GetChildren(),
				},
			}
		else
			return { error = "Service not found: " .. serviceName }
		end
	else
		local services = {}
		local commonServices = {
			"Workspace",
			"Players",
			"StarterGui",
			"StarterPack",
			"StarterPlayer",
			"ReplicatedStorage",
			"ServerStorage",
			"ServerScriptService",
			"HttpService",
			"TeleportService",
			"DataStoreService",
		}

		for _, svcName in ipairs(commonServices) do
			local service = safeCall(game.GetService, game, svcName)
			if service then
				table.insert(services, {
					name = service.Name,
					className = service.ClassName,
					path = getInstancePath(service),
					childCount = #service:GetChildren(),
				})
			end
		end

		return { services = services }
	end
end

QueryHandlers.searchObjects = function(requestData)
	local query = requestData.query
	local searchType = requestData.searchType or "name"
	local propertyName = requestData.propertyName

	if not query then
		return { error = "Query is required" }
	end

	local results = {}

	local function searchRecursive(instance)
		local match = false

		if searchType == "name" then
			match = instance.Name:lower():find(query:lower()) ~= nil
		elseif searchType == "class" then
			match = instance.ClassName:lower():find(query:lower()) ~= nil
		elseif searchType == "property" and propertyName then
			local success, value = pcall(function()
				return tostring(instance[propertyName])
			end)
			if success then
				match = value:lower():find(query:lower()) ~= nil
			end
		end

		if match then
			table.insert(results, {
				name = instance.Name,
				className = instance.ClassName,
				path = getInstancePath(instance),
			})
		end

		for _, child in ipairs(instance:GetChildren()) do
			searchRecursive(child)
		end
	end

	searchRecursive(game)

	return {
		results = results,
		query = query,
		searchType = searchType,
		count = #results,
	}
end

QueryHandlers.getInstanceProperties = function(requestData)
	local instancePath = requestData.instancePath
	if not instancePath then
		return { error = "Instance path is required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local properties = {}
	local success, result = pcall(function()
		local basicProps = { "Name", "ClassName", "Parent" }
		for _, prop in ipairs(basicProps) do
			local propSuccess, propValue = pcall(function()
				local val = instance[prop]
				if prop == "Parent" and val then
					return getInstancePath(val)
				elseif val == nil then
					return "nil"
				else
					return tostring(val)
				end
			end)
			if propSuccess then
				properties[prop] = propValue
			end
		end

		local commonProps = {
			"Size",
			"Position",
			"Rotation",
			"CFrame",
			"Anchored",
			"CanCollide",
			"Transparency",
			"BrickColor",
			"Material",
			"Color",
			"Text",
			"TextColor3",
			"BackgroundColor3",
			"Image",
			"ImageColor3",
			"Visible",
			"Active",
			"ZIndex",
			"BorderSizePixel",
			"BackgroundTransparency",
			"ImageTransparency",
			"TextTransparency",
			"Value",
			"Enabled",
			"Brightness",
			"Range",
			"Shadows",
			"Face",
			"SurfaceType",
		}

		for _, prop in ipairs(commonProps) do
			local propSuccess, propValue = pcall(function()
				local val = instance[prop]
				if typeof(val) == "UDim2" then
					return { X = { Scale = val.X.Scale, Offset = val.X.Offset }, Y = { Scale = val.Y.Scale, Offset = val.Y.Offset }, _type = "UDim2" }
				end
				return tostring(val)
			end)
			if propSuccess then
				properties[prop] = propValue
			end
		end

		if instance:IsA("LuaSourceContainer") then
			properties.Source = readScriptSource(instance)
			if instance:IsA("BaseScript") then
				properties.Enabled = tostring(instance.Enabled)
			end
		end

		-- Only Parts have a Shape property; MeshParts do not.
		if instance:IsA("Part") then
			properties.Shape = tostring(instance.Shape)
		end

		-- TopSurface and BottomSurface exist on all BaseParts
		if instance:IsA("BasePart") then
			properties.TopSurface = tostring(instance.TopSurface)
			properties.BottomSurface = tostring(instance.BottomSurface)
		end

		-- Asset IDs for Meshes, Sounds, Animations, etc.
		if instance:IsA("MeshPart") then
			properties.MeshId = tostring(instance.MeshId)
			properties.TextureID = tostring(instance.TextureID)
		end

		if instance:IsA("SpecialMesh") then
			properties.MeshId = tostring(instance.MeshId)
			properties.TextureId = tostring(instance.TextureId)
			properties.MeshType = tostring(instance.MeshType)
		end

		if instance:IsA("Sound") then
			properties.SoundId = tostring(instance.SoundId)
			properties.TimeLength = tostring(instance.TimeLength)
			properties.IsPlaying = tostring(instance.IsPlaying)
		end

		if instance:IsA("Animation") then
			properties.AnimationId = tostring(instance.AnimationId)
		end

		if instance:IsA("Decal") or instance:IsA("Texture") then
			properties.Texture = tostring(instance.Texture)
		end

		if instance:IsA("Shirt") or instance:IsA("Pants") or instance:IsA("ShirtGraphic") then
			if instance:IsA("ShirtGraphic") then
				properties.Graphic = tostring(instance.Graphic)
			elseif instance:IsA("Shirt") then
				properties.ShirtTemplate = tostring(instance.ShirtTemplate)
			else
				properties.PantsTemplate = tostring(instance.PantsTemplate)
			end
		end

		properties.ChildCount = tostring(#instance:GetChildren())

		return properties
	end)

	if success then
		return {
			instancePath = instancePath,
			className = instance.ClassName,
			properties = properties,
		}
	else
		return { error = "Failed to get properties: " .. tostring(result) }
	end
end

QueryHandlers.getInstanceChildren = function(requestData)
	local instancePath = requestData.instancePath
	if not instancePath then
		return { error = "Instance path is required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local children = {}
	for _, child in ipairs(instance:GetChildren()) do
		table.insert(children, {
			name = child.Name,
			className = child.ClassName,
			path = getInstancePath(child),
			hasChildren = #child:GetChildren() > 0,
			hasSource = child:IsA("LuaSourceContainer"),
		})
	end

	return {
		instancePath = instancePath,
		children = children,
		count = #children,
	}
end

QueryHandlers.searchByProperty = function(requestData)
	local propertyName = requestData.propertyName
	local propertyValue = requestData.propertyValue

	if not propertyName or not propertyValue then
		return { error = "Property name and value are required" }
	end

	local results = {}

	local function searchRecursive(instance)
		local success, value = pcall(function()
			return tostring(instance[propertyName])
		end)

		if success and value:lower():find(propertyValue:lower()) then
			table.insert(results, {
				name = instance.Name,
				className = instance.ClassName,
				path = getInstancePath(instance),
				propertyValue = value,
			})
		end

		for _, child in ipairs(instance:GetChildren()) do
			searchRecursive(child)
		end
	end

	searchRecursive(game)

	return {
		propertyName = propertyName,
		propertyValue = propertyValue,
		results = results,
		count = #results,
	}
end

QueryHandlers.getClassInfo = function(requestData)
	local className = requestData.className
	if not className then
		return { error = "Class name is required" }
	end

	local success, tempInstance = pcall(function()
		return Instance.new(className)
	end)

	-- If Instance.new fails, try game:GetService for services (e.g. MarketplaceService)
	local isService = false
	if not success then
		local serviceSuccess, serviceInstance = pcall(function()
			return game:GetService(className)
		end)
		if serviceSuccess and serviceInstance then
			success = true
			tempInstance = serviceInstance
			isService = true
		end
	end

	if not success then
		return { error = "Invalid class name: " .. className }
	end

	local classInfo = {
		className = className,
		isService = isService,
		properties = {},
		methods = {},
		events = {},
	}

	local commonProps = {
		"Name",
		"ClassName",
		"Parent",
		"Size",
		"Position",
		"Rotation",
		"CFrame",
		"Anchored",
		"CanCollide",
		"Transparency",
		"BrickColor",
		"Material",
		"Color",
		"Text",
		"TextColor3",
		"BackgroundColor3",
		"Image",
		"ImageColor3",
		"Visible",
		"Active",
		"ZIndex",
		"BorderSizePixel",
		"BackgroundTransparency",
		"ImageTransparency",
		"TextTransparency",
		"Value",
		"Enabled",
		"Brightness",
		"Range",
		"Shadows",
	}

	for _, prop in ipairs(commonProps) do
		local propSuccess, _ = pcall(function()
			return tempInstance[prop]
		end)
		if propSuccess then
			table.insert(classInfo.properties, prop)
		end
	end

	local commonMethods = {
		"Destroy",
		"Clone",
		"FindFirstChild",
		"FindFirstChildOfClass",
		"GetChildren",
		"IsA",
		"IsAncestorOf",
		"IsDescendantOf",
		"WaitForChild",
	}

	for _, method in ipairs(commonMethods) do
		local methodSuccess, _ = pcall(function()
			return tempInstance[method]
		end)
		if methodSuccess then
			table.insert(classInfo.methods, method)
		end
	end

	if not isService then
		tempInstance:Destroy()
	end

	return classInfo
end

QueryHandlers.getProjectStructure = function(requestData)
	local startPath = requestData.path or ""
	local maxDepth = requestData.maxDepth or 3
	local showScriptsOnly = requestData.scriptsOnly or false

	local startInstance
	if startPath == "" or startPath == "game" then
		local services = {}
		local mainServices = {
			"Workspace",
			"ServerScriptService",
			"ServerStorage",
			"ReplicatedStorage",
			"StarterGui",
			"StarterPack",
			"StarterPlayer",
			"Players",
		}

		for _, serviceName in ipairs(mainServices) do
			local service = safeCall(game.GetService, game, serviceName)
			if service then
				local serviceInfo = {
					name = service.Name,
					className = service.ClassName,
					path = getInstancePath(service),
					childCount = #service:GetChildren(),
					hasChildren = #service:GetChildren() > 0,
				}
				table.insert(services, serviceInfo)
			end
		end

		return {
			type = "service_overview",
			services = services,
			timestamp = tick(),
			note = "Use path parameter to explore specific locations (e.g., 'game.ServerScriptService')",
		}
	else
		startInstance = getInstanceByPath(startPath)
		if not startInstance then
			return { error = "Path not found: " .. startPath }
		end
	end

	local function getStructure(instance, depth, currentPath)
		if depth > maxDepth then
			return {
				name = instance.Name,
				className = instance.ClassName,
				path = getInstancePath(instance),
				childCount = #instance:GetChildren(),
				hasMore = true,
				note = "Max depth reached - use this path to explore further",
			}
		end

		local node = {
			name = instance.Name,
			className = instance.ClassName,
			path = getInstancePath(instance),
			children = {},
		}

		if instance:IsA("LuaSourceContainer") then
			node.hasSource = true
			node.scriptType = instance.ClassName
			if instance:IsA("BaseScript") then
				node.enabled = instance.Enabled
			end
		end

		if instance:IsA("GuiObject") then
			node.visible = instance.Visible
			if instance:IsA("Frame") or instance:IsA("ScreenGui") then
				node.guiType = "container"
			elseif instance:IsA("TextLabel") or instance:IsA("TextButton") then
				node.guiType = "text"
				if instance.Text and instance.Text ~= "" then
					node.text = instance.Text
				end
			elseif instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
				node.guiType = "image"
			end
		end

		local children = instance:GetChildren()
		if showScriptsOnly then
			local scriptChildren = {}
			for _, child in ipairs(children) do
				if child:IsA("BaseScript") or child:IsA("Folder") or child:IsA("ModuleScript") then
					table.insert(scriptChildren, child)
				end
			end
			children = scriptChildren
		end

		local childCount = #children
		if childCount > 20 and depth < maxDepth then
			local classGroups = {}
			for _, child in ipairs(children) do
				local cn = child.ClassName
				if not classGroups[cn] then
					classGroups[cn] = {}
				end
				table.insert(classGroups[cn], child)
			end

			node.childSummary = {}
			for cn, classChildren in pairs(classGroups) do
				table.insert(node.childSummary, {
					className = cn,
					count = #classChildren,
					examples = {
						classChildren[1] and classChildren[1].Name,
						classChildren[2] and classChildren[2].Name,
					},
				})
			end

			for cn, classChildren in pairs(classGroups) do
				for i = 1, math.min(3, #classChildren) do
					table.insert(node.children, getStructure(classChildren[i], depth + 1, currentPath))
				end
				if #classChildren > 3 then
					table.insert(node.children, {
						name = "... " .. (#classChildren - 3) .. " more " .. cn .. " objects",
						className = "MoreIndicator",
						path = getInstancePath(instance) .. " [" .. cn .. " children]",
						note = "Use specific path to explore these objects",
					})
				end
			end
		else
			for _, child in ipairs(children) do
				table.insert(node.children, getStructure(child, depth + 1, currentPath))
			end
		end

		return node
	end

	local result = getStructure(startInstance, 0, startPath)
	result.requestedPath = startPath
	result.maxDepth = maxDepth
	result.scriptsOnly = showScriptsOnly
	result.timestamp = tick()

	return result
end

return QueryHandlers
