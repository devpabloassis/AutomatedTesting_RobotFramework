*** Settings ***
Documentation       Page Object: elements shared by every screen (title, message, not-found screen).


*** Keywords ***
Page Title Should Be
    [Arguments]    ${title}
    Text Should Be    ${COMMON}[page_title]    ${title}

Message Should Be
    [Arguments]    ${text}
    Text Should Be    ${COMMON}[message]    ${text}

Message Should Not Appear
    [Arguments]    ${text}
    ${shown}=    Element Exists    ${COMMON}[message]
    IF    ${shown}    Text Should Not Be    ${COMMON}[message]    ${text}    timeout=1s

Back To Companies Link Should Be Visible
    Wait For Element    ${COMMON}[back_to_companies]

Screen Should Be Open
    [Arguments]    ${route}
    [Documentation]    Waits for the screen of a route: /, /login, /cart or /companies/<companyId>.
    ${route}=    Evaluate    $route.split("?")[0]
    IF    $route == "/"
        Wait For Element    ${SCREEN}[home]
        Wait For Element    ${HOME}[company_list]
    ELSE IF    $route == "/login"
        Wait For Element    ${SCREEN}[login]
    ELSE IF    $route == "/cart"
        Wait For Element    ${SCREEN}[cart]
    ELSE IF    $route.startswith("/companies/")
        ${company}=    Evaluate    $route.split("/")[-1]
        Wait For Element    ${SCREEN}[company]
        IF    $company in $COMPANY_NAMES
            Page Title Should Be    ${COMPANY_NAMES}[${company}]
        END
    ELSE
        Wait For Element    ${SCREEN}[not_found]
    END
