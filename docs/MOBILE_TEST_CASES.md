# Test Case Repository — Mobile

> **Note:** this file exists only because no test management tool is integrated into this project. It is a way to **simulate** a test case repository that would normally live in a dedicated tool.

| Field | Value |
|---|---|
| System | Food Marketplace (mobile app, Android and iOS) |
| Based on | [`PRODUCT_SPEC.md`](./PRODUCT_SPEC.md) v1.0 (mobile) |
| App | `application/public/food-marketplace.apk` (package `com.foodmarketplace.app`) |
| Related repository | [`API_TEST_CASES.md`](./API_TEST_CASES.md) |

## 1. Conventions

- **Type:** `H` happy path, `A` alternative flow, `E` exception flow.
- **Expected result:** always describes the correct behavior. When an intentional defect prevents that result, the row shows **Expected failure** and the actual value.
- **Tags:** every test also has the Robot Framework tags `mobile` and `regression`. The column shows the others.
- **Platforms:** every test runs on Android and iOS, except the ones tagged `android_only` (Android system back button). The runner excludes them on iOS.
- **Test data:** tests that use a cart create their own user through the API and start that user's session with a deep link (`foodmarket://open/?user=<user>`).
- **Setup through the API:** when a precondition is not what is being validated, it is built through the API.
- **Reset between tests:** before each test, a deep link ends the session and opens the company list. One Appium session is used for the whole run.
- **"Restart the app":** closes and opens the app again. It is the mobile equivalent of reloading a web page.
- **Injected failures:** the app talks to the API through a local proxy. A test can make a route answer `500 INTERNAL_ERROR` (the mobile equivalent of mocking a route in a browser).
- **Automation:** each ID is a test case in `automated_testing/tests/mobile/`, named `<ID> - <title>`.

## 2. Navigation and catalog (BR-01, US-01)

| ID | Scenario | Type | Precondition | Steps | Expected result | Tags |
|---|---|---|---|---|---|---|
| TC-MOB-NAV-001 | See companies without logging in | H | No session | Open `/` | 4 companies, **Sign in** in the header and counter 0 | `smoke feature_catalog` |
| TC-MOB-NAV-002 | Open each company | H | No session | Tap each company on the home screen | Company screen with 4 products | `smoke feature_catalog` |
| TC-MOB-NAV-003 | Go back through the header | A | On a company screen | Tap **Food Marketplace** | Company list shown | `feature_catalog` |
| TC-MOB-NAV-004 | Go back with the system back button | A | On a company screen, coming from `/` | Press the Android back button | Company list shown | `feature_catalog android_only` |
| TC-MOB-NAV-005 | Open a company by deep link | A | — | Open `/companies/juices` | **Fresh Fruit Juices** with 4 products | `feature_catalog` |
| TC-MOB-NAV-006 | Non-existent company | E | — | Open `/companies/nonexistent` | `Company not found` and a back button | `feature_catalog` |
| TC-MOB-NAV-007 | Non-existent route | E | — | Open `/does-not-exist` | `Page not found` and a back button | `feature_catalog` |
| TC-MOB-NAV-008 | Catalog fails to load | E | Companies API answering 500 (proxy) | Open `/` | Error message returned by the API | `feature_catalog` |
| TC-MOB-NAV-009 | Landscape orientation | A | Device in landscape | Open `/` | The 4 companies are shown | `feature_catalog responsive` |

## 3. Products (US-01)

| ID | Scenario | Type | Precondition | Steps | Expected result | Tags |
|---|---|---|---|---|---|---|
| TC-MOB-PRD-001 | Default price with size | H | On `/companies/pizzeria` | Look at **Supreme** | Size **Small** selected and `$38.90` | `smoke feature_catalog` |
| TC-MOB-PRD-002 | Change the pizza size | H | On `/companies/pizzeria` | Select **Medium** and then **Large** on **Supreme** | `$52.90` and then `$66.90` | `feature_catalog` |
| TC-MOB-PRD-003 | Change the juice size | A | On `/companies/juices` | Select **Large** on **Orange** | `$14.90` | `feature_catalog` |
| TC-MOB-PRD-004 | Burger without size | A | On `/companies/burgers` | Look at **Double** | `$36.90`, no size selector | `feature_catalog` |
| TC-MOB-PRD-005 | Japanese food without size | A | On `/companies/japanese` | Look at **Philadelphia Hot Roll** | `$29.90`, no size selector | `feature_catalog` |

## 4. Login (BR-02, BR-03, US-02)

| ID | Scenario | Type | Precondition | Steps | Expected result | Tags |
|---|---|---|---|---|---|---|
| TC-MOB-LOG-001 | Valid login | H | No session | Enter a valid username and password and tap **Sign in** | Company list, username in the header and **Sign out** | `smoke feature_login` |
| TC-MOB-LOG-002 | Seed users can sign in | H | No session | Sign in and out with each of the 4 seed users | Login granted to all of them | `feature_login` |
| TC-MOB-LOG-003 | Session is kept after restarting the app | A | Logged in | Restart the app | User still in the header | `feature_login` |
| TC-MOB-LOG-004 | Return to the company | A | No session, on `/companies/pizzeria` | Tap **Add to cart** and sign in | Back on the pizzeria screen, logged in, cart still empty | `smoke feature_login` |
| TC-MOB-LOG-005 | Return to the cart | A | No session, on `/cart` | Tap **Sign in** in the cart and sign in | Back on the cart screen | `feature_login` |
| TC-MOB-LOG-006 | Sign out | H | Logged in, 1 item in the cart | Tap **Sign out** | **Sign in** in the header, counter 0, company list | `smoke feature_login` |
| TC-MOB-LOG-007 | Open login while logged in | A | Logged in | Open `/login` | Company list shown instead | `feature_login` |
| TC-MOB-LOG-008 | Wrong password | E | On `/login` | `user_manual` with a wrong password | `Invalid username or password.`, not logged in | `smoke feature_login` |
| TC-MOB-LOG-009 | Non-existent user | E | On `/login` | Unregistered username | `Invalid username or password.`, not logged in | `feature_login` |
| TC-MOB-LOG-010 | Empty fields | E | On `/login` | Tap **Sign in** with empty fields | Username field focused, still on login, no request sent (proxy) | `feature_login` |
| TC-MOB-LOG-011 | External redirect blocked | E | On `/login?next=//example.com` | Sign in with `user_manual` | Company list: the app ignores the external `next` | `feature_login security` |

## 5. Add to cart (BR-05, BR-09, BR-10, US-03)

| ID | Scenario | Type | Precondition | Steps | Expected result | Tags |
|---|---|---|---|---|---|---|
| TC-MOB-ADD-001 | Add to an empty cart | H | Logged in, empty cart | Select **Medium** on **Supreme** and tap **Add to cart** | `Product added to the cart.`, counter 1, item `pizzeria/supreme/M` with quantity 1 | `smoke feature_cart` |
| TC-MOB-ADD-002 | Same company, another product | H | 1 pizza in the cart | Add **Pepperoni** | Counter 2, no warning, 2 items | `feature_cart` |
| TC-MOB-ADD-003 | Same product and size | A | Logged in | Add **Double** twice | Counter 2, 1 item with quantity 2 | `feature_cart` |
| TC-MOB-ADD-004 | Same product, another size | A | Logged in | Add **Orange** Small and then Large | Counter 2, 2 items | `feature_cart` |
| TC-MOB-ADD-005 | Add without logging in | E | No session | Tap **Add to cart** | Login screen and `Sign in to add products to the cart.` | `smoke feature_cart` |
| TC-MOB-ADD-006 | Quantity limit | E | 99 units of **Double** | Add **Double** | `Item quantity cannot exceed 99.`, quantity still 99 | `feature_cart` |
| TC-MOB-ADD-007 | API failure when adding | E | `/cart/items` answering 500 (proxy) | Add **Double** | `Internal error.`, counter 0 | `feature_cart` |
| TC-MOB-ADD-008 | Session of a non-existent user | E | Session of an unregistered user | Add **Double** | `User not found.` | `feature_cart` |

## 6. Cart (BR-11 to BR-13, US-05)

| ID | Scenario | Type | Precondition | Steps | Expected result | Tags |
|---|---|---|---|---|---|---|
| TC-MOB-CRT-001 | Show item details | H | 1 pizza in the cart | Open `/cart` | Supreme, Noble Oven Pizzeria · Medium, `$52.90`, quantity 1, subtotal and total `$52.90` | `smoke feature_cart` |
| TC-MOB-CRT-002 | Empty cart | A | Logged in, empty cart | Open `/cart` | `Your cart is empty.` and **View companies** | `feature_cart` |
| TC-MOB-CRT-003 | Cart without logging in | E | No session | Open `/cart` | `Sign in to view your cart.` and **Sign in** | `feature_cart` |
| TC-MOB-CRT-004 | Update quantity | H | 1 pizza in the cart | Enter 3 and tap **Update** | Quantity field shows 3. **Expected failure (BUG-02):** shows 6 | `smoke feature_cart known_bug` |
| TC-MOB-CRT-005 | Recalculate amounts | H | 1 pizza in the cart | Enter 3 and tap **Update** | Subtotal and total `$158.70`, counter 3. **Expected failure (BUG-02):** `$317.40` | `feature_cart known_bug` |
| TC-MOB-CRT-006 | Zero quantity | E | 1 pizza in the cart | Update to 0 | `Quantity must be an integer from 1 to 99.`, quantity still 1 | `feature_cart` |
| TC-MOB-CRT-007 | Quantity above maximum | E | 1 pizza in the cart | Update to 100 | Same message, quantity still 1 | `feature_cart` |
| TC-MOB-CRT-008 | Negative quantity | E | 1 pizza in the cart | Update to -1 | Same message, quantity still 1 | `feature_cart` |
| TC-MOB-CRT-009 | Decimal quantity | E | 1 pizza in the cart | Update to 1.5 | Same message, quantity still 1 | `feature_cart` |
| TC-MOB-CRT-010 | Empty quantity | E | 1 pizza in the cart | Clear the field and tap **Update** | Same message, quantity still 1 | `feature_cart` |
| TC-MOB-CRT-011 | Remove one of several items | H | 2 pizzas in the cart | Remove **Pepperoni** | Item gone, total `$52.90`, counter 1 | `smoke feature_cart` |
| TC-MOB-CRT-012 | Remove the last item | A | 1 pizza in the cart | Remove it | Empty cart notice, counter 0 | `feature_cart` |
| TC-MOB-CRT-013 | Independent carts | A | Another user has a pizza | Open `/cart` as a new user | Empty cart | `feature_cart` |
| TC-MOB-CRT-014 | Cart is kept | A | User with 1 pizza | Sign in, open the cart, restart the app, sign out and in again | The item is shown every time | `feature_cart` |

## 7. Company switch (BR-05 to BR-08, US-04)

Precondition of every test: logged in, 1 pizza (`supreme/M`) in the cart, on `/companies/burgers`, counter 1.

| ID | Scenario | Type | Steps | Expected result | Tags |
|---|---|---|---|---|---|
| TC-MOB-SWT-001 | Show the warning | H | Add **Double** | Warning with `the cart will be cleared`, **Yes** and **No** | `smoke feature_company_switch` |
| TC-MOB-SWT-002 | Confirming with Yes clears the cart | H | Add **Double**, tap **Yes** | Cart with only `double`. **Expected failure (BUG-01):** `supreme` and `double` | `smoke feature_company_switch known_bug` |
| TC-MOB-SWT-003 | Declining with No | A | Add **Double**, tap **No** | Warning closed, counter 1, cart with only `supreme` | `smoke feature_company_switch` |
| TC-MOB-SWT-004 | Close the warning with the back button | A | Add **Double**, press back | Same as **No** | `feature_company_switch android_only` |
| TC-MOB-SWT-005 | Back button after a previous Yes | A | **Yes**, go to juices, add **Orange**, press back | Warning closed and the cart did not change | `feature_company_switch android_only` |
| TC-MOB-SWT-006 | Counter after Yes | H | Add **Double**, tap **Yes** | Counter 1. **Expected failure (BUG-01):** 2 | `smoke feature_company_switch known_bug` |
| TC-MOB-SWT-007 | Counter after Yes with several units | A | With 2 more pepperoni (counter 3), add **Double**, tap **Yes** | Counter 1. **Expected failure (BUG-01):** 4 | `feature_company_switch known_bug` |
| TC-MOB-SWT-008 | Counter after Yes and app restart | A | **Yes**, restart the app, open the cart | Counter 1. **Expected failure (BUG-01):** 2 | `feature_company_switch known_bug` |
| TC-MOB-SWT-009 | Counter after Yes and another item from the same company | A | **Yes**, then add **Classic** | No new warning, counter 2. **Expected failure (BUG-01):** the warning appears again | `feature_company_switch known_bug` |
| TC-MOB-SWT-010 | Counter matches the cart after Yes | A | **Yes**, then open the cart | Counter equals `totalItems` of the API cart | `feature_company_switch` |
| TC-MOB-SWT-011 | Counter after No with several units | A | With counter 3, add **Double**, tap **No** | Counter still 3 | `feature_company_switch` |

## 8. Checkout (BR-14 to BR-16, US-06)

Precondition of every test: logged in as a new user.

| ID | Scenario | Type | Precondition | Steps | Expected result | Tags |
|---|---|---|---|---|---|---|
| TC-MOB-CHK-001 | Check out a valid cart | H | 1 pizza, on `/cart` | Tap **Checkout** | `Order confirmed` and **Pay** visible | `smoke feature_checkout` |
| TC-MOB-CHK-002 | Different companies | E | Mixed cart (built through BUG-01) | Tap **Checkout** | Different-companies message, no **Pay**. **Expected failure (BUG-03):** `Order confirmed` | `smoke feature_checkout known_bug` |
| TC-MOB-CHK-003 | Update after checking out | A | Checked out | Update the quantity | **Pay** disappears | `feature_checkout` |
| TC-MOB-CHK-004 | Remove after checking out | A | Checked out, 2 items | Remove one item | **Pay** disappears | `feature_checkout` |
| TC-MOB-CHK-005 | Restart the app after checking out | A | Checked out | Restart the app and open the cart | **Checkout** visible, no **Pay** | `feature_checkout` |
| TC-MOB-CHK-006 | Pay before checking out | E | 1 pizza | Open `/cart` | **Checkout** visible, no **Pay** | `feature_checkout` |
| TC-MOB-CHK-007 | Empty cart | E | Empty cart | Open `/cart` | Empty cart notice, no **Checkout** or **Pay** | `feature_checkout` |
| TC-MOB-CHK-008 | Cart emptied in another session | E | On `/cart` with 1 item | Empty the cart through the API, tap **Checkout** | `The cart is empty.`, no **Pay** | `feature_checkout` |

## 9. Payment (BR-17, US-07)

Precondition of every test: logged in, 1 pizza, checked out on `/cart`, **Pay** visible.

| ID | Scenario | Type | Steps | Expected result | Tags |
|---|---|---|---|---|---|
| TC-MOB-PAY-001 | Pay for the order | H | Tap **Pay** | `Fake payment completed` | `smoke feature_payment` |
| TC-MOB-PAY-002 | Cart after payment | H | Tap **Pay** | Empty cart notice, counter 0 | `smoke feature_payment` |
| TC-MOB-PAY-003 | Cart emptied before paying | E | Empty the cart through the API, tap **Pay** | `The cart is empty.`, no **Pay** | `feature_payment` |
| TC-MOB-PAY-004 | API failure when paying | E | `/cart/pay` answering 500 (proxy), tap **Pay** | `Internal error.`, never `Fake payment completed` | `feature_payment` |
| TC-MOB-PAY-005 | Pay with different companies | E | A burger is added with a company switch through the API (BUG-01), tap **Pay** | Different-companies message, no **Pay**, 2 items kept | `feature_payment` |

## 10. Running by tag

Commands run inside `automated_testing/`.

| Goal | Command |
|---|---|
| All mobile tests (first connected device) | `python run.py --suite mobile` |
| Mobile smoke | `python run.py --suite mobile --include smoke` |
| Company switch | `python run.py --suite mobile --include feature_company_switch` |
| Without known defects | `python run.py --suite mobile --exclude known_bug` |
| A specific Android device | `python run.py --suite mobile --platform android --device <serial>` |
| iOS simulator | `python run.py --suite mobile --platform ios --device <udid>` |
