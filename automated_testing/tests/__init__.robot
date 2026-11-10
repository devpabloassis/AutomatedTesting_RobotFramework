*** Settings ***
Documentation       Food Marketplace — automated API and mobile tests.
...                 The API is started on the test port (3100) with a clean database before any suite.

Resource            ../resources/common.resource

Suite Setup         Start The Test API
Suite Teardown      Stop The Test API
Test Tags           regression
