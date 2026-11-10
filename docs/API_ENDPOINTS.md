# API Documentation — Food Marketplace

| Field | Value |
|---|---|
| Base URL | `http://127.0.0.1:3000/api` (tests: `http://127.0.0.1:3100/api`) |
| Format | JSON in requests and responses (`Content-Type: application/json; charset=utf-8`) |
| Authentication | No token. The user is identified by the `:username` in the route |
| Monetary values | Integers in cents (`5290` = $52.90) |
| Contracts | JSON Schemas in [`automated_testing/contracts/`](../automated_testing/contracts/) |
| Business rules | [`PRODUCT_SPEC.md`](./PRODUCT_SPEC.md) |
| Test cases | [`API_TEST_CASES.md`](./API_TEST_CASES.md) |

## Summary

| # | Method | Route | Purpose | Success | Success contract |
|---|---|---|---|---|---|
| 1 | POST | [`/users`](#1-post-users--create-user) | Create user | 201 | `user` |
| 2 | GET | [`/users/:username`](#2-get-usersusername--fetch-user) | Fetch user | 200 | `user` |
| 3 | POST | [`/login`](#3-post-login--log-in) | Validate credentials | 200 | `user` |
| 4 | GET | [`/companies`](#4-get-companies--list-companies) | List companies and products | 200 | `companies` |
| 5 | GET | [`/companies/:companyId`](#5-get-companiescompanyid--fetch-company) | Fetch one company | 200 | `company` |
| 6 | GET | [`/users/:username/cart`](#6-get-usersusernamecart--fetch-cart) | Fetch cart | 200 | `cart` |
| 7 | POST | [`/users/:username/cart/items`](#7-post-usersusernamecartitems--add-item) | Add item | 201 | `cart` |
| 8 | PATCH | [`/users/:username/cart/items/:itemId`](#8-patch-usersusernamecartitemsitemid--update-quantity) | Update quantity | 200 | `cart` |
| 9 | DELETE | [`/users/:username/cart/items/:itemId`](#9-delete-usersusernamecartitemsitemid--remove-item) | Remove item | 200 | `cart` |
| 10 | POST | [`/users/:username/cart/checkout`](#10-post-usersusernamecartcheckout--check-out) | Check out | 200 | `checkout` |
| 11 | POST | [`/users/:username/cart/pay`](#11-post-usersusernamecartpay--pay) | Pay (fake) | 200 | `payment` |

## Common rules

### Error format

Every error response follows the `error` contract:

```json
{ "code": "USER_NOT_FOUND", "message": "User not found." }
```

| Code | Status | When it happens |
|---|---|---|
| `VALIDATION_ERROR` | 400 | Field outside its domain, invalid JSON, body larger than 100 KB or invalid URL |
| `INVALID_CREDENTIALS` | 401 | Username or password do not match |
| `USER_NOT_FOUND` | 404 | The `:username` does not exist |
| `COMPANY_NOT_FOUND` | 404 | The `:companyId` does not exist |
| `ITEM_NOT_FOUND` | 404 | The `:itemId` does not exist in the user's cart |
| `NOT_FOUND` | 404 | Non-existent route |
| `METHOD_NOT_ALLOWED` | 405 | The route exists but does not accept the method |
| `USER_ALREADY_EXISTS` | 409 | Username already registered |
| `CART_COMPANY_CONFLICT` | 409 | The item belongs to another company and the switch was not confirmed |
| `QUANTITY_LIMIT_EXCEEDED` | 422 | The item quantity would exceed 99 |
| `CART_EMPTY` | 422 | Checking out or paying for an empty cart |
| `CART_MIXED_COMPANIES` | 422 | Cart with items from different companies |
| `INTERNAL_ERROR` | 500 | Unexpected error |

### Request body

- When sent, it must be a JSON **object**. An array, a string or `null` returns 400 `VALIDATION_ERROR`.
- An empty body is treated as `{}`.
- The size limit is 100 KB.

### Input handling

The API validates only the **domain** of each field (type, length and allowed characters). There is no specific SQL injection filter: a payload is treated as plain text. Data is stored in a JSON file, with no SQL database.

### Response contract

The contracts do not accept extra fields (`additionalProperties: false`). A new field in a response is a contract break and must be agreed with consumers before it is released.

---

## 1. `POST /users` — Create user

Rules: BR-18, BR-19.

**Body**

| Field | Type | Required | Domain |
|---|---|---|---|
| `username` | string | Yes | 3 to 30 characters: `A-Z`, `a-z`, `0-9` and `_` |
| `password` | string | Yes | At least 8 characters, any character |

```json
{ "username": "new_user", "password": "securePass1" }
```

**Response 201** — `user` contract

```json
{ "username": "new_user", "createdAt": "2026-11-09T18:56:00.000Z" }
```

The password is stored as a hash and is never returned.

**Errors**

| Status | Code | Cause |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `username` or `password` outside its domain |
| 409 | `USER_ALREADY_EXISTS` | `username` already registered (case-sensitive) |

## 2. `GET /users/:username` — Fetch user

**Parameters:** `username`, compared exactly.

**Response 200** — `user` contract

```json
{ "username": "user_manual", "createdAt": "2026-11-09T12:00:00.000Z" }
```

**Errors:** 404 `USER_NOT_FOUND`.

## 3. `POST /login` — Log in

Rules: BR-02, BR-03.

**Body**

| Field | Type | Required |
|---|---|---|
| `username` | string | Yes |
| `password` | string | Yes |

```json
{ "username": "user_manual", "password": "loveMetalSongs@" }
```

**Response 200** — `user` contract, same as fetching a user.

**Errors**

| Status | Code | Cause |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `username` or `password` missing or not a string |
| 401 | `INVALID_CREDENTIALS` | Non-existent user or wrong password. The message is the same in both cases |

## 4. `GET /companies` — List companies

Rule: BR-01. No login required.

**Response 200** — `companies` contract: a list of companies, each one in the `company` contract format.

```json
[
  {
    "id": "pizzeria",
    "name": "Noble Oven Pizzeria",
    "description": "Wood-fired oven pizzas.",
    "products": [
      {
        "id": "supreme",
        "name": "Supreme",
        "options": [
          { "id": "S", "label": "Small", "priceCents": 3890 },
          { "id": "M", "label": "Medium", "priceCents": 5290 },
          { "id": "L", "label": "Large", "priceCents": 6690 }
        ]
      }
    ]
  }
]
```

Companies: `pizzeria`, `burgers`, `japanese` and `juices`, with 4 products each.

> **Intentional defect (BUG-04):** each company in the list also has the internal field `commissionPercent`, which is not part of the contract. Scenario `TC-API-CON-008` fails because of it.

## 5. `GET /companies/:companyId` — Fetch company

**Parameters:** `companyId`, compared exactly (`Pizzeria` does not match `pizzeria`).

**Response 200** — `company` contract: a single object, in the same format as each element of the list.

**Errors:** 404 `COMPANY_NOT_FOUND`.

## 6. `GET /users/:username/cart` — Fetch cart

Rules: BR-04, BR-12.

**Response 200** — `cart` contract

```json
{
  "username": "user_manual",
  "items": [
    {
      "id": "6f1c2a4e-0d6b-4c55-9a3e-2b7d1f0c9e11",
      "companyId": "pizzeria",
      "companyName": "Noble Oven Pizzeria",
      "productId": "supreme",
      "productName": "Supreme",
      "optionId": "M",
      "optionLabel": "Medium",
      "unitPriceCents": 5290,
      "quantity": 2,
      "subtotalCents": 10580
    }
  ],
  "companyIds": ["pizzeria"],
  "hasMixedCompanies": false,
  "totalItems": 2,
  "totalCents": 10580
}
```

| Field | Meaning |
|---|---|
| `items[].id` | Item UUID. It is the `:itemId` used to update and remove |
| `subtotalCents` | `unitPriceCents × quantity` |
| `companyIds` | Companies in the cart, without repetition |
| `hasMixedCompanies` | `true` when there is more than one company |
| `totalItems` | Sum of the quantities. It is the number shown in the header counter |
| `totalCents` | Sum of the subtotals |

**Errors:** 404 `USER_NOT_FOUND`.

## 7. `POST /users/:username/cart/items` — Add item

Rules: BR-05 to BR-10.

**Body**

| Field | Type | Required | Domain |
|---|---|---|---|
| `companyId` | string | Yes | Exact id of a company |
| `productId` | string | Yes | Exact id of a product of that company |
| `optionId` | string | Yes | `S`, `M` or `L` (sized products) or `R` (single option) |
| `quantity` | integer | No (default 1) | 1 to 99 |
| `replaceCart` | boolean | No (default `false`) | Only `true` confirms the company switch and must clear the cart |

```json
{ "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": 1 }
```

- The same product and option adds the quantity to the existing item.
- A product from another company, without `replaceCart: true`, returns 409 and the cart does not change.

**Response 201** — `cart` contract, with the updated cart.

**Errors**

| Status | Code | Cause |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Invalid company, product or option, or `quantity` outside 1 to 99 |
| 404 | `USER_NOT_FOUND` | Non-existent user |
| 409 | `CART_COMPANY_CONFLICT` | Item from another company without confirmation |
| 422 | `QUANTITY_LIMIT_EXCEEDED` | The sum would exceed 99 |

> **Intentional defect (BUG-01):** with `replaceCart: true`, the previous items are not removed. The cart ends up with different companies.

## 8. `PATCH /users/:username/cart/items/:itemId` — Update quantity

Rules: BR-10, BR-11.

**Body**

| Field | Type | Required | Domain |
|---|---|---|---|
| `quantity` | integer | Yes | 1 to 99 |

```json
{ "quantity": 3 }
```

**Response 200** — `cart` contract.

**Errors**

| Status | Code | Cause |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `quantity` missing or outside 1 to 99 |
| 404 | `USER_NOT_FOUND` / `ITEM_NOT_FOUND` | Non-existent user or item |

> **Intentional defect (BUG-02):** the quantity is stored doubled (`3` becomes `6`).

## 9. `DELETE /users/:username/cart/items/:itemId` — Remove item

Rule: BR-13. No body.

**Response 200** — `cart` contract, without the removed item.

**Errors:** 404 `USER_NOT_FOUND` / `ITEM_NOT_FOUND`.

## 10. `POST /users/:username/cart/checkout` — Check out

Rules: BR-14 to BR-16. No body. The cart is not changed.

**Response 200** — `checkout` contract

```json
{ "status": "READY_FOR_PAYMENT", "totalCents": 5290 }
```

**Errors**

| Status | Code | Cause |
|---|---|---|
| 404 | `USER_NOT_FOUND` | Non-existent user |
| 422 | `CART_EMPTY` | Empty cart |
| 422 | `CART_MIXED_COMPANIES` | Items from different companies |

> **Intentional defect (BUG-03):** a cart with different companies is not rejected. The route returns 200.

## 11. `POST /users/:username/cart/pay` — Pay

Rule: BR-17. No body. Simulated payment: on success, the cart is emptied.

**Response 200** — `payment` contract

```json
{ "status": "PAID", "totalCents": 5290, "message": "Fake payment completed" }
```

**Errors**

| Status | Code | Cause |
|---|---|---|
| 404 | `USER_NOT_FOUND` | Non-existent user |
| 422 | `CART_EMPTY` | Empty cart |
| 422 | `CART_MIXED_COMPANIES` | Items from different companies. The cart is kept |

## Contracts

| Contract | File | Used by |
|---|---|---|
| `user` | `user.schema.json` | 1, 2, 3 |
| `companies` | `companies.schema.json` | 4 |
| `company` | `company.schema.json` | 5 and each element of 4 |
| `cart` | `cart.schema.json` | 6, 7, 8, 9 |
| `checkout` | `checkout.schema.json` | 10 |
| `payment` | `payment.schema.json` | 11 |
| `error` | `error.schema.json` | Every error response |

The scenarios that validate the contracts are in section 10 of the [API test cases](./API_TEST_CASES.md) (`TC-API-CON-001` to `028`, tag `@contract`).
