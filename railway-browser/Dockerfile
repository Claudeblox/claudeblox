FROM dorowu/ubuntu-desktop-lxde-vnc:focal

ENV RESOLUTION=1280x720
ENV VNC_PASSWORD=claudeblox
ENV USER=root

# Install socat for port forwarding
RUN rm -f /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
