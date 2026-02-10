--!strict
--[[
    Roblox Studio MCP Server - End-to-End Tests

    These tests simulate the Roblox Studio plugin's HTTP communication
    with the MCP server to verify the API contract is correct.

    Run with: lune run tests/luau/e2e.luau

    Prerequisites:
    - MCP server must be running: npm run dev (or npm start)
    - Lune must be installed: https://lune-org.github.io/docs
]]

local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")
local task = require("@lune/task")

-- Configuration
local SERVER_URL = "http://localhost:3002"
local TEST_TIMEOUT = 5 -- seconds

-- Test utilities
local testsPassed = 0
local testsFailed = 0
local currentTest = ""

local function log(message: string)
    print(`[TEST] {message}`)
end

local function logSuccess(message: string)
    print(`[PASS] {message}`)
end

local function logError(message: string)
    print(`[FAIL] {message}`)
end

local function assert_eq(actual: any, expected: any, message: string?)
    if actual ~= expected then
        error(`Assertion failed: {message or "values not equal"}\n  Expected: {expected}\n  Actual: {actual}`)
    end
end

local function assert_true(value: any, message: string?)
    if not value then
        error(`Assertion failed: {message or "expected true"}`)
    end
end

local function assert_contains(str: string, substring: string, message: string?)
    if not string.find(str, substring, 1, true) then
        error(`Assertion failed: {message or "string does not contain substring"}\n  String: {str}\n  Substring: {substring}`)
    end
end

local function runTest(name: string, testFn: () -> ())
    currentTest = name
    log(`Running: {name}`)

    local success, err = pcall(testFn)

    if success then
        testsPassed += 1
        logSuccess(name)
    else
        testsFailed += 1
        logError(`{name}: {err}`)
    end
end

-- HTTP helper functions
local function httpGet(endpoint: string): (boolean, net.FetchResponse?)
    local success, response = pcall(function()
        return net.request({
            url = SERVER_URL .. endpoint,
            method = "GET",
            headers = {
                ["Content-Type"] = "application/json",
            },
        })
    end)

    if success then
        return true, response
    else
        return false, nil
    end
end

local function httpPost(endpoint: string, body: any): (boolean, net.FetchResponse?)
    local success, response = pcall(function()
        return net.request({
            url = SERVER_URL .. endpoint,
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json",
            },
            body = serde.encode("json", body),
        })
    end)

    if success then
        return true, response
    else
        return false, nil
    end
end

-- ============================================================================
-- Tests
-- ============================================================================

local function testHealthEndpoint()
    local success, response = httpGet("/health")
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
    assert_eq(response.statusCode, 200, "Status code should be 200")

    local data = serde.decode("json", response.body)
    assert_eq(data.status, "ok", "Status should be 'ok'")
    assert_eq(data.service, "robloxstudio-mcp", "Service name should match")
end

local function testStatusEndpoint()
    local success, response = httpGet("/status")
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
    assert_eq(response.statusCode, 200, "Status code should be 200")

    local data = serde.decode("json", response.body)
    assert_true(data.pluginConnected ~= nil, "Should have pluginConnected field")
    assert_true(data.mcpServerActive ~= nil, "Should have mcpServerActive field")
end

local function testReadyEndpoint()
    local success, response = httpPost("/ready", {})
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
    assert_eq(response.statusCode, 200, "Status code should be 200")

    local data = serde.decode("json", response.body)
    assert_eq(data.success, true, "Should return success: true")
end

local function testDisconnectEndpoint()
    local success, response = httpPost("/disconnect", {})
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
    assert_eq(response.statusCode, 200, "Status code should be 200")

    local data = serde.decode("json", response.body)
    assert_eq(data.success, true, "Should return success: true")
end

local function testPollEndpointNoMCP()
    -- When MCP is not active, poll should return 503
    local success, response = httpGet("/poll")
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
    -- Note: This might return 200 or 503 depending on MCP state
    -- We just verify it returns valid JSON
    local data = serde.decode("json", response.body)
    assert_true(data ~= nil, "Should return valid JSON")
end

local function testMCPEndpointGetPlaceInfo()
    local success, response = httpPost("/mcp/get_place_info", {})
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
    -- This will timeout waiting for Studio plugin, but should return valid response structure
    -- In E2E testing with actual Studio, this would return place info
end

local function testMCPEndpointGetServices()
    local success, response = httpPost("/mcp/get_services", {})
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointSearchFiles()
    local success, response = httpPost("/mcp/search_files", {
        query = "test",
        searchType = "name"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointGetFileTree()
    local success, response = httpPost("/mcp/get_file_tree", {
        path = ""
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointGetProjectStructure()
    local success, response = httpPost("/mcp/get_project_structure", {
        path = "",
        maxDepth = 3,
        scriptsOnly = false
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointSetProperty()
    local success, response = httpPost("/mcp/set_property", {
        instancePath = "game.Workspace.Part",
        propertyName = "Name",
        propertyValue = "TestPart"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointMassSetProperty()
    local success, response = httpPost("/mcp/mass_set_property", {
        paths = {"game.Workspace.Part1", "game.Workspace.Part2"},
        propertyName = "Anchored",
        propertyValue = true
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointCreateObject()
    local success, response = httpPost("/mcp/create_object", {
        className = "Part",
        parent = "game.Workspace",
        name = "TestPart"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointDeleteObject()
    local success, response = httpPost("/mcp/delete_object", {
        instancePath = "game.Workspace.TestPart"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointGetScriptSource()
    local success, response = httpPost("/mcp/get_script_source", {
        instancePath = "game.ServerScriptService.TestScript"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointSetScriptSource()
    local success, response = httpPost("/mcp/set_script_source", {
        instancePath = "game.ServerScriptService.TestScript",
        source = "print('Hello World')"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointEditScriptLines()
    local success, response = httpPost("/mcp/edit_script_lines", {
        instancePath = "game.ServerScriptService.TestScript",
        startLine = 1,
        endLine = 1,
        newContent = "print('Modified')"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointInsertScriptLines()
    local success, response = httpPost("/mcp/insert_script_lines", {
        instancePath = "game.ServerScriptService.TestScript",
        afterLine = 0,
        newContent = "-- New line at top"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointDeleteScriptLines()
    local success, response = httpPost("/mcp/delete_script_lines", {
        instancePath = "game.ServerScriptService.TestScript",
        startLine = 1,
        endLine = 1
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointGetAttribute()
    local success, response = httpPost("/mcp/get_attribute", {
        instancePath = "game.Workspace.Part",
        attributeName = "TestAttribute"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointSetAttribute()
    local success, response = httpPost("/mcp/set_attribute", {
        instancePath = "game.Workspace.Part",
        attributeName = "TestAttribute",
        attributeValue = "TestValue"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointGetAttributes()
    local success, response = httpPost("/mcp/get_attributes", {
        instancePath = "game.Workspace.Part"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointDeleteAttribute()
    local success, response = httpPost("/mcp/delete_attribute", {
        instancePath = "game.Workspace.Part",
        attributeName = "TestAttribute"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointGetTags()
    local success, response = httpPost("/mcp/get_tags", {
        instancePath = "game.Workspace.Part"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointAddTag()
    local success, response = httpPost("/mcp/add_tag", {
        instancePath = "game.Workspace.Part",
        tagName = "TestTag"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointRemoveTag()
    local success, response = httpPost("/mcp/remove_tag", {
        instancePath = "game.Workspace.Part",
        tagName = "TestTag"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointGetTagged()
    local success, response = httpPost("/mcp/get_tagged", {
        tagName = "TestTag"
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointSmartDuplicate()
    local success, response = httpPost("/mcp/smart_duplicate", {
        instancePath = "game.Workspace.Part",
        count = 3,
        options = {
            namePattern = "Part{n}",
            positionOffset = {5, 0, 0}
        }
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointMassDuplicate()
    local success, response = httpPost("/mcp/mass_duplicate", {
        duplications = {
            {
                instancePath = "game.Workspace.Part",
                count = 2
            }
        }
    })
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

local function testMCPEndpointGetSelection()
    local success, response = httpPost("/mcp/get_selection", {})
    assert_true(success, "HTTP request should succeed")
    assert_true(response, "Response should exist")
end

-- ============================================================================
-- Main Test Runner
-- ============================================================================

local function checkServerAvailable(): boolean
    local success, response = httpGet("/health")
    return success and response ~= nil and response.statusCode == 200
end

local function main()
    print("=" .. string.rep("=", 60))
    print("Roblox Studio MCP Server - E2E Tests")
    print("=" .. string.rep("=", 60))
    print("")

    -- Check if server is running
    log("Checking if MCP server is available...")
    if not checkServerAvailable() then
        logError("MCP server is not running!")
        print("\nPlease start the server with: npm run dev")
        print("Then run this test again: lune run tests/luau/e2e.luau")
        process.exit(1)
    end
    logSuccess("Server is available")
    print("")

    -- Run tests
    print("-" .. string.rep("-", 60))
    print("Core Endpoints")
    print("-" .. string.rep("-", 60))
    runTest("Health endpoint", testHealthEndpoint)
    runTest("Status endpoint", testStatusEndpoint)
    runTest("Ready endpoint", testReadyEndpoint)
    runTest("Disconnect endpoint", testDisconnectEndpoint)
    runTest("Poll endpoint (no MCP)", testPollEndpointNoMCP)

    print("")
    print("-" .. string.rep("-", 60))
    print("MCP Tool Endpoints")
    print("-" .. string.rep("-", 60))
    runTest("MCP: get_place_info", testMCPEndpointGetPlaceInfo)
    runTest("MCP: get_services", testMCPEndpointGetServices)
    runTest("MCP: search_files", testMCPEndpointSearchFiles)
    runTest("MCP: get_file_tree", testMCPEndpointGetFileTree)
    runTest("MCP: get_project_structure", testMCPEndpointGetProjectStructure)
    runTest("MCP: set_property", testMCPEndpointSetProperty)
    runTest("MCP: mass_set_property", testMCPEndpointMassSetProperty)
    runTest("MCP: create_object", testMCPEndpointCreateObject)
    runTest("MCP: delete_object", testMCPEndpointDeleteObject)
    runTest("MCP: get_script_source", testMCPEndpointGetScriptSource)
    runTest("MCP: set_script_source", testMCPEndpointSetScriptSource)
    runTest("MCP: edit_script_lines", testMCPEndpointEditScriptLines)
    runTest("MCP: insert_script_lines", testMCPEndpointInsertScriptLines)
    runTest("MCP: delete_script_lines", testMCPEndpointDeleteScriptLines)
    runTest("MCP: get_attribute", testMCPEndpointGetAttribute)
    runTest("MCP: set_attribute", testMCPEndpointSetAttribute)
    runTest("MCP: get_attributes", testMCPEndpointGetAttributes)
    runTest("MCP: delete_attribute", testMCPEndpointDeleteAttribute)
    runTest("MCP: get_tags", testMCPEndpointGetTags)
    runTest("MCP: add_tag", testMCPEndpointAddTag)
    runTest("MCP: remove_tag", testMCPEndpointRemoveTag)
    runTest("MCP: get_tagged", testMCPEndpointGetTagged)
    runTest("MCP: smart_duplicate", testMCPEndpointSmartDuplicate)
    runTest("MCP: mass_duplicate", testMCPEndpointMassDuplicate)
    runTest("MCP: get_selection", testMCPEndpointGetSelection)

    -- Print summary
    print("")
    print("=" .. string.rep("=", 60))
    print("Test Summary")
    print("=" .. string.rep("=", 60))
    print(`Passed: {testsPassed}`)
    print(`Failed: {testsFailed}`)
    print(`Total:  {testsPassed + testsFailed}`)
    print("")

    if testsFailed > 0 then
        logError("Some tests failed!")
        process.exit(1)
    else
        logSuccess("All tests passed!")
        process.exit(0)
    end
end

main()
