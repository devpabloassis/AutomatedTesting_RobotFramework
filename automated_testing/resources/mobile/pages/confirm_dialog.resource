*** Settings ***
Documentation       Page Object: company switch warning.


*** Keywords ***
Switch Warning Should Be Visible
    Wait For Element    ${CONFIRM_DIALOG}[dialog]

Switch Warning Should Not Be Visible
    Element Should Not Exist    ${CONFIRM_DIALOG}[dialog]

Switch Warning Should Not Appear
    [Documentation]    Checks for a while, because the warning only appears after an API call.
    Element Should Stay Absent    ${CONFIRM_DIALOG}[dialog]

Switch Warning Text Should Contain
    [Arguments]    ${text}
    Text Should Contain    ${CONFIRM_DIALOG}[text]    ${text}

Switch Warning Should Have Yes And No
    [Documentation]    The label of a Compose button is a child node, so the ids identify the options.
    Wait For Element    ${CONFIRM_DIALOG}[yes_button]
    Wait For Element    ${CONFIRM_DIALOG}[no_button]

Answer Switch Warning
    [Arguments]    ${answer}
    IF    $answer == "Yes"
        Tap Element    ${CONFIRM_DIALOG}[yes_button]
    ELSE
        Tap Element    ${CONFIRM_DIALOG}[no_button]
    END
