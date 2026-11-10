*** Settings ***
Documentation       Field domain characters
...                 As the API owner
...                 I want to accept only values inside each field's domain
...                 So that invalid input is rejected before it is processed
...
...                 Values are written as JSON. In Robot Framework, \\ represents a single backslash.
...                 The {unique_...} placeholders generate new values from the same character class,
...                 so the tests can run again against the same database.

Resource            ../../resources/api/api.resource

Test Tags           domain


*** Test Cases ***
# Username: accepted characters

TC-API-DOM-001 - Lowercase only
    [Template]    The username should be accepted
    {unique_lowercase}

TC-API-DOM-002 - Uppercase only
    [Template]    The username should be accepted
    {unique_uppercase}

TC-API-DOM-003 - Digits only
    [Template]    The username should be accepted
    {unique_digits}

TC-API-DOM-004 - Underscores only
    [Template]    The username should be accepted
    {free_underscores}

TC-API-DOM-005 - Valid combination
    [Template]    The username should be accepted
    {unique_mix}

# Username: rejected values

TC-API-DOM-010 - Empty string
    [Template]    The username should be rejected
    ""

TC-API-DOM-011 - Inner space
    [Template]    The username should be rejected
    "john doe"

TC-API-DOM-012 - Leading space
    [Template]    The username should be rejected
    " johndoe"

TC-API-DOM-013 - Trailing space
    [Template]    The username should be rejected
    "johndoe "

TC-API-DOM-014 - Trailing line break
    [Template]    The username should be rejected
    "johndoe\\n"

TC-API-DOM-015 - Tab
    [Template]    The username should be rejected
    "john\\tdoe"

TC-API-DOM-016 - Hyphen
    [Template]    The username should be rejected
    "john-doe"

TC-API-DOM-017 - Dot
    [Template]    The username should be rejected
    "john.doe"

TC-API-DOM-018 - At sign
    [Template]    The username should be rejected
    "john@doe"

TC-API-DOM-019 - Accented letter
    [Template]    The username should be rejected
    "joão"

TC-API-DOM-020 - Cedilla
    [Template]    The username should be rejected
    "façade"

TC-API-DOM-021 - Emoji
    [Template]    The username should be rejected
    "john😀"

TC-API-DOM-022 - Single quote
    [Template]    The username should be rejected
    "john'doe"

TC-API-DOM-023 - Double quote
    [Template]    The username should be rejected
    "john\\"doe"

TC-API-DOM-024 - Semicolon
    [Template]    The username should be rejected
    "john;doe"

TC-API-DOM-025 - Percent sign
    [Template]    The username should be rejected
    "john%doe"

TC-API-DOM-026 - Slashes
    [Template]    The username should be rejected
    "john/doe\\\\x"

TC-API-DOM-027 - HTML markup
    [Template]    The username should be rejected
    "<b>john</b>"

TC-API-DOM-028 - Number type
    [Template]    The username should be rejected
    123456

TC-API-DOM-029 - Null type
    [Template]    The username should be rejected
    null

TC-API-DOM-030 - Array type
    [Template]    The username should be rejected
    \["john_doe"]

# Password

TC-API-DOM-040 - Symbols
    [Template]    The password should be accepted and work for login
    !@#$%^&*()

TC-API-DOM-041 - Accents and cedilla
    [Template]    The password should be accepted and work for login
    açãoÉótima

TC-API-DOM-042 - Spaces
    [Template]    The password should be accepted and work for login
    password with spaces

TC-API-DOM-043 - Emoji
    [Template]    The password should be accepted and work for login
    secret😀😀😀😀

TC-API-DOM-044 - Number type
    [Template]    The password should be rejected
    12345678

TC-API-DOM-045 - Null type
    [Template]    The password should be rejected
    null

# Quantity

TC-API-DOM-050 - Numeric string
    [Template]    The quantity should be rejected when adding and updating
    "3"

TC-API-DOM-051 - Decimal
    [Template]    The quantity should be rejected when adding and updating
    1.5

TC-API-DOM-052 - Alphabetic string
    [Template]    The quantity should be rejected when adding and updating
    "abc"

TC-API-DOM-053 - Symbol
    [Template]    The quantity should be rejected when adding and updating
    "!"

TC-API-DOM-054 - Boolean
    [Template]    The quantity should be rejected when adding and updating
    true

TC-API-DOM-055 - Null
    [Template]    The quantity should be rejected when adding and updating
    null

TC-API-DOM-056 - Array
    [Template]    The quantity should be rejected when adding and updating
    \[1]

TC-API-DOM-057 - Object
    [Template]    The quantity should be rejected when adding and updating
    {}

TC-API-DOM-058 - Valid scientific notation
    Given a new user exists
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": 1e1 }
    Then the response status should be 201
    And the response should contain    { "items": [{ "quantity": 10 }] }

TC-API-DOM-059 - Scientific notation above the limit
    Given a new user exists
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": 1e2 }
    Then the response should be a 400 error with code "VALIDATION_ERROR"

# Catalog identifiers

TC-API-DOM-060 - Uppercase companyId
    [Template]    The item should be rejected
    { "companyId": "PIZZERIA", "productId": "supreme", "optionId": "M" }

TC-API-DOM-061 - Uppercase productId
    [Template]    The item should be rejected
    { "companyId": "pizzeria", "productId": "SUPREME", "optionId": "M" }

TC-API-DOM-062 - Lowercase optionId
    [Template]    The item should be rejected
    { "companyId": "pizzeria", "productId": "supreme", "optionId": "m" }

TC-API-DOM-063 - Space in companyId
    [Template]    The item should be rejected
    { "companyId": "pizzeria ", "productId": "supreme", "optionId": "M" }

TC-API-DOM-064 - Space in optionId
    [Template]    The item should be rejected
    { "companyId": "pizzeria", "productId": "supreme", "optionId": " M" }

TC-API-DOM-065 - Accent in productId
    [Template]    The item should be rejected
    { "companyId": "pizzeria", "productId": "suprême", "optionId": "M" }

TC-API-DOM-066 - Number type
    [Template]    The item should be rejected
    { "companyId": 1, "productId": "supreme", "optionId": "M" }

TC-API-DOM-067 - Null type
    [Template]    The item should be rejected
    { "companyId": "pizzeria", "productId": "supreme", "optionId": null }

# replaceCart: only the boolean true confirms the company switch

TC-API-DOM-070 - replaceCart as string
    [Template]    The company switch should not be confirmed by
    "true"

TC-API-DOM-071 - replaceCart as number
    [Template]    The company switch should not be confirmed by
    1

TC-API-DOM-072 - replaceCart null
    [Template]    The company switch should not be confirmed by
    null

TC-API-DOM-073 - replaceCart false
    [Template]    The company switch should not be confirmed by
    false

# URL parameters

TC-API-DOM-074 - Accent in the URL
    [Template]    The path should return an error
    /users/jo%C3%A3o    404    USER_NOT_FOUND

TC-API-DOM-075 - Space in the URL
    [Template]    The path should return an error
    /users/john%20doe    404    USER_NOT_FOUND

TC-API-DOM-076 - Invalid URL encoding
    [Template]    The path should return an error
    /users/%E0%A4%A    400    VALIDATION_ERROR


*** Keywords ***
The username should be accepted
    [Arguments]    ${username}
    When I send "POST" to "/users" with the body    { "username": "${username}", "password": "validPass1" }
    Then the response status should be 201

The username should be rejected
    [Arguments]    ${value}
    When I send "POST" to "/users" with the body    { "username": ${value}, "password": "validPass1" }
    Then the response should be a 400 error with code "VALIDATION_ERROR"

The password should be accepted and work for login
    [Arguments]    ${password}
    When I send "POST" to "/users" with the body    { "username": "{unique_name}", "password": "${password}" }
    Then the response status should be 201
    And logging in with the sent credentials should return status 200

The password should be rejected
    [Arguments]    ${value}
    When I send "POST" to "/users" with the body    { "username": "{unique_name}", "password": ${value} }
    Then the response should be a 400 error with code "VALIDATION_ERROR"

The quantity should be rejected when adding and updating
    [Arguments]    ${value}
    Given a new user exists
    And the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M", "quantity": ${value} }
    Then the response should be a 400 error with code "VALIDATION_ERROR"
    When I send "PATCH" to "/users/{user}/cart/items/{item}" with the body    { "quantity": ${value} }
    Then the response should be a 400 error with code "VALIDATION_ERROR"

The item should be rejected
    [Arguments]    ${body}
    Given a new user exists
    When I send "POST" to "/users/{user}/cart/items" with the body    ${body}
    Then the response should be a 400 error with code "VALIDATION_ERROR"

The company switch should not be confirmed by
    [Arguments]    ${value}
    Given a new user exists
    And the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/items" with the body
    ...    { "companyId": "burgers", "productId": "double", "optionId": "R", "replaceCart": ${value} }
    Then the response should be a 409 error with code "CART_COMPANY_CONFLICT"

The path should return an error
    [Arguments]    ${path}    ${status}    ${code}
    When I send "GET" to "${path}"
    Then the response should be a ${status} error with code "${code}"
