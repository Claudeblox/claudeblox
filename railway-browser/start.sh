#!/bin/bash

# Substitute PORT into nginx config
envsubst '${PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start the desktop environment in background
/startup.sh &

# Wait for noVNC to be ready
echo "Waiting for noVNC to start..."
sleep 10

# Start nginx on Railway's PORT
echo "Starting nginx on PORT=$PORT"
exec nginx -g 'daemon off;'
