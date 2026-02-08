# ==============================================
# ClaudeBlox - Start Claude Code on VPS
# ==============================================

param(
    [Parameter()]
    [ValidateSet("build", "play", "test", "dev-update", "publish")]
    [string]$Action = "build"
)

$WorkDir = "C:\claudeblox\workspace"
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

Write-Host "=== ClaudeBlox: $Action ===" -ForegroundColor Cyan

# Define prompts for each action
$prompts = @{
    "build" = @"
You are ClaudeBlox. You have access to Roblox Studio via MCP tools (robloxstudio).

Your task: Build a complete Roblox game from scratch.

Use the development cycle:
1. Design the game architecture (genre, core loop, services)
2. Create scripts via MCP run_code (ServerScriptService, ReplicatedStorage, StarterGui)
3. Build the 3D world (terrain, parts, lighting)
4. Test everything works

Available MCP tools: run_code, create_script, edit_script, insert_model, get_children, etc.

Start building NOW. Pick an interesting game genre and go.
"@

    "play" = @"
You are ClaudeBlox computer-player. You can SEE the screen and INTERACT with Roblox Studio.

Your tools:
- Bash: python C:\claudeblox\screenshot.py  (saves screen.png)
- Read: C:\claudeblox\screen.png  (you see the screenshot)
- Bash: python C:\claudeblox\action.py --click X Y
- Bash: python C:\claudeblox\action.py --key W/A/S/D/space
- Bash: python C:\claudeblox\action.py --hold W 2.0

PLAY LOOP (repeat 20-50 times):
1. Take screenshot
2. Read it (you're multimodal)
3. Decide action
4. Execute action
5. Repeat

First: Make sure Play mode is active in Studio. If not, click the Play button.
Then: Play the game! Move around, interact, test everything.
"@

    "test" = @"
You are ClaudeBlox tester. Test the current game in Roblox Studio via MCP.

1. Use run_code to check all scripts have source
2. Use run_code to verify RemoteEvents exist
3. Use run_code to test game loads properly
4. Use run_code to simulate player actions
5. Check for errors in output

Report results as PASS/FAIL with details.
"@

    "dev-update" = @"
You are claudezilla. Post a development update to Twitter about the current Roblox game being built.

Check the current state of the game via MCP, then write a tweet in your casual gamer voice.
Use the post_tweet tool to post it.
"@

    "publish" = @"
Publish the current Roblox game:
1. Generate cover art via generate_cover tool
2. Add to database via add_game_to_database with platform: "roblox"
3. Post announcement to Twitter via claudezilla

Do all three steps.
"@
}

$prompt = $prompts[$Action]

Write-Host "Starting Claude Code with action: $Action" -ForegroundColor Yellow
Write-Host "Prompt length: $($prompt.Length) chars" -ForegroundColor Gray

# Run Claude Code
claude -p $prompt `
    --max-turns 100 `
    --dangerously-skip-permissions `
    --output-format json

Write-Host "`n=== $Action Complete ===" -ForegroundColor Cyan
