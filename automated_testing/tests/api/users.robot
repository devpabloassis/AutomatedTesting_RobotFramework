*** Settings ***
Documentation       Users
...                 As an API consumer
...                 I want to create and fetch users
...                 So that customers can use the system

Resource            ../../resources/api/api.resource

Test Tags           feature_user


*** Test Cases ***
TC-API-USR-001 - Create a valid user
    [Tags]    smoke
    When I send "POST" to "/users" with the body    { "username": "{unique_name}", "password": "validPass1" }
    Then the response status should be 201
    And the response should contain    { "username": "{generated_name}" }
    And the response should have the creation date
    And the response should not contain password data

TC-API-USR-002 - Minimum username length
    [Template]    Creating a user should succeed
    { "username": "{name_3_chars}", "password": "validPass1" }

TC-API-USR-003 - Maximum username length
    [Template]    Creating a user should succeed
    { "username": "{name_30_chars}", "password": "validPass1" }

TC-API-USR-004 - Minimum password length
    [Template]    Creating a user should succeed
    { "username": "{unique_name}", "password": "12345678" }

TC-API-USR-005 - Username is case-sensitive
    When I send "POST" to "/users" with the body    { "username": "Case_{unique_name}", "password": "validPass1" }
    Then the response status should be 201
    When I send "POST" to "/users" with the body    { "username": "case_{generated_name}", "password": "validPass1" }
    Then the response status should be 201

TC-API-USR-006 - Username already exists
    Given a new user exists
    When I send "POST" to "/users" with the body    { "username": "{user}", "password": "validPass1" }
    Then the response should be a 409 error with code "USER_ALREADY_EXISTS"

TC-API-USR-007 - Username below minimum
    [Template]    Creating a user should fail with a validation error
    { "username": "ab", "password": "validPass1" }

TC-API-USR-008 - Username above maximum
    [Template]    Creating a user should fail with a validation error
    { "username": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "password": "validPass1" }

TC-API-USR-009 - Password below minimum
    [Template]    Creating a user should fail with a validation error
    { "username": "{unique_name}", "password": "1234567" }

TC-API-USR-010 - Missing username
    [Template]    Creating a user should fail with a validation error
    { "password": "validPass1" }

TC-API-USR-011 - Missing password
    [Template]    Creating a user should fail with a validation error
    { "username": "{unique_name}" }

TC-API-USR-012 - Empty body
    When I send "POST" to "/users" without a body
    Then the response should be a 400 error with code "VALIDATION_ERROR"

TC-API-USR-013 - Malformed JSON
    [Template]    Creating a user should fail with a validation error
    {"username":

TC-API-USR-014 - Body is not an object
    [Template]    Creating a user should fail with a validation error
    \[]

TC-API-USR-015 - Body larger than 100 KB
    When I send "POST" to "/users" with a 150 KB password
    Then the response should be a 400 error with code "VALIDATION_ERROR"

TC-API-USR-020 - Fetch an existing user
    [Tags]    smoke
    Given a new user exists
    When I send "GET" to "/users/{user}"
    Then the response status should be 200
    And the response should contain    { "username": "{user}" }
    And the response should have the creation date
    And the response should not contain password data

TC-API-USR-021 - Seed users exist
    [Tags]    smoke
    Then each seed user should be found

TC-API-USR-022 - Non-existent user
    When I send "GET" to "/users/{unique_name}"
    Then the response should be a 404 error with code "USER_NOT_FOUND"

TC-API-USR-023 - Different letter case
    When I send "GET" to "/users/User_Manual"
    Then the response should be a 404 error with code "USER_NOT_FOUND"


*** Keywords ***
Creating a user should succeed
    [Arguments]    ${body}
    When I send "POST" to "/users" with the body    ${body}
    Then the response status should be 201

Creating a user should fail with a validation error
    [Arguments]    ${body}
    When I send "POST" to "/users" with the body    ${body}
    Then the response should be a 400 error with code "VALIDATION_ERROR"
