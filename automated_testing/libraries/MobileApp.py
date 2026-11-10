"""Cross-platform helpers for the Food Marketplace app, built on top of AppiumLibrary.

Every element used by the tests has a stable id, defined with `testTag` in the Compose code:
- Android: the id is the `resource-id` (located with UiSelector().resourceId("..."));
- iOS: the id is the `accessibilityIdentifier` (located with the accessibility id strategy).

The keywords take the plain id (for example "cart-count") and build the platform locator,
so the page resources and the tests are the same for Android and iOS.
"""

import re
import subprocess
import time
import xml.etree.ElementTree as ElementTree
from urllib.parse import quote

from appium.webdriver.common.appiumby import AppiumBy
from robot.api import logger
from robot.api.deco import keyword, library
from robot.libraries.BuiltIn import BuiltIn
from robot.utils import timestr_to_secs

POLL_INTERVAL = 0.25


@library(scope="GLOBAL")
class MobileApp:
    def __init__(self, platform: str = "android", app_package: str = "com.foodmarketplace.app",
                 ios_bundle_id: str = "com.foodmarketplace.app", timeout: str = "10s"):
        self.platform = platform.lower()
        self.app_package = app_package
        self.ios_bundle_id = ios_bundle_id
        self.timeout = timestr_to_secs(timeout)
        self.api_url = None
        self.udid = None

    # ------------------------------------------------------------------ session

    @property
    def _appium(self):
        return BuiltIn().get_library_instance("AppiumLibrary")

    @property
    def driver(self):
        return self._appium._current_application()

    @property
    def is_android(self) -> bool:
        return self.platform == "android"

    @keyword
    def open_food_marketplace_app(self, appium_url: str, udid: str, app_path: str, app_api_url: str,
                                  app_activity: str = ".MainActivity") -> None:
        """Opens an Appium session on the device, installing the app from application/public."""
        self.udid = udid
        self.api_url = app_api_url
        if self.is_android:
            capabilities = {
                "platformName": "Android",
                "appium:automationName": "UiAutomator2",
                "appium:app": app_path,
                "appium:appPackage": self.app_package,
                "appium:appActivity": app_activity,
                "appium:noReset": False,
                "appium:autoGrantPermissions": True,
                "appium:disableWindowAnimation": True,
                "appium:newCommandTimeout": 300,
                "appium:uiautomator2ServerInstallTimeout": 120000,
                "appium:adbExecTimeout": 60000,
            }
        else:
            capabilities = {
                "platformName": "iOS",
                "appium:automationName": "XCUITest",
                "appium:app": app_path,
                "appium:bundleId": self.ios_bundle_id,
                "appium:newCommandTimeout": 300,
            }
        if udid:
            capabilities["appium:udid"] = udid
        self._appium.open_application(appium_url, **capabilities)
        if self.is_android:
            # Compose is idle most of the time; a short idle wait keeps the commands fast.
            self.driver.update_settings({"waitForIdleTimeout": 100})

    @keyword
    def forward_ports_to_device(self, *ports) -> None:
        """Android: `adb reverse` makes 127.0.0.1:<port> on the device reach this computer.
        iOS simulators share the network of the Mac, so nothing is needed."""
        if not self.is_android:
            return
        serial = ["-s", self.udid] if self.udid else []
        for port in ports:
            subprocess.run(["adb", *serial, "reverse", f"tcp:{port}", f"tcp:{port}"], check=True,
                           capture_output=True, timeout=30)

    # ------------------------------------------------------------------ navigation

    @keyword
    def open_deep_link(self, route: str = "/", user=None) -> None:
        """Opens foodmarket://open<route>. `user` starts that session; an empty string ends it;
        None keeps the current session. The API URL of the app always points to the test proxy."""
        separator = "&" if "?" in route else "?"
        url = f"foodmarket://open{route}{separator}api={quote(self.api_url, safe='')}"
        if user is not None:
            url += f"&user={quote(user, safe='')}"
        logger.info(f"Deep link: {url}")
        if self.is_android:
            self.driver.execute_script("mobile: deepLink", {"url": url, "package": self.app_package})
        else:
            self.driver.execute_script("mobile: deepLink", {"url": url, "bundleId": self.ios_bundle_id})

    @keyword
    def restart_app(self) -> None:
        """Closes and opens the app again (the mobile equivalent of reloading a web page)."""
        app_id = self.app_package if self.is_android else self.ios_bundle_id
        self.driver.terminate_app(app_id)
        self.driver.activate_app(app_id)

    @keyword
    def press_back(self) -> None:
        """Android system back button."""
        if not self.is_android:
            raise AssertionError("The system back button only exists on Android.")
        self.driver.back()

    @keyword
    def set_device_orientation(self, orientation: str) -> None:
        self.driver.orientation = orientation.upper()

    @keyword
    def hide_keyboard_if_shown(self) -> None:
        try:
            if self.driver.is_keyboard_shown():
                self.driver.hide_keyboard()
        except Exception:  # noqa: BLE001 - keyboard state is best effort
            pass

    # ------------------------------------------------------------------ locating

    def _by(self, element_id: str):
        if self.is_android:
            return AppiumBy.ANDROID_UIAUTOMATOR, f'new UiSelector().resourceId("{element_id}")'
        return AppiumBy.ACCESSIBILITY_ID, element_id

    def _find_now(self, element_id: str):
        elements = self.driver.find_elements(*self._by(element_id))
        return elements[0] if elements else None

    def _scroll_into_view(self, element_id: str):
        """Elements outside the screen are not in the accessibility tree, so the test scrolls."""
        try:
            if self.is_android:
                selector = (
                    "new UiScrollable(new UiSelector().scrollable(true)).setMaxSearchSwipes(6)"
                    f'.scrollIntoView(new UiSelector().resourceId("{element_id}"))'
                )
                return self.driver.find_element(AppiumBy.ANDROID_UIAUTOMATOR, selector)
            self.driver.execute_script("mobile: scroll", {"predicateString": f"name == '{element_id}'",
                                                          "toVisible": True})
            return self._find_now(element_id)
        except Exception:  # noqa: BLE001 - nothing to scroll or element not found
            return None

    def _find(self, element_id: str, timeout=None, scroll: bool = True):
        deadline = time.monotonic() + (self.timeout if timeout is None else timestr_to_secs(timeout))
        scrolled = False
        while True:
            element = self._find_now(element_id)
            if element is not None:
                return element
            if scroll and not scrolled and self._has_content():
                element = self._scroll_into_view(element_id)
                scrolled = True
                if element is not None:
                    return element
            if time.monotonic() >= deadline:
                raise AssertionError(f'Element "{element_id}" was not found.')
            time.sleep(POLL_INTERVAL)

    def _has_content(self) -> bool:
        """Scrolling only helps after the screen finished loading."""
        return self._find_now("loading") is None

    def _poll(self, check, timeout, failure):
        deadline = time.monotonic() + (self.timeout if timeout is None else timestr_to_secs(timeout))
        last = None
        while True:
            try:
                ok, last = check()
                if ok:
                    return last
            except Exception as error:  # noqa: BLE001 - stale elements while the screen redraws
                last = error
            if time.monotonic() >= deadline:
                raise AssertionError(failure(last))
            time.sleep(POLL_INTERVAL)

    # ------------------------------------------------------------------ actions

    @keyword
    def tap_element(self, element_id: str, timeout=None) -> None:
        self._find(element_id, timeout).click()

    @keyword
    def type_into(self, element_id: str, text: str) -> None:
        element = self._find(element_id)
        element.click()
        element.clear()
        if text:
            element.send_keys(text)
        self.hide_keyboard_if_shown()

    # ------------------------------------------------------------------ queries and assertions

    @keyword
    def wait_for_element(self, element_id: str, timeout=None) -> None:
        self._find(element_id, timeout)

    @keyword
    def text_of(self, element_id: str, timeout=None) -> str:
        return self._find(element_id, timeout).text

    @keyword
    def element_exists(self, element_id: str, timeout="0s") -> bool:
        try:
            self._find(element_id, timeout, scroll=timestr_to_secs(timeout) > 0)
            return True
        except AssertionError:
            return False

    @keyword
    def element_should_not_exist(self, element_id: str, timeout="3s") -> None:
        """Waits until the element is gone (screens update asynchronously)."""
        self._poll(
            lambda: (self._find_now(element_id) is None, None),
            timeout,
            lambda _: f'Element "{element_id}" should not be visible, but it is.',
        )

    @keyword
    def element_should_stay_absent(self, element_id: str, duration="1.5s") -> None:
        """Checks during the whole duration that the element does not appear."""
        deadline = time.monotonic() + timestr_to_secs(duration)
        while time.monotonic() < deadline:
            if self._find_now(element_id) is not None:
                raise AssertionError(f'Element "{element_id}" appeared, but it should not.')
            time.sleep(POLL_INTERVAL)

    @keyword
    def text_should_be(self, element_id: str, expected: str, timeout=None) -> None:
        def check():
            actual = self._find(element_id, timeout="1s").text
            return actual == expected, actual

        self._poll(check, timeout, lambda actual: f'Element "{element_id}": expected "{expected}", found "{actual}".')

    @keyword
    def text_should_not_be(self, element_id: str, unexpected: str, timeout=None) -> None:
        def check():
            actual = self._find(element_id, timeout="1s").text
            return actual != unexpected, actual

        self._poll(check, timeout, lambda actual: f'Element "{element_id}" still shows "{actual}".')

    @keyword
    def text_should_contain(self, element_id: str, expected: str, timeout=None) -> None:
        def check():
            actual = self._find(element_id, timeout="1s").text
            return expected in actual, actual

        self._poll(check, timeout, lambda actual: f'Element "{element_id}": "{actual}" does not contain "{expected}".')

    @keyword
    def field_value_should_be(self, element_id: str, expected: str, timeout=None) -> None:
        """Text of an input field. On Android the field node exposes the typed text."""
        def check():
            element = self._find(element_id, timeout="1s")
            actual = element.text if self.is_android else element.get_attribute("value")
            return actual == expected, actual

        self._poll(check, timeout, lambda actual: f'Field "{element_id}": expected "{expected}", found "{actual}".')

    @keyword
    def option_should_be_selected(self, element_id: str) -> None:
        attribute = "checked" if self.is_android else "value"
        value = str(self._find(element_id).get_attribute(attribute)).lower()
        if value not in ("true", "1"):
            raise AssertionError(f'Option "{element_id}" is not selected ({attribute}={value}).')

    @keyword
    def element_should_be_focused(self, element_id: str, timeout="3s") -> None:
        attribute = "focused" if self.is_android else "hasFocus"
        self._poll(
            lambda: (str(self._find(element_id).get_attribute(attribute)).lower() == "true", None),
            timeout,
            lambda _: f'Element "{element_id}" is not focused.',
        )

    @keyword
    def collect_ids_matching(self, pattern: str, max_swipes: int = 6) -> list:
        """Returns every element id that matches the regular expression, scrolling the screen
        from top to bottom (elements outside the screen are not in the accessibility tree)."""
        regex = re.compile(pattern)
        found = []
        self._scroll_to_top()
        for _ in range(int(max_swipes) + 1):
            for element_id in self._ids_on_screen():
                if regex.search(element_id) and element_id not in found:
                    found.append(element_id)
            # The ids are read before each swipe, so the last position is also read.
            if not self._scroll_down():
                for element_id in self._ids_on_screen():
                    if regex.search(element_id) and element_id not in found:
                        found.append(element_id)
                break
        self._scroll_to_top()
        logger.info(f"Ids matching {pattern}: {found}")
        return found

    def _ids_on_screen(self) -> list:
        root = ElementTree.fromstring(self.driver.page_source.encode("utf-8"))
        attribute = "resource-id" if self.is_android else "name"
        return [node.get(attribute) for node in root.iter() if node.get(attribute)]

    def _scrollable(self):
        if not self.is_android:
            return None
        elements = self.driver.find_elements(AppiumBy.ANDROID_UIAUTOMATOR, "new UiSelector().scrollable(true)")
        return elements[0] if elements else None

    def _scroll_down(self) -> bool:
        if self.is_android:
            scrollable = self._scrollable()
            if scrollable is None:
                return False
            return bool(self.driver.execute_script(
                "mobile: scrollGesture", {"elementId": scrollable.id, "direction": "down", "percent": 0.75}))
        self.driver.execute_script("mobile: swipe", {"direction": "up"})
        return True

    def _scroll_to_top(self) -> None:
        if self.is_android:
            scrollable = self._scrollable()
            for _ in range(10):
                if scrollable is None or not self.driver.execute_script(
                        "mobile: scrollGesture", {"elementId": scrollable.id, "direction": "up", "percent": 1.0}):
                    return
        else:
            for _ in range(3):
                self.driver.execute_script("mobile: swipe", {"direction": "down"})
