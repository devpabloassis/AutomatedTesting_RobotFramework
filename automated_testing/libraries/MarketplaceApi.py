"""Robot Framework library for the Food Marketplace API.

It keeps the state of one test (user, item, last response...), replaces the {placeholders}
used in the request paths and bodies of the .robot files, and implements the assertions.
The library scope is TEST: every test starts with a clean state.
"""

import http.client
import json
import re
import secrets
import string
import sys
import uuid
from pathlib import Path
from urllib.parse import quote, urlsplit

from robot.api import logger
from robot.api.deco import keyword, library

sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "config"))
from server_process import ServerProcess, free_port  # noqa: E402
import settings  # noqa: E402

PLACEHOLDER = re.compile(r"\{([a-z0-9_]+)\}")
SENSITIVE_FIELDS = ["password", "salt", "hash"]
SEED_USERS = ["user_manual", "user_robot", "user_hybrid", "user_fail"]
VALID_PASSWORD = "validPass1"


def unique_name() -> str:
    """Unique names let the tests run again against the same database."""
    return "u" + uuid.uuid4().hex[:20]


def random_from(alphabet: str, length: int = 20) -> str:
    return "".join(secrets.choice(alphabet) for _ in range(length))


def parse_item(reference: str) -> dict:
    """Item reference in the "company/product/option" format, for example "pizzeria/supreme/M"."""
    company_id, product_id, option_id = reference.split("/")
    return {"companyId": company_id, "productId": product_id, "optionId": option_id}


def product_list(text: str) -> list:
    return [product.strip() for product in text.split(",") if product.strip()]


def matches(actual, expected) -> bool:
    """Partial deep comparison: objects may have extra keys; arrays must have the same length."""
    if isinstance(expected, dict):
        return isinstance(actual, dict) and all(
            key in actual and matches(actual[key], value) for key, value in expected.items()
        )
    if isinstance(expected, list):
        return (
            isinstance(actual, list)
            and len(actual) == len(expected)
            and all(matches(a, e) for a, e in zip(actual, expected))
        )
    if isinstance(expected, bool) or isinstance(actual, bool):
        return type(expected) is type(actual) and expected == actual
    return actual == expected


class Response:
    def __init__(self, status: int, headers: dict, text: str):
        self.status = status
        self.headers = {name.lower(): value for name, value in headers.items()}
        self.text = text
        try:
            self.json = json.loads(text)
        except ValueError:
            self.json = None


@library(scope="TEST", listener="SELF")
class MarketplaceApi:
    ROBOT_LISTENER_API_VERSION = 3

    def __init__(self, api_url: str = settings.API_URL):
        self.api_url = api_url.rstrip("/")
        self.username = None
        self.other_username = None
        self.item_id = None
        self.other_item_id = None
        self.payload = None
        self.generated_name = None
        self.generated_password = None
        self.last_body = None
        self.response = None
        self.cart_snapshot = None
        self.seed_created_at = None
        self.isolated_server = None

    # Listener: the isolated server of a test is always stopped at the end of the test.
    def _end_test(self, data, result):
        if self.isolated_server:
            self.isolated_server.stop()
            self.isolated_server = None

    # ------------------------------------------------------------------ helpers

    def _required(self, value, description):
        if value is None:
            raise AssertionError(f"The test has not defined {description} yet.")
        return value

    def _url(self, path: str) -> str:
        base = self.isolated_server.url if self.isolated_server else self.api_url
        return f"{base}{path}"

    def _request(self, method: str, path: str, body=None) -> Response:
        """Sends the request with http.client, so the path reaches the server exactly as written
        (other clients normalize invalid percent-encoding, which TC-API-DOM-076 needs to send)."""
        url = urlsplit(self._url(path))
        headers = {}
        data = None
        if body is not None:
            data = body.encode("utf-8") if isinstance(body, str) else json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"
        connection = http.client.HTTPConnection(url.hostname, url.port, timeout=15)
        try:
            target = url.path + (f"?{url.query}" if url.query else "")
            connection.request(method, target, body=data, headers=headers)
            raw = connection.getresponse()
            return Response(raw.status, dict(raw.getheaders()), raw.read().decode("utf-8"))
        finally:
            connection.close()

    def _cart_path(self, username: str) -> str:
        return f"/users/{quote(username, safe='')}/cart"

    def _cart(self, username: str) -> dict:
        response = self._request("GET", self._cart_path(username))
        if response.status != 200:
            raise AssertionError(f"Could not read the cart of {username}: {response.status} {response.text}")
        return response.json

    def _add(self, username: str, item: dict) -> dict:
        response = self._request("POST", f"{self._cart_path(username)}/items", item)
        if response.status != 201:
            raise AssertionError(f"Could not add {item} to the cart: {response.status} {response.text}")
        return response.json

    def _create_user(self, username: str, password: str = VALID_PASSWORD) -> None:
        response = self._request("POST", "/users", {"username": username, "password": password})
        if response.status != 201:
            raise AssertionError(f"Could not create the user {username}: {response.status} {response.text}")

    def _free_underscore_name(self) -> str:
        for length in range(3, 31):
            name = "_" * length
            if self._request("GET", f"/users/{name}").status == 404:
                return name
        raise AssertionError("Reset the test database: every underscore-only name has already been created.")

    def _placeholder_value(self, key: str) -> str:
        values = {
            "user": lambda: self._required(self.username, "the user"),
            "other_user": lambda: self._required(self.other_username, "the other user"),
            "item": lambda: self._required(self.item_id, "the item"),
            "other_item": lambda: self._required(self.other_item_id, "the other user's item"),
            "payload": lambda: self._required(self.payload, "the payload"),
            "generated_name": lambda: self._required(self.generated_name, "a generated name"),
            "name_3_chars": lambda: unique_name()[-3:],
            "name_30_chars": lambda: unique_name().ljust(30, "x"),
            "unique_lowercase": lambda: random_from(string.ascii_lowercase),
            "unique_uppercase": lambda: random_from(string.ascii_uppercase),
            "unique_digits": lambda: random_from(string.digits),
            "unique_mix": lambda: "Ab_12" + random_from("abc123"),
            "free_underscores": self._free_underscore_name,
        }
        if key == "unique_name":
            self.generated_name = unique_name()
            return self.generated_name
        if key == "unique_password":
            self.generated_password = f"secret{unique_name()}"
            return self.generated_password
        if key not in values:
            raise AssertionError(f"Unknown placeholder: {{{key}}}")
        return values[key]()

    def resolve(self, text: str, mode: str = "body") -> str:
        """Replaces each {placeholder}. In paths the value is URL-encoded; in bodies, JSON-escaped."""
        cache = {}
        for key in PLACEHOLDER.findall(text):
            if key not in cache:
                cache[key] = self._placeholder_value(key)

        def replace(match):
            value = cache[match.group(1)]
            return quote(value, safe="-_.!~*'()") if mode == "path" else json.dumps(value, ensure_ascii=False)[1:-1]

        return PLACEHOLDER.sub(replace, text)

    def _last(self) -> Response:
        return self._required(self.response, "a response")

    # ------------------------------------------------------------------ setup through the API

    @keyword
    def create_new_user(self) -> str:
        """Creates a user through the API and makes it the user of the test."""
        self.username = unique_name()
        self.item_id = None
        self.cart_snapshot = None
        self._create_user(self.username)
        return self.username

    @keyword
    def get_test_user(self) -> str:
        return self._required(self.username, "the user")

    @keyword
    def get_unique_name(self) -> str:
        return unique_name()

    @keyword
    def create_another_user_with_item(self, reference: str) -> str:
        self.other_username = unique_name()
        self._create_user(self.other_username)
        cart = self._add(self.other_username, parse_item(reference))
        self.other_item_id = cart["items"][0]["id"]
        return self.other_username

    @keyword
    def add_item_to_user_cart(self, reference: str, quantity: int = 1) -> None:
        item = parse_item(reference)
        cart = self._add(self._required(self.username, "the user"), {**item, "quantity": int(quantity)})
        if self.item_id is None:
            self.item_id = next(
                candidate["id"]
                for candidate in cart["items"]
                if candidate["productId"] == item["productId"] and candidate["optionId"] == item["optionId"]
            )

    @keyword
    def add_item_with_company_switch(self, reference: str) -> None:
        """Adds an item with replaceCart: true, the same request the app sends after "Yes"."""
        self._add(self._required(self.username, "the user"), {**parse_item(reference), "replaceCart": True})

    @keyword
    def build_cart_with_different_companies(self) -> None:
        """This cart can only be built because of BUG-01."""
        self.add_item_to_user_cart("pizzeria/supreme/M")
        self.add_item_with_company_switch("burgers/double/R")

    @keyword
    def empty_user_cart(self) -> None:
        username = self._required(self.username, "the user")
        for item in self._cart(username)["items"]:
            response = self._request("DELETE", f"{self._cart_path(username)}/items/{item['id']}")
            if response.status != 200:
                raise AssertionError(f"Could not remove the item {item['id']}: {response.status}")

    @keyword
    def get_user_cart(self) -> dict:
        return self._cart(self._required(self.username, "the user"))

    @keyword
    def save_cart_state(self) -> None:
        self.cart_snapshot = self.get_user_cart()

    # ------------------------------------------------------------------ cart assertions (through the API)

    @keyword
    def user_cart_should_have_items(self, count: int) -> None:
        items = self.get_user_cart()["items"]
        if len(items) != int(count):
            raise AssertionError(f"Expected {count} item(s) in the cart, found {len(items)}: {items}")

    @keyword
    def user_cart_should_contain_only_products(self, products: str) -> None:
        actual = [item["productId"] for item in self.get_user_cart()["items"]]
        expected = product_list(products)
        if actual != expected:
            raise AssertionError(f"Expected the cart products {expected}, found {actual}")

    @keyword
    def user_cart_should_contain_item(self, reference: str, quantity: int) -> None:
        expected = {**parse_item(reference), "quantity": int(quantity)}
        items = self.get_user_cart()["items"]
        if not any(matches(item, expected) for item in items):
            raise AssertionError(f"The cart does not contain {expected}. Items: {items}")

    @keyword
    def item_quantity_in_cart_should_be(self, quantity: int) -> None:
        item_id = self._required(self.item_id, "the item")
        item = next((item for item in self.get_user_cart()["items"] if item["id"] == item_id), None)
        actual = item["quantity"] if item else None
        if actual != int(quantity):
            raise AssertionError(f"Expected the item quantity {quantity}, found {actual}")

    @keyword
    def other_user_cart_should_have_items(self, count: int) -> None:
        items = self._cart(self._required(self.other_username, "the other user"))["items"]
        if len(items) != int(count):
            raise AssertionError(f"Expected {count} item(s) in the other user's cart, found {len(items)}")

    @keyword
    def other_user_item_quantity_should_be(self, quantity: int) -> None:
        items = self._cart(self._required(self.other_username, "the other user"))["items"]
        item = next((item for item in items if item["id"] == self.other_item_id), None)
        actual = item["quantity"] if item else None
        if actual != int(quantity):
            raise AssertionError(f"Expected the other user's item quantity {quantity}, found {actual}")

    @keyword
    def user_cart_should_not_have_changed(self) -> None:
        current = self.get_user_cart()
        saved = self._required(self.cart_snapshot, "the saved cart state")
        if current != saved:
            raise AssertionError(f"The cart changed.\nBefore: {saved}\nAfter:  {current}")

    @keyword
    def user_cart_total_items(self) -> int:
        return self.get_user_cart()["totalItems"]

    # ------------------------------------------------------------------ requests

    @keyword
    def send_request(self, method: str, path: str, body: str = None) -> None:
        resolved_path = self.resolve(path, "path")
        resolved_body = None if body is None else self.resolve(body, "body")
        try:
            self.last_body = None if resolved_body is None else json.loads(resolved_body)
        except ValueError:
            self.last_body = None
        logger.info(f"{method} {self._url(resolved_path)}\n{resolved_body or ''}")
        self.response = self._request(method, resolved_path, resolved_body)
        logger.info(f"Response {self.response.status}: {self.response.text[:2000]}")

    @keyword
    def send_request_with_large_password(self, method: str, path: str, kilobytes: int) -> None:
        body = json.dumps({"username": unique_name(), "password": "x" * (int(kilobytes) * 1024)})
        self.response = self._request(method, self.resolve(path, "path"), body)

    @keyword
    def set_sql_injection_payload(self, payload: str) -> None:
        self.payload = payload

    # ------------------------------------------------------------------ response assertions

    @keyword
    def response_status_should_be(self, status: int) -> None:
        response = self._last()
        if response.status != int(status):
            raise AssertionError(f"Expected status {status}, received {response.status}: {response.text}")

    @keyword
    def response_should_be_error(self, status: int, code: str) -> None:
        self.response_status_should_be(status)
        actual = (self._last().json or {}).get("code") if isinstance(self._last().json, dict) else None
        if actual != code:
            raise AssertionError(f'Expected the error code "{code}", received "{actual}"')

    @keyword
    def error_message_should_be(self, message: str) -> None:
        actual = (self._last().json or {}).get("message")
        if actual != message:
            raise AssertionError(f'Expected the message "{message}", received "{actual}"')

    @keyword
    def response_should_contain(self, expected: str) -> None:
        expected_json = json.loads(self.resolve(expected, "body"))
        if not matches(self._last().json, expected_json):
            raise AssertionError(
                f"The response does not contain the expected values.\n"
                f"Expected (partial): {json.dumps(expected_json)}\nReceived: {self._last().text}"
            )

    @keyword
    def response_should_be_exactly(self, expected: str) -> None:
        expected_json = json.loads(self.resolve(expected, "body"))
        if self._last().json != expected_json:
            raise AssertionError(f"Expected: {json.dumps(expected_json)}\nReceived: {self._last().text}")

    @keyword
    def get_response_body(self):
        return self._last().json

    @keyword
    def get_response_status(self) -> int:
        return self._last().status

    @keyword
    def response_should_have_creation_date(self) -> None:
        if not (self._last().json or {}).get("createdAt"):
            raise AssertionError(f"The response has no createdAt: {self._last().text}")

    @keyword
    def response_should_not_contain_password_data(self) -> None:
        body = self._last().json or {}
        present = [field for field in SENSITIVE_FIELDS if field in body]
        if present:
            raise AssertionError(f"The response exposes sensitive fields: {present}")

    @keyword
    def response_should_not_contain_the_payload(self) -> None:
        escaped = json.dumps(self._required(self.payload, "the payload"), ensure_ascii=False)[1:-1]
        if escaped in self._last().text:
            raise AssertionError("The response contains the payload.")

    @keyword
    def returned_cart_should_have_items(self, count: int) -> None:
        items = (self._last().json or {}).get("items", [])
        if len(items) != int(count):
            raise AssertionError(f"Expected {count} item(s) in the returned cart, found {len(items)}")

    @keyword
    def returned_cart_should_contain_only_products(self, products: str) -> None:
        actual = [item["productId"] for item in (self._last().json or {}).get("items", [])]
        if actual != product_list(products):
            raise AssertionError(f"Expected the products {product_list(products)}, found {actual}")

    @keyword
    def response_header_should_contain(self, name: str, value: str) -> None:
        actual = self._last().headers.get(name.lower(), "")
        if value not in actual:
            raise AssertionError(f'Header "{name}" is "{actual}", expected it to contain "{value}"')

    @keyword
    def login_with_sent_credentials_should_return(self, status: int) -> None:
        body = self._required(self.last_body, "the sent body")
        response = self._request("POST", "/login", {"username": body["username"], "password": body["password"]})
        if response.status != int(status):
            raise AssertionError(f"Login returned {response.status}, expected {status}: {response.text}")

    # ------------------------------------------------------------------ catalog

    @keyword
    def response_should_have_companies_with_products(self, companies: int, products: int) -> None:
        body = self._last().json
        if len(body) != int(companies):
            raise AssertionError(f"Expected {companies} companies, found {len(body)}")
        for company in body:
            if len(company["products"]) != int(products):
                raise AssertionError(f"{company['id']} has {len(company['products'])} products, expected {products}")

    @keyword
    def catalog_prices_should_be(self, company: str, product: str, prices: str) -> None:
        companies = self._request("GET", "/companies").json
        found = next((c for c in companies if c["id"] == company), {"products": []})
        product_data = next((p for p in found["products"] if p["id"] == product), None)
        actual = [option["priceCents"] for option in product_data["options"]] if product_data else None
        expected = [int(price) for price in prices.split(",")]
        if actual != expected:
            raise AssertionError(f"{company}/{product}: expected prices {expected}, found {actual}")

    @keyword
    def company_should_be_returned_by_its_id(self, company_id: str) -> None:
        response = self._request("GET", f"/companies/{quote(company_id, safe='')}")
        if response.status != 200 or response.json.get("id") != company_id:
            raise AssertionError(f"Fetching {company_id} returned {response.status}: {response.text[:300]}")

    @keyword
    def products_of_company_should_have_options(self, company_id: str, options: str) -> None:
        expected = [option.strip() for option in options.split(",")]
        for product in self._request("GET", f"/companies/{company_id}").json["products"]:
            actual = [option["id"] for option in product["options"]]
            if actual != expected:
                raise AssertionError(f"{company_id}/{product['id']}: expected options {expected}, found {actual}")

    # ------------------------------------------------------------------ users

    @keyword
    def user_should_be_found(self, username: str) -> None:
        response = self._request("GET", f"/users/{quote(username, safe='')}")
        if response.status != 200 or response.json.get("username") != username:
            raise AssertionError(f"{username}: GET returned {response.status}")

    @keyword
    def user_should_be_able_to_log_in(self, username: str, password: str) -> None:
        response = self._request("POST", "/login", {"username": username, "password": password})
        if response.status != 200:
            raise AssertionError(f"{username}: login returned {response.status}")

    # ------------------------------------------------------------------ persistence (isolated server)

    @keyword
    def use_isolated_server(self) -> None:
        """Starts a dedicated server and database, for scenarios that restart the system."""
        db_path = Path(settings.PROJECT_ROOT) / ".test-data" / f"isolated-{uuid.uuid4().hex[:8]}.json"
        self.isolated_server = ServerProcess(settings.API_SERVER_SCRIPT, free_port(), str(db_path))
        self.isolated_server.start(clean_database=True)

    @keyword
    def restart_isolated_server(self) -> None:
        self._required(self.isolated_server, "the isolated server").restart()

    def _seed_created_at(self) -> list:
        return [self._request("GET", f"/users/{user}").json["createdAt"] for user in SEED_USERS]

    @keyword
    def save_creation_date_of_seed_users(self) -> None:
        self.seed_created_at = self._seed_created_at()

    @keyword
    def creation_date_of_seed_users_should_be_unchanged(self) -> None:
        if self._seed_created_at() != self._required(self.seed_created_at, "the saved dates"):
            raise AssertionError("The creation date of a seed user changed after the restart.")

    def _database(self) -> str:
        return Path(self._required(self.isolated_server, "the isolated server").db_path).read_text("utf-8")

    @keyword
    def each_seed_user_should_appear_once_in_database(self) -> None:
        users = json.loads(self._database())["users"]
        for username in SEED_USERS:
            count = sum(1 for user in users if user["username"] == username)
            if count != 1:
                raise AssertionError(f"{username} appears {count} times in the database.")

    @keyword
    def database_should_not_contain_the_sent_password(self) -> None:
        if self._required(self.generated_password, "the generated password") in self._database():
            raise AssertionError("The password is stored in plain text.")

    @keyword
    def get_api_url(self) -> str:
        return self.api_url
