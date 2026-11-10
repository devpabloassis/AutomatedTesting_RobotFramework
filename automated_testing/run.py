#!/usr/bin/env python3
"""Test runner for the Food Marketplace suites (API + mobile).

Without options it runs every test (API and mobile) on the connected device:
the platform is detected automatically and, on Android, the first device listed by
`adb devices` is used.

Examples:
    python run.py                                   # everything, first connected device
    python run.py --platform android --device emulator-5554
    python run.py --platform ios --device <simulator-udid>
    python run.py --suite api --include smoke       # API smoke tests only
    python run.py --suite mobile --include feature_cart --exclude known_bug
    python run.py --test "TC-MOB-CRT-004*"          # a single test by id
    python run.py --list-devices
    python run.py -- --loglevel DEBUG               # anything after -- goes to Robot Framework

What the runner does:
    1. resolves the platform and the device (only when mobile tests are selected);
    2. starts the API on port 3100 with a clean database;
    3. starts a local Appium server if none is running at --appium-url;
    4. runs the API suite in parallel (pabot) and the mobile suite in series (one device);
    5. merges the results into results/report.html and results/log.html.
"""

import argparse
import json
import os
import platform as host_platform
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "config"))
sys.path.insert(0, str(ROOT / "libraries"))

import settings  # noqa: E402
from server_process import ServerProcess, is_api_up  # noqa: E402

RESULTS = ROOT / "results"
SUITES = {"api": "Tests.Api", "mobile": "Tests.Mobile"}


# ---------------------------------------------------------------------------- environment


def log(message: str) -> None:
    print(f"[run] {message}", flush=True)


def android_sdk() -> Path | None:
    for candidate in (os.environ.get("ANDROID_HOME"), os.environ.get("ANDROID_SDK_ROOT"),
                      Path.home() / "Android" / "Sdk", Path.home() / "Library" / "Android" / "sdk"):
        if candidate and Path(candidate).is_dir():
            return Path(candidate)
    return None


def prepare_environment() -> None:
    """Appium needs ANDROID_HOME and adb in the PATH; both are filled in when missing.
    pabot starts the `robot` command, so the folder of this Python (the venv) goes first in the PATH."""
    os.environ["PATH"] = str(Path(sys.executable).parent) + os.pathsep + os.environ["PATH"]
    sdk = android_sdk()
    if sdk:
        os.environ.setdefault("ANDROID_HOME", str(sdk))
        os.environ.setdefault("ANDROID_SDK_ROOT", str(sdk))
        platform_tools = str(sdk / "platform-tools")
        if platform_tools not in os.environ["PATH"].split(os.pathsep):
            os.environ["PATH"] = platform_tools + os.pathsep + os.environ["PATH"]
    if "JAVA_HOME" not in os.environ and shutil.which("java"):
        java = Path(shutil.which("java")).resolve()
        os.environ["JAVA_HOME"] = str(java.parent.parent)
    os.environ["APPIUM_HOME"] = os.environ.get("APPIUM_HOME", str(ROOT / ".appium"))


# ---------------------------------------------------------------------------- devices


def android_devices() -> list[str]:
    if not shutil.which("adb"):
        return []
    output = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=30).stdout
    devices = []
    for line in output.splitlines()[1:]:
        parts = line.split()
        if len(parts) >= 2 and parts[1] == "device":
            devices.append(parts[0])
    return devices


def ios_devices() -> list[str]:
    """Booted iOS simulators (macOS only)."""
    if host_platform.system() != "Darwin" or not shutil.which("xcrun"):
        return []
    output = subprocess.run(["xcrun", "simctl", "list", "devices", "booted", "-j"],
                            capture_output=True, text=True, timeout=30).stdout
    devices = []
    for runtime_devices in json.loads(output or "{}").get("devices", {}).values():
        devices.extend(device["udid"] for device in runtime_devices if device.get("state") == "Booted")
    return devices


def resolve_target(requested_platform: str | None, requested_device: str | None) -> tuple[str, str]:
    """Returns (platform, udid). Without options: the first connected Android device, then the
    first booted iOS simulator."""
    if requested_platform and requested_device:
        return requested_platform, requested_device
    if requested_platform == "android" or (requested_platform is None and android_devices()):
        devices = android_devices()
        if not devices:
            raise SystemExit("No Android device found. Check `adb devices` or use --suite api.")
        if requested_device and requested_device not in devices:
            raise SystemExit(f"Device {requested_device} is not connected. Connected: {devices}")
        return "android", requested_device or devices[0]
    if requested_platform == "ios" or (requested_platform is None and ios_devices()):
        devices = ios_devices()
        if not devices and not requested_device:
            raise SystemExit("No booted iOS simulator found. Boot one or pass --device <udid>.")
        return "ios", requested_device or devices[0]
    raise SystemExit("No device connected (Android or iOS). Connect a device or run --suite api.")


# ---------------------------------------------------------------------------- appium


def appium_is_up(url: str) -> bool:
    try:
        with urllib.request.urlopen(f"{url.rstrip('/')}/status", timeout=2) as response:
            return response.status == 200
    except (urllib.error.URLError, OSError):
        return False


def ensure_appium_driver(target_platform: str) -> None:
    driver = "uiautomator2" if target_platform == "android" else "xcuitest"
    installed = subprocess.run(["npx", "appium", "driver", "list", "--installed", "--json"],
                               cwd=ROOT, capture_output=True, text=True).stdout
    if driver not in installed:
        log(f"Installing the Appium {driver} driver...")
        subprocess.run(["npx", "appium", "driver", "install", driver], cwd=ROOT, check=True)


def start_appium(url: str, target_platform: str):
    if appium_is_up(url):
        log(f"Using the Appium server at {url}")
        return None
    if not (ROOT / "node_modules" / ".bin" / "appium").exists():
        raise SystemExit("Appium is not installed. Run `npm install` inside automated_testing/.")
    ensure_appium_driver(target_platform)
    port = url.rstrip("/").rsplit(":", 1)[-1]
    RESULTS.mkdir(exist_ok=True)
    log_file = open(RESULTS / "appium.log", "w")  # noqa: SIM115 - closed with the process
    process = subprocess.Popen(["npx", "appium", "--port", port, "--relaxed-security"],
                               cwd=ROOT, stdout=log_file, stderr=subprocess.STDOUT)
    for _ in range(60):
        if appium_is_up(url):
            log(f"Appium started at {url} (log: results/appium.log)")
            return process
        time.sleep(0.5)
    process.terminate()
    raise SystemExit("Appium did not start. See results/appium.log.")


# ---------------------------------------------------------------------------- robot


def robot_filters(args) -> list[str]:
    options = []
    for tag in args.include:
        options += ["--include", tag]
    for tag in args.exclude:
        options += ["--exclude", tag]
    for name in args.test:
        options += ["--test", name]
    return options


def run_suite(name: str, args, variables: dict, extra: list[str]) -> Path:
    output_dir = RESULTS / name
    options = ["--outputdir", str(output_dir), "--suite", SUITES[name],
               "--output", "output.xml", "--log", "NONE", "--report", "NONE"]
    for key, value in variables.items():
        options += ["--variable", f"{key}:{value}"]
    options += robot_filters(args) + extra
    if name == "api" and args.processes > 1:
        command = [sys.executable, "-m", "pabot.pabot", "--processes", str(args.processes)]
    else:
        # A tag filter that selects no test of this suite is not an error.
        # (Not used with pabot: there it makes every process load the whole suite tree.)
        command = [sys.executable, "-m", "robot", "--runemptysuite"]
    log(f"Running the {name} tests...")
    subprocess.run(command + options + [str(ROOT / "tests")], cwd=ROOT)
    return output_dir / "output.xml"


def merge_results(outputs: list[Path]) -> int:
    existing = [str(output) for output in outputs if output.exists()]
    if not existing:
        return 252
    command = [sys.executable, "-m", "robot.rebot", "--name", "Food Marketplace", "--outputdir", str(RESULTS),
               "--output", "output.xml", "--log", "log.html", "--report", "report.html",
               "--xunit", "junit.xml", *existing]
    return subprocess.run(command, cwd=ROOT).returncode


# ---------------------------------------------------------------------------- main


def parse_args(argv):
    extra = []
    if "--" in argv:
        index = argv.index("--")
        argv, extra = argv[:index], argv[index + 1:]
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--platform", choices=["android", "ios"], help="mobile platform (default: detected)")
    parser.add_argument("--device", help="device udid/serial (default: first connected device)")
    parser.add_argument("--suite", choices=["all", "api", "mobile"], default="all", help="default: all")
    parser.add_argument("-i", "--include", action="append", default=[], metavar="TAG",
                        help="run only tests with this tag (repeatable; Robot patterns like smokeANDcart work)")
    parser.add_argument("-e", "--exclude", action="append", default=[], metavar="TAG",
                        help="skip tests with this tag (repeatable)")
    parser.add_argument("-t", "--test", action="append", default=[], metavar="NAME",
                        help="run only the tests with this name (wildcards allowed, e.g. 'TC-API-CRT-0*')")
    parser.add_argument("--processes", type=int, default=4, help="parallel processes for the API suite (default: 4)")
    parser.add_argument("--appium-url", default=settings.APPIUM_URL, help=f"default: {settings.APPIUM_URL}")
    parser.add_argument("--list-devices", action="store_true", help="list the connected devices and exit")
    return parser.parse_args(argv), extra


def main(argv=None) -> int:
    args, extra = parse_args(sys.argv[1:] if argv is None else argv)
    prepare_environment()

    if args.list_devices:
        print("Android:", android_devices() or "none")
        print("iOS simulators:", ios_devices() or "none")
        return 0

    suites = ["api", "mobile"] if args.suite == "all" else [args.suite]
    variables = {}
    appium = None

    if "mobile" in suites:
        target_platform, udid = resolve_target(args.platform, args.device)
        app = Path(settings.ANDROID_APP if target_platform == "android" else settings.IOS_APP)
        if not app.exists():
            hint = ("cd application/src_mobile && ./gradlew publishApk" if target_platform == "android"
                    else "build the iOS app on macOS (see application/src_mobile/README.md)")
            raise SystemExit(f"App not found: {app}\nBuild it first: {hint}")
        log(f"Platform: {target_platform} | device: {udid}")
        variables = {"PLATFORM": target_platform, "DEVICE_UDID": udid, "APPIUM_URL": args.appium_url}
        # Tests that only make sense on the other platform (e.g. the Android back button).
        args.exclude.append("ios_only" if target_platform == "android" else "android_only")

    if RESULTS.exists():
        shutil.rmtree(RESULTS)
    RESULTS.mkdir()

    server = ServerProcess(settings.API_SERVER_SCRIPT, settings.TEST_PORT, settings.TEST_DB_PATH)
    if is_api_up(server.url):
        raise SystemExit(f"Port {settings.TEST_PORT} is busy. Stop that process or set TEST_PORT.")
    log(f"Starting the API at {server.url} with a clean database")
    server.start(clean_database=True)

    outputs = []
    try:
        if "mobile" in suites:
            appium = start_appium(args.appium_url, variables["PLATFORM"])
        for name in suites:
            outputs.append(run_suite(name, args, variables, extra))
    finally:
        server.stop()
        if appium:
            appium.terminate()

    return_code = merge_results(outputs)
    log(f"Report: {RESULTS / 'report.html'}")
    return return_code


if __name__ == "__main__":
    sys.exit(main())
