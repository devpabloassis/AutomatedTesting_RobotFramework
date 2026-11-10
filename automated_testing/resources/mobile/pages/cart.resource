*** Settings ***
Documentation       Page Object: cart, checkout and payment.
...                 Item references use the "<productId>/<optionId>" format, for example "supreme/M".


*** Keywords ***
Cart Row Id
    [Arguments]    ${reference}
    ${product}    ${option}=    Split String    ${reference}    /
    RETURN    cart-item-${product}-${option}

Item Should Be In The Cart
    [Arguments]    ${reference}
    ${row}=    Cart Row Id    ${reference}
    Wait For Element    ${row}

Item Should Not Be In The Cart
    [Arguments]    ${reference}
    ${row}=    Cart Row Id    ${reference}
    Element Should Not Exist    ${row}    timeout=10s

Item Row Should Show
    [Arguments]    ${reference}    ${name}    ${company}    ${option}    ${unit_price}
    ${row}=    Cart Row Id    ${reference}
    Text Should Be    ${row}-name    ${name}
    Text Should Be    ${row}-details    ${company} · ${option}
    Text Should Be    ${row}-unit-price    ${unit_price}

Item Quantity Field Should Be
    [Arguments]    ${reference}    ${quantity}
    ${row}=    Cart Row Id    ${reference}
    Field Value Should Be    ${row}-quantity    ${quantity}

Item Subtotal Should Be
    [Arguments]    ${reference}    ${subtotal}
    ${row}=    Cart Row Id    ${reference}
    Text Should Be    ${row}-subtotal    ${subtotal}

Change Item Quantity
    [Arguments]    ${reference}    ${quantity}
    ${row}=    Cart Row Id    ${reference}
    Type Into    ${row}-quantity    ${quantity}
    Tap Element    ${row}-update

Remove Item
    [Arguments]    ${reference}
    ${row}=    Cart Row Id    ${reference}
    Tap Element    ${row}-delete

Cart Total Should Be
    [Arguments]    ${total}
    Text Should Be    ${CART}[total]    ${total}

Cart Total Should Not Be
    [Arguments]    ${total}
    Text Should Not Be    ${CART}[total]    ${total}

Empty Cart Notice Should Be Visible
    Text Should Be    ${CART}[empty_message]    Your cart is empty.

View Companies Link Should Be Visible
    Wait For Element    ${CART}[view_companies_link]

Cart Sign In Notice Should Be
    [Arguments]    ${text}
    Text Should Be    ${CART}[login_message]    ${text}

Cart Sign In Button Should Be Visible
    Wait For Element    ${CART}[login_button]

Tap Cart Sign In Button
    Tap Element    ${CART}[login_button]

Tap Checkout
    Tap Element    ${CART}[checkout_button]

Tap Pay
    Tap Element    ${CART}[pay_button]

Checkout Button Should Be Visible
    Wait For Element    ${CART}[checkout_button]

Checkout Button Should Not Be Visible
    Element Should Not Exist    ${CART}[checkout_button]

Pay Button Should Be Visible
    Wait For Element    ${CART}[pay_button]

Pay Button Should Not Be Visible
    Element Should Not Exist    ${CART}[pay_button]
