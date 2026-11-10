*** Settings ***
Documentation       Keywords shared by the API and mobile suites.
...                 Preconditions are built through the API, so every test creates its own user
...                 and the tests do not interfere with each other.

Variables           ../config/settings.py
Variables           test_data.py
Library             ../libraries/MarketplaceApi.py    ${API_URL}
Library             ../libraries/ContractValidator.py
Library             ../libraries/TestServer.py


*** Keywords ***
Start The Test API
    [Documentation]    Starts the API on the test port with a clean database (or reuses the one run.py started).
    Ensure Test Server Is Running    ${API_SERVER_SCRIPT}    ${TEST_PORT}    ${TEST_DB_PATH}

Stop The Test API
    Stop Test Server

# Users

A new user exists
    Create New User

Another new user exists with the item "${reference:[^"]+}"
    Create Another User With Item    ${reference}

# Cart preparation

The user's cart has the item "${reference:[^"]+}"
    Add Item To User Cart    ${reference}

The user's cart has the item "${reference:[^"]+}" with quantity ${quantity:\d+}
    Add Item To User Cart    ${reference}    ${quantity}

The user's cart has items from different companies
    [Documentation]    This cart can only be built because of BUG-01.
    Build Cart With Different Companies

The cart is emptied in another session
    Empty User Cart

The cart receives the item "${reference:[^"]+}" with a company switch in another session
    Add Item With Company Switch    ${reference}

I save the cart state
    Save Cart State

# Cart assertions (through the API)

The user's cart should have ${count:\d+} item
    User Cart Should Have Items    ${count}

The user's cart should have ${count:\d+} items
    User Cart Should Have Items    ${count}

The user's cart should contain only the products "${products}"
    User Cart Should Contain Only Products    ${products}

The user's cart should contain the item "${reference:[^"]+}" with quantity ${quantity:\d+}
    User Cart Should Contain Item    ${reference}    ${quantity}

The item quantity in the cart should be ${quantity:\d+}
    Item Quantity In Cart Should Be    ${quantity}

The other user's cart should have ${count:\d+} item
    Other User Cart Should Have Items    ${count}

The other user's item quantity should be ${quantity:\d+}
    Other User Item Quantity Should Be    ${quantity}

The user's cart should not have changed
    User Cart Should Not Have Changed
