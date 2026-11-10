*** Settings ***
Documentation       Requests and persistence
...                 As the API owner
...                 I want consistent responses and safely stored data
...                 So that the system behaves well across restarts

Resource            ../../resources/api/api.resource


*** Test Cases ***
TC-API-GEN-001 - JSON response
    [Tags]    smoke
    When I send "GET" to "/companies"
    Then the response header "content-type" should contain "application/json"

TC-API-GEN-002 - Non-existent route
    When I send "GET" to "/nonexistent"
    Then the response should be a 404 error with code "NOT_FOUND"

TC-API-GEN-003 - Method not allowed
    When I send "DELETE" to "/users"
    Then the response should be a 405 error with code "METHOD_NOT_ALLOWED"

# The tests below restart the system, so they use their own server and database.

TC-API-GEN-010 - Data kept after restart
    [Tags]    persistence
    Given I am using an isolated server
    When I send "POST" to "/users" with the body    { "username": "{unique_name}", "password": "validPass1" }
    And I send "POST" to "/users/{generated_name}/cart/items" with the body
    ...    { "companyId": "pizzeria", "productId": "supreme", "optionId": "M" }
    And I restart the server
    And I send "POST" to "/login" with the body    { "username": "{generated_name}", "password": "validPass1" }
    Then the response status should be 200
    When I send "GET" to "/users/{generated_name}/cart"
    Then the returned cart should contain only the products "supreme"

TC-API-GEN-011 - Restart neither duplicates nor changes seed users
    [Tags]    persistence
    Given I am using an isolated server
    And I save the creation date of the seed users
    When I restart the server
    Then the creation date of the seed users should be unchanged
    And each seed user should appear only once in the database

TC-API-GEN-012 - Password not stored in plain text
    [Tags]    security    persistence
    Given I am using an isolated server
    When I send "POST" to "/users" with the body    { "username": "{unique_name}", "password": "{unique_password}" }
    Then the response status should be 201
    And the database file should not contain the sent password
