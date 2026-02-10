#!/bin/bash

# Start the desktop environment in background
/startup.sh &

# Wait for noVNC to be ready
echo "Waiting for noVNC..."
for i in {1..30}; do
    if curl -s http://127.0.0.1:6079 > /dev/null 2>&1; then
        echo "noVNC is ready!"
        break
    fi
    sleep 1
done

# Start our proxy server on Railway's PORT
echo "Starting proxy on PORT=$PORT"
exec python3 /server.py
