*** Settings ***
Documentation       SQL injection
...                 As the person responsible for API security
...                 I want SQL injection payloads to be treated as plain text
...                 So that no data is exposed or changed
...
...                 Data-driven tests: each test runs its template once for each of the 8 payloads in
...                 resources/test_data.py (SQL-01 to SQL-08). A failing payload does not stop the others.

Resource            ../../resources/api/api.resource

Test Tags           security    sqli


*** Test Cases ***
TC-API-SQL-001 - Create user with a malicious username
    [Template]    Malicious username is rejected when creating a user
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}
    END

TC-API-SQL-002 - Create user with a malicious password
    [Template]    Malicious password is accepted and not echoed
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}
    END

TC-API-SQL-003 - Log in with the payload as the password
    [Template]    Malicious password works as a normal password
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}
    END

TC-API-SQL-004 - Log in with a malicious username
    [Tags]    feature_login
    [Template]    Login with the request body is rejected
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    { "username": "{payload}", "password": "loveMetalSongs@" }
    END

TC-API-SQL-005 - Log in with a malicious password
    [Tags]    feature_login
    [Template]    Login with the request body is rejected
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    { "username": "user_manual", "password": "{payload}" }
    END

TC-API-SQL-006 - Fetch user
    [Template]    The GET request returns an error
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    /users/{payload}    404    USER_NOT_FOUND
    END

TC-API-SQL-007 - Fetch company
    [Template]    The GET request returns an error
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    /companies/{payload}    404    COMPANY_NOT_FOUND
    END

TC-API-SQL-008 - Fetch cart
    [Template]    The GET request returns an error
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    /users/{payload}/cart    404    USER_NOT_FOUND
    END

TC-API-SQL-009 - Add item with a malicious companyId
    [Template]    Malicious item is rejected and the cart is unchanged
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    { "companyId": "{payload}", "productId": "supreme", "optionId": "M" }
    END

TC-API-SQL-010 - Add item with a malicious productId
    [Template]    Malicious item is rejected and the cart is unchanged
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    { "companyId": "pizzeria", "productId": "{payload}", "optionId": "M" }
    END

TC-API-SQL-011 - Add item with a malicious optionId
    [Template]    Malicious item is rejected and the cart is unchanged
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    { "companyId": "pizzeria", "productId": "supreme", "optionId": "{payload}" }
    END

TC-API-SQL-012 - Add item with a malicious quantity
    [Template]    Malicious item is rejected and the cart is unchanged
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": "{payload}" }
    END

TC-API-SQL-013 - Add item with a malicious replaceCart
    [Template]    Malicious replaceCart does not confirm the company switch
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}
    END

TC-API-SQL-014 - Update item with a malicious quantity
    [Template]    Malicious quantity does not change the item
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}
    END

TC-API-SQL-015 - Update item with a malicious itemId
    [Template]    Malicious itemId does not update any item
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}
    END

TC-API-SQL-016 - Remove item with a malicious itemId
    [Template]    Malicious itemId does not remove any item
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}
    END

TC-API-SQL-017 - Check out and pay with a malicious username
    [Template]    Checkout and payment of a malicious username return not found
    FOR    ${payload}    IN    @{SQL_PAYLOADS.values()}
        ${payload}
    END

TC-API-SQL-018 - Integrity after the attacks
    [Tags]    smoke
    Then each seed user should be found
    And each seed user should be able to log in with the password "loveMetalSongs@"


*** Keywords ***
Malicious username is rejected when creating a user
    [Arguments]    ${payload}
    Given the SQL injection payload is "${payload}"
    When I send "POST" to "/users" with the body    { "username": "{payload}", "password": "validPass1" }
    Then the response should be a 400 error with code "VALIDATION_ERROR"
    When I send "GET" to "/users/{payload}"
    Then the response should be a 404 error with code "USER_NOT_FOUND"

Malicious password is accepted and not echoed
    [Arguments]    ${payload}
    Given the SQL injection payload is "${payload}"
    When I send "POST" to "/users" with the body    { "username": "{unique_name}", "password": "{payload}" }
    Then the response status should be 201
    And the response should not contain the payload

Malicious password works as a normal password
    [Arguments]    ${payload}
    Given the SQL injection payload is "${payload}"
    When I send "POST" to "/users" with the body    { "username": "{unique_name}", "password": "{payload}" }
    Then the response status should be 201
    And logging in with the sent credentials should return status 200

Login with the request body is rejected
    [Arguments]    ${payload}    ${body}
    Given the SQL injection payload is "${payload}"
    When I send "POST" to "/login" with the body    ${body}
    Then the response should be a 401 error with code "INVALID_CREDENTIALS"

The GET request returns an error
    [Arguments]    ${payload}    ${path}    ${status}    ${code}
    Given the SQL injection payload is "${payload}"
    When I send "GET" to "${path}"
    Then the response should be a ${status} error with code "${code}"

Malicious item is rejected and the cart is unchanged
    [Arguments]    ${payload}    ${body}
    Given a new user exists
    And the SQL injection payload is "${payload}"
    When I send "POST" to "/users/{user}/cart/items" with the body    ${body}
    Then the response should be a 400 error with code "VALIDATION_ERROR"
    And the user's cart should have 0 items

Malicious replaceCart does not confirm the company switch
    [Arguments]    ${payload}
    Given a new user exists
    And the user's cart has the item "pizzeria/supreme/M"
    And the SQL injection payload is "${payload}"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "burgers", "productId": "double", "optionId": "R", "replaceCart": "{payload}" }
    Then the response should be a 409 error with code "CART_COMPANY_CONFLICT"
    And the user's cart should have 1 item

Malicious quantity does not change the item
    [Arguments]    ${payload}
    Given a new user exists
    And the user's cart has the item "pizzeria/supreme/M"
    And the SQL injection payload is "${payload}"
    When I send "PATCH" to "/users/{user}/cart/items/{item}" with the body    { "quantity": "{payload}" }
    Then the response should be a 400 error with code "VALIDATION_ERROR"
    And the item quantity in the cart should be 1

Malicious itemId does not update any item
    [Arguments]    ${payload}
    Given a new user exists
    And the user's cart has the item "pizzeria/supreme/M"
    And the SQL injection payload is "${payload}"
    When I send "PATCH" to "/users/{user}/cart/items/{payload}" with the body    { "quantity": 2 }
    Then the response should be a 404 error with code "ITEM_NOT_FOUND"
    And the item quantity in the cart should be 1

Malicious itemId does not remove any item
    [Arguments]    ${payload}
    Given a new user exists
    And the user's cart has the item "pizzeria/supreme/M"
    And the SQL injection payload is "${payload}"
    When I send "DELETE" to "/users/{user}/cart/items/{payload}"
    Then the response should be a 404 error with code "ITEM_NOT_FOUND"
    And the user's cart should have 1 item

Checkout and payment of a malicious username return not found
    [Arguments]    ${payload}
    Given the SQL injection payload is "${payload}"
    When I send "POST" to "/users/{payload}/cart/checkout"
    Then the response should be a 404 error with code "USER_NOT_FOUND"
    When I send "POST" to "/users/{payload}/cart/pay"
    Then the response should be a 404 error with code "USER_NOT_FOUND"
