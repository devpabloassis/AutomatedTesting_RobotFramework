*** Settings ***
Documentation       Cart
...                 As a customer
...                 I want to view, add, update and remove cart items
...                 So that I can build my order from a single company

Resource            ../../resources/api/api.resource

Test Setup          Given a new user exists
Test Tags           feature_cart


*** Test Cases ***
# View

TC-API-CRT-001 - Empty cart
    [Tags]    smoke
    When I send "GET" to "/users/{user}/cart"
    Then the response status should be 200
    And the response should be exactly
    ...    { "username": "{user}", "items": [], "companyIds": [], "hasMixedCompanies": false, "totalItems": 0, "totalCents": 0 }

TC-API-CRT-002 - Cart with items
    Given the user's cart has the item "pizzeria/supreme/M" with quantity 2
    When I send "GET" to "/users/{user}/cart"
    Then the response status should be 200
    And the response should contain
    ...    { "items": [{ "productId": "supreme", "optionId": "M", "quantity": 2, "subtotalCents": 10580 }], "totalItems": 2, "totalCents": 10580 }

TC-API-CRT-003 - Independent carts
    Given another new user exists with the item "pizzeria/supreme/M"
    When I send "GET" to "/users/{user}/cart"
    Then the response status should be 200
    And the returned cart should have 0 items

TC-API-CRT-004 - Non-existent user
    When I send "GET" to "/users/{unique_name}/cart"
    Then the response should be a 404 error with code "USER_NOT_FOUND"

# Add

TC-API-CRT-010 - Add to an empty cart
    [Tags]    smoke
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": 1 }
    Then the response status should be 201
    And the returned cart should have 1 item
    And the response should contain    { "totalCents": 5290 }

TC-API-CRT-011 - Quantity omitted
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M" }
    Then the response status should be 201
    And the response should contain    { "items": [{ "quantity": 1 }] }

TC-API-CRT-012 - Another product from the same company
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "pepperoni", "optionId": "S" }
    Then the response status should be 201
    And the returned cart should have 2 items

TC-API-CRT-013 - Same product and option
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M" }
    Then the response status should be 201
    And the response should contain    { "items": [{ "productId": "supreme", "quantity": 2 }] }

TC-API-CRT-014 - Same product, another option
    Given the user's cart has the item "pizzeria/supreme/S"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "L" }
    Then the response status should be 201
    And the returned cart should have 2 items

TC-API-CRT-015 - Maximum quantity
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": 99 }
    Then the response status should be 201
    And the response should contain    { "items": [{ "quantity": 99 }] }

TC-API-CRT-016 - Sum up to the limit
    Given the user's cart has the item "pizzeria/supreme/M" with quantity 98
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": 1 }
    Then the response status should be 201
    And the response should contain    { "items": [{ "quantity": 99 }] }

TC-API-CRT-017 - replaceCart with an empty cart
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "replaceCart": true }
    Then the response status should be 201
    And the returned cart should have 1 item

TC-API-CRT-018 - replaceCart with the same company
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "pepperoni", "optionId": "S", "replaceCart": true }
    Then the response status should be 201
    And the returned cart should have 2 items

TC-API-CRT-019 - Another company without confirmation
    [Tags]    smoke    feature_company_switch
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "burgers", "productId": "double", "optionId": "R" }
    Then the response should be a 409 error with code "CART_COMPANY_CONFLICT"
    And the user's cart should contain only the products "supreme"

TC-API-CRT-020 - Another company with confirmation
    [Documentation]    Expected failure: BUG-01 (the cart is not cleared when replaceCart is true).
    [Tags]    smoke    feature_company_switch    known_bug
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "burgers", "productId": "double", "optionId": "R", "replaceCart": true }
    Then the response status should be 201
    And the returned cart should contain only the products "double"
    And the response should contain    { "hasMixedCompanies": false }

TC-API-CRT-021 - Sum above the limit
    Given the user's cart has the item "pizzeria/supreme/M" with quantity 99
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": 1 }
    Then the response should be a 422 error with code "QUANTITY_LIMIT_EXCEEDED"
    And the item quantity in the cart should be 99

TC-API-CRT-022 - Non-existent user
    When I send "POST" to "/users/{unique_name}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M" }
    Then the response should be a 404 error with code "USER_NOT_FOUND"

TC-API-CRT-023 - Non-existent company
    [Template]    Adding the item should fail with a validation error
    { "companyId": "x", "productId": "supreme", "optionId": "M" }

TC-API-CRT-024 - Non-existent product
    [Template]    Adding the item should fail with a validation error
    { "companyId": "pizzeria", "productId": "x", "optionId": "M" }

TC-API-CRT-025 - Non-existent option
    [Template]    Adding the item should fail with a validation error
    { "companyId": "pizzeria", "productId": "supreme", "optionId": "X" }

TC-API-CRT-026 - Product from another company
    [Template]    Adding the item should fail with a validation error
    { "companyId": "pizzeria", "productId": "double", "optionId": "R" }

TC-API-CRT-027 - Option R on a sized product
    [Template]    Adding the item should fail with a validation error
    { "companyId": "pizzeria", "productId": "supreme", "optionId": "R" }

TC-API-CRT-028 - Size on a single-option product
    [Template]    Adding the item should fail with a validation error
    { "companyId": "burgers", "productId": "double", "optionId": "M" }

TC-API-CRT-029 - Missing required fields
    [Template]    Adding the item should fail with a validation error
    {}

# Update quantity (expected failures in the known_bug tests: BUG-02, the quantity is stored doubled)

TC-API-CRT-030 - Update quantity
    [Tags]    smoke    known_bug
    [Template]    Updating the quantity should store exactly the value sent
    3

TC-API-CRT-031 - Minimum quantity
    [Tags]    known_bug
    [Template]    Updating the quantity should store exactly the value sent
    1

TC-API-CRT-032 - Maximum quantity
    [Tags]    known_bug
    [Template]    Updating the quantity should store exactly the value sent
    99

TC-API-CRT-033 - Recalculate amounts
    [Tags]    known_bug
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "PATCH" to "/users/{user}/cart/items/{item}" with the body    { "quantity": 3 }
    Then the response status should be 200
    And the response should contain    { "items": [{ "subtotalCents": 15870 }], "totalCents": 15870, "totalItems": 3 }

TC-API-CRT-034 - Zero quantity
    [Template]    Updating the quantity should fail with a validation error
    { "quantity": 0 }

TC-API-CRT-035 - Above the maximum
    [Template]    Updating the quantity should fail with a validation error
    { "quantity": 100 }

TC-API-CRT-036 - Negative quantity
    [Template]    Updating the quantity should fail with a validation error
    { "quantity": -1 }

TC-API-CRT-037 - Missing quantity
    [Template]    Updating the quantity should fail with a validation error
    {}

TC-API-CRT-038 - Non-existent item
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "PATCH" to "/users/{user}/cart/items/nonexistent" with the body    { "quantity": 1 }
    Then the response should be a 404 error with code "ITEM_NOT_FOUND"

TC-API-CRT-039 - Non-existent user
    When I send "PATCH" to "/users/{unique_name}/cart/items/x" with the body    { "quantity": 1 }
    Then the response should be a 404 error with code "USER_NOT_FOUND"

TC-API-CRT-040 - Another user's item
    Given another new user exists with the item "pizzeria/supreme/M"
    When I send "PATCH" to "/users/{user}/cart/items/{other_item}" with the body    { "quantity": 5 }
    Then the response should be a 404 error with code "ITEM_NOT_FOUND"
    And the other user's item quantity should be 1

# Remove

TC-API-CRT-050 - Remove one of several items
    [Tags]    smoke
    Given the user's cart has the item "pizzeria/supreme/M"
    And the user's cart has the item "pizzeria/pepperoni/S"
    When I send "DELETE" to "/users/{user}/cart/items/{item}"
    Then the response status should be 200
    And the returned cart should contain only the products "pepperoni"
    And the response should contain    { "totalCents": 3490 }

TC-API-CRT-051 - Remove the last item
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "DELETE" to "/users/{user}/cart/items/{item}"
    Then the response status should be 200
    And the response should contain    { "items": [], "totalCents": 0 }

TC-API-CRT-052 - Non-existent item
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "DELETE" to "/users/{user}/cart/items/nonexistent"
    Then the response should be a 404 error with code "ITEM_NOT_FOUND"

TC-API-CRT-053 - Item already removed
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "DELETE" to "/users/{user}/cart/items/{item}"
    Then the response status should be 200
    When I send "DELETE" to "/users/{user}/cart/items/{item}"
    Then the response should be a 404 error with code "ITEM_NOT_FOUND"

TC-API-CRT-054 - Non-existent user
    When I send "DELETE" to "/users/{unique_name}/cart/items/x"
    Then the response should be a 404 error with code "USER_NOT_FOUND"

TC-API-CRT-055 - Another user's item
    Given another new user exists with the item "pizzeria/supreme/M"
    When I send "DELETE" to "/users/{user}/cart/items/{other_item}"
    Then the response should be a 404 error with code "ITEM_NOT_FOUND"
    And the other user's cart should have 1 item


*** Keywords ***
Adding the item should fail with a validation error
    [Arguments]    ${body}
    When I send "POST" to "/users/{user}/cart/items" with the body    ${body}
    Then the response should be a 400 error with code "VALIDATION_ERROR"
    And the user's cart should have 0 items

Updating the quantity should store exactly the value sent
    [Arguments]    ${quantity}
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "PATCH" to "/users/{user}/cart/items/{item}" with the body    { "quantity": ${quantity} }
    Then the response status should be 200
    And the response should contain    { "items": [{ "quantity": ${quantity} }] }

Updating the quantity should fail with a validation error
    [Arguments]    ${body}
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "PATCH" to "/users/{user}/cart/items/{item}" with the body    ${body}
    Then the response should be a 400 error with code "VALIDATION_ERROR"
    And the item quantity in the cart should be 1
