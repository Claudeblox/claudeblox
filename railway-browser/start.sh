#!/bin/bash

# Start the desktop environment in background
/startup.sh &

# Wait for noVNC to be ready (simple sleep)
echo "Waiting for noVNC to start..."
sleep 10

# Start our proxy server on Railway's PORT
echo "Starting proxy on PORT=$PORT"
exec python3 /server.py
