"""Default settings of the test run. Every value can be overridden with `-v NAME:value`
(or through the options of run.py)."""

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = PROJECT_ROOT.parent

# System under test: the API is started by the test run, with a clean database.
TEST_PORT = int(os.environ.get("TEST_PORT", "3100"))
API_URL = f"http://127.0.0.1:{TEST_PORT}/api"
TEST_DB_PATH = str(PROJECT_ROOT / ".test-data" / "db.json")
API_SERVER_SCRIPT = str(REPOSITORY_ROOT / "application" / "src_api" / "server.js")

# The mobile app talks to the API through a local proxy that can inject failures and record
# requests. On Android, `adb reverse` maps these ports from the device to this computer.
PROXY_PORT = int(os.environ.get("PROXY_PORT", "3101"))
APP_API_URL = f"http://127.0.0.1:{PROXY_PORT}/api"

# Mobile
PLATFORM = os.environ.get("PLATFORM", "android")
DEVICE_UDID = os.environ.get("DEVICE_UDID", "")
APPIUM_URL = os.environ.get("APPIUM_URL", "http://127.0.0.1:4723")
ANDROID_APP = str(REPOSITORY_ROOT / "application" / "public" / "food-marketplace.apk")
IOS_APP = str(REPOSITORY_ROOT / "application" / "public" / "FoodMarketplace.app")
APP_PACKAGE = "com.foodmarketplace.app"
APP_ACTIVITY = ".MainActivity"
IOS_BUNDLE_ID = "com.foodmarketplace.app"

# Timeouts
UI_TIMEOUT = "10s"
