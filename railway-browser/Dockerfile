FROM dorowu/ubuntu-desktop-lxde-vnc:focal

ENV RESOLUTION=1280x720
ENV VNC_PASSWORD=claudeblox
ENV USER=root

# Install nginx for WebSocket proxying
RUN apt-get update && apt-get install -y nginx gettext-base && rm -rf /var/lib/apt/lists/*

# Copy configs
COPY nginx.conf /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
