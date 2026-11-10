"""Robot Framework library that provides the API used by the whole test run."""

import sys
from pathlib import Path

from robot.api import logger
from robot.api.deco import keyword, library

sys.path.insert(0, str(Path(__file__).parent))
from server_process import ServerProcess, is_api_up  # noqa: E402


@library(scope="GLOBAL")
class TestServer:
    """Starts the API on the test port with a clean database, unless it is already running.

    run.py starts the server once before Robot Framework (needed for parallel runs with pabot).
    When a suite is executed directly with `robot`, this library starts and stops the server itself.
    """

    def __init__(self):
        self._server = None

    @keyword
    def ensure_test_server_is_running(self, script: str, port: int, db_path: str) -> None:
        server = ServerProcess(script, port, db_path)
        if is_api_up(server.url):
            logger.info(f"Using the API that is already running at {server.url}")
            return
        logger.info(f"Starting the API at {server.url} with a clean database ({db_path})")
        server.start(clean_database=True)
        self._server = server

    @keyword
    def stop_test_server(self) -> None:
        """Stops the server only if this library started it."""
        if self._server:
            self._server.stop()
            self._server = None
