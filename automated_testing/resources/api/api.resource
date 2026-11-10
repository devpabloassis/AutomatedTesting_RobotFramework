*** Settings ***
Documentation       Keywords of the API suites, written as Given/When/Then sentences.
...                 Request paths and bodies accept {placeholders}, replaced by MarketplaceApi.py:
...                 {user} the test user, {item} its cart item, {unique_name} a new unique name,
...                 {generated_name} the last generated name, {payload} the SQL injection payload, etc.

Resource            ../common.resource


*** Keywords ***
# Requests

I send "${method:[A-Z]+}" to "${path:[^"]*}"
    Send Request    ${method}    ${path}

I send "${method:[A-Z]+}" to "${path:[^"]*}" without a body
    Send Request    ${method}    ${path}

I send "${method:[A-Z]+}" to "${path:[^"]*}" with the body
    [Arguments]    ${body}
    Send Request    ${method}    ${path}    ${body}

I send "${method:[A-Z]+}" to "${path:[^"]*}" with a ${kilobytes:\d+} KB password
    Send Request With Large Password    ${method}    ${path}    ${kilobytes}

The SQL injection payload is "${payload}"
    Set Sql Injection Payload    ${payload}

# Responses

The response status should be ${status:\d+}
    Response Status Should Be    ${status}

The response should be a ${status:\d+} error with code "${code}"
    Response Should Be Error    ${status}    ${code}

The error message should be "${message}"
    Error Message Should Be    ${message}

The response should contain
    [Arguments]    ${expected}
    Response Should Contain    ${expected}

The response should be exactly
    [Arguments]    ${expected}
    Response Should Be Exactly    ${expected}

The response should follow the "${contract}" contract
    ${body}=    Get Response Body
    Body Should Follow Contract    ${contract}    ${body}

The response should be a ${status:\d+} error that follows the contract
    Response Status Should Be    ${status}
    ${body}=    Get Response Body
    Body Should Follow Contract    error    ${body}

The response should have the creation date
    Response Should Have Creation Date

The response should not contain password data
    Response Should Not Contain Password Data

The response should not contain the payload
    Response Should Not Contain The Payload

The returned cart should have ${count:\d+} item
    Returned Cart Should Have Items    ${count}

The returned cart should have ${count:\d+} items
    Returned Cart Should Have Items    ${count}

The returned cart should contain only the products "${products}"
    Returned Cart Should Contain Only Products    ${products}

The response header "${name}" should contain "${value}"
    Response Header Should Contain    ${name}    ${value}

Logging in with the sent credentials should return status ${status:\d+}
    Login With Sent Credentials Should Return    ${status}

# Catalog

The response should have ${companies:\d+} companies with ${products:\d+} products each
    Response Should Have Companies With Products    ${companies}    ${products}

The products of the companies "${companies}" should have the options "${options}"
    @{company_ids}=    Evaluate    [company.strip() for company in $companies.split(',')]
    FOR    ${company_id}    IN    @{company_ids}
        Products Of Company Should Have Options    ${company_id}    ${options}
    END

# Seed users

Each seed user should be found
    FOR    ${username}    IN    @{SEED_USERS}
        User Should Be Found    ${username}
    END

Each seed user should be able to log in with the password "${password}"
    FOR    ${username}    IN    @{SEED_USERS}
        User Should Be Able To Log In    ${username}    ${password}
    END

# Persistence

I am using an isolated server
    Use Isolated Server

I restart the server
    Restart Isolated Server

I save the creation date of the seed users
    Save Creation Date Of Seed Users

The creation date of the seed users should be unchanged
    Creation Date Of Seed Users Should Be Unchanged

Each seed user should appear only once in the database
    Each Seed User Should Appear Once In Database

The database file should not contain the sent password
    Database Should Not Contain The Sent Password
