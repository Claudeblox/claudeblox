local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")
local Utils = require(script.Parent.Utils)
local getInstancePath = Utils.getInstancePath
local getInstanceByPath = Utils.getInstanceByPath

local MetadataHandlers = {}

-- Attribute Tools: Get a single attribute
MetadataHandlers.getAttribute = function(requestData)
	local instancePath = requestData.instancePath
	local attributeName = requestData.attributeName

	if not instancePath or not attributeName then
		return { error = "Instance path and attribute name are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local success, result = pcall(function()
		local value = instance:GetAttribute(attributeName)
		local valueType = typeof(value)

		-- Serialize the value for JSON transport
		local serializedValue = value
		if valueType == "Vector3" then
			serializedValue = { X = value.X, Y = value.Y, Z = value.Z, _type = "Vector3" }
		elseif valueType == "Color3" then
			serializedValue = { R = value.R, G = value.G, B = value.B, _type = "Color3" }
		elseif valueType == "CFrame" then
			serializedValue = { Position = { X = value.Position.X, Y = value.Position.Y, Z = value.Position.Z }, _type = "CFrame" }
		elseif valueType == "UDim2" then
			serializedValue = { X = { Scale = value.X.Scale, Offset = value.X.Offset }, Y = { Scale = value.Y.Scale, Offset = value.Y.Offset }, _type = "UDim2" }
		elseif valueType == "BrickColor" then
			serializedValue = { Name = value.Name, _type = "BrickColor" }
		end

		return {
			instancePath = instancePath,
			attributeName = attributeName,
			value = serializedValue,
			valueType = valueType,
			exists = value ~= nil
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to get attribute: " .. tostring(result) }
	end
end

-- Attribute Tools: Set an attribute
MetadataHandlers.setAttribute = function(requestData)
	local instancePath = requestData.instancePath
	local attributeName = requestData.attributeName
	local attributeValue = requestData.attributeValue
	local valueType = requestData.valueType -- Optional type hint

	if not instancePath or not attributeName then
		return { error = "Instance path and attribute name are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local success, result = pcall(function()
		local value = attributeValue

		-- Handle special type conversions
		if type(attributeValue) == "table" then
			if attributeValue._type == "Vector3" or valueType == "Vector3" then
				value = Vector3.new(attributeValue.X or 0, attributeValue.Y or 0, attributeValue.Z or 0)
			elseif attributeValue._type == "Color3" or valueType == "Color3" then
				value = Color3.new(attributeValue.R or 0, attributeValue.G or 0, attributeValue.B or 0)
			elseif attributeValue._type == "UDim2" or valueType == "UDim2" then
				value = UDim2.new(
					attributeValue.X and attributeValue.X.Scale or 0,
					attributeValue.X and attributeValue.X.Offset or 0,
					attributeValue.Y and attributeValue.Y.Scale or 0,
					attributeValue.Y and attributeValue.Y.Offset or 0
				)
			elseif attributeValue._type == "BrickColor" or valueType == "BrickColor" then
				value = BrickColor.new(attributeValue.Name or "Medium stone grey")
			end
		end

		instance:SetAttribute(attributeName, value)
		ChangeHistoryService:SetWaypoint("Set attribute " .. attributeName .. " on " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			attributeName = attributeName,
			value = attributeValue,
			message = "Attribute set successfully"
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to set attribute: " .. tostring(result) }
	end
end

-- Attribute Tools: Get all attributes
MetadataHandlers.getAttributes = function(requestData)
	local instancePath = requestData.instancePath

	if not instancePath then
		return { error = "Instance path is required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local success, result = pcall(function()
		local attributes = instance:GetAttributes()
		local serializedAttributes = {}

		for name, value in pairs(attributes) do
			local vType = typeof(value)
			local serializedValue = value

			if vType == "Vector3" then
				serializedValue = { X = value.X, Y = value.Y, Z = value.Z, _type = "Vector3" }
			elseif vType == "Color3" then
				serializedValue = { R = value.R, G = value.G, B = value.B, _type = "Color3" }
			elseif vType == "CFrame" then
				serializedValue = { Position = { X = value.Position.X, Y = value.Position.Y, Z = value.Position.Z }, _type = "CFrame" }
			elseif vType == "UDim2" then
				serializedValue = { X = { Scale = value.X.Scale, Offset = value.X.Offset }, Y = { Scale = value.Y.Scale, Offset = value.Y.Offset }, _type = "UDim2" }
			elseif vType == "BrickColor" then
				serializedValue = { Name = value.Name, _type = "BrickColor" }
			end

			serializedAttributes[name] = {
				value = serializedValue,
				type = vType
			}
		end

		local count = 0
		for _ in pairs(serializedAttributes) do count = count + 1 end

		return {
			instancePath = instancePath,
			attributes = serializedAttributes,
			count = count
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to get attributes: " .. tostring(result) }
	end
end

-- Attribute Tools: Delete an attribute
MetadataHandlers.deleteAttribute = function(requestData)
	local instancePath = requestData.instancePath
	local attributeName = requestData.attributeName

	if not instancePath or not attributeName then
		return { error = "Instance path and attribute name are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local success, result = pcall(function()
		local existed = instance:GetAttribute(attributeName) ~= nil
		instance:SetAttribute(attributeName, nil)
		ChangeHistoryService:SetWaypoint("Delete attribute " .. attributeName .. " from " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			attributeName = attributeName,
			existed = existed,
			message = existed and "Attribute deleted successfully" or "Attribute did not exist"
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to delete attribute: " .. tostring(result) }
	end
end

-- Tag Tools: Get all tags on an instance
MetadataHandlers.getTags = function(requestData)
	local instancePath = requestData.instancePath

	if not instancePath then
		return { error = "Instance path is required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local success, result = pcall(function()
		local tags = CollectionService:GetTags(instance)

		return {
			instancePath = instancePath,
			tags = tags,
			count = #tags
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to get tags: " .. tostring(result) }
	end
end

-- Tag Tools: Add a tag to an instance
MetadataHandlers.addTag = function(requestData)
	local instancePath = requestData.instancePath
	local tagName = requestData.tagName

	if not instancePath or not tagName then
		return { error = "Instance path and tag name are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local success, result = pcall(function()
		local alreadyHad = CollectionService:HasTag(instance, tagName)
		CollectionService:AddTag(instance, tagName)
		ChangeHistoryService:SetWaypoint("Add tag " .. tagName .. " to " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			tagName = tagName,
			alreadyHad = alreadyHad,
			message = alreadyHad and "Instance already had this tag" or "Tag added successfully"
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to add tag: " .. tostring(result) }
	end
end

-- Tag Tools: Remove a tag from an instance
MetadataHandlers.removeTag = function(requestData)
	local instancePath = requestData.instancePath
	local tagName = requestData.tagName

	if not instancePath or not tagName then
		return { error = "Instance path and tag name are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local success, result = pcall(function()
		local hadTag = CollectionService:HasTag(instance, tagName)
		CollectionService:RemoveTag(instance, tagName)
		ChangeHistoryService:SetWaypoint("Remove tag " .. tagName .. " from " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			tagName = tagName,
			hadTag = hadTag,
			message = hadTag and "Tag removed successfully" or "Instance did not have this tag"
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to remove tag: " .. tostring(result) }
	end
end

-- Tag Tools: Get all instances with a specific tag
MetadataHandlers.getTagged = function(requestData)
	local tagName = requestData.tagName

	if not tagName then
		return { error = "Tag name is required" }
	end

	local success, result = pcall(function()
		local taggedInstances = CollectionService:GetTagged(tagName)
		local instances = {}

		for _, instance in ipairs(taggedInstances) do
			table.insert(instances, {
				name = instance.Name,
				className = instance.ClassName,
				path = getInstancePath(instance)
			})
		end

		return {
			tagName = tagName,
			instances = instances,
			count = #instances
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to get tagged instances: " .. tostring(result) }
	end
end

-- Selection handlers
MetadataHandlers.getSelection = function(requestData)
	local selection = Selection:Get()

	if #selection == 0 then
		return {
			success = true,
			selection = {},
			count = 0,
			message = "No objects selected"
		}
	end

	local selectedObjects = {}
	for _, instance in ipairs(selection) do
		table.insert(selectedObjects, {
			name = instance.Name,
			className = instance.ClassName,
			path = getInstancePath(instance),
			parent = instance.Parent and getInstancePath(instance.Parent) or nil
		})
	end

	return {
		success = true,
		selection = selectedObjects,
		count = #selection,
		message = #selection .. " object(s) selected"
	}
end

MetadataHandlers.executeLuau = function(requestData)
	local code = requestData.code
	if not code or code == "" then
		return { error = "Code is required" }
	end

	-- Capture print output
	local output = {}
	local oldPrint = print
	local oldWarn = warn
	print = function(...)
		local args = {...}
		local parts = {}
		for i = 1, select("#", ...) do
			table.insert(parts, tostring(args[i]))
		end
		table.insert(output, table.concat(parts, "\t"))
		oldPrint(...)
	end
	warn = function(...)
		local args = {...}
		local parts = {}
		for i = 1, select("#", ...) do
			table.insert(parts, tostring(args[i]))
		end
		table.insert(output, "[warn] " .. table.concat(parts, "\t"))
		oldWarn(...)
	end

	local success, result = pcall(function()
		local fn, compileError = loadstring(code)
		if not fn then
			error("Compile error: " .. tostring(compileError))
		end
		return fn()
	end)

	-- Restore original print/warn
	print = oldPrint
	warn = oldWarn

	if success then
		return {
			success = true,
			returnValue = result ~= nil and tostring(result) or nil,
			output = output,
			message = "Code executed successfully"
		}
	else
		return {
			success = false,
			error = tostring(result),
			output = output,
			message = "Code execution failed"
		}
	end
end

return MetadataHandlers
