# ClaudeBlox Update Script
# Copies files from deploy_vps to C:\claudeblox
# Run from the deploy_vps folder: powershell -ExecutionPolicy Bypass -File update.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CLAUDEBLOX - UPDATE FILES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$source = $PSScriptRoot  # Current folder (deploy_vps)
$dest = "C:\claudeblox"

# Check if source is valid
if (-not (Test-Path "$source\CLAUDE.md")) {
    Write-Host "ERROR: Run this script from the deploy_vps folder!" -ForegroundColor Red
    Write-Host "Current folder: $source"
    exit 1
}

# Check if destination exists
if (-not (Test-Path $dest)) {
    Write-Host "ERROR: C:\claudeblox not found! Run setup.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Source: $source"
Write-Host "Destination: $dest"
Write-Host ""

# Copy files
Write-Host "[1/7] Copying CLAUDE.md..." -ForegroundColor Green
Copy-Item "$source\CLAUDE.md" "$dest\CLAUDE.md" -Force

Write-Host "[2/7] Copying scripts..." -ForegroundColor Green
Copy-Item "$source\scripts\*" "$dest\scripts\" -Force -Recurse

Write-Host "[3/7] Copying stream overlay..." -ForegroundColor Green
Copy-Item "$source\stream\*" "$dest\stream\" -Force -Recurse

Write-Host "[4/7] Copying OBS assets..." -ForegroundColor Green
Copy-Item "$source\obs\*" "$dest\obs\" -Force -Recurse

Write-Host "[5/7] Copying agents..." -ForegroundColor Green
Copy-Item "$source\.claude\agents\*" "$dest\.claude\agents\" -Force -Recurse

Write-Host "[6/7] Copying skills..." -ForegroundColor Green
# Skills have subfolders
$skills = @("build-game", "test-game", "play-game", "dev-update")
foreach ($skill in $skills) {
    $skillPath = "$source\.claude\skills\$skill"
    if (Test-Path $skillPath) {
        Copy-Item "$skillPath\*" "$dest\.claude\skills\$skill\" -Force -Recurse
    }
}

Write-Host "[7/7] Copying batch files..." -ForegroundColor Green
Copy-Item "$source\run_forever.bat" "$dest\run_forever.bat" -Force
Copy-Item "$source\reset.bat" "$dest\reset.bat" -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  UPDATE COMPLETE!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Show what was copied
Write-Host "Files in C:\claudeblox:" -ForegroundColor Yellow
Get-ChildItem $dest -Recurse -File | Select-Object -First 20 | ForEach-Object {
    $relativePath = $_.FullName.Replace($dest, "")
    Write-Host "  $relativePath"
}
$count = (Get-ChildItem $dest -Recurse -File).Count
if ($count -gt 20) {
    Write-Host "  ... and $($count - 20) more files"
}

Write-Host ""
Write-Host "Ready to run: C:\claudeblox\run_forever.bat" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
