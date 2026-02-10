#!/bin/bash

# Railway sets PORT env variable
# The base image uses HTTP_PORT to configure the web interface port
export HTTP_PORT=${PORT:-80}

# Start the desktop with correct port
exec /startup.sh
