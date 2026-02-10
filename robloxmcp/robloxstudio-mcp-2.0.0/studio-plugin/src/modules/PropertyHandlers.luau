local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Utils = require(script.Parent.Utils)
local getInstancePath = Utils.getInstancePath
local getInstanceByPath = Utils.getInstanceByPath
local convertPropertyValue = Utils.convertPropertyValue
local evaluateFormula = Utils.evaluateFormula

local PropertyHandlers = {}

PropertyHandlers.setProperty = function(requestData)
	local instancePath = requestData.instancePath
	local propertyName = requestData.propertyName
	local propertyValue = requestData.propertyValue

	if not instancePath or not propertyName then
		return { error = "Instance path and property name are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	local success, result = pcall(function()
		-- Handle instance reference properties (Parent, PrimaryPart, etc.)
		if propertyName == "Parent" or propertyName == "PrimaryPart" then
			if type(propertyValue) == "string" then
				local refInstance = getInstanceByPath(propertyValue)
				if refInstance then
					instance[propertyName] = refInstance
				else
					return { error = propertyName .. " instance not found: " .. propertyValue }
				end
			end
		elseif propertyName == "Name" then
			instance.Name = tostring(propertyValue)
		elseif propertyName == "Source" and instance:IsA("LuaSourceContainer") then
			instance.Source = tostring(propertyValue)
		else
			-- Use the generic converter for all other properties
			local convertedValue = convertPropertyValue(instance, propertyName, propertyValue)
			if convertedValue ~= nil then
				instance[propertyName] = convertedValue
			else
				instance[propertyName] = propertyValue
			end
		end

		ChangeHistoryService:SetWaypoint("Set " .. propertyName .. " property")
		return true
	end)

	if success and result ~= false then
		return {
			success = true,
			instancePath = instancePath,
			propertyName = propertyName,
			propertyValue = propertyValue,
			message = "Property set successfully",
		}
	else
		return {
			error = "Failed to set property: " .. tostring(result),
			instancePath = instancePath,
			propertyName = propertyName,
		}
	end
end

PropertyHandlers.massSetProperty = function(requestData)
	local paths = requestData.paths
	local propertyName = requestData.propertyName
	local propertyValue = requestData.propertyValue

	if not paths or type(paths) ~= "table" or #paths == 0 or not propertyName then
		return { error = "Paths array and property name are required" }
	end

	local results = {}
	local successCount = 0
	local failureCount = 0

	for _, path in ipairs(paths) do
		local instance = getInstanceByPath(path)
		if instance then
			local success, err = pcall(function()
				instance[propertyName] = propertyValue
			end)

			if success then
				successCount = successCount + 1
				table.insert(results, {
					path = path,
					success = true,
					propertyName = propertyName,
					propertyValue = propertyValue
				})
			else
				failureCount = failureCount + 1
				table.insert(results, {
					path = path,
					success = false,
					error = tostring(err)
				})
			end
		else
			failureCount = failureCount + 1
			table.insert(results, {
				path = path,
				success = false,
				error = "Instance not found"
			})
		end
	end

	if successCount > 0 then
		ChangeHistoryService:SetWaypoint("Mass set " .. propertyName .. " property")
	end

	return {
		results = results,
		summary = {
			total = #paths,
			succeeded = successCount,
			failed = failureCount
		}
	}
end

PropertyHandlers.massGetProperty = function(requestData)
	local paths = requestData.paths
	local propertyName = requestData.propertyName

	if not paths or type(paths) ~= "table" or #paths == 0 or not propertyName then
		return { error = "Paths array and property name are required" }
	end

	local results = {}

	for _, path in ipairs(paths) do
		local instance = getInstanceByPath(path)
		if instance then
			local success, value = pcall(function()
				return instance[propertyName]
			end)

			if success then
				table.insert(results, {
					path = path,
					success = true,
					propertyName = propertyName,
					propertyValue = value
				})
			else
				table.insert(results, {
					path = path,
					success = false,
					error = tostring(value)
				})
			end
		else
			table.insert(results, {
				path = path,
				success = false,
				error = "Instance not found"
			})
		end
	end

	return {
		results = results,
		propertyName = propertyName
	}
end

PropertyHandlers.setCalculatedProperty = function(requestData)
	local paths = requestData.paths
	local propertyName = requestData.propertyName
	local formula = requestData.formula
	local variables = requestData.variables

	if not paths or type(paths) ~= "table" or #paths == 0 or not propertyName or not formula then
		return { error = "Paths, property name, and formula are required" }
	end

	local results = {}
	local successCount = 0
	local failureCount = 0

	for index, path in ipairs(paths) do
		local instance = getInstanceByPath(path)
		if instance then
			local value, evalError = evaluateFormula(formula, variables, instance, index)

			if value ~= nil and not evalError then
				local success, err = pcall(function()
					instance[propertyName] = value
				end)

				if success then
					successCount = successCount + 1
					table.insert(results, {
						path = path,
						success = true,
						propertyName = propertyName,
						calculatedValue = value,
						formula = formula
					})
				else
					failureCount = failureCount + 1
					table.insert(results, {
						path = path,
						success = false,
						error = "Property set failed: " .. tostring(err)
					})
				end
			else
				failureCount = failureCount + 1
				table.insert(results, {
					path = path,
					success = false,
					error = evalError or "Formula evaluation failed"
				})
			end
		else
			failureCount = failureCount + 1
			table.insert(results, {
				path = path,
				success = false,
				error = "Instance not found"
			})
		end
	end

	if successCount > 0 then
		ChangeHistoryService:SetWaypoint("Set calculated " .. propertyName .. " property")
	end

	return {
		results = results,
		summary = {
			total = #paths,
			succeeded = successCount,
			failed = failureCount
		},
		formula = formula
	}
end

PropertyHandlers.setRelativeProperty = function(requestData)
	local paths = requestData.paths
	local propertyName = requestData.propertyName
	local operation = requestData.operation
	local value = requestData.value
	local component = requestData.component

	if not paths or type(paths) ~= "table" or #paths == 0 or not propertyName or not operation or value == nil then
		return { error = "Paths, property name, operation, and value are required" }
	end

	local results = {}
	local successCount = 0
	local failureCount = 0

	for _, path in ipairs(paths) do
		local instance = getInstanceByPath(path)
		if instance then
			local success, err = pcall(function()
				local currentValue = instance[propertyName]
				local newValue

				if component and typeof(currentValue) == "Vector3" then
					local x, y, z = currentValue.X, currentValue.Y, currentValue.Z
					local targetValue = value

					if component == "X" then
						if operation == "add" then x = x + targetValue
						elseif operation == "subtract" then x = x - targetValue
						elseif operation == "multiply" then x = x * targetValue
						elseif operation == "divide" then x = x / targetValue
						elseif operation == "power" then x = x ^ targetValue
						end
					elseif component == "Y" then
						if operation == "add" then y = y + targetValue
						elseif operation == "subtract" then y = y - targetValue
						elseif operation == "multiply" then y = y * targetValue
						elseif operation == "divide" then y = y / targetValue
						elseif operation == "power" then y = y ^ targetValue
						end
					elseif component == "Z" then
						if operation == "add" then z = z + targetValue
						elseif operation == "subtract" then z = z - targetValue
						elseif operation == "multiply" then z = z * targetValue
						elseif operation == "divide" then z = z / targetValue
						elseif operation == "power" then z = z ^ targetValue
						end
					end

					newValue = Vector3.new(x, y, z)
				elseif typeof(currentValue) == "Color3" and typeof(value) == "Color3" then
					local r, g, b = currentValue.R, currentValue.G, currentValue.B

					if operation == "add" then
						newValue = Color3.new(
							math.min(1, r + value.R),
							math.min(1, g + value.G),
							math.min(1, b + value.B)
						)
					elseif operation == "subtract" then
						newValue = Color3.new(
							math.max(0, r - value.R),
							math.max(0, g - value.G),
							math.max(0, b - value.B)
						)
					elseif operation == "multiply" then
						newValue = Color3.new(r * value.R, g * value.G, b * value.B)
					end
				elseif type(currentValue) == "number" and type(value) == "number" then
					if operation == "add" then
						newValue = currentValue + value
					elseif operation == "subtract" then
						newValue = currentValue - value
					elseif operation == "multiply" then
						newValue = currentValue * value
					elseif operation == "divide" then
						newValue = currentValue / value
					elseif operation == "power" then
						newValue = currentValue ^ value
					end
				elseif typeof(currentValue) == "Vector3" and type(value) == "number" then
					local x, y, z = currentValue.X, currentValue.Y, currentValue.Z

					if operation == "add" then
						newValue = Vector3.new(x + value, y + value, z + value)
					elseif operation == "subtract" then
						newValue = Vector3.new(x - value, y - value, z - value)
					elseif operation == "multiply" then
						newValue = Vector3.new(x * value, y * value, z * value)
					elseif operation == "divide" then
						newValue = Vector3.new(x / value, y / value, z / value)
					elseif operation == "power" then
						newValue = Vector3.new(x ^ value, y ^ value, z ^ value)
					end
				elseif typeof(currentValue) == "UDim2" and type(value) == "number" and component then
					local xs, xo = currentValue.X.Scale, currentValue.X.Offset
					local ys, yo = currentValue.Y.Scale, currentValue.Y.Offset
					if component == "XScale" then
						if operation == "add" then xs = xs + value
						elseif operation == "subtract" then xs = xs - value
						elseif operation == "multiply" then xs = xs * value
						elseif operation == "divide" then xs = xs / value
						elseif operation == "power" then xs = xs ^ value
						end
					elseif component == "XOffset" then
						if operation == "add" then xo = xo + value
						elseif operation == "subtract" then xo = xo - value
						elseif operation == "multiply" then xo = xo * value
						elseif operation == "divide" then xo = xo / value
						elseif operation == "power" then xo = xo ^ value
						end
					elseif component == "YScale" then
						if operation == "add" then ys = ys + value
						elseif operation == "subtract" then ys = ys - value
						elseif operation == "multiply" then ys = ys * value
						elseif operation == "divide" then ys = ys / value
						elseif operation == "power" then ys = ys ^ value
						end
					elseif component == "YOffset" then
						if operation == "add" then yo = yo + value
						elseif operation == "subtract" then yo = yo - value
						elseif operation == "multiply" then yo = yo * value
						elseif operation == "divide" then yo = yo / value
						elseif operation == "power" then yo = yo ^ value
						end
					end
					newValue = UDim2.new(xs, xo, ys, yo)
				else
					error("Unsupported property type or operation")
				end

				instance[propertyName] = newValue
				return newValue
			end)

			if success then
				successCount = successCount + 1
				table.insert(results, {
					path = path,
					success = true,
					propertyName = propertyName,
					operation = operation,
					value = value,
					component = component,
					newValue = err
				})
			else
				failureCount = failureCount + 1
				table.insert(results, {
					path = path,
					success = false,
					error = tostring(err)
				})
			end
		else
			failureCount = failureCount + 1
			table.insert(results, {
				path = path,
				success = false,
				error = "Instance not found"
			})
		end
	end

	if successCount > 0 then
		ChangeHistoryService:SetWaypoint("Set relative " .. propertyName .. " property")
	end

	return {
		results = results,
		summary = {
			total = #paths,
			succeeded = successCount,
			failed = failureCount
		},
		operation = operation,
		value = value
	}
end

return PropertyHandlers
