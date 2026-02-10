FROM dorowu/ubuntu-desktop-lxde-vnc:focal

ENV RESOLUTION=1280x720
ENV VNC_PASSWORD=claudeblox
ENV USER=root

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY server.py /server.py
COPY start.sh /start.sh
RUN chmod +x /start.sh /server.py

CMD ["/start.sh"]
