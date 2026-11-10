# Food Marketplace — mobile app

Kotlin Multiplatform app with a single UI written in [Compose Multiplatform](https://www.jetbrains.com/compose-multiplatform/), shared by Android and iOS. It is the mobile client of the API in [`../src_api`](../src_api).

## Structure

```text
src_mobile/
├── composeApp/
│   └── src/
│       ├── commonMain/      # Shared code: UI, navigation, API client, deep links, test tags
│       ├── androidMain/     # MainActivity, SharedPreferences, OkHttp engine, AndroidManifest
│       └── iosMain/         # MainViewController, NSUserDefaults, Darwin engine
├── iosApp/iosApp/           # SwiftUI host of the shared UI (iOS)
└── gradle/libs.versions.toml
```

| Layer | Files |
|---|---|
| Screens | `ui/screens/CatalogScreens.kt` (companies, products), `ui/screens/AccountScreens.kt` (login, cart) |
| Shared components | `ui/components/Components.kt` (header, message, company switch warning) |
| State and navigation | `state/AppState.kt`, `state/Screen.kt` |
| Deep links | `state/DeepLink.kt` |
| API client | `api/MarketApi.kt` (Ktor) |
| Ids used by the tests | `ui/TestTags.kt` |

## Element ids for test automation

Every element used by the tests has a stable id, set with `Modifier.testTag(...)`:

- **Android:** `testTagsAsResourceId` turns each tag into the view `resource-id`. Appium locates it with `UiSelector().resourceId("cart-count")`.
- **iOS:** Compose maps each tag to the `accessibilityIdentifier`. Appium locates it with the accessibility id strategy.

Tagged texts inside a clickable card use `Modifier.automationId(...)`. It adds a merge boundary, so the text keeps its own node in the accessibility tree and is not merged into the card.

The full list of ids is in `ui/TestTags.kt` and in [`docs/PRODUCT_SPEC.md`](../../docs/PRODUCT_SPEC.md#8-user-interface).

## Deep links

```text
foodmarket://open/<route>?user=<username>&api=<url>
```

| Route | Screen |
|---|---|
| `/` | Company list |
| `/companies/<companyId>` | Company products |
| `/login?next=<route>` | Login, returning to `next` (internal routes only) |
| `/cart` | Cart, checkout and payment |

`user` and `api` are **test hooks**. `user` starts a session (`user=` ends it), and `api` changes the API base URL. The automated tests use them to prepare each scenario quickly, the same way a web test sets `localStorage`.

## API address

The default is `http://127.0.0.1:3000/api`.

- **Physical Android device:** run `adb reverse tcp:3000 tcp:3000` so that `127.0.0.1:3000` on the phone reaches the computer.
- **Android emulator:** use `adb reverse` as well, or open `foodmarket://open/?api=http://10.0.2.2:3000/api`.
- **iOS simulator:** it shares the network of the Mac, so nothing is needed.

The automated tests point the app to their own proxy (`http://127.0.0.1:3101/api`) through the `api` parameter.

## Build

Requirements: JDK 17 or later and the Android SDK (platform 35). Set the SDK path in `local.properties` (`sdk.dir=...`) or in `ANDROID_HOME`.

```bash
cd application/src_mobile
./gradlew publishApk     # builds the debug APK and copies it to application/public/food-marketplace.apk
```

Install and open it manually:

```bash
adb install -r ../public/food-marketplace.apk
adb reverse tcp:3000 tcp:3000
adb shell am start -a android.intent.action.VIEW -d "foodmarket://open/"
```

### iOS (macOS only)

The iOS targets (`iosX64`, `iosArm64`, `iosSimulatorArm64`) are declared in `composeApp/build.gradle.kts`. On Linux and Windows they are skipped. On a Mac with Xcode:

1. Create an iOS App project in Xcode named `iosApp` inside `iosApp/`, and replace its sources with the files in `iosApp/iosApp/`.
2. Add a *Run Script* build phase before *Compile Sources*:
   `cd "$SRCROOT/.." && ./gradlew :composeApp:embedAndSignAppleFrameworkForXcode`
3. In *Build Settings*, add `$(SRCROOT)/../composeApp/build/xcode-frameworks/$(CONFIGURATION)/$(SDK_NAME)` to *Framework Search Paths*, and `-framework ComposeApp` to *Other Linker Flags*.
4. Build for a simulator and copy `FoodMarketplace.app` to `application/public/`. That is the path the tests use for iOS.
