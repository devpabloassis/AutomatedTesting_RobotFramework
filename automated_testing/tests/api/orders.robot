*** Settings ***
Documentation       Order checkout and payment
...                 As a customer
...                 I want to check out and pay for my order
...                 So that I complete a purchase from a single company

Resource            ../../resources/api/api.resource

Test Setup          Given a new user exists


*** Test Cases ***
# Checkout

TC-API-ORD-001 - Check out a valid cart
    [Tags]    smoke    feature_checkout
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/checkout"
    Then the response status should be 200
    And the response should be exactly    { "status": "READY_FOR_PAYMENT", "totalCents": 5290 }
    And the user's cart should have 1 item

TC-API-ORD-002 - Check out an empty cart
    [Tags]    feature_checkout
    When I send "POST" to "/users/{user}/cart/checkout"
    Then the response should be a 422 error with code "CART_EMPTY"

TC-API-ORD-003 - Check out with different companies
    [Documentation]    Expected failure: BUG-03. The setup depends on BUG-01.
    [Tags]    smoke    feature_checkout    known_bug
    Given the user's cart has items from different companies
    When I send "POST" to "/users/{user}/cart/checkout"
    Then the response should be a 422 error with code "CART_MIXED_COMPANIES"
    And the error message should be "The cart has items from different companies. The order cannot be completed."

TC-API-ORD-004 - Check out twice
    [Tags]    feature_checkout
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/checkout"
    Then the response status should be 200
    When I send "POST" to "/users/{user}/cart/checkout"
    Then the response status should be 200

TC-API-ORD-005 - Check out with a non-existent user
    [Tags]    feature_checkout
    When I send "POST" to "/users/{unique_name}/cart/checkout"
    Then the response should be a 404 error with code "USER_NOT_FOUND"

# Payment

TC-API-ORD-010 - Pay for a valid cart
    [Tags]    smoke    feature_payment
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/checkout"
    Then the response status should be 200
    When I send "POST" to "/users/{user}/cart/pay"
    Then the response status should be 200
    And the response should contain    { "status": "PAID", "message": "Fake payment completed" }
    And the user's cart should have 0 items

TC-API-ORD-011 - Pay without checking out first
    [Tags]    feature_payment
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/pay"
    Then the response status should be 200
    And the response should contain    { "status": "PAID" }

TC-API-ORD-012 - Pay for an empty cart
    [Tags]    feature_payment
    When I send "POST" to "/users/{user}/cart/pay"
    Then the response should be a 422 error with code "CART_EMPTY"

TC-API-ORD-013 - Pay with different companies
    [Documentation]    The setup depends on BUG-01. The payment route itself works.
    [Tags]    feature_payment
    Given the user's cart has items from different companies
    When I send "POST" to "/users/{user}/cart/pay"
    Then the response should be a 422 error with code "CART_MIXED_COMPANIES"
    And the user's cart should have 2 items

TC-API-ORD-014 - Pay twice
    [Tags]    feature_payment
    Given the user's cart has the item "pizzeria/supreme/M"
    When I send "POST" to "/users/{user}/cart/pay"
    Then the response status should be 200
    When I send "POST" to "/users/{user}/cart/pay"
    Then the response should be a 422 error with code "CART_EMPTY"

TC-API-ORD-015 - Pay with a non-existent user
    [Tags]    feature_payment
    When I send "POST" to "/users/{unique_name}/cart/pay"
    Then the response should be a 404 error with code "USER_NOT_FOUND"
