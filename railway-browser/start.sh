#!/bin/bash

PORT=${PORT:-8080}
echo "=== Railway PORT=$PORT ==="

# Start desktop in background
/startup.sh &

# Wait for internal nginx to be ready on port 80
echo "Waiting for nginx on port 80..."
sleep 5

# Forward Railway's PORT to internal nginx on 80
echo "Starting socat: $PORT -> 80"
exec socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:127.0.0.1:80
