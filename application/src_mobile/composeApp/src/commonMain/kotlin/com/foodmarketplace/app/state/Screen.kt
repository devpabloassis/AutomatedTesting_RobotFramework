package com.foodmarketplace.app.state

/**
 * App screens. They are plain classes (not data classes) on purpose: every navigation creates a
 * new instance, so the screen reloads its data, the same way a web page does.
 */
sealed class Screen(val route: String) {
    class Home : Screen("/")
    class CompanyDetail(val companyId: String) : Screen("/companies/$companyId")
    class Login(val next: Screen? = null) : Screen("/login")
    class Cart : Screen("/cart")
    class NotFound(val title: String) : Screen("/not-found")
}
