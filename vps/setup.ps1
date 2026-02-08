# ==============================================
# ClaudeBlox VPS Setup Script
# Run this on Shadow PC after first connection
# ==============================================

$ErrorActionPreference = "Continue"

Write-Host @"

  ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗  ██╗
 ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗██╔╝
 ██║     ██║     ███████║██║   ██║██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚███╔╝
 ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝  ██╔══██╗██║     ██║   ██║ ██╔██╗
 ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗██████╔╝███████╗╚██████╔╝██╔╝ ██╗
  ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝╚═════╝ ╚══════╝ ╚═════╝ ╚═╝  ╚═╝

                         AUTONOMOUS ROBLOX GAME DEVELOPER
                               VPS SETUP SCRIPT

"@ -ForegroundColor Cyan

# ==============================================
# 0. Create folder structure
# ==============================================

Write-Host "`n[0/10] Creating folder structure..." -ForegroundColor Yellow

$folders = @(
    "C:\claudeblox",
    "C:\claudeblox\deploy",
    "C:\claudeblox\logs",
    "C:\claudeblox\screenshots",
    "C:\claudeblox\scripts"
)

foreach ($folder in $folders) {
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        Write-Host "  Created: $folder" -ForegroundColor Gray
    }
}

Write-Host "Folder structure ready" -ForegroundColor Green

# ==============================================
# 1. Install Git
# ==============================================

Write-Host "`n[1/10] Installing Git..." -ForegroundColor Yellow

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    winget install Git.Git --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Write-Host "Git: $(git --version)" -ForegroundColor Green

# ==============================================
# 2. Install Node.js LTS
# ==============================================

Write-Host "`n[2/10] Installing Node.js LTS..." -ForegroundColor Yellow

if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Write-Host "Node.js: $(node --version)" -ForegroundColor Green

# ==============================================
# 3. Install Python 3.12
# ==============================================

Write-Host "`n[3/10] Installing Python 3.12..." -ForegroundColor Yellow

if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Write-Host "Python: $(python --version)" -ForegroundColor Green

# Install Python dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Gray
pip install pyautogui pillow websocket-client psutil --quiet

# ==============================================
# 4. Install Claude Code CLI
# ==============================================

Write-Host "`n[4/10] Installing Claude Code CLI..." -ForegroundColor Yellow

npm install -g @anthropic-ai/claude-code
Write-Host "Claude Code installed" -ForegroundColor Green

# ==============================================
# 5. Install OBS Studio
# ==============================================

Write-Host "`n[5/10] Installing OBS Studio..." -ForegroundColor Yellow

if (!(Get-Command obs64 -ErrorAction SilentlyContinue)) {
    winget install OBSProject.OBSStudio --accept-source-agreements --accept-package-agreements
}

Write-Host "OBS Studio installed" -ForegroundColor Green

# ==============================================
# 6. Clone ClaudeBlox repository
# ==============================================

Write-Host "`n[6/10] Cloning ClaudeBlox repository..." -ForegroundColor Yellow

$repoUrl = Read-Host "Enter your ClaudeBlox git repository URL (or press Enter to skip)"

if ($repoUrl -ne "") {
    Set-Location "C:\claudeblox"
    git clone $repoUrl deploy
    Write-Host "Repository cloned to C:\claudeblox\deploy" -ForegroundColor Green
} else {
    Write-Host "Skipped - you'll need to manually copy files to C:\claudeblox\deploy" -ForegroundColor Yellow
}

# ==============================================
# 7. Install Roblox Studio
# ==============================================

Write-Host "`n[7/10] Installing Roblox Studio..." -ForegroundColor Yellow

$robloxInstaller = "$env:TEMP\RobloxStudioLauncherBeta.exe"
Invoke-WebRequest -Uri "https://setup.rbxcdn.com/RobloxStudioLauncherBeta.exe" -OutFile $robloxInstaller

Write-Host "Roblox Studio installer downloaded" -ForegroundColor Gray
Write-Host "Please run the installer manually: $robloxInstaller" -ForegroundColor Yellow
Write-Host "After installation, log in to Roblox Studio" -ForegroundColor Yellow

Start-Process $robloxInstaller
Read-Host "Press Enter after Roblox Studio is installed and you're logged in"

# ==============================================
# 8. Setup MCP
# ==============================================

Write-Host "`n[8/10] Setting up Roblox MCP..." -ForegroundColor Yellow

# Add Roblox MCP to Claude Code
claude mcp add robloxstudio -- npx robloxstudio-mcp

Write-Host "Roblox MCP added" -ForegroundColor Green

# ==============================================
# 9. Setup Twitter MCP (optional)
# ==============================================

Write-Host "`n[9/10] Setting up Twitter MCP..." -ForegroundColor Yellow

$setupTwitter = Read-Host "Do you want to setup Twitter integration? (y/n)"

if ($setupTwitter -eq "y") {
    # Create Twitter MCP directory
    $twitterDir = "C:\claudeblox\deploy\twitter_mcp"

    if (Test-Path $twitterDir) {
        Set-Location $twitterDir
        npm install

        Write-Host "Enter your Twitter API credentials:" -ForegroundColor Yellow
        $apiKey = Read-Host "API Key"
        $apiSecret = Read-Host "API Secret"
        $accessToken = Read-Host "Access Token"
        $accessSecret = Read-Host "Access Token Secret"

        # Create .env file
        @"
TWITTER_API_KEY=$apiKey
TWITTER_API_SECRET=$apiSecret
TWITTER_ACCESS_TOKEN=$accessToken
TWITTER_ACCESS_SECRET=$accessSecret
"@ | Out-File -FilePath "$twitterDir\.env" -Encoding UTF8

        # Add Twitter MCP to Claude
        claude mcp add twitter -- node "$twitterDir\server.js"

        Write-Host "Twitter MCP configured" -ForegroundColor Green
    } else {
        Write-Host "Twitter MCP directory not found. Skipping." -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipped Twitter setup" -ForegroundColor Gray
}

# ==============================================
# 10. Setup Auto-start
# ==============================================

Write-Host "`n[10/10] Setting up auto-start..." -ForegroundColor Yellow

# Create startup script
$startupScript = @'
# ClaudeBlox Startup Script
Start-Sleep -Seconds 10

# Start OBS
Start-Process "C:\Program Files\obs-studio\bin\64bit\obs64.exe" -ArgumentList "--startstreaming"

# Wait for OBS to load
Start-Sleep -Seconds 5

# Start Roblox Studio
$robloxPath = Get-ChildItem -Path "$env:LOCALAPPDATA\Roblox\Versions" -Filter "RobloxStudioBeta.exe" -Recurse | Select-Object -First 1
if ($robloxPath) {
    Start-Process $robloxPath.FullName
}

# Wait for Studio to load
Start-Sleep -Seconds 15

# Start watchdog
Set-Location "C:\claudeblox\deploy"
python watchdog\watchdog.py
'@

$startupScript | Out-File -FilePath "C:\claudeblox\startup.ps1" -Encoding UTF8

# Create scheduled task for auto-start
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\claudeblox\startup.ps1"
$trigger = New-ScheduledTaskTrigger -AtLogon
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "ClaudeBlox" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

Write-Host "Auto-start configured" -ForegroundColor Green

# ==============================================
# Done!
# ==============================================

Write-Host @"

==============================================
           SETUP COMPLETE!
==============================================

What was installed:
  - Git
  - Node.js
  - Python 3.12 + dependencies
  - Claude Code CLI
  - OBS Studio
  - Roblox MCP

Next steps:
  1. Open Roblox Studio
  2. Create new place or open existing Backrooms project
  3. Enable HTTP Requests in Game Settings
  4. Install MCP Plugin (search "Model Context Protocol" in Toolbox)
  5. Configure OBS:
     - Create scenes: CODING, PLAYING, BUILDING, IDLE
     - Enable WebSocket: Tools -> WebSocket Server Settings
     - Set password: claudeblox
     - Add sources (Display Capture)
     - Configure Kick stream key
  6. Start streaming in OBS
  7. Run: cd C:\claudeblox\deploy && claude

The AI will take over from there!

"@ -ForegroundColor Cyan

# Keep window open
Read-Host "Press Enter to exit"
