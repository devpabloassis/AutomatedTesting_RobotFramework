*** Settings ***
Documentation       Order checkout
...                 As a customer
...                 I want to check out my cart
...                 So that I can move on to payment

Resource            ../../resources/mobile/mobile.resource

Test Setup          Reset the app and log in as a new user
Test Tags           feature_checkout


*** Test Cases ***
TC-MOB-CHK-001 - Check out a valid cart
    [Tags]    smoke
    Given the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    When I check out
    Then I should see the message "Order confirmed"
    And the Pay button should be visible

TC-MOB-CHK-002 - Different companies
    [Documentation]    Expected failure: BUG-03. The setup depends on BUG-01.
    [Tags]    smoke    known_bug
    Given the user's cart has items from different companies
    And I am on the screen "/cart"
    When I check out
    Then I should see the message "The cart has items from different companies. The order cannot be completed."
    And the Pay button should not be visible

TC-MOB-CHK-003 - Update after checking out
    Given the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    When I check out
    Then the Pay button should be visible
    When I change the quantity of the item "supreme/M" to "2"
    Then the Pay button should not be visible

TC-MOB-CHK-004 - Remove after checking out
    Given the user's cart has the item "pizzeria/supreme/M"
    And the user's cart has the item "pizzeria/pepperoni/S"
    And I am on the screen "/cart"
    When I check out
    Then the Pay button should be visible
    When I remove the item "pepperoni/S"
    Then the Pay button should not be visible

TC-MOB-CHK-005 - Restart the app after checking out
    Given the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    When I check out
    Then the Pay button should be visible
    When I restart the app
    And I open the cart through the header
    Then the Checkout button should be visible
    And the Pay button should not be visible

TC-MOB-CHK-006 - Pay before checking out
    Given the user's cart has the item "pizzeria/supreme/M"
    When I open the screen "/cart"
    Then the Checkout button should be visible
    And the Pay button should not be visible

TC-MOB-CHK-007 - Empty cart
    When I open the screen "/cart"
    Then I should see the empty cart notice
    And the Checkout button should not be visible
    And the Pay button should not be visible

TC-MOB-CHK-008 - Cart emptied in another session
    Given the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    And the Checkout button should be visible
    When the cart is emptied in another session
    And I check out
    Then I should see the message "The cart is empty."
    And the Pay button should not be visible


*** Keywords ***
Reset the app and log in as a new user
    Reset App
    I am logged in as a new user
