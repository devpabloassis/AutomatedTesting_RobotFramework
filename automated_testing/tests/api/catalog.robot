*** Settings ***
Documentation       Catalog
...                 As an API consumer
...                 I want to fetch companies and products
...                 So that I can show the catalog to customers

Resource            ../../resources/api/api.resource

Test Tags           feature_catalog


*** Test Cases ***
TC-API-CAT-001 - List companies
    [Tags]    smoke
    When I send "GET" to "/companies"
    Then the response status should be 200
    And the response should have 4 companies with 4 products each

TC-API-CAT-002 - Catalog prices
    [Documentation]    Prices in cents, one value per option (Small, Medium, Large or Regular).
    [Template]    Catalog Prices Should Be
    # company    product             prices
    pizzeria     supreme             3890,5290,6690
    pizzeria     pepperoni           3490,4890,6290
    pizzeria     chicken-cheese      3690,5090,6490
    pizzeria     margherita          3290,4690,6090
    burgers      vegan               3190
    burgers      classic             2990
    burgers      egg-burger          2690
    burgers      double              3690
    japanese     beef-yakisoba       3490
    japanese     chicken-yakisoba    3190
    japanese     mixed-yakisoba      3790
    japanese     philly-hot-roll     2990
    juices       orange              890,1190,1490
    juices       pineapple           990,1290,1590
    juices       guava               950,1250,1550
    juices       acerola             900,1200,1500

TC-API-CAT-003 - Fetch each company
    [Template]    Company Should Be Returned By Its Id
    pizzeria
    burgers
    japanese
    juices

TC-API-CAT-004 - Size options
    Then the products of the companies "pizzeria, juices" should have the options "S, M, L"

TC-API-CAT-005 - Single option
    Then the products of the companies "burgers, japanese" should have the options "R"

TC-API-CAT-006 - Non-existent company
    [Template]    Fetching the company should return not found
    nonexistent

TC-API-CAT-007 - Different letter case
    [Template]    Fetching the company should return not found
    Pizzeria


*** Keywords ***
Fetching the company should return not found
    [Arguments]    ${company}
    When I send "GET" to "/companies/${company}"
    Then the response should be a 404 error with code "COMPANY_NOT_FOUND"
