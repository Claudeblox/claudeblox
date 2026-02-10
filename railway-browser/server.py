#!/usr/bin/env python3
"""
Simple HTTP proxy for Railway.
Proxies requests to noVNC running on localhost:6079.
"""
import os
import socket
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.request import urlopen, Request
from urllib.error import URLError

NOVNC_URL = "http://127.0.0.1:6079"
PORT = int(os.environ.get("PORT", 8080))


class ProxyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.proxy_request()

    def do_POST(self):
        self.proxy_request()

    def proxy_request(self):
        try:
            # Build target URL
            target = NOVNC_URL + self.path

            # Forward request
            req = Request(target)
            for key, val in self.headers.items():
                if key.lower() not in ('host', 'connection'):
                    req.add_header(key, val)

            resp = urlopen(req, timeout=10)

            # Send response
            self.send_response(resp.status)
            for key, val in resp.headers.items():
                if key.lower() not in ('transfer-encoding', 'connection'):
                    self.send_header(key, val)
            self.end_headers()
            self.wfile.write(resp.read())

        except URLError as e:
            self.send_response(502)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(f"noVNC not ready: {e}".encode())
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(f"Error: {e}".encode())

    def log_message(self, format, *args):
        print(f"[Proxy] {args[0]}")


def main():
    print(f"Starting proxy on port {PORT}")
    print(f"Proxying to {NOVNC_URL}")
    server = HTTPServer(('0.0.0.0', PORT), ProxyHandler)
    server.serve_forever()


if __name__ == "__main__":
    main()
