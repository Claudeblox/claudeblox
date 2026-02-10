local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ScriptEditorService = game:GetService("ScriptEditorService")
local Utils = require(script.Parent.Utils)
local getInstancePath = Utils.getInstancePath
local getInstanceByPath = Utils.getInstanceByPath
local readScriptSource = Utils.readScriptSource
local splitLines = Utils.splitLines
local joinLines = Utils.joinLines

local ScriptHandlers = {}

ScriptHandlers.getScriptSource = function(requestData)
	local instancePath = requestData.instancePath
	local startLine = requestData.startLine
	local endLine = requestData.endLine

	if not instancePath then
		return { error = "Instance path is required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	if not instance:IsA("LuaSourceContainer") then
		return { error = "Instance is not a script-like object: " .. instance.ClassName }
	end

	local success, result = pcall(function()
		local fullSource = readScriptSource(instance)
		local lines, hasTrailingNewline = splitLines(fullSource)
		local totalLineCount = #lines

		-- If line range is specified, extract only those lines
		local sourceToReturn = fullSource
		local returnedStartLine = 1
		local returnedEndLine = totalLineCount

		if startLine or endLine then
			local actualStartLine = math.max(1, startLine or 1)
			local actualEndLine = math.min(#lines, endLine or #lines)

			local selectedLines = {}
			for i = actualStartLine, actualEndLine do
				table.insert(selectedLines, lines[i] or "")
			end

			sourceToReturn = table.concat(selectedLines, '\n')
			if hasTrailingNewline and actualEndLine == #lines and sourceToReturn:sub(-1) ~= "\n" then
				sourceToReturn ..= "\n"
			end
			returnedStartLine = actualStartLine
			returnedEndLine = actualEndLine
		end

		-- Build numbered source for AI agents to accurately identify line numbers
		local numberedLines = {}
		local linesToNumber = startLine and select(1, splitLines(sourceToReturn)) or lines
		local lineOffset = returnedStartLine - 1
		for i, line in ipairs(linesToNumber) do
			table.insert(numberedLines, (i + lineOffset) .. ": " .. line)
		end
		local numberedSource = table.concat(numberedLines, "\n")

		local resp = {
			instancePath = instancePath,
			className = instance.ClassName,
			name = instance.Name,
			source = sourceToReturn,
			numberedSource = numberedSource,
			sourceLength = string.len(fullSource),
			lineCount = totalLineCount,
			-- Line range info
			startLine = returnedStartLine,
			endLine = returnedEndLine,
			isPartial = (startLine ~= nil or endLine ~= nil),
			-- Helpful metadata for large scripts
			truncated = false,
		}

		-- If the source is very large (>50000 chars) and no range specified,
		-- return first 1000 lines with truncation notice
		if not startLine and not endLine and string.len(fullSource) > 50000 then
			local truncatedLines = {}
			local truncatedNumberedLines = {}
			local maxLines = math.min(1000, #lines)
			for i = 1, maxLines do
				table.insert(truncatedLines, lines[i])
				table.insert(truncatedNumberedLines, i .. ": " .. lines[i])
			end
			resp.source = table.concat(truncatedLines, '\n')
			resp.numberedSource = table.concat(truncatedNumberedLines, '\n')
			resp.truncated = true
			resp.endLine = maxLines
			resp.note = "Script truncated to first 1000 lines. Use startLine/endLine parameters to read specific sections."
		end

		if instance:IsA("BaseScript") then
			resp.enabled = instance.Enabled
		end
		return resp
	end)

	if success then
		return result
	else
		return { error = "Failed to get script source: " .. tostring(result) }
	end
end

ScriptHandlers.setScriptSource = function(requestData)
	local instancePath = requestData.instancePath
	local newSource = requestData.source

	if not instancePath or not newSource then
		return { error = "Instance path and source are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	if not instance:IsA("LuaSourceContainer") then
		return { error = "Instance is not a script-like object: " .. instance.ClassName }
	end

	-- Normalize escape sequences that may have been double-escaped
	local sourceToSet = newSource :: string
	-- Fix double-escaped newlines, tabs, etc.
	sourceToSet = sourceToSet:gsub("\\n", "\n")
	sourceToSet = sourceToSet:gsub("\\t", "\t")
	sourceToSet = sourceToSet:gsub("\\r", "\r")
	sourceToSet = sourceToSet:gsub("\\\\", "\\")
	local updateSuccess, updateResult = pcall(function()
		local oldSourceLength = string.len(readScriptSource(instance))

		ScriptEditorService:UpdateSourceAsync(instance, function(oldContent)
			return sourceToSet
		end)

		ChangeHistoryService:SetWaypoint("Set script source: " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			oldSourceLength = oldSourceLength,
			newSourceLength = string.len(sourceToSet),
			method = "UpdateSourceAsync",
			message = "Script source updated successfully (editor-safe)"
		}
	end)

	if updateSuccess then
		return updateResult
	end

	-- Fallback to direct assignment if UpdateSourceAsync fails
	local directSuccess, directResult = pcall(function()
		local oldSource = instance.Source
		instance.Source = sourceToSet

		ChangeHistoryService:SetWaypoint("Set script source: " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			oldSourceLength = string.len(oldSource),
			newSourceLength = string.len(sourceToSet),
			method = "direct",
			message = "Script source updated successfully (direct assignment)"
		}
	end)

	if directSuccess then
		return directResult
	end

	-- Final fallback: replace the script entirely
	local replaceSuccess, replaceResult = pcall(function()
		local parent = instance.Parent
		local name = instance.Name
		local className = instance.ClassName
		local wasBaseScript = instance:IsA("BaseScript")
		local enabled
		if wasBaseScript then
			enabled = instance.Enabled
		end

		local newScript = Instance.new(className)
		newScript.Name = name
		newScript.Source = sourceToSet
		if wasBaseScript then
			newScript.Enabled = enabled
		end

		newScript.Parent = parent
		instance:Destroy()

		ChangeHistoryService:SetWaypoint("Replace script: " .. name)

		return {
			success = true,
			instancePath = getInstancePath(newScript),
			method = "replace",
			message = "Script replaced successfully with new source"
		}
	end)

	if replaceSuccess then
		return replaceResult
	else
		return {
			error = "Failed to set script source. UpdateSourceAsync failed: " .. tostring(updateResult) ..
			        ". Direct assignment failed: " .. tostring(directResult) ..
			        ". Replace method failed: " .. tostring(replaceResult)
		}
	end
end

-- Partial Script Editing: Edit specific lines
ScriptHandlers.editScriptLines = function(requestData)
	local instancePath = requestData.instancePath
	local startLine = requestData.startLine
	local endLine = requestData.endLine
	local newContent = requestData.newContent

	if not instancePath or not startLine or not endLine or not newContent then
		return { error = "Instance path, startLine, endLine, and newContent are required" }
	end

	-- Normalize escape sequences that may have been double-escaped
	newContent = newContent:gsub("\\n", "\n")
	newContent = newContent:gsub("\\t", "\t")
	newContent = newContent:gsub("\\r", "\r")
	newContent = newContent:gsub("\\\\", "\\")

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	if not instance:IsA("LuaSourceContainer") then
		return { error = "Instance is not a script-like object: " .. instance.ClassName }
	end

	local success, result = pcall(function()
		local lines, hadTrailingNewline = splitLines(readScriptSource(instance))
		local totalLines = #lines

		if startLine < 1 or startLine > totalLines then
			error("startLine out of range (1-" .. totalLines .. ")")
		end
		if endLine < startLine or endLine > totalLines then
			error("endLine out of range (" .. startLine .. "-" .. totalLines .. ")")
		end

		-- Split new content into lines
		local newLines = select(1, splitLines(newContent))

		-- Build new source: lines before + new content + lines after
		local resultLines = {}

		-- Lines before the edit
		for i = 1, startLine - 1 do
			table.insert(resultLines, lines[i])
		end

		-- New content lines
		for _, line in ipairs(newLines) do
			table.insert(resultLines, line)
		end

		-- Lines after the edit
		for i = endLine + 1, totalLines do
			table.insert(resultLines, lines[i])
		end

		local newSource = joinLines(resultLines, hadTrailingNewline)

		-- Use UpdateSourceAsync for editor compatibility
		ScriptEditorService:UpdateSourceAsync(instance, function(oldContent)
			return newSource
		end)

		ChangeHistoryService:SetWaypoint("Edit script lines " .. startLine .. "-" .. endLine .. ": " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			editedLines = { startLine = startLine, endLine = endLine },
			linesRemoved = endLine - startLine + 1,
			linesAdded = #newLines,
			newLineCount = #resultLines,
			message = "Script lines edited successfully"
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to edit script lines: " .. tostring(result) }
	end
end

-- Partial Script Editing: Insert lines after a specific line
ScriptHandlers.insertScriptLines = function(requestData)
	local instancePath = requestData.instancePath
	local afterLine = requestData.afterLine or 0 -- 0 means insert at beginning
	local newContent = requestData.newContent

	if not instancePath or not newContent then
		return { error = "Instance path and newContent are required" }
	end

	-- Normalize escape sequences that may have been double-escaped
	newContent = newContent:gsub("\\n", "\n")
	newContent = newContent:gsub("\\t", "\t")
	newContent = newContent:gsub("\\r", "\r")
	newContent = newContent:gsub("\\\\", "\\")

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	if not instance:IsA("LuaSourceContainer") then
		return { error = "Instance is not a script-like object: " .. instance.ClassName }
	end

	local success, result = pcall(function()
		local lines, hadTrailingNewline = splitLines(readScriptSource(instance))
		local totalLines = #lines

		if afterLine < 0 or afterLine > totalLines then
			error("afterLine out of range (0-" .. totalLines .. ")")
		end

		-- Split new content into lines
		local newLines = select(1, splitLines(newContent))

		-- Build new source
		local resultLines = {}

		-- Lines before insertion point
		for i = 1, afterLine do
			table.insert(resultLines, lines[i])
		end

		-- New content lines
		for _, line in ipairs(newLines) do
			table.insert(resultLines, line)
		end

		-- Lines after insertion point
		for i = afterLine + 1, totalLines do
			table.insert(resultLines, lines[i])
		end

		local newSource = joinLines(resultLines, hadTrailingNewline)

		-- Use UpdateSourceAsync for editor compatibility
		ScriptEditorService:UpdateSourceAsync(instance, function(oldContent)
			return newSource
		end)

		ChangeHistoryService:SetWaypoint("Insert script lines after line " .. afterLine .. ": " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			insertedAfterLine = afterLine,
			linesInserted = #newLines,
			newLineCount = #resultLines,
			message = "Script lines inserted successfully"
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to insert script lines: " .. tostring(result) }
	end
end

-- Partial Script Editing: Delete specific lines
ScriptHandlers.deleteScriptLines = function(requestData)
	local instancePath = requestData.instancePath
	local startLine = requestData.startLine
	local endLine = requestData.endLine

	if not instancePath or not startLine or not endLine then
		return { error = "Instance path, startLine, and endLine are required" }
	end

	local instance = getInstanceByPath(instancePath)
	if not instance then
		return { error = "Instance not found: " .. instancePath }
	end

	if not instance:IsA("LuaSourceContainer") then
		return { error = "Instance is not a script-like object: " .. instance.ClassName }
	end

	local success, result = pcall(function()
		local lines, hadTrailingNewline = splitLines(readScriptSource(instance))
		local totalLines = #lines

		if startLine < 1 or startLine > totalLines then
			error("startLine out of range (1-" .. totalLines .. ")")
		end
		if endLine < startLine or endLine > totalLines then
			error("endLine out of range (" .. startLine .. "-" .. totalLines .. ")")
		end

		-- Build new source without the deleted lines
		local resultLines = {}

		for i = 1, startLine - 1 do
			table.insert(resultLines, lines[i])
		end

		for i = endLine + 1, totalLines do
			table.insert(resultLines, lines[i])
		end

		local newSource = joinLines(resultLines, hadTrailingNewline)

		-- Use UpdateSourceAsync for editor compatibility
		ScriptEditorService:UpdateSourceAsync(instance, function(oldContent)
			return newSource
		end)

		ChangeHistoryService:SetWaypoint("Delete script lines " .. startLine .. "-" .. endLine .. ": " .. instance.Name)

		return {
			success = true,
			instancePath = instancePath,
			deletedLines = { startLine = startLine, endLine = endLine },
			linesDeleted = endLine - startLine + 1,
			newLineCount = #resultLines,
			message = "Script lines deleted successfully"
		}
	end)

	if success then
		return result
	else
		return { error = "Failed to delete script lines: " .. tostring(result) }
	end
end

return ScriptHandlers
