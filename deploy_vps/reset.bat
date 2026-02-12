@echo off
echo.
echo  ========================================
echo   CLAUDEBLOX - FULL RESET
echo  ========================================
echo.

echo Clearing gamemaster folder (state, architecture, bugs, logs)...
if exist "C:\claudeblox\gamemaster\state.json" del /q "C:\claudeblox\gamemaster\state.json"
if exist "C:\claudeblox\gamemaster\architecture.md" del /q "C:\claudeblox\gamemaster\architecture.md"
if exist "C:\claudeblox\gamemaster\buglist.md" del /q "C:\claudeblox\gamemaster\buglist.md"
if exist "C:\claudeblox\gamemaster\changelog.md" del /q "C:\claudeblox\gamemaster\changelog.md"
if exist "C:\claudeblox\gamemaster\roadmap.md" del /q "C:\claudeblox\gamemaster\roadmap.md"
if exist "C:\claudeblox\gamemaster\logs" rmdir /s /q "C:\claudeblox\gamemaster\logs"
mkdir "C:\claudeblox\gamemaster\logs"

echo Clearing screenshots (all cycle and showcase folders)...
if exist "C:\claudeblox\screenshots" rmdir /s /q "C:\claudeblox\screenshots"
mkdir "C:\claudeblox\screenshots"

echo Clearing logs...
if exist "C:\claudeblox\logs" rmdir /s /q "C:\claudeblox\logs"
mkdir "C:\claudeblox\logs"

echo Clearing runtime files...
if exist "C:\claudeblox\game_state.json" del /q "C:\claudeblox\game_state.json"
if exist "C:\claudeblox\actions.txt" del /q "C:\claudeblox\actions.txt"

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
echo   2. Run: run_forever.bat
echo.
pause
