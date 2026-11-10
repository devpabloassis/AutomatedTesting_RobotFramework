*** Settings ***
Documentation       Navigation
...                 As a visitor
...                 I want to browse the companies without signing in
...                 So that I can see the options before buying

Resource            ../../resources/mobile/mobile.resource

Test Tags           feature_catalog


*** Test Cases ***
TC-MOB-NAV-001 - See companies without logging in
    [Tags]    smoke
    Given I am not logged in
    When I open the screen "/"
    Then I should see 4 companies
    And I should see the Sign in link in the header
    And the cart counter should show "0"

TC-MOB-NAV-002 - Open each company
    [Tags]    smoke
    Given I am not logged in
    Then each company should open from the home screen with 4 products

TC-MOB-NAV-003 - Go back through the header
    Given I am on the screen "/companies/juices"
    And I should see 4 products
    When I tap the header brand
    Then I should see 4 companies

TC-MOB-NAV-004 - Go back with the system back button
    [Tags]    android_only
    Given I am on the screen "/"
    When I tap the company "juices"
    Then I should be on the screen "/companies/juices"
    When I press the back button
    Then I should see 4 companies

TC-MOB-NAV-005 - Open a company by deep link
    When I open the screen "/companies/juices"
    Then the page title should be "Fresh Fruit Juices"
    And I should see 4 products

TC-MOB-NAV-006 - Non-existent company
    [Template]    Opening the route should show not found
    /companies/nonexistent    Company not found

TC-MOB-NAV-007 - Non-existent route
    [Template]    Opening the route should show not found
    /does-not-exist    Page not found

TC-MOB-NAV-008 - Catalog fails to load
    Given the API responds with a 500 error on "/api/companies$"
    When I open the screen "/"
    Then I should see the message "Internal error."

TC-MOB-NAV-009 - Landscape orientation
    [Tags]    responsive
    [Teardown]    Run Keywords    Finish Mobile Test    AND    The device goes back to portrait orientation
    Given the device is in landscape orientation
    When I open the screen "/"
    Then I should see 4 companies


*** Keywords ***
Opening the route should show not found
    [Arguments]    ${route}    ${title}
    When I open the screen "${route}"
    Then the page title should be "${title}"
    And I should see the link back to the companies
