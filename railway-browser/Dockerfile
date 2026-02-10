FROM dorowu/ubuntu-desktop-lxde-vnc:focal

ENV RESOLUTION=1280x720
ENV VNC_PASSWORD=claudeblox
ENV USER=root

# sed is already in the image, no extra packages needed

COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
