package com.foodmarketplace.app.ui

/**
 * Identifiers of every element used by the automated tests.
 * On Android each one becomes the `resource-id`; on iOS, the `accessibilityIdentifier`.
 * For repeated elements, the identifier includes the item id.
 * The test project keeps the same ids in its object map: automated_testing/resources/mobile/ObjectMap.py.
 */
object TestTags {
    // Screens
    const val SCREEN_HOME = "screen-home"
    const val SCREEN_COMPANY = "screen-company"
    const val SCREEN_LOGIN = "screen-login"
    const val SCREEN_CART = "screen-cart"
    const val SCREEN_NOT_FOUND = "screen-not-found"
    const val LOADING = "loading"

    // Common
    const val PAGE_TITLE = "page-title"
    const val PAGE_SUBTITLE = "page-subtitle"
    const val MESSAGE = "message"
    const val BACK_TO_COMPANIES = "back-to-companies"

    // Header
    const val HEADER_BRAND = "header-brand"
    const val HEADER_CART_LINK = "header-cart-link"
    const val CART_COUNT = "cart-count"
    const val LOGGED_USER = "logged-user"
    const val LOGOUT_BUTTON = "logout-button"
    const val LOGIN_LINK = "login-link"

    // Home
    const val COMPANY_LIST = "company-list"
    fun company(companyId: String) = "company-$companyId"
    fun companyName(companyId: String) = "company-$companyId-name"
    fun companyDescription(companyId: String) = "company-$companyId-description"

    // Company
    const val PRODUCT_LIST = "product-list"
    fun product(productId: String) = "product-$productId"
    fun productName(productId: String) = "product-$productId-name"
    fun productPrice(productId: String) = "product-$productId-price"
    fun productSize(productId: String) = "product-$productId-size"
    fun productSizeOption(productId: String, optionId: String) = "product-$productId-size-$optionId"
    fun productAdd(productId: String) = "product-$productId-add"

    // Company switch warning
    const val CONFIRM_DIALOG = "confirm-dialog"
    const val CONFIRM_TITLE = "confirm-title"
    const val CONFIRM_TEXT = "confirm-text"
    const val CONFIRM_YES = "confirm-yes"
    const val CONFIRM_NO = "confirm-no"

    // Login
    const val LOGIN_FORM = "login-form"
    const val LOGIN_USERNAME = "login-username"
    const val LOGIN_PASSWORD = "login-password"
    const val LOGIN_SUBMIT = "login-submit"

    // Cart
    const val CART_EMPTY_MESSAGE = "cart-empty-message"
    const val CART_VIEW_COMPANIES = "cart-view-companies"
    const val CART_LOGIN_MESSAGE = "cart-login-message"
    const val CART_LOGIN_BUTTON = "cart-login-button"
    const val CART_LIST = "cart-list"
    fun cartItem(productId: String, optionId: String) = "cart-item-$productId-$optionId"
    const val CART_TOTAL = "cart-total"
    const val CHECKOUT_BUTTON = "checkout-button"
    const val PAY_BUTTON = "pay-button"
}

/** Formats cents as US dollars, for example 662310 -> "$6,623.10". */
fun formatMoney(cents: Int): String {
    val sign = if (cents < 0) "-" else ""
    val absolute = kotlin.math.abs(cents)
    val dollars = (absolute / 100).toString().reversed().chunked(3).joinToString(",").reversed()
    val remainder = (absolute % 100).toString().padStart(2, '0')
    return "$sign$$dollars.$remainder"
}
