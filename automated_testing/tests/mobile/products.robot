*** Settings ***
Documentation       Products
...                 As a visitor
...                 I want to see the products with their sizes and prices
...                 So that I can choose what to order

Resource            ../../resources/mobile/mobile.resource

Test Tags           feature_catalog


*** Test Cases ***
TC-MOB-PRD-001 - Default price with size
    [Tags]    smoke
    When I am on the screen "/companies/pizzeria"
    Then the selected size of the product "supreme" should be "S"
    And the price of the product "supreme" should be "$38.90"

TC-MOB-PRD-002 - Change the pizza size
    Given I am on the screen "/companies/pizzeria"
    When I select the size "Medium" for the product "supreme"
    Then the price of the product "supreme" should be "$52.90"
    When I select the size "Large" for the product "supreme"
    Then the price of the product "supreme" should be "$66.90"

TC-MOB-PRD-003 - Change the juice size
    Given I am on the screen "/companies/juices"
    When I select the size "Large" for the product "orange"
    Then the price of the product "orange" should be "$14.90"

TC-MOB-PRD-004 - Burger without size
    [Template]    The product should have a single price
    burgers    double    $36.90

TC-MOB-PRD-005 - Japanese food without size
    [Template]    The product should have a single price
    japanese    philly-hot-roll    $29.90


*** Keywords ***
The product should have a single price
    [Arguments]    ${company}    ${product}    ${price}
    When I am on the screen "/companies/${company}"
    Then the price of the product "${product}" should be "${price}"
    And the product "${product}" should not have a size selector
