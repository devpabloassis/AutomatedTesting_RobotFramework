# Test Case Repository — API

> **Note:** this file exists only because no test management tool is integrated into this project. It is a way to **simulate** a test case repository that would normally live in a dedicated tool.

| Field | Value |
|---|---|
| System | Food Marketplace |
| Based on | [`PRODUCT_SPEC.md`](./PRODUCT_SPEC.md) v1.0 |
| Base URL | `http://127.0.0.1:3000/api` |
| Related repository | [`MOBILE_TEST_CASES.md`](./MOBILE_TEST_CASES.md) |

## 1. Conventions

- **Type:** `H` happy path, `A` alternative flow, `E` exception flow.
- **Expected result:** always describes the correct behavior. When an intentional defect prevents that result, the row shows **Expected failure** and the actual value.
- **`CODE` error:** means the given status with the body `{ "code": "CODE", "message": "..." }`.
- **Tags:** every test also has the Robot Framework tags `api` and `regression`. The column shows the others.
- **Automation:** each ID is a test case in `automated_testing/tests/api/`, named `<ID> - <title>`.
- **Test data:** scenarios that change a cart create their own user with `POST /users`, so they can run in parallel. The seed users are reserved for the scenarios that mention them. `<user>` stands for the scenario's user.

## 2. Input handling

The API handles **only the domain of the characters and values** of each field. There is no SQL injection-specific filter, escaping or blocking. A malicious payload is treated like any other text: it is rejected when it violates the field domain and, otherwise, follows the normal rule of the route.

| Field | Accepted domain | Outside the domain |
|---|---|---|
| `username` (creation) | String of 3 to 30 characters, only `A-Z`, `a-z`, `0-9` and `_` | 400 `VALIDATION_ERROR` |
| `password` (creation) | String with at least 8 characters; any character is accepted | 400 `VALIDATION_ERROR` |
| `username` and `password` (login) | String | 400 if not a string; 401 if it is a string with no match |
| `companyId`, `productId`, `optionId` | Exact catalog value, case-sensitive | 400 `VALIDATION_ERROR` |
| `quantity` | JSON integer from 1 to 99 | 400 `VALIDATION_ERROR` |
| `replaceCart` | Only the boolean `true` confirms the switch | Any other value means no confirmation |
| URL parameters | Text used only for lookup | Resource 404, no match |

## 3. Users

### 3.1 Create user — `POST /users` (BR-18, BR-19)

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-USR-001 | Create a valid user | H | Valid `username` and `password` | 201 with `username` and `createdAt`, without `password`, `salt` or `hash` | `smoke feature_user` |
| TC-API-USR-002 | Minimum username length | A | 3-character `username` | 201 | `feature_user` |
| TC-API-USR-003 | Maximum username length | A | 30-character `username` | 201 | `feature_user` |
| TC-API-USR-004 | Minimum password length | A | 8-character `password` | 201 | `feature_user` |
| TC-API-USR-005 | Username is case-sensitive | A | Create `Case_X` and `case_x` | 201 for both | `feature_user` |
| TC-API-USR-006 | Username already exists | E | Repeat a `username` | 409 `USER_ALREADY_EXISTS` | `feature_user` |
| TC-API-USR-007 | Username below minimum | E | 2 characters | 400 `VALIDATION_ERROR` | `feature_user` |
| TC-API-USR-008 | Username above maximum | E | 31 characters | 400 `VALIDATION_ERROR` | `feature_user` |
| TC-API-USR-009 | Password below minimum | E | 7 characters | 400 `VALIDATION_ERROR` | `feature_user` |
| TC-API-USR-010 | Missing username | E | Only `password` | 400 `VALIDATION_ERROR` | `feature_user` |
| TC-API-USR-011 | Missing password | E | Only `username` | 400 `VALIDATION_ERROR` | `feature_user` |
| TC-API-USR-012 | Empty body | E | No body | 400 `VALIDATION_ERROR` | `feature_user` |
| TC-API-USR-013 | Malformed JSON | E | `{"username":` | 400 `VALIDATION_ERROR` | `feature_user` |
| TC-API-USR-014 | Body is not an object | E | `[]` | 400 `VALIDATION_ERROR` | `feature_user` |
| TC-API-USR-015 | Body larger than 100 KB | E | JSON larger than 100 KB | 400 `VALIDATION_ERROR` | `feature_user` |

### 3.2 Fetch user — `GET /users/:username`

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-USR-020 | Fetch an existing user | H | Created user | 200 with `username` and `createdAt`, without password data | `smoke feature_user` |
| TC-API-USR-021 | Seed users exist | H | `user_manual`, `user_robot`, `user_hybrid`, `user_fail` | 200 for all four | `smoke feature_user` |
| TC-API-USR-022 | Non-existent user | E | Unregistered name | 404 `USER_NOT_FOUND` | `feature_user` |
| TC-API-USR-023 | Different letter case | E | `User_Manual` | 404 `USER_NOT_FOUND` | `feature_user` |

## 4. Login — `POST /login` (BR-03)

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-LOG-001 | Valid credentials | H | Correct username and password | 200 with `username`, without password data | `smoke feature_login` |
| TC-API-LOG-002 | Seed users can log in | H | The 4 users with `loveMetalSongs@` | 200 for all four | `smoke feature_login` |
| TC-API-LOG-003 | Wrong password | E | Wrong password | 401 `INVALID_CREDENTIALS` | `feature_login` |
| TC-API-LOG-004 | Non-existent user | E | Unregistered name | 401 with the same message as a wrong password | `feature_login` |
| TC-API-LOG-005 | Password with different case | E | `LOVEMETALSONGS@` | 401 `INVALID_CREDENTIALS` | `feature_login` |
| TC-API-LOG-006 | Missing username | E | Only `password` | 400 `VALIDATION_ERROR` | `feature_login` |
| TC-API-LOG-007 | Missing password | E | Only `username` | 400 `VALIDATION_ERROR` | `feature_login` |
| TC-API-LOG-008 | Non-string fields | E | `username: 123`, `password: 123` | 400 `VALIDATION_ERROR` | `feature_login` |

## 5. Catalog

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-CAT-001 | List companies | H | `GET /companies` | 200 with 4 companies, each with 4 products | `smoke feature_catalog` |
| TC-API-CAT-002 | Catalog prices | H | Compare with section 4 of the specification | All values in cents match | `feature_catalog` |
| TC-API-CAT-003 | Fetch each company | H | `pizzeria`, `burgers`, `japanese`, `juices` | 200 with the requested company | `feature_catalog` |
| TC-API-CAT-004 | Size options | A | `pizzeria` and `juices` | Products with options `S`, `M` and `L` | `feature_catalog` |
| TC-API-CAT-005 | Single option | A | `burgers` and `japanese` | Products with option `R` only | `feature_catalog` |
| TC-API-CAT-006 | Non-existent company | E | `GET /companies/nonexistent` | 404 `COMPANY_NOT_FOUND` | `feature_catalog` |
| TC-API-CAT-007 | Different letter case | E | `GET /companies/Pizzeria` | 404 `COMPANY_NOT_FOUND` | `feature_catalog` |

## 6. Cart

### 6.1 View — `GET /users/:username/cart` (BR-04, BR-12)

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-CRT-001 | Empty cart | H | New user | 200 with `items: []`, `companyIds: []`, `hasMixedCompanies: false`, `totalItems: 0`, `totalCents: 0` | `smoke feature_cart` |
| TC-API-CRT-002 | Cart with items | H | 2 × `supreme` `M` | 200 with item data, `subtotalCents: 10580`, `totalItems: 2`, `totalCents: 10580` | `feature_cart` |
| TC-API-CRT-003 | Independent carts | A | Items for user A; fetch B | B's cart is empty | `feature_cart` |
| TC-API-CRT-004 | Non-existent user | E | Unregistered name | 404 `USER_NOT_FOUND` | `feature_cart` |

### 6.2 Add — `POST /users/:username/cart/items` (BR-05 to BR-10)

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-CRT-010 | Add to an empty cart | H | `pizzeria/supreme/M`, `quantity: 1` | 201 with 1 item and `totalCents: 5290` | `smoke feature_cart` |
| TC-API-CRT-011 | Quantity omitted | A | No `quantity` | 201 with quantity 1 | `feature_cart` |
| TC-API-CRT-012 | Another product from the same company | A | 2 products from `pizzeria` | 201 with 2 items | `feature_cart` |
| TC-API-CRT-013 | Same product and option | A | Add `supreme/M` twice | 201 with 1 item and quantity 2 | `feature_cart` |
| TC-API-CRT-014 | Same product, another option | A | `supreme/S` and `supreme/L` | 201 with 2 items | `feature_cart` |
| TC-API-CRT-015 | Maximum quantity | A | `quantity: 99` | 201 with quantity 99 | `feature_cart` |
| TC-API-CRT-016 | Sum up to the limit | A | 98 and then 1 of the same item | 201 with quantity 99 | `feature_cart` |
| TC-API-CRT-017 | `replaceCart` with an empty cart | A | `replaceCart: true` | 201 with 1 item | `feature_cart` |
| TC-API-CRT-018 | `replaceCart` with the same company | A | `pizzeria` item, then another `pizzeria` item with `replaceCart: true` | 201 with 2 items, no company switch | `feature_cart` |
| TC-API-CRT-019 | Another company without confirmation | E | `pizzeria`, then `burgers` | 409 `CART_COMPANY_CONFLICT` and cart unchanged | `smoke feature_cart feature_company_switch` |
| TC-API-CRT-020 | Another company with confirmation | H | `pizzeria`, then `burgers` with `replaceCart: true` | 201 with only the `burgers` item. **Expected failure (BUG-01):** returns both items and `hasMixedCompanies: true` | `smoke feature_cart feature_company_switch known_bug` |
| TC-API-CRT-021 | Sum above the limit | E | 99 and then 1 of the same item | 422 `QUANTITY_LIMIT_EXCEEDED` and quantity 99 kept | `feature_cart` |
| TC-API-CRT-022 | Non-existent user | E | Unregistered name | 404 `USER_NOT_FOUND` | `feature_cart` |
| TC-API-CRT-023 | Non-existent company | E | `companyId: "x"` | 400 `VALIDATION_ERROR` | `feature_cart` |
| TC-API-CRT-024 | Non-existent product | E | `productId: "x"` | 400 `VALIDATION_ERROR` | `feature_cart` |
| TC-API-CRT-025 | Non-existent option | E | `optionId: "X"` | 400 `VALIDATION_ERROR` | `feature_cart` |
| TC-API-CRT-026 | Product from another company | E | `pizzeria/double/R` | 400 `VALIDATION_ERROR` | `feature_cart` |
| TC-API-CRT-027 | Option `R` on a sized product | E | `pizzeria/supreme/R` | 400 `VALIDATION_ERROR` | `feature_cart` |
| TC-API-CRT-028 | Size on a single-option product | E | `burgers/double/M` | 400 `VALIDATION_ERROR` | `feature_cart` |
| TC-API-CRT-029 | Missing required fields | E | Body `{}` | 400 `VALIDATION_ERROR` | `feature_cart` |

### 6.3 Update quantity — `PATCH /users/:username/cart/items/:itemId` (BR-10, BR-11)

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-CRT-030 | Update quantity | H | `quantity: 3` | 200 with quantity 3. **Expected failure (BUG-02):** quantity 6 | `smoke feature_cart known_bug` |
| TC-API-CRT-031 | Minimum quantity | A | `quantity: 1` | 200 with quantity 1. **Expected failure (BUG-02):** quantity 2 | `feature_cart known_bug` |
| TC-API-CRT-032 | Maximum quantity | A | `quantity: 99` | 200 with quantity 99. **Expected failure (BUG-02):** quantity 198, violating BR-10 | `feature_cart known_bug` |
| TC-API-CRT-033 | Recalculate amounts | H | `supreme/M`, `quantity: 3` | `subtotalCents` and `totalCents` equal to 15870, `totalItems: 3`. **Expected failure (BUG-02):** 31740 and `totalItems: 6` | `feature_cart known_bug` |
| TC-API-CRT-034 | Zero quantity | E | `quantity: 0` | 400 `VALIDATION_ERROR` and item unchanged | `feature_cart` |
| TC-API-CRT-035 | Above the maximum | E | `quantity: 100` | 400 `VALIDATION_ERROR` and item unchanged | `feature_cart` |
| TC-API-CRT-036 | Negative quantity | E | `quantity: -1` | 400 `VALIDATION_ERROR` and item unchanged | `feature_cart` |
| TC-API-CRT-037 | Missing quantity | E | Body `{}` | 400 `VALIDATION_ERROR` and item unchanged | `feature_cart` |
| TC-API-CRT-038 | Non-existent item | E | Unknown `itemId` | 404 `ITEM_NOT_FOUND` | `feature_cart` |
| TC-API-CRT-039 | Non-existent user | E | Unregistered name | 404 `USER_NOT_FOUND` | `feature_cart` |
| TC-API-CRT-040 | Another user's item | E | User A's `itemId` on user B's route | 404 `ITEM_NOT_FOUND` and A's item unchanged | `feature_cart` |

### 6.4 Remove — `DELETE /users/:username/cart/items/:itemId` (BR-13)

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-CRT-050 | Remove one of several items | H | Cart with 2 items | 200 with the remaining item and the total recalculated | `smoke feature_cart` |
| TC-API-CRT-051 | Remove the last item | A | Cart with 1 item | 200 with an empty cart and `totalCents: 0` | `feature_cart` |
| TC-API-CRT-052 | Non-existent item | E | Unknown `itemId` | 404 `ITEM_NOT_FOUND` | `feature_cart` |
| TC-API-CRT-053 | Item already removed | E | Remove twice | 404 `ITEM_NOT_FOUND` on the second call | `feature_cart` |
| TC-API-CRT-054 | Non-existent user | E | Unregistered name | 404 `USER_NOT_FOUND` | `feature_cart` |
| TC-API-CRT-055 | Another user's item | E | User A's `itemId` on user B's route | 404 `ITEM_NOT_FOUND` and A's item kept | `feature_cart` |

## 7. Checkout and payment

`TC-API-ORD-003` and `TC-API-ORD-013` build the mixed cart with `replaceCart: true`, which is only possible because of BUG-01. When that defect is fixed, the precondition will no longer be reachable through the API.

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-ORD-001 | Check out a valid cart | H | Items from one company; `POST .../checkout` | 200 with `status: READY_FOR_PAYMENT`, the total and the cart kept | `smoke feature_checkout` |
| TC-API-ORD-002 | Check out an empty cart | E | No items | 422 `CART_EMPTY` | `feature_checkout` |
| TC-API-ORD-003 | Check out with different companies | E | Mixed cart | 422 `CART_MIXED_COMPANIES` with the AC-06.2 message. **Expected failure (BUG-03):** 200 with `status: READY_FOR_PAYMENT` | `smoke feature_checkout known_bug` |
| TC-API-ORD-004 | Check out twice | A | Repeat with the valid cart | 200 both times | `feature_checkout` |
| TC-API-ORD-005 | Check out with a non-existent user | E | Unregistered name | 404 `USER_NOT_FOUND` | `feature_checkout` |
| TC-API-ORD-010 | Pay for a valid cart | H | After checkout; `POST .../pay` | 200 with `status: PAID`, `message: Fake payment completed` and an empty cart | `smoke feature_payment` |
| TC-API-ORD-011 | Pay without checking out first | A | Valid cart, no `checkout` | 200 with `status: PAID`, since the API revalidates the cart on every payment | `feature_payment` |
| TC-API-ORD-012 | Pay for an empty cart | E | No items | 422 `CART_EMPTY` | `feature_payment` |
| TC-API-ORD-013 | Pay with different companies | E | Mixed cart | 422 `CART_MIXED_COMPANIES` and cart kept | `feature_payment` |
| TC-API-ORD-014 | Pay twice | E | Repeat after payment | 422 `CART_EMPTY` on the second call | `feature_payment` |
| TC-API-ORD-015 | Pay with a non-existent user | E | Unregistered name | 404 `USER_NOT_FOUND` | `feature_payment` |

## 8. Field domain characters

### 8.1 `username` on creation

| ID | Scenario | Type | Value sent | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-DOM-001 | Lowercase only | A | `abcdef` | 201 | `domain` |
| TC-API-DOM-002 | Uppercase only | A | `ABCDEF` | 201 | `domain` |
| TC-API-DOM-003 | Digits only | A | `123456` | 201 | `domain` |
| TC-API-DOM-004 | Underscores only | A | `___` | 201 | `domain` |
| TC-API-DOM-005 | Valid combination | H | `Ab_12` | 201 | `domain` |
| TC-API-DOM-010 | Empty string | E | Empty string | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-011 | Inner space | E | `john doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-012 | Leading space | E | ` johndoe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-013 | Trailing space | E | `johndoe ` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-014 | Trailing line break | E | `johndoe` followed by `\n` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-015 | Tab | E | `john` `\t` `doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-016 | Hyphen | E | `john-doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-017 | Dot | E | `john.doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-018 | At sign | E | `john@doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-019 | Accented letter | E | `joão` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-020 | Cedilla | E | `façade` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-021 | Emoji | E | `john😀` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-022 | Single quote | E | `john'doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-023 | Double quote | E | `john"doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-024 | Semicolon | E | `john;doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-025 | Percent sign | E | `john%doe` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-026 | Slashes | E | `john/doe\x` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-027 | HTML markup | E | `<b>john</b>` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-028 | Number type | E | `123456` without quotes | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-029 | Null type | E | `null` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-030 | Array type | E | `["john_doe"]` | 400 `VALIDATION_ERROR` | `domain` |

### 8.2 `password` on creation

| ID | Scenario | Type | Value sent | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-DOM-040 | Symbols | A | `!@#$%^&*()` | 201, and logging in with the same password returns 200 | `domain` |
| TC-API-DOM-041 | Accents and cedilla | A | `açãoÉótima` | 201, and logging in with the same password returns 200 | `domain` |
| TC-API-DOM-042 | Spaces | A | `password with spaces` | 201, and logging in with the same password returns 200 | `domain` |
| TC-API-DOM-043 | Emoji | A | `secret😀😀😀😀` | 201, and logging in with the same password returns 200 | `domain` |
| TC-API-DOM-044 | Number type | E | `12345678` without quotes | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-045 | Null type | E | `null` | 400 `VALIDATION_ERROR` | `domain` |

### 8.3 `quantity`

Each value is sent to `POST .../cart/items` and, when indicated, to `PATCH .../cart/items/:itemId`.

| ID | Scenario | Type | Value sent | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-DOM-050 | Numeric string | E | `"3"`, in POST and PATCH | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-051 | Decimal | E | `1.5`, in POST and PATCH | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-052 | Alphabetic string | E | `"abc"`, in POST and PATCH | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-053 | Symbol | E | `"!"`, in POST and PATCH | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-054 | Boolean | E | `true`, in POST and PATCH | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-055 | Null | E | `null`, in POST and PATCH | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-056 | Array | E | `[1]`, in POST and PATCH | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-057 | Object | E | `{}`, in POST and PATCH | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-058 | Valid scientific notation | A | `1e1`, in POST | 201 with quantity 10, since the JSON represents the integer 10 | `domain` |
| TC-API-DOM-059 | Scientific notation above the limit | E | `1e2`, in POST | 400 `VALIDATION_ERROR` | `domain` |

### 8.4 Catalog identifiers

| ID | Scenario | Type | Value sent | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-DOM-060 | Uppercase `companyId` | E | `PIZZERIA` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-061 | Uppercase `productId` | E | `SUPREME` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-062 | Lowercase `optionId` | E | `m` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-063 | Space in `companyId` | E | `pizzeria ` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-064 | Space in `optionId` | E | ` M` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-065 | Accent in `productId` | E | `suprême` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-066 | Number type | E | `companyId: 1` | 400 `VALIDATION_ERROR` | `domain` |
| TC-API-DOM-067 | Null type | E | `optionId: null` | 400 `VALIDATION_ERROR` | `domain` |

### 8.5 `replaceCart` and URL parameters

| ID | Scenario | Type | Value sent | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-DOM-070 | `replaceCart` as string | E | `"true"`, with a company conflict | 409 `CART_COMPANY_CONFLICT` | `domain` |
| TC-API-DOM-071 | `replaceCart` as number | E | `1`, with a company conflict | 409 `CART_COMPANY_CONFLICT` | `domain` |
| TC-API-DOM-072 | `replaceCart` null | E | `null`, with a company conflict | 409 `CART_COMPANY_CONFLICT` | `domain` |
| TC-API-DOM-073 | `replaceCart` false | A | `false`, with a company conflict | 409 `CART_COMPANY_CONFLICT` | `domain` |
| TC-API-DOM-074 | Accent in the URL | E | `GET /users/jo%C3%A3o` | 404 `USER_NOT_FOUND` | `domain` |
| TC-API-DOM-075 | Space in the URL | E | `GET /users/john%20doe` | 404 `USER_NOT_FOUND` | `domain` |
| TC-API-DOM-076 | Invalid URL encoding | E | `GET /users/%E0%A4%A` | 400 `VALIDATION_ERROR` | `domain` |

## 9. SQL injection

Each scenario runs with **all** the payloads below. They work as the data set of a data-driven test: in Robot Framework, each test uses a `[Template]` with a `FOR` loop over the payloads (`resources/test_data.py`), and a failing payload does not stop the others. Values are sent as JSON or, in URL parameters, percent-encoded.

| ID | Payload |
|---|---|
| SQL-01 | `' OR '1'='1` |
| SQL-02 | `' OR 1=1--` |
| SQL-03 | `admin'--` |
| SQL-04 | `'; DROP TABLE users;--` |
| SQL-05 | `" OR ""="` |
| SQL-06 | `' UNION SELECT username, password FROM users--` |
| SQL-07 | `1; SELECT pg_sleep(5)--` |
| SQL-08 | `') OR ('1'='1` |

| ID | Scenario | Type | Field | Expected result | Reason | Tags |
|---|---|---|---|---|---|---|
| TC-API-SQL-001 | Create user | E | `username` | 400 `VALIDATION_ERROR` and user not created | Violates the field domain | `security sqli` |
| TC-API-SQL-002 | Create user | A | `password` | 201; the response does not contain the password | The password accepts any character | `security sqli` |
| TC-API-SQL-003 | Log in with the payload as the password | A | `password` | 200 only for the user created with that same text | The payload is an ordinary password | `security sqli` |
| TC-API-SQL-004 | Log in | E | `username`, with `user_manual`'s correct password | 401 `INVALID_CREDENTIALS` | There is no user with that name | `security sqli feature_login` |
| TC-API-SQL-005 | Log in | E | `user_manual`'s `password` | 401 `INVALID_CREDENTIALS` | The password does not match | `security sqli feature_login` |
| TC-API-SQL-006 | Fetch user | E | `:username` | 404 `USER_NOT_FOUND`, without returning other users | No match | `security sqli` |
| TC-API-SQL-007 | Fetch company | E | `:companyId` | 404 `COMPANY_NOT_FOUND` | No match | `security sqli` |
| TC-API-SQL-008 | Fetch cart | E | `:username` | 404 `USER_NOT_FOUND`, without returning other users' items | No match | `security sqli` |
| TC-API-SQL-009 | Add item | E | `companyId` | 400 `VALIDATION_ERROR` and cart unchanged | Not in the catalog | `security sqli` |
| TC-API-SQL-010 | Add item | E | `productId` | 400 `VALIDATION_ERROR` and cart unchanged | Not in the catalog | `security sqli` |
| TC-API-SQL-011 | Add item | E | `optionId` | 400 `VALIDATION_ERROR` and cart unchanged | Not in the catalog | `security sqli` |
| TC-API-SQL-012 | Add item | E | `quantity` | 400 `VALIDATION_ERROR` and cart unchanged | Not an integer | `security sqli` |
| TC-API-SQL-013 | Add item with a conflict | E | `replaceCart` | 409 `CART_COMPANY_CONFLICT` and cart unchanged | Not the boolean `true` | `security sqli` |
| TC-API-SQL-014 | Update item | E | `quantity` | 400 `VALIDATION_ERROR` and item unchanged | Not an integer | `security sqli` |
| TC-API-SQL-015 | Update item | E | `:itemId` | 404 `ITEM_NOT_FOUND` and the real item unchanged | No match | `security sqli` |
| TC-API-SQL-016 | Remove item | E | `:itemId` | 404 `ITEM_NOT_FOUND` and the real item kept | No match | `security sqli` |
| TC-API-SQL-017 | Check out and pay | E | `:username` | 404 `USER_NOT_FOUND` on both routes | No match | `security sqli` |
| TC-API-SQL-018 | Integrity after the attacks | H | — | The 4 seed users can still be fetched and can still log in | No data was affected | `security sqli smoke` |

## 10. Contract

The scenarios validate the response against the JSON Schemas in `automated_testing/contracts/`, described in [`API_ENDPOINTS.md`](./API_ENDPOINTS.md). All of them have the `contract` tag.

A response follows the contract when it has every required field, with the defined type and format, and **no extra field**. On failure, the test lists each violation, for example `[0].commissionPercent: field not allowed by the contract`.

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-CON-001 | Create user | H | Valid `POST /users` | 201 in the `user` contract | `smoke feature_user` |
| TC-API-CON-002 | Validation error when creating a user | E | 2-character `username` | 400 in the `error` contract | `feature_user` |
| TC-API-CON-003 | User already exists | E | Registered `username` | 409 in the `error` contract | `feature_user` |
| TC-API-CON-004 | Fetch user | H | `GET /users/<user>` | 200 in the `user` contract | `feature_user` |
| TC-API-CON-005 | Non-existent user | E | `GET /users/` with an unregistered name | 404 in the `error` contract | `feature_user` |
| TC-API-CON-006 | Valid login | H | `user_manual` with the correct password | 200 in the `user` contract | `smoke feature_login` |
| TC-API-CON-007 | Invalid login | E | Wrong password | 401 in the `error` contract | `feature_login` |
| TC-API-CON-008 | List companies | H | `GET /companies` | 200 in the `companies` contract, with no extra fields. **Expected failure (BUG-04):** each company has `commissionPercent` | `smoke feature_catalog known_bug` |
| TC-API-CON-009 | Fetch company | H | `GET /companies/pizzeria` | 200 in the `company` contract | `feature_catalog` |
| TC-API-CON-010 | Non-existent company | E | `GET /companies/nonexistent` | 404 in the `error` contract | `feature_catalog` |
| TC-API-CON-011 | Empty cart | H | `GET /users/<user>/cart` | 200 in the `cart` contract | `feature_cart` |
| TC-API-CON-012 | Cart with items | H | Cart with 2 items | 200 in the `cart` contract, including each item | `smoke feature_cart` |
| TC-API-CON-013 | Cart of a non-existent user | E | `GET /users/<nonexistent>/cart` | 404 in the `error` contract | `feature_cart` |
| TC-API-CON-014 | Add item | H | Valid `POST /cart/items` | 201 in the `cart` contract | `feature_cart` |
| TC-API-CON-015 | Invalid item | E | Option `R` for `orange` | 400 in the `error` contract | `feature_cart` |
| TC-API-CON-016 | Company conflict | E | Item from another company without `replaceCart` | 409 in the `error` contract | `feature_company_switch` |
| TC-API-CON-017 | Quantity limit | E | Item with 99 units; add 1 more | 422 in the `error` contract | `feature_cart` |
| TC-API-CON-018 | Update quantity | H | `PATCH` with `quantity` 2 | 200 in the `cart` contract | `feature_cart` |
| TC-API-CON-019 | Update a non-existent item | E | `PATCH` on a non-existent `:itemId` | 404 in the `error` contract | `feature_cart` |
| TC-API-CON-020 | Remove item | H | `DELETE` of an existing item | 200 in the `cart` contract | `feature_cart` |
| TC-API-CON-021 | Remove a non-existent item | E | `DELETE` on a non-existent `:itemId` | 404 in the `error` contract | `feature_cart` |
| TC-API-CON-022 | Check out | H | `POST /cart/checkout` with 1 item | 200 in the `checkout` contract | `smoke feature_checkout` |
| TC-API-CON-023 | Check out an empty cart | E | `POST /cart/checkout` with no items | 422 in the `error` contract | `feature_checkout` |
| TC-API-CON-024 | Pay for the order | H | `POST /cart/pay` with 1 item | 200 in the `payment` contract | `smoke feature_payment` |
| TC-API-CON-025 | Pay with different companies | E | Mixed cart, built through BUG-01 | 422 in the `error` contract | `feature_payment` |
| TC-API-CON-026 | Non-existent route | E | `GET /nonexistent` | 404 in the `error` contract | — |
| TC-API-CON-027 | Method not allowed | E | `DELETE /users` | 405 in the `error` contract | — |
| TC-API-CON-028 | Invalid JSON | E | Body with malformed JSON | 400 in the `error` contract | — |

## 11. Requests and persistence

| ID | Scenario | Type | Input | Expected result | Tags |
|---|---|---|---|---|---|
| TC-API-GEN-001 | JSON response | H | Any API route | `Content-Type` header with `application/json` | `smoke` |
| TC-API-GEN-002 | Non-existent route | E | `GET /nonexistent` | 404 `NOT_FOUND` | — |
| TC-API-GEN-003 | Method not allowed | E | `DELETE /users` | 405 `METHOD_NOT_ALLOWED` | — |
| TC-API-GEN-010 | Data kept after restart | H | Create a user and an item; restart the server | User and cart are still available | `persistence` |
| TC-API-GEN-011 | Restart neither duplicates nor changes seed users | A | Restart the server | The 4 users are still unique, with the same `createdAt` | `persistence` |
| TC-API-GEN-012 | Password not stored in plain text | H | Create a user; inspect the database file | The password entered does not appear in the file | `security persistence` |

## 12. Running by tag

Commands run inside `automated_testing/`.

| Goal | Command |
|---|---|
| All API tests | `python run.py --suite api` |
| API smoke | `python run.py --suite api --include smoke` |
| Domain | `python run.py --suite api --include domain` |
| SQL injection | `python run.py --suite api --include sqli` |
| Contract | `python run.py --suite api --include contract` |
| Cart | `python run.py --suite api --include feature_cart` |
| Without known defects | `python run.py --suite api --exclude known_bug` |
