#!/bin/bash

PORT=${PORT:-8080}
echo "=== Railway PORT=$PORT, Kasm on 6901 ==="

# Start Kasm in background
/dockerstartup/kasm_default_profile.sh /dockerstartup/vnc_startup.sh &

# Wait for Kasm to start
echo "Waiting for Kasm VNC on 6901..."
sleep 10

# Forward Railway PORT to Kasm's 6901
echo "Starting socat: $PORT -> 6901"
exec socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:127.0.0.1:6901
