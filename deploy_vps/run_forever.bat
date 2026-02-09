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

cd /d C:\claudeblox

REM Start Claude with initial prompt as argument
claude "Read CLAUDE.md and start working. If gamemaster/state.json exists, continue from where you left off. If not, start fresh. Tweet that you are back online, then begin the build cycle. GO." --model sonnet --dangerously-skip-permissions

echo.
echo [%date% %time%] Claude exited. Restarting in 10 seconds...
echo [%date% %time%] Claude exited >> C:\claudeblox\logs\restarts.log
echo.

timeout /t 10 /nobreak

goto loop
