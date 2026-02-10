local ScriptEditorService = game:GetService("ScriptEditorService")

local Utils = {}

function Utils.safeCall(func, ...)
	local success, result = pcall(func, ...)
	if success then
		return result
	else
		warn("MCP Plugin Error: " .. tostring(result))
		return nil
	end
end

function Utils.getInstancePath(instance)
	if not instance or instance == game then
		return "game"
	end

	local path = {}
	local current = instance

	while current and current ~= game do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end

	return "game." .. table.concat(path, ".")
end

function Utils.getInstanceByPath(path)
	if path == "game" or path == "" then
		return game
	end

	path = path:gsub("^game%.", "")

	local parts = {}
	for part in path:gmatch("[^%.]+") do
		table.insert(parts, part)
	end

	local current = game
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then
			return nil
		end
	end

	return current
end

-- Helper to normalize line endings and split without inventing an extra trailing line
function Utils.splitLines(source)
	local normalized = (source or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
	local endsWithNewline = normalized:sub(-1) == "\n"

	local lines = {}
	local start = 1

	while true do
		local newlinePos = string.find(normalized, "\n", start, true)
		if newlinePos then
			table.insert(lines, string.sub(normalized, start, newlinePos - 1))
			start = newlinePos + 1
		else
			local remainder = string.sub(normalized, start)
			if remainder ~= "" or not endsWithNewline then
				table.insert(lines, remainder)
			end
			break
		end
	end

	if #lines == 0 then
		table.insert(lines, "")
	end

	return lines, endsWithNewline
end

function Utils.joinLines(lines, hadTrailingNewline)
	local source = table.concat(lines, "\n")
	if hadTrailingNewline and source:sub(-1) ~= "\n" then
		source ..= "\n"
	end
	return source
end

-- Read script source, preferring draft content from ScriptEditorService when available
function Utils.readScriptSource(instance)
	local ok, result = pcall(function()
		local doc = ScriptEditorService:FindDocument(instance)
		if doc then
			return doc:GetText()
		end
		return nil
	end)
	if ok and result then
		return result
	end
	return instance.Source
end

-- Helper to convert property values from JSON to Roblox types
function Utils.convertPropertyValue(instance, propertyName, propertyValue)
	-- Handle nil
	if propertyValue == nil then
		return nil
	end

	-- Handle arrays (likely Vector3, Color3, UDim2)
	if type(propertyValue) == "table" and #propertyValue > 0 then
		-- Check if it's a Vector3-like property
		if #propertyValue == 3 then
			local prop = propertyName:lower()
			if prop == "position" or prop == "size" or prop == "orientation" or prop == "velocity" or prop == "angularvelocity" then
				return Vector3.new(propertyValue[1] or 0, propertyValue[2] or 0, propertyValue[3] or 0)
			elseif prop == "color" or prop == "color3" then
				return Color3.new(propertyValue[1] or 0, propertyValue[2] or 0, propertyValue[3] or 0)
			else
				-- Try to infer from current property type
				local success, currentVal = pcall(function() return instance[propertyName] end)
				if success then
					if typeof(currentVal) == "Vector3" then
						return Vector3.new(propertyValue[1] or 0, propertyValue[2] or 0, propertyValue[3] or 0)
					elseif typeof(currentVal) == "Color3" then
						return Color3.new(propertyValue[1] or 0, propertyValue[2] or 0, propertyValue[3] or 0)
					end
				end
			end
		elseif #propertyValue == 2 then
			-- Possibly Vector2
			local success, currentVal = pcall(function() return instance[propertyName] end)
			if success and typeof(currentVal) == "Vector2" then
				return Vector2.new(propertyValue[1] or 0, propertyValue[2] or 0)
			end
		end
	end

	-- Handle object with X, Y, Z keys (Vector3)
	if type(propertyValue) == "table" and (propertyValue.X or propertyValue.Y or propertyValue.Z) then
		return Vector3.new(propertyValue.X or 0, propertyValue.Y or 0, propertyValue.Z or 0)
	end

	-- Handle object with R, G, B keys (Color3)
	if type(propertyValue) == "table" and (propertyValue.R or propertyValue.G or propertyValue.B) then
		return Color3.new(propertyValue.R or 0, propertyValue.G or 0, propertyValue.B or 0)
	end

	-- Handle UDim2: { X = { Scale, Offset }, Y = { Scale, Offset } } or array [scaleX, offsetX, scaleY, offsetY]
	if type(propertyValue) == "table" then
		if type(propertyValue.X) == "table" and type(propertyValue.Y) == "table" then
			local xScale = (propertyValue.X.Scale ~= nil) and propertyValue.X.Scale or 0
			local xOffset = (propertyValue.X.Offset ~= nil) and propertyValue.X.Offset or 0
			local yScale = (propertyValue.Y.Scale ~= nil) and propertyValue.Y.Scale or 0
			local yOffset = (propertyValue.Y.Offset ~= nil) and propertyValue.Y.Offset or 0
			return UDim2.new(xScale, xOffset, yScale, yOffset)
		end
		if #propertyValue == 4 then
			local success, currentVal = pcall(function() return instance[propertyName] end)
			if success and typeof(currentVal) == "UDim2" then
				return UDim2.new(
					propertyValue[1] or 0,
					propertyValue[2] or 0,
					propertyValue[3] or 0,
					propertyValue[4] or 0
				)
			end
		end
	end

	-- Handle Enum values (strings like "Ball", "Cylinder", etc.)
	if type(propertyValue) == "string" then
		local success, currentVal = pcall(function() return instance[propertyName] end)
		if success and typeof(currentVal) == "EnumItem" then
			local enumType = tostring(currentVal.EnumType)
			local enumSuccess, enumVal = pcall(function()
				return Enum[enumType][propertyValue]
			end)
			if enumSuccess and enumVal then
				return enumVal
			end
		end
		-- Handle BrickColor
		if propertyName == "BrickColor" then
			return BrickColor.new(propertyValue)
		end
	end

	-- Handle boolean strings
	if type(propertyValue) == "string" then
		if propertyValue == "true" then return true end
		if propertyValue == "false" then return false end
	end

	-- Return as-is for primitives (number, boolean, string)
	return propertyValue
end

function Utils.evaluateFormula(formula, variables, instance, index)
	local value = formula

	value = value:gsub("index", tostring(index))

	if instance and instance:IsA("BasePart") then
		local pos = instance.Position
		local size = instance.Size
		value = value:gsub("Position%.X", tostring(pos.X))
		value = value:gsub("Position%.Y", tostring(pos.Y))
		value = value:gsub("Position%.Z", tostring(pos.Z))
		value = value:gsub("Size%.X", tostring(size.X))
		value = value:gsub("Size%.Y", tostring(size.Y))
		value = value:gsub("Size%.Z", tostring(size.Z))
		value = value:gsub("magnitude", tostring(pos.magnitude))
	end

	if variables then
		for k, v in pairs(variables) do
			value = value:gsub(k, tostring(v))
		end
	end

	value = value:gsub("sin%(([%d%.%-]+)%)", function(x) return tostring(math.sin(tonumber(x) or 0)) end)
	value = value:gsub("cos%(([%d%.%-]+)%)", function(x) return tostring(math.cos(tonumber(x) or 0)) end)
	value = value:gsub("sqrt%(([%d%.%-]+)%)", function(x) return tostring(math.sqrt(tonumber(x) or 0)) end)
	value = value:gsub("abs%(([%d%.%-]+)%)", function(x) return tostring(math.abs(tonumber(x) or 0)) end)
	value = value:gsub("floor%(([%d%.%-]+)%)", function(x) return tostring(math.floor(tonumber(x) or 0)) end)
	value = value:gsub("ceil%(([%d%.%-]+)%)", function(x) return tostring(math.ceil(tonumber(x) or 0)) end)

	local result = tonumber(value)
	if result then
		return result, nil
	end

	local success, evalResult = pcall(function()
		local num = tonumber(value)
		if num then
			return num
		end

		local a, b = value:match("^([%d%.%-]+)%s*%*%s*([%d%.%-]+)$")
		if a and b then
			return (tonumber(a) or 0) * (tonumber(b) or 0)
		end

		a, b = value:match("^([%d%.%-]+)%s*%+%s*([%d%.%-]+)$")
		if a and b then
			return (tonumber(a) or 0) + (tonumber(b) or 0)
		end

		a, b = value:match("^([%d%.%-]+)%s*%-%s*([%d%.%-]+)$")
		if a and b then
			return (tonumber(a) or 0) - (tonumber(b) or 0)
		end

		a, b = value:match("^([%d%.%-]+)%s*/%s*([%d%.%-]+)$")
		if a and b then
			local divisor = tonumber(b) or 1
			if divisor ~= 0 then
				return (tonumber(a) or 0) / divisor
			end
		end

		error("Unsupported formula pattern: " .. value)
	end)

	if success and type(evalResult) == "number" then
		return evalResult, nil
	else
		return index, "Complex formulas not supported - using index value"
	end
end

-- Version comparison helper
function Utils.compareVersions(v1, v2)
	local function parseVersion(v)
		local parts = {}
		for num in string.gmatch(v, "%d+") do
			table.insert(parts, tonumber(num) or 0)
		end
		return parts
	end

	local p1, p2 = parseVersion(v1), parseVersion(v2)
	for i = 1, math.max(#p1, #p2) do
		local n1, n2 = p1[i] or 0, p2[i] or 0
		if n1 < n2 then return -1 end
		if n1 > n2 then return 1 end
	end
	return 0
end

return Utils
