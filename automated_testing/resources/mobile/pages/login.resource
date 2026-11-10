*** Settings ***
Documentation       Page Object: login screen.


*** Keywords ***
Log In
    [Arguments]    ${username}    ${password}
    Wait For Element    ${LOGIN}[form]
    Type Into    ${LOGIN}[username]    ${username}
    Type Into    ${LOGIN}[password]    ${password}
    Tap Sign In Button

Tap Sign In Button
    Tap Element    ${LOGIN}[submit_button]

Username Field Should Be Focused
    Element Should Be Focused    ${LOGIN}[username]
