"""Starts and stops the Food Marketplace API (application/src_api/server.js) as a child process."""

import os
import socket
import subprocess
import time
import urllib.error
import urllib.request
from pathlib import Path


def is_api_up(api_url: str) -> bool:
    try:
        with urllib.request.urlopen(f"{api_url}/companies", timeout=1) as response:
            return response.status == 200
    except (urllib.error.URLError, OSError):
        return False


def free_port() -> int:
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        return probe.getsockname()[1]


class ServerProcess:
    """One API server with its own port and database file."""

    def __init__(self, script: str, port: int, db_path: str):
        self.script = script
        self.port = int(port)
        self.db_path = str(db_path)
        self.url = f"http://127.0.0.1:{self.port}/api"
        self._process = None

    def start(self, clean_database: bool = False, timeout: float = 15.0) -> None:
        if clean_database:
            Path(self.db_path).unlink(missing_ok=True)
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        environment = {**os.environ, "PORT": str(self.port), "DB_PATH": self.db_path, "HOST": "127.0.0.1"}
        self._process = subprocess.Popen(
            ["node", self.script],
            env=environment,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if self._process.poll() is not None:
                raise RuntimeError(f"The API server exited during start-up (port {self.port} may be in use).")
            if is_api_up(self.url):
                return
            time.sleep(0.1)
        self.stop()
        raise RuntimeError(f"The API server did not start on port {self.port}.")

    def stop(self) -> None:
        if self._process and self._process.poll() is None:
            self._process.terminate()
            try:
                self._process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self._process.kill()
        self._process = None

    def restart(self) -> None:
        self.stop()
        self.start()
