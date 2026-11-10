# Product Specification — Food Marketplace

| Field | Value |
|---|---|
| Product | Food Marketplace (system under test for test automation) |
| Document version | 1.0 (mobile) |
| Date | 2026-11-10 |
| Audience | Product, development and QA |
| Status | Approved for development |

## 1. Overview

Food Marketplace is a mobile application (Android and iOS, built with Kotlin Multiplatform) where customers browse food companies, choose products, build a cart from **a single company** and place an order with a simulated payment.

The product exists to be the target of automated mobile and API tests. The app is a client of a REST API, and both are part of the system under test. For that reason, it contains **intentional defects**, described in section 10. Sections 3 to 9 always describe the **correct expected behavior**: that is the behavior the tests must validate.

## 2. Scope

### 2.1 In scope

- Creating and fetching users through the API.
- Login in the app, validated by the API.
- Public browsing of companies and products.
- One cart per user: adding items, updating quantities and removing items.
- Single-company cart enforcement.
- Order checkout and simulated payment.
- Persistence in a local JSON file.

### 2.2 Out of scope

- Sign-up screen (users are created through the API only).
- Real payment, delivery and order history.
- Catalog administration (products are fixed in the code).
- Authorization on API routes. There is no session token, and the system must run in a local environment only.

## 3. Roles

| Role | Description | Permissions |
|---|---|---|
| Visitor | Not logged in | View companies and products |
| Customer | Authenticated | Everything a visitor can do, plus using the cart, checking out and paying |

### 3.1 Seed users

Every time the system starts, it ensures the users below exist. The operation neither duplicates records nor changes existing users.

| Username | Password |
|---|---|
| `user_manual` | `loveMetalSongs@` |
| `user_robot` | `loveMetalSongs@` |
| `user_hybrid` | `loveMetalSongs@` |
| `user_fail` | `loveMetalSongs@` |

## 4. Catalog

The catalog is fixed in the code. Products without size variations have a single option, called "Regular".

### 4.1 Noble Oven Pizzeria (`pizzeria`)

| Product | Small | Medium | Large |
|---|---:|---:|---:|
| Supreme | $38.90 | $52.90 | $66.90 |
| Pepperoni | $34.90 | $48.90 | $62.90 |
| Chicken & Cream Cheese | $36.90 | $50.90 | $64.90 |
| Margherita | $32.90 | $46.90 | $60.90 |

### 4.2 Hot Griddle Burgers (`burgers`)

| Product | Price |
|---|---:|
| Vegan | $31.90 |
| Classic | $29.90 |
| Egg Burger | $26.90 |
| Double | $36.90 |

### 4.3 Japa Express (`japanese`)

| Product | Price |
|---|---:|
| Beef Yakisoba | $34.90 |
| Chicken Yakisoba | $31.90 |
| Mixed Yakisoba | $37.90 |
| Philadelphia Hot Roll | $29.90 |

### 4.4 Fresh Fruit Juices (`juices`)

| Product | Small | Medium | Large |
|---|---:|---:|---:|
| Orange | $8.90 | $11.90 | $14.90 |
| Pineapple | $9.90 | $12.90 | $15.90 |
| Guava | $9.50 | $12.50 | $15.50 |
| Acerola | $9.00 | $12.00 | $15.00 |

## 5. Business rules

| ID | Rule |
|---|---|
| BR-01 | Companies and products can be viewed without logging in. |
| BR-02 | Only an authenticated customer can use the cart. When a visitor tries to add a product without logging in, they are taken to the login screen and returned to the company after signing in. |
| BR-03 | Login is granted only after the API validates the username and password. |
| BR-04 | Each user has a single cart, independent from the others. |
| BR-05 | The cart can only contain products from one company. |
| BR-06 | When a product from another company is added, the application warns that continuing will clear the cart and asks for confirmation. |
| BR-07 | When the customer confirms with **Yes**, all previous items are removed and only the new product remains in the cart. |
| BR-08 | When the customer chooses **No**, the cart stays unchanged and the product is not added. |
| BR-09 | Adding the same product with the same option again adds the quantity to the existing item. |
| BR-10 | The quantity must be an integer from 1 to 99. The total quantity of an item cannot exceed 99. |
| BR-11 | When the quantity is updated, the item takes exactly the value entered. |
| BR-12 | The item subtotal is the unit price times the quantity. The total is the sum of the subtotals. |
| BR-13 | An item can be removed from the cart at any time before payment. |
| BR-14 | An empty cart cannot be checked out. |
| BR-15 | A cart with items from more than one company cannot be checked out. The backend rejects the order and the UI shows the returned message. |
| BR-16 | After a successful checkout, the message `Order confirmed` is shown together with the **Pay** button, which only appears in this condition. Any later change to the cart requires a new checkout. |
| BR-17 | After payment, the message `Fake payment completed` is shown and the cart is emptied. |
| BR-18 | The username is unique, has 3 to 30 characters and accepts letters, digits and `_`. The password has at least 8 characters. |
| BR-19 | Passwords are neither stored in plain text nor returned by the API. |

## 6. User stories and acceptance criteria

### US-01 — Browse without logging in

**As a** visitor, **I want** to see companies and products **so that** I know the options before signing in.

- **AC-01.1:** the home screen shows the 4 companies.
- **AC-01.2:** when opening a company, its 4 products are shown with options and prices.
- **AC-01.3:** when a size is selected, the price shown matches that size.
- **AC-01.4:** when tapping **Add to cart** without logging in, the visitor is sent to the login screen and nothing is added.

### US-02 — Log in

**As a** customer, **I want** to sign in with username and password **so that** I can use my cart.

- **AC-02.1:** with valid credentials, the username appears in the header.
- **AC-02.2:** with invalid credentials, the message `Invalid username or password.` is shown and login is not granted.
- **AC-02.3:** the session is kept when the app is closed and opened again.
- **AC-02.4:** tapping **Sign out** ends the session.

### US-03 — Add products

**As a** customer, **I want** to add products to the cart **so that** I can build my order.

- **AC-03.1:** with an empty cart, the product is added with quantity 1.
- **AC-03.2:** adding another product from the same company shows no warning.
- **AC-03.3:** adding the same product and option adds 1 to the item quantity.
- **AC-03.4:** the header counter shows the sum of the quantities in the cart.

### US-04 — Switch company

**As a** customer, **I want** to be warned when I choose a product from another company **so that** I can decide whether to switch my order.

```gherkin
Given I have items from "Noble Oven Pizzeria" in the cart
When I add a product from "Hot Griddle Burgers"
Then I see the warning that continuing will clear the cart
And I see the options "Yes" and "No"

When I choose "Yes"
Then the pizzeria items are removed
And the cart contains only the burger product

When I choose "No"
Then the cart still contains only the pizzeria items
```

### US-05 — Manage the cart

**As a** customer, **I want** to update and remove items **so that** I can adjust my order.

- **AC-05.1:** the cart shows company, product, option, unit price, quantity and subtotal.
- **AC-05.2:** when a valid quantity is entered and **Update** is tapped, the item takes exactly the quantity entered.
- **AC-05.3:** subtotal, total and the header counter are recalculated after the update.
- **AC-05.4:** an invalid quantity is rejected and the item stays unchanged.
- **AC-05.5:** when **Remove** is tapped, the item leaves the cart and the total is recalculated.

### US-06 — Check out

**As a** customer, **I want** to check out my cart **so that** I can move on to payment.

- **AC-06.1:** with a single-company cart, **Checkout** shows `Order confirmed` and enables the **Pay** button.
- **AC-06.2:** with items from more than one company, the backend rejects the order, the message `The cart has items from different companies. The order cannot be completed.` is shown and **Pay** does not appear.
- **AC-06.3:** updating or removing an item after checkout hides the **Pay** button.

### US-07 — Pay

**As a** customer, **I want** to pay for the order **so that** I complete the purchase.

- **AC-07.1:** when **Pay** is tapped, the message `Fake payment completed` is shown.
- **AC-07.2:** after payment, the cart is empty and the counter shows 0.
- **AC-07.3:** with items from more than one company, the backend rejects the payment, the different-companies message is shown and the items stay in the cart.

## 7. Main flow

```text
Visitor or Customer
   └─ Home screen ─ choose company ─ choose product and option ─ Add to cart
         ├─ not logged in ─────────────────── Login ─ back to the company
         ├─ empty cart or same company ─ product added
         └─ another company ─ clear-cart warning
                ├─ No ─ cart unchanged
                └─ Yes ─ cart cleared ─ product from the new company added

Cart ─ update/remove items ─ Checkout
         ├─ empty or different companies ─ blocking message
         └─ valid ─ "Order confirmed" ─ Pay button ─ "Fake payment completed" ─ empty cart
```

## 8. User interface

The app has the same screens as the routes of the web version. Each screen can also be opened with a deep link `foodmarket://open/<route>`.

| Route (deep link) | Screen | Access |
|---|---|---|
| `/` | Company list | Public |
| `/companies/:companyId` | Company products | Public |
| `/login` | Login | Public |
| `/cart` | Cart, checkout and payment | Customer |

Navigation: the header brand returns to the company list, and the Android back button returns to the previous screen. Every screen shows the header, with the brand, the cart link with the counter, and the session (username and **Sign out**, or **Sign in**).

### 8.1 Element ids

Every element used by the automation has a unique id, defined with `testTag` in the Compose code (`TestTags.kt`). On Android the id is the `resource-id`, and on iOS it is the `accessibilityIdentifier`. For repeated elements, the id includes the item identifier. The test project keeps these ids in the object map `automated_testing/resources/mobile/object_map.py`.

| Screen | Element | Id |
|---|---|---|
| All | Screen containers | `screen-home`, `screen-company`, `screen-login`, `screen-cart`, `screen-not-found` |
| All | Title, subtitle and loading indicator | `page-title`, `page-subtitle`, `loading` |
| All | Screen message | `message` |
| All | Back button on a not-found screen | `back-to-companies` |
| Header | Brand, cart link and counter | `header-brand`, `header-cart-link`, `cart-count` |
| Header | Logged-in user, **Sign out** and **Sign in** | `logged-user`, `logout-button`, `login-link` |
| Home | Company list | `company-list` |
| Home | Company card, name and description | `company-<companyId>`, `company-<companyId>-name`, `company-<companyId>-description` |
| Company | Product list | `product-list` |
| Company | Product card, name and price | `product-<productId>`, `product-<productId>-name`, `product-<productId>-price` |
| Company | Size selector and each size | `product-<productId>-size`, `product-<productId>-size-<optionId>` |
| Company | **Add to cart** | `product-<productId>-add` |
| Company | Company switch warning | `confirm-dialog`, `confirm-title`, `confirm-text`, `confirm-yes`, `confirm-no` |
| Login | Form, username, password and **Sign in** | `login-form`, `login-username`, `login-password`, `login-submit` |
| Cart | Empty cart and **View companies** | `cart-empty-message`, `cart-view-companies` |
| Cart | Cart without login and **Sign in** | `cart-login-message`, `cart-login-button` |
| Cart | Item list | `cart-list` |
| Cart | Item row | `cart-item-<productId>-<optionId>` |
| Cart | Name, company and option, unit price and subtotal | `<row>-name`, `<row>-details`, `<row>-unit-price`, `<row>-subtotal` |
| Cart | Quantity, **Update** and **Remove** | `<row>-quantity`, `<row>-update`, `<row>-delete` |
| Cart | Total, **Checkout** and **Pay** | `cart-total`, `checkout-button`, `pay-button` |

`<row>` stands for the item row id, for example `cart-item-supreme-M`. A size option is selected when its `checked` attribute is `true` (Android).

### 8.2 Test hooks

The deep links accept two optional parameters, used only to prepare test scenarios quickly:

| Parameter | Effect |
|---|---|
| `user=<username>` | Starts the session of that user without the login screen. `user=` (empty) ends the session |
| `api=<url>` | Changes the API base URL, for example to the test proxy `http://127.0.0.1:3101/api` |

## 9. API

Base URL: `http://127.0.0.1:3000/api`. The source code is in `application/src_api/`. Requests and responses use JSON. Errors have the format `{ "code": "CODE", "message": "Description" }`. Monetary values are returned in cents. The full documentation of each endpoint, with examples and contracts, is in [`API_ENDPOINTS.md`](./API_ENDPOINTS.md).

| Method | Route | Purpose | Success | Errors |
|---|---|---|---|---|
| POST | `/users` | Create user | 201 | 400 `VALIDATION_ERROR`, 409 `USER_ALREADY_EXISTS` |
| GET | `/users/:username` | Fetch user | 200 | 404 `USER_NOT_FOUND` |
| POST | `/login` | Validate credentials | 200 | 400 `VALIDATION_ERROR`, 401 `INVALID_CREDENTIALS` |
| GET | `/companies` | List the catalog | 200 | — |
| GET | `/companies/:companyId` | Fetch company | 200 | 404 `COMPANY_NOT_FOUND` |
| GET | `/users/:username/cart` | Fetch cart | 200 | 404 `USER_NOT_FOUND` |
| POST | `/users/:username/cart/items` | Add item | 201 | 400, 404, 409 `CART_COMPANY_CONFLICT`, 422 `QUANTITY_LIMIT_EXCEEDED` |
| PATCH | `/users/:username/cart/items/:itemId` | Update quantity | 200 | 400, 404 `ITEM_NOT_FOUND` |
| DELETE | `/users/:username/cart/items/:itemId` | Remove item | 200 | 404 `ITEM_NOT_FOUND` |
| POST | `/users/:username/cart/checkout` | Check out | 200 | 422 `CART_EMPTY`, 422 `CART_MIXED_COMPANIES` |
| POST | `/users/:username/cart/pay` | Pay | 200 | 422 `CART_EMPTY`, 422 `CART_MIXED_COMPANIES` |

Request body examples:

```jsonc
// POST /users
{ "username": "new_user", "password": "securePass1" }

// POST /login
{ "username": "user_manual", "password": "loveMetalSongs@" }

// POST /users/:username/cart/items
// replaceCart: true confirms the company switch and must clear the cart (BR-07)
{ "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": 1, "replaceCart": false }

// PATCH /users/:username/cart/items/:itemId
{ "quantity": 3 }
```

The option identifiers are `S`, `M` and `L` for sized products, and `R` for the single (Regular) option.

Data is stored in `application/data/db.json`. Each write replaces the file atomically.

## 10. Intentional defects

> The defects below were inserted on purpose and **must not be fixed**. They exist so that the automated tests fail at known points. In the code, they are marked with `INTENTIONAL DEFECT` comments.

### BUG-01 — Cart is not cleared when switching company

| Field | Description |
|---|---|
| Violated rule | BR-07 / US-04 |
| Severity | High |
| Layer | API: `POST /users/:username/cart/items` with `replaceCart: true` |
| Steps | 1. Sign in and add a product from one company. 2. Open another company and add a product. 3. Tap **Yes** in the warning. |
| Expected result | Only the product from the new company remains in the cart. |
| Actual result | The cart keeps the previous items and also receives the new product. The header counter shows the sum of the quantities of this cart: with 1 previous item, it goes from 1 to 2 instead of showing 1. |

### BUG-02 — Quantity is doubled when updating an item

| Field | Description |
|---|---|
| Violated rule | BR-11 / AC-05.2 |
| Severity | High |
| Layer | API: `PATCH /users/:username/cart/items/:itemId` |
| Steps | 1. Add a product. 2. In the cart, enter quantity 3. 3. Tap **Update**. |
| Expected result | The item has quantity 3. |
| Actual result | The item has quantity 6, and subtotal, total and counter reflect that value. |

### BUG-03 — Order with different companies is accepted

| Field | Description |
|---|---|
| Violated rule | BR-15 / AC-06.2 |
| Severity | High |
| Layer | API: `POST /users/:username/cart/checkout` |
| Steps | 1. Build a cart with items from two companies. 2. Tap **Checkout**. |
| Expected result | The backend returns 422 `CART_MIXED_COMPANIES`, the message `The cart has items from different companies. The order cannot be completed.` is shown and **Pay** does not appear. |
| Actual result | The backend returns 200, the message `Order confirmed` is shown and the **Pay** button appears. |

### BUG-04 — Company list breaks the contract

| Field | Description |
|---|---|
| Violated rule | `companies` contract (see [`API_ENDPOINTS.md`](./API_ENDPOINTS.md)) |
| Severity | Medium |
| Layer | API: `GET /companies` |
| Steps | 1. Call `GET /companies`. 2. Compare each company with the contract. |
| Expected result | Each company has only `id`, `name`, `description` and `products`. |
| Actual result | Each company also has the internal field `commissionPercent`, which is not in the contract. Fetching a single company (`GET /companies/:companyId`) does not have the defect. |

### Observable effects

| Behavior | Cause | Note |
|---|---|---|
| A cart with different companies reaches checkout. | BUG-01 | This is what makes BUG-03 observable. |
| With a mixed cart, **Pay** appears, but the payment is rejected. | BUG-03 | The payment route keeps the different-companies validation. |
| The app keeps working with the extra field in the list. | BUG-04 | The defect is only detected by contract validation. |
| An item can exceed quantity 99 after an update. | BUG-02 | Violates BR-10. The value entered is accepted up to 99 and doubled when stored. |

## 11. Suggested validation matrix

| Scenario | Reference | Result with the current defects |
|---|---|---|
| Valid and invalid login | US-02 | Pass |
| Browsing without login | US-01 | Pass |
| Adding from the same company | US-03 | Pass |
| Warning when switching company | BR-06 | Pass |
| Choosing **No** in the warning | BR-08 | Pass |
| Choosing **Yes** in the warning | BR-07 | **Fail (BUG-01)** |
| Removing an item | AC-05.5 | Pass |
| Updating the quantity | AC-05.2 | **Fail (BUG-02)** |
| Blocking different companies | AC-06.2 | **Fail (BUG-03)** |
| Checkout and payment | US-06 / US-07 | Pass |
| Company list contract | `GET /companies` | **Fail (BUG-04)** |
| Contract of the other endpoints | Section 9 | Pass |

## 12. Non-functional requirements

- API: local execution, with Node.js 22 or later and no external dependencies.
- API server on `127.0.0.1`, port `3000` by default (`HOST` and `PORT` variables).
- Database path configurable through the `DB_PATH` variable, to isolate test runs.
- Mobile app: Android 8.0 (API 26) or later; iOS through Compose Multiplatform (built on macOS).
- The app works in portrait and landscape orientation, and keeps its state when the device rotates.
- Stable element ids for automation on both platforms (section 8.1).
