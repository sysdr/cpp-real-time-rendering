#!/usr/bin/env python3
"""Dashboard server: serves static files and /run-demo to run ./start.sh."""
import http.server
import json
import os
import subprocess
import sys

PORT = int(os.environ.get("DASHBOARD_PORT", "8769"))
BIND = os.environ.get("DASHBOARD_BIND", "127.0.0.1")
PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))

class DashboardHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split("?")[0].lstrip("/") or "dashboard.html"
        if path == "run-demo":
            self._run_demo()
            return
        filepath = os.path.join(PROJECT_DIR, path)
        if ".." in path or not os.path.abspath(filepath).startswith(PROJECT_DIR):
            self.send_error(404)
            return
        if os.path.isfile(filepath):
            self._serve_file(filepath, path)
        else:
            self.send_error(404)
    def _serve_file(self, filepath, path):
        content_type = "application/octet-stream"
        if path.endswith(".html"): content_type = "text/html; charset=utf-8"
        elif path.endswith(".json"): content_type = "application/json"
        try:
            with open(filepath, "rb") as f: data = f.read()
        except OSError:
            self.send_error(500)
            return
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)
    def _run_demo(self):
        start_sh = os.path.join(PROJECT_DIR, "start.sh")
        if not os.path.isfile(start_sh) or not os.access(start_sh, os.X_OK):
            self._send_json({"stdout": "", "stderr": "start.sh not found or not executable.", "returncode": -1})
            return
        try:
            r = subprocess.run(["./start.sh"], cwd=PROJECT_DIR, capture_output=True, text=True, timeout=120, env={**os.environ})
            self._send_json({"stdout": r.stdout or "", "stderr": r.stderr or "", "returncode": r.returncode})
        except subprocess.TimeoutExpired:
            self._send_json({"stdout": "", "stderr": "Command timed out.", "returncode": -1})
        except Exception as e:
            self._send_json({"stdout": "", "stderr": str(e), "returncode": -1})
    def _send_json(self, obj):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, format, *args):
        sys.stderr.write("%s - - [%s] %s\n" % (self.address_string(), self.log_date_time_string(), format % args))

def main():
    with http.server.HTTPServer((BIND, PORT), DashboardHandler) as httpd:
        print("Dashboard at http://%s:%s/dashboard.html" % (BIND, PORT), flush=True)
        httpd.serve_forever()
if __name__ == "__main__":
    main()
