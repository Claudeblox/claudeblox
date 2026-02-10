local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Utils = require(script.Parent.Utils)
local getInstancePath = Utils.getInstancePath
local getInstanceByPath = Utils.getInstanceByPath
local convertPropertyValue = Utils.convertPropertyValue

local InstanceHandlers = {}

InstanceHandlers.createObject = function(requestData)
	local className = requestData.className
	local parentPath = requestData.parent
	local name = requestData.name
	local properties = requestData.properties or {}

	if not className or not parentPath then
		return { error = "Class name and parent are required" }
	end

	local parentInstance = getInstanceByPath(parentPath)
	if not parentInstance then
		return { error = "Parent instance not found: " .. parentPath }
	end

	local success, newInstance = pcall(function()
		local instance = Instance.new(className)

		if name then
			instance.Name = name
		end

		for propertyName, propertyValue in pairs(properties) do
			pcall(function()
				instance[propertyName] = propertyValue
			end)
		end

		instance.Parent = parentInstance
		ChangeHistoryService:SetWaypoint("Create " .. className)
		return instance
	end)

	if success and newInstance then
		return {
			success = true,
			className = className,
			parent = parentPath,
			instancePath = getInstancePath(newInstance),
			name = newInstance.Name,
			message = "Object created successfully",
		}
	else
		return {
			error = "Failed to create object: " .. tostring(newInstance),
			className = className,
			parent = parentPath,
		}
	end
end

InstanceHandlers.deleteObject = function(requestData)
	local instancePath = requestData.instancePath

	if not instancePath then
		return { error = "Instance path is required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	if instance == game then
		return { error = "Cannot delete the game instance" }
	end

	local success, result = pcall(function()
		local name = instance.Name
		local className = instance.ClassName
		instance:Destroy()
		ChangeHistoryService:SetWaypoint("Delete " .. className .. " (" .. name .. ")")
		return true
	end)

	if success then
		return {
			success = true,
			instancePath = instancePath,
			message = "Object deleted successfully",
		}
	else
		return {
			error = "Failed to delete object: " .. tostring(result),
			instancePath = instancePath,
		}
	end
end

InstanceHandlers.massCreateObjects = function(requestData)
	local objects = requestData.objects

	if not objects or type(objects) ~= "table" or #objects == 0 then
		return { error = "Objects array is required" }
	end

	local results = {}
	local successCount = 0
	local failureCount = 0

	for _, objData in ipairs(objects) do
		local className = objData.className
		local parentPath = objData.parent
		local name = objData.name

		if className and parentPath then
			local parentInstance = getInstanceByPath(parentPath)
			if parentInstance then
				local success, newInstance = pcall(function()
					local instance = Instance.new(className)
					if name then
						instance.Name = name
					end
					instance.Parent = parentInstance
					return instance
				end)

				if success and newInstance then
					successCount = successCount + 1
					table.insert(results, {
						success = true,
						className = className,
						parent = parentPath,
						instancePath = getInstancePath(newInstance),
						name = newInstance.Name
					})
				else
					failureCount = failureCount + 1
					table.insert(results, {
						success = false,
						className = className,
						parent = parentPath,
						error = tostring(newInstance)
					})
				end
			else
				failureCount = failureCount + 1
				table.insert(results, {
					success = false,
					className = className,
					parent = parentPath,
					error = "Parent instance not found"
				})
			end
		else
			failureCount = failureCount + 1
			table.insert(results, {
				success = false,
				error = "Class name and parent are required"
			})
		end
	end

	if successCount > 0 then
		ChangeHistoryService:SetWaypoint("Mass create objects")
	end

	return {
		results = results,
		summary = {
			total = #objects,
			succeeded = successCount,
			failed = failureCount
		}
	}
end

InstanceHandlers.massCreateObjectsWithProperties = function(requestData)
	local objects = requestData.objects

	if not objects or type(objects) ~= "table" or #objects == 0 then
		return { error = "Objects array is required" }
	end

	local results = {}
	local successCount = 0
	local failureCount = 0

	for _, objData in ipairs(objects) do
		local className = objData.className
		local parentPath = objData.parent
		local name = objData.name
		local properties = objData.properties or {}

		if className and parentPath then
			local parentInstance = getInstanceByPath(parentPath)
			if parentInstance then
				local success, newInstance = pcall(function()
					local instance = Instance.new(className)

					if name then
						instance.Name = name
					end

					-- Set Parent first so property type inference works
					instance.Parent = parentInstance

					for propertyName, propertyValue in pairs(properties) do
						pcall(function()
							local convertedValue = convertPropertyValue(instance, propertyName, propertyValue)
							if convertedValue ~= nil then
								instance[propertyName] = convertedValue
							end
						end)
					end

					return instance
				end)

				if success and newInstance then
					successCount = successCount + 1
					table.insert(results, {
						success = true,
						className = className,
						parent = parentPath,
						instancePath = getInstancePath(newInstance),
						name = newInstance.Name
					})
				else
					failureCount = failureCount + 1
					table.insert(results, {
						success = false,
						className = className,
						parent = parentPath,
						error = tostring(newInstance)
					})
				end
			else
				failureCount = failureCount + 1
				table.insert(results, {
					success = false,
					className = className,
					parent = parentPath,
					error = "Parent instance not found"
				})
			end
		else
			failureCount = failureCount + 1
			table.insert(results, {
				success = false,
				error = "Class name and parent are required"
			})
		end
	end

	if successCount > 0 then
		ChangeHistoryService:SetWaypoint("Mass create objects with properties")
	end

	return {
		results = results,
		summary = {
			total = #objects,
			succeeded = successCount,
			failed = failureCount
		}
	}
end

InstanceHandlers.smartDuplicate = function(requestData)
	local instancePath = requestData.instancePath
	local count = requestData.count
	local options = requestData.options or {}

	if not instancePath or not count or count < 1 then
		return { error = "Instance path and count > 0 are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local results = {}
	local successCount = 0
	local failureCount = 0

	for i = 1, count do
		local success, newInstance = pcall(function()
			local clone = instance:Clone()

			if options.namePattern then
				clone.Name = options.namePattern:gsub("{n}", tostring(i))
			else
				clone.Name = instance.Name .. i
			end

			if options.positionOffset and clone:IsA("BasePart") then
				local offset = options.positionOffset
				local currentPos = clone.Position
				clone.Position = Vector3.new(
					currentPos.X + (offset[1] or 0) * i,
					currentPos.Y + (offset[2] or 0) * i,
					currentPos.Z + (offset[3] or 0) * i
				)
			end

			if options.rotationOffset and clone:IsA("BasePart") then
				local offset = options.rotationOffset
				local currentCFrame = clone.CFrame
				clone.CFrame = currentCFrame * CFrame.Angles(
					math.rad((offset[1] or 0) * i),
					math.rad((offset[2] or 0) * i),
					math.rad((offset[3] or 0) * i)
				)
			end

			if options.scaleOffset and clone:IsA("BasePart") then
				local offset = options.scaleOffset
				local currentSize = clone.Size
				clone.Size = Vector3.new(
					currentSize.X * ((offset[1] or 1) ^ i),
					currentSize.Y * ((offset[2] or 1) ^ i),
					currentSize.Z * ((offset[3] or 1) ^ i)
				)
			end

			if options.propertyVariations then
				for propName, values in pairs(options.propertyVariations) do
					if values and #values > 0 then
						local valueIndex = ((i - 1) % #values) + 1
						pcall(function()
							clone[propName] = values[valueIndex]
						end)
					end
				end
			end

			if options.targetParents and options.targetParents[i] then
				local targetParent = getInstanceByPath(options.targetParents[i])
				if targetParent then
					clone.Parent = targetParent
				else
					clone.Parent = instance.Parent
				end
			else
				clone.Parent = instance.Parent
			end

			return clone
		end)

		if success and newInstance then
			successCount = successCount + 1
			table.insert(results, {
				success = true,
				instancePath = getInstancePath(newInstance),
				name = newInstance.Name,
				index = i
			})
		else
			failureCount = failureCount + 1
			table.insert(results, {
				success = false,
				index = i,
				error = tostring(newInstance)
			})
		end
	end

	if successCount > 0 then
		ChangeHistoryService:SetWaypoint("Smart duplicate " .. instance.Name .. " (" .. successCount .. " copies)")
	end

	return {
		results = results,
		summary = {
			total = count,
			succeeded = successCount,
			failed = failureCount
		},
		sourceInstance = instancePath
	}
end

InstanceHandlers.massDuplicate = function(requestData)
	local duplications = requestData.duplications

	if not duplications or type(duplications) ~= "table" or #duplications == 0 then
		return { error = "Duplications array is required" }
	end

	local allResults = {}
	local totalSuccess = 0
	local totalFailures = 0

	for _, duplication in ipairs(duplications) do
		local result = InstanceHandlers.smartDuplicate(duplication)
		table.insert(allResults, result)

		if result.summary then
			totalSuccess = totalSuccess + result.summary.succeeded
			totalFailures = totalFailures + result.summary.failed
		end
	end

	if totalSuccess > 0 then
		ChangeHistoryService:SetWaypoint("Mass duplicate operations (" .. totalSuccess .. " objects)")
	end

	return {
		results = allResults,
		summary = {
			total = totalSuccess + totalFailures,
			succeeded = totalSuccess,
			failed = totalFailures
		}
	}
end

return InstanceHandlers
