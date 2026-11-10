# Test Automation with Robot Framework

[![Tests](https://github.com/devpabloassis/AutomatedTesting_RobotFramework/actions/workflows/tests.yml/badge.svg)](https://github.com/devpabloassis/AutomatedTesting_RobotFramework/actions/workflows/tests.yml)

**Mobile** (Android and iOS) and **API** test automation project built with [Robot Framework](https://robotframework.org), [Appium](https://appium.io) and Python, with keyword-driven, BDD-style (Given/When/Then) tests.

The repository has two parts:

- **`application/`**: a food marketplace, the system under test. It has a REST API and a **Kotlin Multiplatform** mobile app, and it contains **defects inserted on purpose** so that the tests fail at known points.
- **`automated_testing/`**: the Robot Framework project, with 266 test cases covering mobile UI, API, contracts, field domain characters and SQL injection.

> This project is the mobile counterpart of [AutomatedTesting_Playwright](https://github.com/devpabloassis/AutomatedTesting_Playwright) (Web + API). It has the same business rules, the same test case IDs and the same intentional defects.

## Highlights

- **Robot Framework BDD:** tests are written as Given/When/Then sentences with embedded arguments, and every test is traceable to a documented test case ID (`TC-API-*`, `TC-MOB-*`).
- **One suite, two platforms:** the same mobile tests run on **Android** (UiAutomator2) and **iOS** (XCUITest). Elements are located by stable ids (`testTag` → Android `resource-id` / iOS `accessibilityIdentifier`).
- **Automatic device selection:** with no options, `run.py` detects the platform and uses the first device listed by `adb devices`. Platform, device, suite and tags can be chosen on the command line.
- **Page Object Model** plus a central **object map** with every element id.
- **Fast and isolated mobile setup:** preconditions are built through the API, and test hooks in the app's deep links start a user session without going through the login screen.
- **Fault injection without mocks in the app:** the app talks to the API through a local proxy that can return `500` on any route and record requests.
- **Contract testing** with JSON Schema ([jsonschema](https://python-jsonschema.readthedocs.io)), with readable violation messages.
- **Data-driven tests** with `[Template]` (field domain, quantities and SQL injection payloads).
- **Parallel API run** with [pabot](https://pabot.org); persistence tests start their own server and database.
- **Known defects tracked with tags** (`known_bug`), so the suite separates real regressions from expected failures.
- **Continuous integration** with GitHub Actions: API suite as the gate, a check that the known defects still fail, and the APK build.

## The system under test

A marketplace with 4 companies (pizzeria, burgers, Japanese food and juices), each with 4 products.

- Browse the catalog without logging in.
- Log in and build a cart.
- The cart accepts items from a single company. When a product from another company is chosen, a warning asks whether the cart should be cleared.
- Update quantities and remove items.
- Check out and make a fake payment.

| Component | Technology | Location |
|---|---|---|
| REST API | Node.js 22, no external dependencies, JSON file storage | `application/src_api/` |
| Mobile app | Kotlin Multiplatform + Compose Multiplatform, Ktor client | `application/src_mobile/` |
| Android artifact | Debug APK | `application/public/food-marketplace.apk` |

Seed users: `user_manual`, `user_robot`, `user_hybrid` and `user_fail`, all with the password `loveMetalSongs@`.

### Intentional defects

These defects **must not be fixed**. They exist to show how the tests detect problems. In the code, they are marked with the `INTENTIONAL DEFECT` comment.

| Defect | Behavior |
|---|---|
| BUG-01 | When the company switch is confirmed, the cart is not cleared |
| BUG-02 | When an item quantity is updated, the value is stored doubled |
| BUG-03 | An order with items from different companies is accepted |
| BUG-04 | The company list returns a field that is not in the API contract |

## Structure

```text
AutomatedTesting_RobotFramework/
├── application/                     # System under test
│   ├── src_api/                     # REST API (server.js), catalog and storage
│   ├── src_mobile/                  # Kotlin Multiplatform app (Android + iOS)
│   └── public/                      # Built artifact: food-marketplace.apk
├── automated_testing/               # Robot Framework project
│   ├── tests/
│   │   ├── api/                     # API suites (.robot)
│   │   └── mobile/                  # Mobile suites (.robot)
│   ├── resources/
│   │   ├── common.resource          # Shared keywords (users and cart through the API)
│   │   ├── api/api.resource         # API keywords (Given/When/Then)
│   │   ├── mobile/mobile.resource   # Mobile keywords (Given/When/Then)
│   │   ├── mobile/pages/            # Page Objects
│   │   ├── mobile/object_map.py     # Element ids
│   │   └── test_data.py             # Test data and SQL injection payloads
│   ├── libraries/                   # Python libraries: API client, contracts, Appium helpers,
│   │                                # fault proxy and test server
│   ├── contracts/                   # JSON Schemas for the contract tests
│   ├── config/settings.py           # Ports, URLs, app paths and timeouts
│   └── run.py                       # Test runner (platform, device, suite and tags)
└── docs/                            # Documentation
```

## Getting started

Prerequisites:

- Python 3.10 or later and Node.js 22 or later.
- For mobile tests on Android: Android SDK platform tools (`adb`) and a device or emulator with USB or wireless debugging enabled.
- For iOS: macOS with Xcode and a booted simulator.

### Install

```bash
cd automated_testing
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
npm install                        # local Appium server (the driver is installed on the first mobile run)
```

### Run the tests

```bash
python run.py
```

With no options, the runner:

1. detects the platform and picks the **first device** listed by `adb devices` (or the first booted iOS simulator);
2. starts the API on port `3100` with a clean database;
3. starts Appium if it is not running and installs the app from `application/public/`;
4. runs the API tests (in parallel) and the mobile tests (in series), and merges the reports.

| Command | What it runs |
|---|---|
| `python run.py` | Everything, on the first connected device |
| `python run.py --suite api` | API only (no device needed) |
| `python run.py --suite mobile` | Mobile only |
| `python run.py --platform android --device <serial>` | A specific Android device |
| `python run.py --platform ios --device <udid>` | A specific iOS simulator |
| `python run.py --include smoke` | Smoke tests |
| `python run.py --include contract` | Contract tests |
| `python run.py --include feature_cartANDsmoke` | Tests with both tags |
| `python run.py --exclude known_bug` | Everything except the intentional defect tests |
| `python run.py --include known_bug` | Only the intentional defect tests |
| `python run.py --test "TC-MOB-CRT-004*"` | A single test by ID |
| `python run.py --list-devices` | List the connected devices |

Reports: `automated_testing/results/report.html`, `log.html` (with screenshots of failed mobile steps) and `junit.xml`.

### Expected result

```text
266 tests, 251 passed, 15 failed
```

The **15 failures are expected**: each one maps to one of the intentional defects (7 API and 8 mobile). The reason for each failure is explained in the [test execution guide](docs/TEST_EXECUTION.md#5-expected-failures). For a run without failures, use `python run.py --exclude known_bug`.

### Run the system manually

```bash
cd application
npm start                                   # API at http://127.0.0.1:3000/api
adb install -r public/food-marketplace.apk
adb reverse tcp:3000 tcp:3000               # the app reaches the API through 127.0.0.1:3000
```

To rebuild the APK: `cd application/src_mobile && ./gradlew publishApk` (see [`application/src_mobile/README.md`](application/src_mobile/README.md)).

## Example test

```robotframework
*** Test Cases ***
TC-MOB-SWT-006 - Counter after Yes
    [Documentation]    Expected failure: BUG-01.
    [Tags]    smoke    known_bug
    When I add the product "double" to the cart
    And I answer the company switch warning with "Yes"
    Then I should see the message "Product added to the cart."
    And the cart counter should show "1"
```

The suite setup creates a user through the API, adds a pizza to the cart and opens the burgers screen with a deep link, so each test starts in a known state.

## Documentation

| Document | Content |
|---|---|
| [`docs/PRODUCT_SPEC.md`](docs/PRODUCT_SPEC.md) | Business rules, user stories, screens, element ids and intentional defects |
| [`docs/API_ENDPOINTS.md`](docs/API_ENDPOINTS.md) | The 11 API endpoints, with examples, errors and contracts |
| [`docs/API_TEST_CASES.md`](docs/API_TEST_CASES.md) | Catalog of the API test cases |
| [`docs/MOBILE_TEST_CASES.md`](docs/MOBILE_TEST_CASES.md) | Catalog of the mobile test cases |
| [`docs/TEST_EXECUTION.md`](docs/TEST_EXECUTION.md) | How to run, filter by tag and platform, and the reason for each expected failure |
| [`application/src_mobile/README.md`](application/src_mobile/README.md) | Mobile app architecture, deep links, ids and build |

## Tech stack

- [Robot Framework](https://robotframework.org) 7.3 with [AppiumLibrary](https://github.com/serhatbolsu/robotframework-appiumlibrary) and [pabot](https://pabot.org)
- [Appium](https://appium.io) 3 with the UiAutomator2 (Android) and XCUITest (iOS) drivers
- Python libraries for the API client, contract validation ([jsonschema](https://python-jsonschema.readthedocs.io)), fault proxy and test server
- [Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html) 2.1 and [Compose Multiplatform](https://www.jetbrains.com/compose-multiplatform/) 1.7 for the app
- Node.js 22 for the API, with no external dependencies
