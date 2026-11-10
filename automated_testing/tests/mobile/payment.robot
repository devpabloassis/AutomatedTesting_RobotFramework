*** Settings ***
Documentation       Payment
...                 As a customer
...                 I want to pay for my checked-out order
...                 So that I complete the purchase

Resource            ../../resources/mobile/mobile.resource

Test Setup          A customer has checked out a cart
Test Tags           feature_payment


*** Test Cases ***
TC-MOB-PAY-001 - Pay for the order
    [Tags]    smoke
    When I tap Pay
    Then I should see the message "Fake payment completed"

TC-MOB-PAY-002 - Cart after payment
    [Tags]    smoke
    When I tap Pay
    Then I should see the empty cart notice
    And the cart counter should show "0"

TC-MOB-PAY-003 - Cart emptied before paying
    When the cart is emptied in another session
    And I tap Pay
    Then I should see the message "The cart is empty."
    And the Pay button should not be visible

TC-MOB-PAY-004 - API failure when paying
    Given the API responds with a 500 error on "/cart/pay$"
    When I tap Pay
    Then I should see the message "Internal error."
    And the message "Fake payment completed" should not appear

TC-MOB-PAY-005 - Pay with different companies
    [Documentation]    The setup depends on BUG-01. The payment route itself works.
    When the cart receives the item "burgers/double/R" with a company switch in another session
    And I tap Pay
    Then I should see the message "The cart has items from different companies. The order cannot be completed."
    And the message "Fake payment completed" should not appear
    And the Pay button should not be visible
    And the user's cart should have 2 items


*** Keywords ***
A customer has checked out a cart
    Reset App
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    And I check out
    And the Pay button should be visible
