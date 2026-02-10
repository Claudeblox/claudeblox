FROM kasmweb/chrome:1.15.0

USER root

# Kasm uses KASM_PORT, we need to map it to Railway's PORT
COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
