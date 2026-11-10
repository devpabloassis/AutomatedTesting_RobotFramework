"""Object map: the id of every element used by the mobile tests.

The ids are defined with `testTag` in the Compose code
(application/src_mobile/composeApp/src/commonMain/kotlin/com/foodmarketplace/app/ui/TestTags.kt).
On Android each id is the `resource-id`; on iOS, the `accessibilityIdentifier`.
For repeated elements, the id includes the item, and the page resources build it, for example
`product-${product}-price` or `cart-item-${product}-${option}-subtotal`.
"""

SCREEN = {
    "home": "screen-home",
    "company": "screen-company",
    "login": "screen-login",
    "cart": "screen-cart",
    "not_found": "screen-not-found",
    "loading": "loading",
}

COMMON = {
    "page_title": "page-title",
    "page_subtitle": "page-subtitle",
    "message": "message",
    "back_to_companies": "back-to-companies",
}

HEADER = {
    "brand": "header-brand",
    "cart_link": "header-cart-link",
    "cart_count": "cart-count",
    "logged_user": "logged-user",
    "logout_button": "logout-button",
    "login_link": "login-link",
}

HOME = {
    "company_list": "company-list",
    # Card ids: company-<companyId>, company-<companyId>-name, company-<companyId>-description
    "company_card_pattern": r"^company-(?!list$)[a-z]+$",
}

COMPANY = {
    "product_list": "product-list",
    # Card ids: product-<productId>, product-<productId>-name, -price, -size, -size-<optionId>, -add
    "product_card_pattern": r"^product-(?!list$)(?!.*-(name|price|size|add)$)[a-z-]+$",
}

CONFIRM_DIALOG = {
    "dialog": "confirm-dialog",
    "title": "confirm-title",
    "text": "confirm-text",
    "yes_button": "confirm-yes",
    "no_button": "confirm-no",
}

LOGIN = {
    "form": "login-form",
    "username": "login-username",
    "password": "login-password",
    "submit_button": "login-submit",
}

CART = {
    "empty_message": "cart-empty-message",
    "view_companies_link": "cart-view-companies",
    "login_message": "cart-login-message",
    "login_button": "cart-login-button",
    "item_list": "cart-list",
    # Item row: cart-item-<productId>-<optionId>, with the suffixes -name, -details,
    # -unit-price, -subtotal, -quantity, -update and -delete
    "total": "cart-total",
    "checkout_button": "checkout-button",
    "pay_button": "pay-button",
}
