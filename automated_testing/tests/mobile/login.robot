*** Settings ***
Documentation       Login
...                 As a customer
...                 I want to sign in with username and password
...                 So that I can use my cart

Resource            ../../resources/mobile/mobile.resource

Test Tags           feature_login


*** Test Cases ***
TC-MOB-LOG-001 - Valid login
    [Tags]    smoke
    Given a new user exists
    And I am on the screen "/login"
    When I log in with the created user
    Then I should see 4 companies
    And I should see the created user in the header
    And I should see the Sign out button

TC-MOB-LOG-002 - Seed users can sign in
    Then each seed user should be able to sign in and sign out with the password "loveMetalSongs@"

TC-MOB-LOG-003 - Session is kept after restarting the app
    Given I am logged in as a new user
    When I restart the app
    Then I should see the created user in the header

TC-MOB-LOG-004 - Return to the company
    [Tags]    smoke
    Given a new user exists
    And I am on the screen "/companies/pizzeria"
    When I add the product "supreme" to the cart
    Then I should be on the login screen
    When I log in with the created user
    Then I should be on the screen "/companies/pizzeria"
    And I should see the created user in the header
    And the user's cart should have 0 items

TC-MOB-LOG-005 - Return to the cart
    Given a new user exists
    And I am on the screen "/cart"
    When I tap the cart's Sign in button
    And I log in with the created user
    Then I should be on the screen "/cart"

TC-MOB-LOG-006 - Sign out
    [Tags]    smoke
    Given I am logged in as a new user
    And the user's cart has the item "pizzeria/supreme/M"
    And I am on the screen "/"
    And the cart counter should show "1"
    When I tap Sign out
    Then I should see the Sign in link in the header
    And the cart counter should show "0"
    And I should be on the screen "/"

TC-MOB-LOG-007 - Open login while logged in
    Given I am logged in as a new user
    When I open the screen "/login"
    Then I should see 4 companies
    And I should be on the screen "/"

TC-MOB-LOG-008 - Wrong password
    [Tags]    smoke
    Given I am on the screen "/login"
    When I log in with the username "user_manual" and the password "wrongPass1"
    Then I should see the message "Invalid username or password."
    And I should not be logged in

TC-MOB-LOG-009 - Non-existent user
    Given I am on the screen "/login"
    When I log in with a non-existent user and the password "loveMetalSongs@"
    Then I should see the message "Invalid username or password."
    And I should not be logged in

TC-MOB-LOG-010 - Empty fields
    Given I am monitoring login requests
    And I am on the screen "/login"
    When I tap Sign in without filling in the fields
    Then the username field should be focused
    And I should be on the login screen
    And no login request should have been sent

TC-MOB-LOG-011 - External redirect blocked
    [Tags]    security
    Given I am on the screen "/login?next=//example.com"
    When I log in with the username "user_manual" and the password "loveMetalSongs@"
    Then I should see 4 companies
    And I should be on the screen "/"
