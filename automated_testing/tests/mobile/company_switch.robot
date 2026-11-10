*** Settings ***
Documentation       Company switch
...                 As a customer
...                 I want to be warned when I choose a product from another company
...                 So that I can decide whether to switch my order
...
...                 The cart counter shows the sum of the quantities in the cart returned by the API.

Resource            ../../resources/mobile/mobile.resource

Test Setup          A customer with a pizza in the cart is on the burgers screen
Test Tags           feature_company_switch


*** Test Cases ***
TC-MOB-SWT-001 - Show the warning
    [Tags]    smoke
    When I add the product "double" to the cart
    Then the company switch warning should show the text "the cart will be cleared"
    And the company switch warning should have the Yes and No options

TC-MOB-SWT-002 - Confirming with Yes clears the cart
    [Documentation]    Expected failure: BUG-01 (the cart is not cleared).
    [Tags]    smoke    known_bug
    When I add the product "double" to the cart
    And I answer the company switch warning with "Yes"
    Then I should see the message "Product added to the cart."
    And the user's cart should contain only the products "double"
    When I open the screen "/cart"
    Then I should see the item "double/R" in the cart
    And the item "supreme/M" should not be in the cart

TC-MOB-SWT-003 - Declining with No
    [Tags]    smoke
    When I add the product "double" to the cart
    And I answer the company switch warning with "No"
    Then the company switch warning should not be visible
    And the cart counter should show "1"
    And the user's cart should contain only the products "supreme"

TC-MOB-SWT-004 - Close the warning with the back button
    [Tags]    android_only
    When I add the product "double" to the cart
    And I close the warning with the back button
    Then the company switch warning should not be visible
    And the cart counter should show "1"
    And the user's cart should contain only the products "supreme"

TC-MOB-SWT-005 - Back button after a previous Yes
    [Tags]    android_only
    When I add the product "double" to the cart
    And I answer the company switch warning with "Yes"
    Then I should see the message "Product added to the cart."
    When I navigate through the app to the company "juices"
    And I save the cart state
    And I add the product "orange" to the cart
    And I close the warning with the back button
    Then the company switch warning should not be visible
    And the user's cart should not have changed

TC-MOB-SWT-006 - Counter after Yes
    [Documentation]    Expected failure: BUG-01.
    [Tags]    smoke    known_bug
    When I add the product "double" to the cart
    And I answer the company switch warning with "Yes"
    Then I should see the message "Product added to the cart."
    And the cart counter should show "1"

TC-MOB-SWT-007 - Counter after Yes with several units
    [Documentation]    Expected failure: BUG-01.
    [Tags]    known_bug
    Given the user's cart has the item "pizzeria/pepperoni/S" with quantity 2
    When I open the screen "/companies/burgers"
    Then the cart counter should show "3"
    When I add the product "double" to the cart
    And I answer the company switch warning with "Yes"
    Then I should see the message "Product added to the cart."
    And the cart counter should show "1"

TC-MOB-SWT-008 - Counter after Yes and app restart
    [Documentation]    Expected failure: BUG-01.
    [Tags]    known_bug
    When I add the product "double" to the cart
    And I answer the company switch warning with "Yes"
    Then I should see the message "Product added to the cart."
    When I restart the app
    Then the cart counter should show "1"
    When I open the cart through the header
    Then the cart counter should show "1"

TC-MOB-SWT-009 - Counter after Yes and another item from the same company
    [Documentation]    Expected failure: BUG-01 (the pizza is still in the cart, so the warning appears again).
    [Tags]    known_bug
    When I add the product "double" to the cart
    And I answer the company switch warning with "Yes"
    Then I should see the message "Product added to the cart."
    When I add the product "classic" to the cart
    Then the company switch warning should not appear
    And the cart counter should show "2"

TC-MOB-SWT-010 - Counter matches the cart after Yes
    When I add the product "double" to the cart
    And I answer the company switch warning with "Yes"
    Then I should see the message "Product added to the cart."
    And the cart counter should match the user's cart
    When I open the cart through the header
    Then the cart counter should match the user's cart

TC-MOB-SWT-011 - Counter after No with several units
    Given the user's cart has the item "pizzeria/pepperoni/S" with quantity 2
    When I open the screen "/companies/burgers"
    Then the cart counter should show "3"
    When I add the product "double" to the cart
    And I answer the company switch warning with "No"
    Then the company switch warning should not be visible
    And the cart counter should show "3"


*** Keywords ***
A customer with a pizza in the cart is on the burgers screen
    Reset App
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/companies/burgers"
    And the cart counter should show "1"
