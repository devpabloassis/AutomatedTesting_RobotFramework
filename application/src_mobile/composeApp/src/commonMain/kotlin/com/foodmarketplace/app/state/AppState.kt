package com.foodmarketplace.app.state

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.foodmarketplace.app.api.ApiException
import com.foodmarketplace.app.api.MarketApi
import com.foodmarketplace.app.platform.KeyValueStore
import io.ktor.client.HttpClient
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

data class Message(val text: String, val isError: Boolean)

class Confirmation(val text: String, internal val answer: CompletableDeferred<Boolean>)

/**
 * Single source of truth of the app: session, navigation stack, screen message,
 * cart counter and the company switch warning.
 */
class AppState(private val store: KeyValueStore, httpClient: HttpClient) {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    var apiBaseUrl by mutableStateOf(store.get(KEY_API_BASE_URL) ?: DEFAULT_API_BASE_URL)
        private set

    val api = MarketApi(httpClient) { apiBaseUrl }

    var session by mutableStateOf(store.get(KEY_SESSION))
        private set

    val backStack = mutableStateListOf<Screen>(Screen.Home())
    val current: Screen get() = backStack.last()

    var message by mutableStateOf<Message?>(null)
        private set

    var cartCount by mutableStateOf(0)

    var confirmation by mutableStateOf<Confirmation?>(null)
        private set

    init {
        refreshCartCount()
    }

    // Navigation

    fun navigate(screen: Screen) {
        backStack.add(screen)
        onScreenChanged()
    }

    fun replace(screen: Screen) {
        backStack.removeAt(backStack.lastIndex)
        backStack.add(screen)
        onScreenChanged()
    }

    fun goHome() {
        backStack.clear()
        backStack.add(Screen.Home())
        onScreenChanged()
    }

    /** Returns false when there is no previous screen, so the platform can close the app. */
    fun back(): Boolean {
        if (backStack.size <= 1) return false
        backStack.removeAt(backStack.lastIndex)
        // The previous screen is shown again with fresh data, like the browser back button.
        val previous = backStack.removeAt(backStack.lastIndex)
        backStack.add(reload(previous))
        onScreenChanged()
        return true
    }

    private fun reload(screen: Screen): Screen = when (screen) {
        is Screen.Home -> Screen.Home()
        is Screen.CompanyDetail -> Screen.CompanyDetail(screen.companyId)
        is Screen.Login -> Screen.Login(screen.next)
        is Screen.Cart -> Screen.Cart()
        is Screen.NotFound -> Screen.NotFound(screen.title)
    }

    private fun onScreenChanged() {
        message = null
        refreshCartCount()
    }

    // Session

    fun signIn(username: String, next: Screen?) {
        persistSession(username)
        // Returns to the screen that asked for the login, or to the company list.
        if (next == null) {
            goHome()
        } else {
            backStack.removeAt(backStack.lastIndex)
            if (backStack.lastOrNull()?.route == next.route) {
                backStack.removeAt(backStack.lastIndex)
            }
            backStack.add(reload(next))
            onScreenChanged()
        }
    }

    fun signOut() {
        persistSession(null)
        cartCount = 0
        goHome()
    }

    private fun persistSession(username: String?) {
        session = username
        store.set(KEY_SESSION, username)
    }

    // Messages

    fun showMessage(text: String) {
        message = Message(text, isError = false)
    }

    fun showError(text: String) {
        message = Message(text, isError = true)
    }

    fun clearMessage() {
        message = null
    }

    // Cart counter: the sum of the quantities in the cart returned by the API.

    fun refreshCartCount() {
        val username = session
        if (username == null) {
            cartCount = 0
            return
        }
        scope.launch {
            cartCount = try {
                api.cart(username).totalItems
            } catch (error: ApiException) {
                0
            }
        }
    }

    // Company switch warning

    suspend fun askConfirmation(text: String): Boolean {
        val pending = Confirmation(text, CompletableDeferred())
        confirmation = pending
        return try {
            pending.answer.await()
        } finally {
            confirmation = null
        }
    }

    fun answerConfirmation(confirmed: Boolean) {
        confirmation?.answer?.complete(confirmed)
    }

    // Deep links

    fun handleDeepLink(url: String) {
        val link = DeepLink.parse(url) ?: return
        link.apiBaseUrl?.let {
            apiBaseUrl = it
            store.set(KEY_API_BASE_URL, it)
        }
        if (link.clearSession) persistSession(null)
        link.sessionUser?.let { persistSession(it) }
        answerConfirmation(false)
        backStack.clear()
        backStack.add(Screen.Home())
        if (link.screen !is Screen.Home) backStack.add(link.screen)
        onScreenChanged()
    }

    companion object {
        /** Default API address. On a physical device, `adb reverse tcp:3000 tcp:3000` makes it work. */
        const val DEFAULT_API_BASE_URL = "http://127.0.0.1:3000/api"
        private const val KEY_SESSION = "marketplace.user"
        private const val KEY_API_BASE_URL = "marketplace.apiBaseUrl"
    }
}
