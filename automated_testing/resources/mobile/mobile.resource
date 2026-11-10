*** Settings ***
Documentation       Keywords of the mobile suites, written as Given/When/Then sentences.
...                 They use the Page Objects in pages/, which locate elements by the ids in object_map.py.
...                 The same keywords run on Android (UiAutomator2) and iOS (XCUITest).
...
...                 The libraries are imported only here: the page resources rely on this file.

Resource            ../common.resource
Library             String
Library             AppiumLibrary    run_on_failure=Capture Page Screenshot
Library             ../../libraries/MobileApp.py    ${PLATFORM}    ${APP_PACKAGE}    ${IOS_BUNDLE_ID}    ${UI_TIMEOUT}
Library             ../../libraries/FaultProxy.py
Variables           object_map.py
Resource            pages/common.resource
Resource            pages/header.resource
Resource            pages/home.resource
Resource            pages/company.resource
Resource            pages/confirm_dialog.resource
Resource            pages/login.resource
Resource            pages/cart.resource


*** Keywords ***
# Session and test lifecycle

Start Mobile Session
    [Documentation]    Starts the fault proxy, maps the ports to the device and opens the app.
    Start Fault Proxy    ${PROXY_PORT}    ${API_URL}
    ${app}=    Set Variable If    $PLATFORM == "ios"    ${IOS_APP}    ${ANDROID_APP}
    Open Food Marketplace App    ${APPIUM_URL}    ${DEVICE_UDID}    ${app}    ${APP_API_URL}    ${APP_ACTIVITY}
    Forward Ports To Device    ${PROXY_PORT}    ${TEST_PORT}

Stop Mobile Session
    Run Keyword And Ignore Error    Close All Applications
    Stop Fault Proxy

Finish Mobile Test
    [Documentation]    Test teardown: screenshot of the device when the test failed.
    Run Keyword If Test Failed    Capture Page Screenshot

Reset App
    [Documentation]    Test setup: no injected failures, no session, company list on screen.
    Reset Fault Proxy
    Open Deep Link    /    user=${EMPTY}
    Screen Should Be Open    /

# Session

I am logged in as a new user
    ${username}=    Create New User
    # A deep link sent while the previous screen is still changing can be dropped: it is sent again.
    Wait Until Keyword Succeeds    3x    1s    Start Session With Deep Link    ${username}

Start Session With Deep Link
    [Arguments]    ${username}
    Open Deep Link    /    user=${username}
    Logged User Should Be    ${username}

I am not logged in
    Open Deep Link    /    user=${EMPTY}
    User Should Not Be Logged In

The app session belongs to a non-existent user
    ${username}=    Get Unique Name
    Open Deep Link    /    user=${username}

# Navigation

I am on the screen "${route}"
    Open Deep Link    ${route}
    Screen Should Be Open    ${route}

I open the screen "${route}"
    Open Deep Link    ${route}

I should be on the screen "${route}"
    Screen Should Be Open    ${route}

I should be on the login screen
    Screen Should Be Open    /login

I restart the app
    Restart App
    Screen Should Be Open    /

I tap the header brand
    Tap Header Brand

I tap the company "${company}"
    Tap Company    ${company}

I navigate through the app to the company "${company}"
    Tap Header Brand
    Screen Should Be Open    /
    Tap Company    ${company}
    Screen Should Be Open    /companies/${company}

I open the cart through the header
    # The soft keyboard closing can move the header while the tap happens: the tap is repeated.
    Wait Until Keyword Succeeds    3x    1s    Open Cart With Header Link

Open Cart With Header Link
    Tap Header Cart Link
    Screen Should Be Open    /cart

I press the back button
    Press Back

The device is in landscape orientation
    Set Device Orientation    LANDSCAPE

The device goes back to portrait orientation
    Set Device Orientation    PORTRAIT

I should see ${count:\d+} companies
    Number Of Companies Should Be    ${count}

I should see ${count:\d+} products
    Number Of Products Should Be    ${count}

The page title should be "${title}"
    Page Title Should Be    ${title}

I should see the link back to the companies
    Back To Companies Link Should Be Visible

Each company should open from the home screen with ${count:\d+} products
    FOR    ${company}    IN    @{COMPANY_IDS}
        Open Deep Link    /
        Screen Should Be Open    /
        Tap Company    ${company}
        Screen Should Be Open    /companies/${company}
        Number Of Products Should Be    ${count}
    END

# Header

I should see the created user in the header
    ${username}=    Get Test User
    Logged User Should Be    ${username}

I should see the Sign out button
    Sign Out Button Should Be Visible

I should see the Sign in link in the header
    Sign In Link Should Be Visible

I should not be logged in
    User Should Not Be Logged In

I tap Sign out
    Tap Sign Out

The cart counter should show "${count}"
    Cart Counter Should Show    ${count}

The cart counter should match the user's cart
    ${total_items}=    User Cart Total Items
    Cart Counter Should Show    ${total_items}

# Messages

I should see the message "${text}"
    Message Should Be    ${text}

The message "${text}" should not appear
    Message Should Not Appear    ${text}

# Login

I log in with the created user
    ${username}=    Get Test User
    Log In    ${username}    ${VALID_PASSWORD}

I log in with the username "${username}" and the password "${password}"
    Log In    ${username}    ${password}

I log in with a non-existent user and the password "${password}"
    ${username}=    Get Unique Name
    Log In    ${username}    ${password}

I tap Sign in without filling in the fields
    Wait For Element    ${LOGIN}[form]
    Tap Sign In Button

The username field should be focused
    Username Field Should Be Focused

I am monitoring login requests
    Clear Recorded Requests

No login request should have been sent
    No Request Should Have Been Sent To    /login$

Each seed user should be able to sign in and sign out with the password "${password}"
    FOR    ${username}    IN    @{SEED_USERS}
        Open Deep Link    /login    user=${EMPTY}
        Screen Should Be Open    /login
        Log In    ${username}    ${password}
        Logged User Should Be    ${username}
        Tap Sign Out
        User Should Not Be Logged In
    END

# Catalog and products

I select the size "${size}" for the product "${product}"
    Select Size    ${product}    ${size}

I add the product "${product}" to the cart
    Tap Add To Cart    ${product}

The selected size of the product "${product}" should be "${option}"
    Selected Size Should Be    ${product}    ${option}

The price of the product "${product}" should be "${price}"
    Product Price Should Be    ${product}    ${price}

The product "${product}" should not have a size selector
    Product Should Not Have A Size Selector    ${product}

# Company switch warning

The company switch warning should show the text "${text}"
    Switch Warning Should Be Visible
    Switch Warning Text Should Contain    ${text}

The company switch warning should have the Yes and No options
    Switch Warning Should Have Yes And No

I answer the company switch warning with "${answer}"
    Switch Warning Should Be Visible
    Answer Switch Warning    ${answer}

I close the warning with the back button
    Switch Warning Should Be Visible
    Press Back

The company switch warning should not be visible
    Switch Warning Should Not Be Visible

The company switch warning should not appear
    Switch Warning Should Not Appear

# Cart

The row of the item "${reference}" should show "${name}", "${company}", "${option}" and "${unit_price}"
    Item Row Should Show    ${reference}    ${name}    ${company}    ${option}    ${unit_price}

The on-screen quantity of the item "${reference}" should be "${quantity}"
    Item Quantity Field Should Be    ${reference}    ${quantity}

The subtotal of the item "${reference}" should be "${subtotal}"
    Item Subtotal Should Be    ${reference}    ${subtotal}

The cart total should be "${total}"
    Cart Total Should Be    ${total}

The cart total should no longer be "${total}"
    Cart Total Should Not Be    ${total}

I change the quantity of the item "${reference}" to "${quantity}"
    Change Item Quantity    ${reference}    ${quantity}

I remove the item "${reference}"
    Remove Item    ${reference}

I should see the item "${reference}" in the cart
    Item Should Be In The Cart    ${reference}

The item "${reference}" should not be in the cart
    Item Should Not Be In The Cart    ${reference}

I should see the empty cart notice
    Empty Cart Notice Should Be Visible

I should see the View companies link
    View Companies Link Should Be Visible

I should see the cart sign-in notice "${text}"
    Cart Sign In Notice Should Be    ${text}

I should see the cart's Sign in button
    Cart Sign In Button Should Be Visible

I tap the cart's Sign in button
    Tap Cart Sign In Button

# Checkout and payment

I check out
    Tap Checkout

I tap Pay
    Tap Pay

The Checkout button should be visible
    Checkout Button Should Be Visible

The Checkout button should not be visible
    Checkout Button Should Not Be Visible

The Pay button should be visible
    Pay Button Should Be Visible

The Pay button should not be visible
    Pay Button Should Not Be Visible

# Failures injected by the proxy

The API responds with a 500 error on "${path_pattern}"
    Inject Server Error    ${path_pattern}
