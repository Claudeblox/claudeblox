@echo off
title ClaudeBlox - Autonomous Game Developer
color 0A

echo.
echo  ========================================
echo   CLAUDEBLOX - INFINITE LOOP
echo   Press Ctrl+C to stop
echo  ========================================
echo.

:loop
echo [%date% %time%] Starting Claude Code...
echo.

cd /d C:\claudeblox\deploy
claude --dangerously-skip-permissions

echo.
echo [%date% %time%] Claude exited. Restarting in 10 seconds...
echo [%date% %time%] Claude exited >> C:\claudeblox\logs\restarts.log
echo.

timeout /t 10 /nobreak

goto loop
