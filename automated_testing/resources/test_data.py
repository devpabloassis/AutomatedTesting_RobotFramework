"""Test data shared by the API and mobile suites."""

SEED_USERS = ["user_manual", "user_robot", "user_hybrid", "user_fail"]
SEED_PASSWORD = "loveMetalSongs@"
VALID_PASSWORD = "validPass1"

COMPANY_IDS = ["pizzeria", "burgers", "japanese", "juices"]

MESSAGES = {
    "invalid_login": "Invalid username or password.",
    "added": "Product added to the cart.",
    "login_to_add": "Sign in to add products to the cart.",
    "quantity_limit": "Item quantity cannot exceed 99.",
    "quantity_range": "Quantity must be an integer from 1 to 99.",
    "empty_cart": "Your cart is empty.",
    "cart_is_empty": "The cart is empty.",
    "checkout_ok": "Order confirmed",
    "mixed_companies": "The cart has items from different companies. The order cannot be completed.",
    "paid": "Fake payment completed",
    "internal_error": "Internal error.",
    "user_not_found": "User not found.",
}

# Each SQL injection scenario runs once for each payload below.
SQL_PAYLOADS = {
    "SQL-01": "' OR '1'='1",
    "SQL-02": "' OR 1=1--",
    "SQL-03": "admin'--",
    "SQL-04": "'; DROP TABLE users;--",
    "SQL-05": '" OR ""="',
    "SQL-06": "' UNION SELECT username, password FROM users--",
    "SQL-07": "1; SELECT pg_sleep(5)--",
    "SQL-08": "') OR ('1'='1",
}

COMPANY_NAMES = {
    "pizzeria": "Noble Oven Pizzeria",
    "burgers": "Hot Griddle Burgers",
    "japanese": "Japa Express",
    "juices": "Fresh Fruit Juices",
}

# Size labels shown in the app and the option id of each one.
SIZE_OPTIONS = {"Small": "S", "Medium": "M", "Large": "L"}
