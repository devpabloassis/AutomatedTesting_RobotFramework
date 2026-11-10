*** Settings ***
Documentation       Mobile tests of the Food Marketplace app (Kotlin Multiplatform).
...                 One Appium session is used for the whole run. Before each test the app is reset
...                 through a deep link: no session, no injected failure and the company list on screen.

Resource            ../../resources/mobile/mobile.resource

Suite Setup         Start Mobile Session
Suite Teardown      Stop Mobile Session
Test Setup          Reset App
Test Teardown       Finish Mobile Test
Test Tags           mobile
