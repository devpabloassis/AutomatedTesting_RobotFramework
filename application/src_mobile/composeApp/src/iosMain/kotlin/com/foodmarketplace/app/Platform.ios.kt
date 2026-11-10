package com.foodmarketplace.app.platform

import androidx.compose.ui.Modifier
import io.ktor.client.HttpClient
import io.ktor.client.engine.darwin.Darwin
import io.ktor.client.plugins.HttpTimeout
import platform.Foundation.NSUserDefaults

actual fun createHttpClient(): HttpClient = HttpClient(Darwin) {
    expectSuccess = false
    install(HttpTimeout) {
        requestTimeoutMillis = 15_000
        connectTimeoutMillis = 5_000
    }
}

// On iOS, Compose already maps each testTag to the accessibilityIdentifier used by XCUITest.
actual fun Modifier.exposeTestTags(): Modifier = this

class UserDefaultsStore : KeyValueStore {
    private val defaults = NSUserDefaults.standardUserDefaults

    override fun get(key: String): String? = defaults.stringForKey(key)

    override fun set(key: String, value: String?) {
        if (value == null) defaults.removeObjectForKey(key) else defaults.setObject(value, key)
    }
}
