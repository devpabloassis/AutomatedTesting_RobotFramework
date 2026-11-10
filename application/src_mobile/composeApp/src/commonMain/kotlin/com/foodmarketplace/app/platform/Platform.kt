package com.foodmarketplace.app.platform

import androidx.compose.ui.Modifier
import io.ktor.client.HttpClient

/** Small persistent key-value storage (SharedPreferences on Android, NSUserDefaults on iOS). */
interface KeyValueStore {
    fun get(key: String): String?
    fun set(key: String, value: String?)
}

/** HTTP client with the native engine of each platform. */
expect fun createHttpClient(): HttpClient

/**
 * Exposes the Compose test tags to the automation tools.
 * Android: each `testTag` becomes the view `resource-id` (UiAutomator2).
 * iOS: Compose maps each `testTag` to the `accessibilityIdentifier` (XCUITest).
 */
expect fun Modifier.exposeTestTags(): Modifier
