package com.foodmarketplace.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.foodmarketplace.app.platform.SharedPreferencesStore
import com.foodmarketplace.app.platform.createHttpClient
import com.foodmarketplace.app.state.AppState

/** Keeps a single AppState per process, so rotation and deep links reuse the same session. */
object AppGraph {
    private var instance: AppState? = null

    fun state(activity: ComponentActivity): AppState =
        instance ?: AppState(SharedPreferencesStore(activity.applicationContext), createHttpClient()).also {
            instance = it
        }
}

class MainActivity : ComponentActivity() {

    private val state by lazy { AppGraph.state(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        handleIntent(intent)

        // System back: previous screen, like the browser back button. On the first screen, closes the app.
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (!state.back()) finish()
            }
        })

        setContent { App(state) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.dataString?.let { state.handleDeepLink(it) }
    }
}
