FROM kasmweb/chrome:1.15.0

USER root

# Install socat for port forwarding
RUN apt-get update && apt-get install -y socat && rm -rf /var/lib/apt/lists/*

COPY start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
