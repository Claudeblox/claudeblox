@echo off
echo.
echo  ========================================
echo   CLAUDEBLOX - RESET FOR NEW SESSION
echo  ========================================
echo.

echo Clearing gamemaster folder...
del /q "C:\claudeblox\gamemaster\*" 2>nul
del /q "C:\claudeblox\gamemaster\logs\*" 2>nul

echo Clearing logs...
del /q "C:\claudeblox\logs\*" 2>nul

echo Clearing screenshots...
del /q "C:\claudeblox\screenshots\*" 2>nul

echo.
echo Done! Ready for fresh start.
echo Run: run_forever.bat
echo.
pause
