package com.foodmarketplace.app.state

/**
 * Deep links in the format `foodmarket://open/<route>?<parameters>`.
 *
 * Routes (the same as the web version of the marketplace):
 * - `/`                       company list
 * - `/companies/<companyId>`  company products
 * - `/login`                  login, with the optional `next` parameter (route opened after signing in)
 * - `/cart`                   cart, checkout and payment
 * - anything else             "Page not found"
 *
 * Optional parameters, used by the automated tests to prepare a scenario quickly
 * (the mobile equivalent of setting localStorage in a web test):
 * - `user=<username>`  starts the session of that user; `user=` (empty) ends the session
 * - `api=<url>`        changes the API base URL, for example `http://127.0.0.1:3101/api`
 */
data class DeepLink(
    val screen: Screen,
    val sessionUser: String?,
    val clearSession: Boolean,
    val apiBaseUrl: String?,
) {
    companion object {
        const val SCHEME = "foodmarket"
        const val HOST = "open"

        fun parse(url: String): DeepLink? {
            val prefix = "$SCHEME://$HOST"
            if (!url.startsWith(prefix)) return null
            val rest = url.removePrefix(prefix)
            if (rest.isNotEmpty() && rest[0] != '/' && rest[0] != '?') return null
            val path = rest.substringBefore('?').ifEmpty { "/" }
            val query = parseQuery(rest.substringAfter('?', ""))
            val user = query["user"]
            return DeepLink(
                screen = routeToScreen(path, query["next"]),
                sessionUser = user?.takeIf { it.isNotEmpty() },
                clearSession = user != null && user.isEmpty(),
                apiBaseUrl = query["api"]?.takeIf { it.isNotEmpty() },
            )
        }

        fun routeToScreen(path: String, next: String? = null): Screen {
            val clean = path.trimEnd('/').ifEmpty { "/" }
            val company = Regex("^/companies/([^/]+)$").find(clean)
            return when {
                clean == "/" -> Screen.Home()
                // Only internal routes are accepted in `next`, which blocks external redirects.
                clean == "/login" -> Screen.Login(
                    next?.takeIf { it.startsWith("/") && !it.startsWith("//") }?.let { routeToScreen(it) },
                )
                clean == "/cart" -> Screen.Cart()
                company != null -> Screen.CompanyDetail(percentDecode(company.groupValues[1]))
                else -> Screen.NotFound("Page not found")
            }
        }

        private fun parseQuery(query: String): Map<String, String> =
            query.split('&').filter { it.isNotEmpty() }.associate { pair ->
                percentDecode(pair.substringBefore('=')) to percentDecode(pair.substringAfter('=', ""))
            }

        private fun percentDecode(value: String): String {
            val bytes = ArrayList<Byte>(value.length)
            var index = 0
            while (index < value.length) {
                val char = value[index]
                val hex = if (char == '%' && index + 3 <= value.length) {
                    value.substring(index + 1, index + 3).toIntOrNull(16)
                } else {
                    null
                }
                when {
                    hex != null -> {
                        bytes.add(hex.toByte())
                        index += 3
                    }
                    char == '+' -> {
                        bytes.add(' '.code.toByte())
                        index++
                    }
                    else -> {
                        char.toString().encodeToByteArray().forEach { bytes.add(it) }
                        index++
                    }
                }
            }
            return bytes.toByteArray().decodeToString()
        }
    }
}
