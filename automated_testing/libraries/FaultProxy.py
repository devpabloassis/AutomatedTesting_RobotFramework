"""HTTP proxy between the mobile app and the API, used by the mobile tests.

The app is opened with its API base URL pointing to this proxy (http://127.0.0.1:3101/api).
The proxy forwards every request to the test API and lets a test:

- inject a 500 error on a route (the mobile equivalent of Playwright's `page.route`);
- record the requests sent by the app (for example, to prove that no login request was sent).
"""

import http.client
import json
import re
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

from robot.api import logger
from robot.api.deco import keyword, library

INTERNAL_ERROR = json.dumps({"code": "INTERNAL_ERROR", "message": "Internal error."}).encode()


class _ProxyHandler(BaseHTTPRequestHandler):
    proxy = None  # set by FaultProxy

    def log_message(self, *args):  # keeps the console clean
        pass

    def _handle(self):
        proxy = self.proxy
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        with proxy.lock:
            proxy.requests.append((self.command, self.path))
            fault = next((pattern for pattern in proxy.faults if pattern.search(self.path)), None)

        if fault is not None:
            self._reply(500, {"Content-Type": "application/json; charset=utf-8"}, INTERNAL_ERROR)
            return

        connection = http.client.HTTPConnection(proxy.target.hostname, proxy.target.port, timeout=15)
        try:
            headers = {"Content-Type": self.headers.get("Content-Type", "application/json")} if body else {}
            connection.request(self.command, self.path, body=body, headers=headers)
            response = connection.getresponse()
            payload = response.read()
            self._reply(response.status, {"Content-Type": response.getheader("Content-Type", "")}, payload)
        except OSError:
            self._reply(502, {"Content-Type": "application/json"}, b'{"code":"BAD_GATEWAY","message":"API down."}')
        finally:
            connection.close()

    def _reply(self, status, headers, payload):
        self.send_response(status)
        for name, value in headers.items():
            self.send_header(name, value)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    do_GET = do_POST = do_PATCH = do_DELETE = do_PUT = _handle


@library(scope="GLOBAL")
class FaultProxy:
    def __init__(self):
        self.lock = threading.Lock()
        self.faults = []
        self.requests = []
        self.target = None
        self._server = None

    @keyword
    def start_fault_proxy(self, port: int, api_url: str) -> None:
        """Starts the proxy on 127.0.0.1:<port>, forwarding to the API at <api_url>."""
        if self._server:
            return
        self.target = urlsplit(api_url)
        handler = type("Handler", (_ProxyHandler,), {"proxy": self})
        self._server = ThreadingHTTPServer(("127.0.0.1", int(port)), handler)
        threading.Thread(target=self._server.serve_forever, daemon=True).start()
        logger.info(f"Fault proxy listening on 127.0.0.1:{port}, forwarding to {api_url}")

    @keyword
    def stop_fault_proxy(self) -> None:
        if self._server:
            self._server.shutdown()
            self._server.server_close()
            self._server = None

    @keyword
    def inject_server_error(self, path_pattern: str) -> None:
        """Every request whose path matches the regular expression returns 500 INTERNAL_ERROR."""
        with self.lock:
            self.faults.append(re.compile(path_pattern))

    @keyword
    def reset_fault_proxy(self) -> None:
        """Removes the injected failures and the recorded requests."""
        with self.lock:
            self.faults.clear()
            self.requests.clear()

    @keyword
    def clear_recorded_requests(self) -> None:
        with self.lock:
            self.requests.clear()

    @keyword
    def no_request_should_have_been_sent_to(self, path_pattern: str) -> None:
        pattern = re.compile(path_pattern)
        with self.lock:
            sent = [f"{method} {path}" for method, path in self.requests if pattern.search(path)]
        if sent:
            raise AssertionError(f"Unexpected request(s): {sent}")
