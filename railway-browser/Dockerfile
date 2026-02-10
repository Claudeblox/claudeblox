FROM dorowu/ubuntu-desktop-lxde-vnc:focal

ENV RESOLUTION=1280x720
ENV VNC_PASSWORD=claudeblox
ENV USER=root

COPY server.py /server.py
COPY start.sh /start.sh
RUN chmod +x /start.sh /server.py

CMD ["/start.sh"]
