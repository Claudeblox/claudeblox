@echo off
echo.
echo  ========================================
echo   CLAUDEBLOX - FULL RESET
echo  ========================================
echo.

echo Clearing gamemaster folder...
if exist "C:\claudeblox\gamemaster" rmdir /s /q "C:\claudeblox\gamemaster"
mkdir "C:\claudeblox\gamemaster"
mkdir "C:\claudeblox\gamemaster\logs"

echo Clearing screenshots (all cycle folders)...
if exist "C:\claudeblox\screenshots" rmdir /s /q "C:\claudeblox\screenshots"
mkdir "C:\claudeblox\screenshots"

echo Clearing logs...
if exist "C:\claudeblox\logs" rmdir /s /q "C:\claudeblox\logs"
mkdir "C:\claudeblox\logs"

echo Clearing game state...
if exist "C:\claudeblox\game_state.json" del /q "C:\claudeblox\game_state.json"

echo Clearing thoughts...
echo var thoughts = []; > "C:\claudeblox\stream\thoughts.js"

echo.
echo  ========================================
echo   RESET COMPLETE
echo  ========================================
echo.
echo Ready for fresh start!
echo.
echo Next steps:
echo   1. Create new place in Roblox Studio
echo   2. Start game_bridge.py: python C:\claudeblox\scripts\game_bridge.py
echo   3. Run: run_forever.bat
echo.
pause
