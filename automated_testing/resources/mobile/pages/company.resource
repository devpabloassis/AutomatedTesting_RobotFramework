*** Settings ***
Documentation       Page Object: products of a company.


*** Keywords ***
Number Of Products Should Be
    [Arguments]    ${expected}
    Wait For Element    ${COMPANY}[product_list]
    @{cards}=    Collect Ids Matching    ${COMPANY}[product_card_pattern]
    Length Should Be    ${cards}    ${expected}

Select Size
    [Arguments]    ${product}    ${size_label}
    Tap Element    product-${product}-size-${SIZE_OPTIONS}[${size_label}]

Tap Add To Cart
    [Arguments]    ${product}
    Tap Element    product-${product}-add

Product Price Should Be
    [Arguments]    ${product}    ${price}
    Text Should Be    product-${product}-price    ${price}

Selected Size Should Be
    [Arguments]    ${product}    ${option}
    Option Should Be Selected    product-${product}-size-${option}

Product Should Not Have A Size Selector
    [Arguments]    ${product}
    Wait For Element    product-${product}-price
    Element Should Not Exist    product-${product}-size
