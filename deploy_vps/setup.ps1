# ClaudeBlox Setup Script for Shadow PC
# Run as Administrator: powershell -ExecutionPolicy Bypass -File setup.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CLAUDEBLOX - INITIAL SETUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some steps may fail." -ForegroundColor Yellow
}

# 1. Create folder structure
Write-Host "[1/6] Creating folder structure..." -ForegroundColor Green
$folders = @(
    "C:\claudeblox",
    "C:\claudeblox\scripts",
    "C:\claudeblox\screenshots",
    "C:\claudeblox\screenshots\good",
    "C:\claudeblox\logs",
    "C:\claudeblox\gamemaster",
    "C:\claudeblox\gamemaster\logs",
    "C:\claudeblox\stream",
    "C:\claudeblox\obs",
    "C:\claudeblox\.claude",
    "C:\claudeblox\.claude\agents",
    "C:\claudeblox\.claude\skills",
    "C:\claudeblox\.claude\skills\build-game",
    "C:\claudeblox\.claude\skills\test-game",
    "C:\claudeblox\.claude\skills\play-game",
    "C:\claudeblox\.claude\skills\dev-update"
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  Created: $folder"
    }
}
Write-Host "  Done!" -ForegroundColor Green

# 2. Check Python
Write-Host "[2/6] Checking Python..." -ForegroundColor Green
$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
    $version = python --version 2>&1
    Write-Host "  Found: $version"
} else {
    Write-Host "  ERROR: Python not found! Install from https://python.org" -ForegroundColor Red
    Write-Host "  Make sure to check 'Add Python to PATH' during installation"
    exit 1
}

# 3. Install Python packages
Write-Host "[3/6] Installing Python packages..." -ForegroundColor Green
$packages = @("pyautogui", "pywin32", "pillow", "obsws-python")
foreach ($pkg in $packages) {
    Write-Host "  Installing $pkg..."
    pip install $pkg --quiet 2>&1 | Out-Null
}
Write-Host "  Done!" -ForegroundColor Green

# 4. Check Node.js
Write-Host "[4/6] Checking Node.js..." -ForegroundColor Green
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $version = node --version 2>&1
    Write-Host "  Found: Node.js $version"
} else {
    Write-Host "  ERROR: Node.js not found! Install from https://nodejs.org" -ForegroundColor Red
    exit 1
}

# 5. Install Claude Code
Write-Host "[5/6] Installing Claude Code..." -ForegroundColor Green
$claude = Get-Command claude -ErrorAction SilentlyContinue
if ($claude) {
    Write-Host "  Claude Code already installed"
} else {
    Write-Host "  Installing via npm..."
    npm install -g @anthropic-ai/claude-code 2>&1 | Out-Null
    Write-Host "  Done!"
}

# 6. Instructions
Write-Host "[6/6] Next steps..." -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: .\update.ps1 - to copy files from repo to C:\claudeblox"
Write-Host "2. Set ANTHROPIC_API_KEY environment variable"
Write-Host "3. Configure MCP server in Claude Code settings"
Write-Host "4. Open Roblox Studio with MCP plugin"
Write-Host "5. Configure OBS (add thoughts.html to PLAYING scene)"
Write-Host "6. Run: C:\claudeblox\run_forever.bat"
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
