*** Settings ***
Documentation       Add to cart
...                 As a customer
...                 I want to add products to the cart
...                 So that I can build my order

Resource            ../../resources/mobile/mobile.resource

Test Tags           feature_cart


*** Test Cases ***
TC-MOB-ADD-001 - Add to an empty cart
    [Tags]    smoke
    Given I am logged in as a new user
    And I am on the screen "/companies/pizzeria"
    When I select the size "Medium" for the product "supreme"
    And I add the product "supreme" to the cart
    Then I should see the message "Product added to the cart."
    And the cart counter should show "1"
    And the user's cart should contain the item "pizzeria/supreme/M" with quantity 1

TC-MOB-ADD-002 - Same company, another product
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/companies/pizzeria"
    And the cart counter should show "1"
    When I add the product "pepperoni" to the cart
    Then the cart counter should show "2"
    And the company switch warning should not appear
    And the user's cart should have 2 items

TC-MOB-ADD-003 - Same product and size
    Given I am logged in as a new user
    And I am on the screen "/companies/burgers"
    When I add the product "double" to the cart
    Then the cart counter should show "1"
    When I add the product "double" to the cart
    Then the cart counter should show "2"
    And the user's cart should have 1 item
    And the user's cart should contain the item "burgers/double/R" with quantity 2

TC-MOB-ADD-004 - Same product, another size
    Given I am logged in as a new user
    And I am on the screen "/companies/juices"
    When I select the size "Small" for the product "orange"
    And I add the product "orange" to the cart
    Then the cart counter should show "1"
    When I select the size "Large" for the product "orange"
    And I add the product "orange" to the cart
    Then the cart counter should show "2"
    And the user's cart should have 2 items

TC-MOB-ADD-005 - Add without logging in
    [Tags]    smoke
    Given I am not logged in
    And I am on the screen "/companies/pizzeria"
    When I add the product "supreme" to the cart
    Then I should be on the login screen
    And I should see the message "Sign in to add products to the cart."

TC-MOB-ADD-006 - Quantity limit
    Given I am logged in as a new user
    And the user's cart has the item "burgers/double/R" with quantity 99
    And I am on the screen "/companies/burgers"
    When I add the product "double" to the cart
    Then I should see the message "Item quantity cannot exceed 99."
    And the item quantity in the cart should be 99

TC-MOB-ADD-007 - API failure when adding
    Given I am logged in as a new user
    And the API responds with a 500 error on "/cart/items$"
    And I am on the screen "/companies/burgers"
    When I add the product "double" to the cart
    Then I should see the message "Internal error."
    And the cart counter should show "0"

TC-MOB-ADD-008 - Session of a non-existent user
    Given the app session belongs to a non-existent user
    And I am on the screen "/companies/burgers"
    When I add the product "double" to the cart
    Then I should see the message "User not found."
