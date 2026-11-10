package com.foodmarketplace.app.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.foodmarketplace.app.api.ApiException
import com.foodmarketplace.app.api.quantityToJson
import com.foodmarketplace.app.model.Cart
import com.foodmarketplace.app.model.CartItem
import com.foodmarketplace.app.state.AppState
import com.foodmarketplace.app.state.Screen
import com.foodmarketplace.app.ui.TestTags
import com.foodmarketplace.app.ui.components.PageHeader
import com.foodmarketplace.app.ui.components.PrimaryButton
import com.foodmarketplace.app.ui.components.SecondaryButton
import com.foodmarketplace.app.ui.components.automationId
import com.foodmarketplace.app.ui.formatMoney
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(state: AppState, screen: Screen.Login) {
    val scope = rememberCoroutineScope()
    var username by remember(screen) { mutableStateOf("") }
    var password by remember(screen) { mutableStateOf("") }
    val usernameFocus = remember { FocusRequester() }

    // An authenticated user does not see the login screen (web: /login redirects to /).
    LaunchedEffect(screen, state.session) {
        if (state.session != null) state.goHome()
    }

    fun submit() {
        // Required fields: the request is not sent and the first empty field receives the focus.
        if (username.isEmpty() || password.isEmpty()) {
            usernameFocus.requestFocus()
            return
        }
        scope.launch {
            state.clearMessage()
            try {
                val user = state.api.login(username, password)
                state.signIn(user.username, screen.next)
            } catch (error: ApiException) {
                state.showError(error.message)
            }
        }
    }

    Column(modifier = Modifier.testTag(TestTags.SCREEN_LOGIN)) {
        PageHeader("Sign in", "Use your account to build your cart.")
        Column(
            modifier = Modifier.fillMaxWidth().testTag(TestTags.LOGIN_FORM),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                label = { Text("Username") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth().focusRequester(usernameFocus).testTag(TestTags.LOGIN_USERNAME),
            )
            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password") },
                singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                modifier = Modifier.fillMaxWidth().testTag(TestTags.LOGIN_PASSWORD),
            )
            PrimaryButton("Sign in", TestTags.LOGIN_SUBMIT, onClick = { submit() }, modifier = Modifier.fillMaxWidth())
        }
    }
}

@Composable
fun CartScreen(state: AppState, screen: Screen.Cart) {
    val username = state.session
    if (username == null) {
        Column(modifier = Modifier.testTag(TestTags.SCREEN_CART)) {
            PageHeader("Cart")
            Text(
                "Sign in to view your cart.",
                modifier = Modifier.padding(bottom = 12.dp).automationId(TestTags.CART_LOGIN_MESSAGE),
            )
            PrimaryButton(
                "Sign in",
                TestTags.CART_LOGIN_BUTTON,
                onClick = { state.navigate(Screen.Login(next = Screen.Cart())) },
            )
        }
        return
    }

    val scope = rememberCoroutineScope()
    var cart by remember(screen) { mutableStateOf<Cart?>(null) }
    // The Pay button only exists right after a successful checkout (BR-16).
    var readyForPayment by remember(screen) { mutableStateOf(false) }

    fun draw(updated: Cart, ready: Boolean = false) {
        cart = updated
        readyForPayment = ready
        state.cartCount = updated.totalItems
    }

    fun action(block: suspend () -> Unit) {
        scope.launch {
            state.clearMessage()
            try {
                block()
            } catch (error: ApiException) {
                readyForPayment = false
                state.showError(error.message)
            }
        }
    }

    LaunchedEffect(screen, username) {
        try {
            draw(state.api.cart(username))
        } catch (error: ApiException) {
            state.showError(error.message)
        }
    }

    Column(modifier = Modifier.testTag(TestTags.SCREEN_CART)) {
        val loaded = cart
        if (loaded == null) {
            if (state.message == null) Loading()
            return@Column
        }
        if (loaded.items.isEmpty()) {
            PageHeader("Cart")
            Text(
                "Your cart is empty.",
                modifier = Modifier.padding(bottom = 12.dp).automationId(TestTags.CART_EMPTY_MESSAGE),
            )
            PrimaryButton("View companies", TestTags.CART_VIEW_COMPANIES, onClick = { state.goHome() })
            return@Column
        }

        PageHeader("Cart", "Review your items before placing the order.")
        Column(
            modifier = Modifier.testTag(TestTags.CART_LIST),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            loaded.items.forEach { item ->
                CartItemRow(
                    item = item,
                    onUpdate = { text ->
                        action { draw(state.api.updateItem(username, item.id, quantityToJson(text))) }
                    },
                    onDelete = { action { draw(state.api.deleteItem(username, item.id)) } },
                )
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("Total: ", style = MaterialTheme.typography.titleMedium)
            Text(
                formatMoney(loaded.totalCents),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.automationId(TestTags.CART_TOTAL),
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(top = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SecondaryButton("Checkout", TestTags.CHECKOUT_BUTTON, onClick = {
                action {
                    state.api.checkout(username)
                    draw(state.api.cart(username), ready = true)
                    state.showMessage("Order confirmed")
                }
            })
            if (readyForPayment) {
                PrimaryButton("Pay", TestTags.PAY_BUTTON, onClick = {
                    action {
                        val payment = state.api.pay(username)
                        draw(state.api.cart(username))
                        state.showMessage(payment.message)
                    }
                })
            }
        }
    }
}

@Composable
private fun CartItemRow(item: CartItem, onUpdate: (String) -> Unit, onDelete: () -> Unit) {
    val row = TestTags.cartItem(item.productId, item.optionId)
    // The field shows the quantity stored by the API every time the cart is redrawn.
    var quantity by remember(item.id, item.quantity) { mutableStateOf(item.quantity.toString()) }

    Card(modifier = Modifier.fillMaxWidth().testTag(row)) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                item.productName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.automationId("$row-name"),
            )
            Text(
                "${item.companyName} · ${item.optionLabel}",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.automationId("$row-details"),
            )
            Row {
                Text("Unit price: ")
                Text(formatMoney(item.unitPriceCents), modifier = Modifier.automationId("$row-unit-price"))
            }
            Row {
                Text("Subtotal: ")
                Text(
                    formatMoney(item.subtotalCents),
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.automationId("$row-subtotal"),
                )
            }
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.padding(top = 8.dp),
            ) {
                OutlinedTextField(
                    value = quantity,
                    onValueChange = { quantity = it },
                    label = { Text("Quantity") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f).testTag("$row-quantity"),
                )
                SecondaryButton("Update", "$row-update", onClick = { onUpdate(quantity) })
                SecondaryButton("Remove", "$row-delete", onClick = onDelete)
            }
        }
    }
}
