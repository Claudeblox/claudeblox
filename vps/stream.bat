@echo off
REM ==============================================
REM ClaudeBlox - Stream to Kick/PumpFun via RTMP
REM Requires: OBS Studio or FFmpeg
REM ==============================================

echo === ClaudeBlox Stream ===

REM Set your stream keys here
set KICK_RTMP=rtmps://fa723fc1b171.global-contribute.live-video.net/app/
set KICK_KEY=your_kick_stream_key_here

set PUMPFUN_RTMP=rtmp://stream.pump.fun/live/
set PUMPFUN_KEY=your_pumpfun_stream_key_here

REM Option 1: FFmpeg direct capture (no OBS needed)
REM Captures entire screen at 30fps, 720p
echo Starting FFmpeg stream...
ffmpeg -f gdigrab -framerate 30 -i desktop ^
    -c:v libx264 -preset veryfast -b:v 2500k -maxrate 2500k -bufsize 5000k ^
    -vf "scale=1280:720" ^
    -c:a aac -b:a 128k -ar 44100 ^
    -f flv "%KICK_RTMP%%KICK_KEY%"

REM Option 2: Multi-stream (uncomment to use)
REM ffmpeg -f gdigrab -framerate 30 -i desktop ^
REM     -c:v libx264 -preset veryfast -b:v 2500k ^
REM     -f flv "%KICK_RTMP%%KICK_KEY%" ^
REM     -f flv "%PUMPFUN_RTMP%%PUMPFUN_KEY%"

echo Stream ended.
pause
