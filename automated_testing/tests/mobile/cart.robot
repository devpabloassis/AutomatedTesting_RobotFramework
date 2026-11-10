*** Settings ***
Documentation       Cart
...                 As a customer
...                 I want to review, update and remove cart items
...                 So that I can adjust my order

Resource            ../../resources/mobile/mobile.resource

Test Tags           feature_cart


*** Test Cases ***
TC-MOB-CRT-001 - Show item details
    [Tags]    smoke
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    When I open the screen "/cart"
    Then the row of the item "supreme/M" should show "Supreme", "Noble Oven Pizzeria", "Medium" and "$52.90"
    And the on-screen quantity of the item "supreme/M" should be "1"
    And the subtotal of the item "supreme/M" should be "$52.90"
    And the cart total should be "$52.90"

TC-MOB-CRT-002 - Empty cart
    Given I am logged in as a new user
    When I open the screen "/cart"
    Then I should see the empty cart notice
    And I should see the View companies link

TC-MOB-CRT-003 - Cart without logging in
    Given I am not logged in
    When I open the screen "/cart"
    Then I should see the cart sign-in notice "Sign in to view your cart."
    And I should see the cart's Sign in button

TC-MOB-CRT-004 - Update quantity
    [Documentation]    Expected failure: BUG-02 (the quantity is stored doubled).
    [Tags]    smoke    known_bug
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    When I change the quantity of the item "supreme/M" to "3"
    Then the cart total should no longer be "$52.90"
    And the on-screen quantity of the item "supreme/M" should be "3"

TC-MOB-CRT-005 - Recalculate amounts
    [Documentation]    Expected failure: BUG-02 (the quantity is stored doubled).
    [Tags]    known_bug
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    When I change the quantity of the item "supreme/M" to "3"
    Then the cart total should no longer be "$52.90"
    And the subtotal of the item "supreme/M" should be "$158.70"
    And the cart total should be "$158.70"
    And the cart counter should show "3"

TC-MOB-CRT-006 - Zero quantity
    [Template]    An invalid quantity should be rejected
    0

TC-MOB-CRT-007 - Quantity above maximum
    [Template]    An invalid quantity should be rejected
    100

TC-MOB-CRT-008 - Negative quantity
    [Template]    An invalid quantity should be rejected
    -1

TC-MOB-CRT-009 - Decimal quantity
    [Template]    An invalid quantity should be rejected
    1.5

TC-MOB-CRT-010 - Empty quantity
    [Template]    An invalid quantity should be rejected
    ${EMPTY}

TC-MOB-CRT-011 - Remove one of several items
    [Tags]    smoke
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And the user's cart has the item "pizzeria/pepperoni/S"
    And I am on the screen "/cart"
    When I remove the item "pepperoni/S"
    Then the item "pepperoni/S" should not be in the cart
    And the cart total should be "$52.90"
    And the cart counter should show "1"

TC-MOB-CRT-012 - Remove the last item
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    When I remove the item "supreme/M"
    Then I should see the empty cart notice
    And the cart counter should show "0"

TC-MOB-CRT-013 - Independent carts
    Given another new user exists with the item "pizzeria/supreme/M"
    And I am logged in as a new user
    When I open the screen "/cart"
    Then I should see the empty cart notice

TC-MOB-CRT-014 - Cart is kept
    Given a new user exists
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/login"
    When I log in with the created user
    Then I should see the created user in the header
    When I open the cart through the header
    Then I should see the item "supreme/M" in the cart
    When I restart the app
    And I open the cart through the header
    Then I should see the item "supreme/M" in the cart
    When I tap Sign out
    Then I should see 4 companies
    When I open the screen "/login"
    And I log in with the created user
    Then I should see the created user in the header
    When I open the cart through the header
    Then I should see the item "supreme/M" in the cart


*** Keywords ***
An invalid quantity should be rejected
    [Arguments]    ${value}
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/cart"
    When I change the quantity of the item "supreme/M" to "${value}"
    Then I should see the message "Quantity must be an integer from 1 to 99."
    And the item quantity in the cart should be 1
