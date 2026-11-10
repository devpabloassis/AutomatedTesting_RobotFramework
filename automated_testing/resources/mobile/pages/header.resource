*** Settings ***
Documentation       Page Object: header (brand, cart link, counter and session).


*** Keywords ***
Tap Header Brand
    Tap Element    ${HEADER}[brand]

Tap Header Cart Link
    Tap Element    ${HEADER}[cart_link]

Cart Counter Should Show
    [Arguments]    ${expected}
    Text Should Be    ${HEADER}[cart_count]    ${expected}

Get Cart Counter
    ${count}=    Text Of    ${HEADER}[cart_count]
    RETURN    ${count}

Logged User Should Be
    [Arguments]    ${username}
    Text Should Be    ${HEADER}[logged_user]    ${username}

Tap Sign Out
    Tap Element    ${HEADER}[logout_button]

Tap Sign In Link
    Tap Element    ${HEADER}[login_link]

Sign Out Button Should Be Visible
    Wait For Element    ${HEADER}[logout_button]

Sign In Link Should Be Visible
    Wait For Element    ${HEADER}[login_link]

User Should Not Be Logged In
    Sign In Link Should Be Visible
    Element Should Not Exist    ${HEADER}[logged_user]
