*** Settings ***
Documentation       Page Object: company list (home screen).


*** Keywords ***
Tap Company
    [Arguments]    ${company}
    Tap Element    company-${company}

Number Of Companies Should Be
    [Arguments]    ${expected}
    Wait For Element    ${HOME}[company_list]
    @{cards}=    Collect Ids Matching    ${HOME}[company_card_pattern]
    Length Should Be    ${cards}    ${expected}

Company Card Should Show
    [Arguments]    ${company}    ${name}
    Text Should Be    company-${company}-name    ${name}
