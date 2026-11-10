*** Settings ***
Documentation       Login
...                 As an API consumer
...                 I want to validate username and password
...                 So that access is granted only to correct credentials

Resource            ../../resources/api/api.resource

Test Tags           feature_login


*** Test Cases ***
TC-API-LOG-001 - Valid credentials
    [Tags]    smoke
    Given a new user exists
    When I send "POST" to "/login" with the body    { "username": "{user}", "password": "validPass1" }
    Then the response status should be 200
    And the response should contain    { "username": "{user}" }
    And the response should not contain password data

TC-API-LOG-002 - Seed users can log in
    [Tags]    smoke
    Then each seed user should be able to log in with the password "loveMetalSongs@"

TC-API-LOG-003 - Wrong password
    [Template]    Login should be rejected as invalid credentials
    user_manual    wrongPass1

TC-API-LOG-004 - Non-existent user
    [Template]    Login should be rejected as invalid credentials
    {unique_name}    loveMetalSongs@

TC-API-LOG-005 - Password with different case
    [Template]    Login should be rejected as invalid credentials
    user_manual    LOVEMETALSONGS@

TC-API-LOG-006 - Missing username
    [Template]    Login should fail with a validation error
    { "password": "loveMetalSongs@" }

TC-API-LOG-007 - Missing password
    [Template]    Login should fail with a validation error
    { "username": "user_manual" }

TC-API-LOG-008 - Non-string fields
    [Template]    Login should fail with a validation error
    { "username": 123, "password": 123 }


*** Keywords ***
Login should be rejected as invalid credentials
    [Arguments]    ${username}    ${password}
    When I send "POST" to "/login" with the body    { "username": "${username}", "password": "${password}" }
    Then the response should be a 401 error with code "INVALID_CREDENTIALS"
    And the error message should be "Invalid username or password."

Login should fail with a validation error
    [Arguments]    ${body}
    When I send "POST" to "/login" with the body    ${body}
    Then the response should be a 400 error with code "VALIDATION_ERROR"
