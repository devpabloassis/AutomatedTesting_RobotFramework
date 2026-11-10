# Test Execution Guide

This document explains how to run the Food Marketplace automated tests (API and mobile) and how to validate the results.

## 1. Project structure

```text
automated_testing/
├── run.py                          # Runner: platform, device, suite, tags, server, Appium and reports
├── requirements.txt                # Robot Framework, AppiumLibrary, pabot, jsonschema
├── package.json                    # Local Appium server
├── config/settings.py              # Ports, URLs, app paths and timeouts (overridable with -v NAME:value)
├── tests/
│   ├── __init__.robot              # Starts the API (port 3100, clean database) for the whole run
│   ├── api/                        # API suites
│   └── mobile/                     # Mobile suites; __init__.robot opens the Appium session
├── resources/
│   ├── common.resource             # Shared keywords: users and cart prepared through the API
│   ├── api/api.resource            # API keywords (Given/When/Then)
│   ├── mobile/mobile.resource      # Mobile keywords (Given/When/Then)
│   ├── mobile/pages/               # Page Objects: header, home, company, login, cart, warning
│   ├── mobile/object_map.py        # Element ids
│   └── test_data.py                # Messages, seed users and SQL injection payloads
├── libraries/
│   ├── MarketplaceApi.py           # API client, {placeholders}, test state and assertions
│   ├── ContractValidator.py        # JSON Schema validation with readable messages
│   ├── MobileApp.py                # Cross-platform helpers on top of AppiumLibrary
│   ├── FaultProxy.py               # Proxy between the app and the API (failures and request log)
│   ├── TestServer.py               # Starts the API when a suite runs without run.py
│   └── server_process.py           # API process management (also used by persistence tests)
└── contracts/                      # JSON Schemas of the API responses
```

### 1.1 How the tests are written

The tests use the Robot Framework **BDD style**: `Given`, `When`, `Then` and `And` are prefixes that Robot Framework ignores when it looks for the keyword, so each sentence is a keyword with **embedded arguments**:

```robotframework
I add the product "${product}" to the cart
    Tap Add To Cart    ${product}
```

Data-driven tests use `[Template]`. The SQL injection tests combine the template with a `FOR` loop over the 8 payloads; every iteration runs even when a previous one fails.

In API requests, `{placeholders}` are replaced with test values: `{user}` is the created user, `{item}` is its cart item, `{unique_name}` generates a new name, `{generated_name}` repeats it and `{payload}` is the SQL injection payload.

### 1.2 How the mobile tests work

```text
Robot Framework ──Appium──> device (Food Marketplace app)
      │                              │
      │ API setup                    │ http://127.0.0.1:3101/api  (adb reverse on Android)
      ▼                              ▼
   API :3100 <──────────── fault proxy :3101 (500 injection, request log)
```

- **One Appium session** for the whole mobile run. Before each test, a deep link ends the session and opens the company list.
- **Preconditions through the API:** the test creates its own user and cart through the API, then opens the app with `foodmarket://open/<route>?user=<user>`. The login screen is only used by the login tests.
- **Element ids:** the keywords receive plain ids such as `cart-count`. `MobileApp.py` builds the locator for the platform: `UiSelector().resourceId("cart-count")` on Android and the accessibility id on iOS. Elements outside the screen are not in the accessibility tree, so the library scrolls to them.
- **Waits:** assertions poll until the expected value appears or the timeout (`UI_TIMEOUT`, 10 s) expires, because the screens update after asynchronous API calls.
- **Failures:** AppiumLibrary captures a screenshot of every failed step into the log.

### 1.3 Contract tests

The contract tests (`tests/api/contract.robot`, tag `contract`) check the **structure** of each response against the JSON Schemas in `automated_testing/contracts/`. A contract requires the mandatory fields with the right type and format, and **rejects extra fields**. When a response does not follow the contract, the error lists each violation:

```text
The response does not follow the "companies" contract:
- [0].commissionPercent: field not allowed by the contract
- [1].commissionPercent: field not allowed by the contract
...
```

## 2. Prerequisites

| Tool | Needed for |
|---|---|
| Python 3.10+ | Robot Framework |
| Node.js 22+ | The API and the local Appium server |
| Android SDK platform tools (`adb`) | Android tests. `run.py` finds the SDK in `ANDROID_HOME` or `~/Android/Sdk` |
| JDK 17+ | Appium UiAutomator2 and the APK build |
| macOS + Xcode | iOS tests only |

First run:

```bash
cd automated_testing
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
npm install
```

The Appium driver (`uiautomator2` or `xcuitest`) is installed automatically on the first mobile run, inside `automated_testing/.appium/`. Nothing is installed globally.

The APK must exist in `application/public/food-marketplace.apk`. To rebuild it: `cd application/src_mobile && ./gradlew publishApk`.

## 3. Choosing the platform and the device

| Situation | Behavior |
|---|---|
| No `--platform` and no `--device` | Uses the first device of `adb devices`. If there is none, the first booted iOS simulator |
| `--platform android` | First device of `adb devices` |
| `--platform android --device <serial>` | That device. It must be listed by `adb devices` |
| `--platform ios` | First booted iOS simulator |
| `--platform ios --device <udid>` | That simulator or device |
| `--suite api` | No device needed |

Wireless debugging serials (`adb-XXXX._adb-tls-connect._tcp`) work as well. On Android, the runner maps ports 3100 and 3101 to the device with `adb reverse`, so the app reaches the test API through `127.0.0.1`.

Tests tagged `android_only` (Android back button) are excluded automatically on iOS, and tests tagged `ios_only` on Android.

## 4. Commands

All commands run inside `automated_testing/`.

| Goal | Command | Tests | Passed | Failed |
|---|---|---:|---:|---:|
| Everything (Android) | `python run.py` | 266 | 251 | 15 |
| API only | `python run.py --suite api` | 195 | 188 | 7 |
| Mobile only (Android) | `python run.py --suite mobile` | 71 | 63 | 8 |
| Smoke | `python run.py --include smoke` | 43 | 35 | 8 |
| Login | `python run.py --include feature_login` | 23 | 23 | 0 |
| Cart | `python run.py --include feature_cart` | 73 | 66 | 7 |
| Contract | `python run.py --include contract` | 28 | 27 | 1 |
| Field domain | `python run.py --include domain` | 57 | 57 | 0 |
| SQL injection | `python run.py --include sqli` | 18 | 18 | 0 |
| Without known defects | `python run.py --exclude known_bug` | 251 | 251 | 0 |
| Known defects only | `python run.py --include known_bug` | 15 | 0 | 15 |

On iOS, the 3 `android_only` tests are not run, so the mobile suite has 68 tests.

### Custom filters

`--include` and `--exclude` accept Robot Framework tag patterns and can be repeated:

```bash
python run.py --include feature_loginORfeature_payment       # one tag or another
python run.py --include smokeANDfeature_cart                 # both tags
python run.py --suite mobile --include smoke                 # a tag in a single suite
python run.py --test "TC-MOB-CRT-004*"                       # a single test by ID
python run.py --suite api --processes 1                      # API tests in series
python run.py -- --loglevel DEBUG                            # extra Robot Framework options
```

Available tags: `api`, `mobile`, `regression`, `smoke`, `known_bug`, `domain`, `sqli`, `contract`, `security`, `persistence`, `responsive`, `android_only`, `feature_user`, `feature_login`, `feature_catalog`, `feature_cart`, `feature_company_switch`, `feature_checkout` and `feature_payment`.

### Running with `robot` directly

```bash
robot --outputdir results --suite Tests.Api tests
robot --outputdir results --suite Tests.Mobile -v DEVICE_UDID:<serial> tests
```

The API is started by `tests/__init__.robot` when it is not running. Appium must already be running (`npx appium`), and the device must be passed with `-v DEVICE_UDID:<serial>`.

## 5. Expected failures

The 15 tests below validate the **correct behavior** and fail because the system has 4 defects inserted on purpose. The defects are described in section 10 of the [product specification](./PRODUCT_SPEC.md) and marked in the code with the `INTENTIONAL DEFECT` comment (`application/src_api/server.js`). All 15 tests have the `known_bug` tag.

| Defect | Endpoint with the defect | API | Mobile | Total |
|---|---|---:|---:|---:|
| BUG-01 — Cart is not cleared when switching company | `POST /users/:username/cart/items` | 1 | 5 | 6 |
| BUG-02 — Quantity is doubled when updating an item | `PATCH /users/:username/cart/items/:itemId` | 4 | 2 | 6 |
| BUG-03 — Order with different companies is accepted | `POST /users/:username/cart/checkout` | 1 | 1 | 2 |
| BUG-04 — Company list breaks the contract | `GET /companies` | 1 | 0 | 1 |
| **Total** | | **7** | **8** | **15** |

### BUG-01 — Cart is not cleared when switching company

**Why it fails:** when the company switch is confirmed (`replaceCart: true`, or **Yes** in the app warning), the API should empty the cart before adding the new product. The line that does this is missing in `addCartItem`. The cart ends up with the old item and the new one, and the header counter shows the sum of both.

| Test | What it validates | Expected | Actual |
|---|---|---|---|
| `TC-API-CRT-020` | Add an item from another company with `replaceCart: true` | Items: `double` | Items: `supreme`, `double` |
| `TC-MOB-SWT-002` | Tapping **Yes** clears the cart | Items: `double` | Items: `supreme`, `double` |
| `TC-MOB-SWT-006` | Counter after **Yes** | `1` | `2` |
| `TC-MOB-SWT-007` | Counter after **Yes**, with 3 units before | `1` | `4` |
| `TC-MOB-SWT-008` | Counter after **Yes** and app restart | `1` | `2` |
| `TC-MOB-SWT-009` | After **Yes**, add another product from the new company | No new warning | The warning appears again |

### BUG-02 — Quantity is doubled when updating an item

**Why it fails:** the API stores twice the value entered (`item.quantity = body.quantity * 2`, in `updateCartItem`).

| Test | What it validates | Expected | Actual |
|---|---|---|---|
| `TC-API-CRT-030` | Update the quantity to 3 | `3` | `6` |
| `TC-API-CRT-031` | Update to the minimum (1) | `1` | `2` |
| `TC-API-CRT-032` | Update to the maximum (99) | `99` | `198` |
| `TC-API-CRT-033` | Recalculate subtotal and total | `15870` | `31740` |
| `TC-MOB-CRT-004` | Quantity field after the update | `3` | `6` |
| `TC-MOB-CRT-005` | Amounts after the update | `$158.70` | `$317.40` |

### BUG-03 — Order with different companies is accepted

**Why it fails:** the `checkout` route only validates the empty cart and returns 200 for a mixed cart. The payment route does not have the defect. The mixed cart can only be built because of BUG-01.

| Test | What it validates | Expected | Actual |
|---|---|---|---|
| `TC-API-ORD-003` | Check out a cart with different companies | 422 `CART_MIXED_COMPANIES` | 200 `READY_FOR_PAYMENT` |
| `TC-MOB-CHK-002` | Message when checking out with different companies | Different-companies message | `Order confirmed` |

### BUG-04 — Company list breaks the contract

**Why it fails:** `GET /companies` adds the internal field `commissionPercent` to each company. The app ignores unknown fields, so only the contract test detects it.

| Test | What it validates | Expected | Actual |
|---|---|---|---|
| `TC-API-CON-008` | `GET /companies` follows the contract | No violations | `[0].commissionPercent: field not allowed by the contract` (and `[1]` to `[3]`) |

### Tests that depend on defects but pass

These tests use BUG-01 only to build a mixed cart. What they validate works, so they pass and do **not** have `known_bug`: `TC-API-ORD-013`, `TC-API-CON-025`, `TC-MOB-PAY-005` and `TC-MOB-SWT-010`.

## 6. Reports

| Report | Location | Use |
|---|---|---|
| Console | Terminal | Follow the run |
| HTML report | `automated_testing/results/report.html` | Summary, filters by tag and status |
| HTML log | `automated_testing/results/log.html` | Every keyword, with the expected and actual values and screenshots of failed mobile steps |
| JUnit | `automated_testing/results/junit.xml` | CI integration |
| Per suite | `automated_testing/results/api/`, `automated_testing/results/mobile/` | Raw output of each part |
| Appium | `automated_testing/results/appium.log` | Appium server log, when `run.py` started it |

The `results/` folder is cleaned on every run.

### Validation checklist

1. Check that the summary shows 251 passed and 15 failed (Android).
2. Compare the failed IDs with the tables in section 5.
3. In `log.html`, check that the expected and actual values of each failure match the tables.
4. Run `python run.py --exclude known_bug` and confirm that every test passes.

## 7. Troubleshooting

| Symptom | Solution |
|---|---|
| `No device connected` | Check `adb devices`. Enable USB or wireless debugging and accept the authorization prompt on the phone |
| `App not found` | Build the APK: `cd application/src_mobile && ./gradlew publishApk` |
| `Port 3100 is busy` | Stop the process using the port or set `TEST_PORT` |
| Appium does not start | See `results/appium.log`. Run `npm install` in `automated_testing/` |
| `ANDROID_HOME` errors in Appium | Set `ANDROID_HOME` to the Android SDK folder |
| The app shows `Unable to reach the server.` | `adb reverse` failed: run `adb reverse tcp:3101 tcp:3101` and `adb reverse tcp:3100 tcp:3100` |
| Elements not found on a small screen | Increase the timeout: `python run.py -- -v UI_TIMEOUT:20s` |
| The device is locked | Unlock it before the run. Appium cannot interact with a locked screen |
