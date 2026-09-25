#!/usr/bin/env bash
set -euo pipefail

UNIT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/acs730-web.service"
APP_DIR=/opt/acs730-web
APP_USER=acs730web
TMP_APP="$(mktemp)"
trap 'rm -f "$TMP_APP"' EXIT

sudo dnf install -y python3

if ! id "$APP_USER" >/dev/null 2>&1; then
    sudo useradd --system --user-group --no-create-home \
        --shell /sbin/nologin "$APP_USER"
fi

sudo install -d -o "$APP_USER" -g "$APP_USER" -m 0755 "$APP_DIR"

cat > "$TMP_APP" <<'PY'
from datetime import datetime, timezone
from html import escape
from http.server import BaseHTTPRequestHandler, HTTPServer
from socket import gethostname


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ("/", "/health"):
            self.send_error(404)
            return

        if self.path == "/health":
            body = "ok\n"
            content_type = "text/plain; charset=utf-8"
        else:
            now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
            body = (
                "<!doctype html><html><body>"
                "<h1>ACS730 web application</h1>"
                f"<p>Host: {escape(gethostname())}</p>"
                f"<p>Current server time: {now}</p>"
                "</body></html>\n"
            )
            content_type = "text/html; charset=utf-8"

        data = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


HTTPServer(("0.0.0.0", 80), Handler).serve_forever()
PY

sudo install -o "$APP_USER" -g "$APP_USER" -m 0644 "$TMP_APP" "$APP_DIR/app.py"
sudo install -o root -g root -m 0644 "$UNIT_SOURCE" \
    /etc/systemd/system/acs730-web.service

sudo systemctl daemon-reload
sudo systemctl enable acs730-web

if sudo systemctl is-active --quiet acs730-web; then
    sudo systemctl restart acs730-web
else
    sudo systemctl start acs730-web
fi

sudo systemctl --no-pager status acs730-web
