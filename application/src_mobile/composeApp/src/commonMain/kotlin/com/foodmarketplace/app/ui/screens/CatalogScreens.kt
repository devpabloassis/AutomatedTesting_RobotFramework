package com.foodmarketplace.app.ui.screens

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.foodmarketplace.app.api.ApiException
import com.foodmarketplace.app.model.Company
import com.foodmarketplace.app.model.Product
import com.foodmarketplace.app.state.AppState
import com.foodmarketplace.app.state.Screen
import com.foodmarketplace.app.ui.TestTags
import com.foodmarketplace.app.ui.components.PageHeader
import com.foodmarketplace.app.ui.components.PrimaryButton
import com.foodmarketplace.app.ui.components.SecondaryButton
import com.foodmarketplace.app.ui.components.automationId
import com.foodmarketplace.app.ui.formatMoney
import kotlinx.coroutines.launch

const val SWITCH_COMPANY_TEXT =
    "Your cart has items from another company. If you continue, the cart will be cleared. Do you want to continue?"

@Composable
fun Loading() {
    CircularProgressIndicator(modifier = Modifier.padding(24.dp).testTag(TestTags.LOADING))
}

@Composable
fun HomeScreen(state: AppState, screen: Screen.Home) {
    var companies by remember(screen) { mutableStateOf<List<Company>?>(null) }
    LaunchedEffect(screen) {
        try {
            companies = state.api.companies()
        } catch (error: ApiException) {
            state.showError(error.message)
        }
    }
    Column(modifier = Modifier.testTag(TestTags.SCREEN_HOME)) {
        val list = companies
        if (list == null) {
            if (state.message == null) Loading()
            return@Column
        }
        PageHeader("Choose a company", "Browse the products, even without signing in.")
        Column(
            modifier = Modifier.testTag(TestTags.COMPANY_LIST),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            list.forEach { company ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { state.navigate(Screen.CompanyDetail(company.id)) }
                        .testTag(TestTags.company(company.id)),
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            company.name,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.automationId(TestTags.companyName(company.id)),
                        )
                        Text(
                            company.description,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.automationId(TestTags.companyDescription(company.id)),
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun NotFoundScreen(state: AppState, title: String) {
    Column(modifier = Modifier.testTag(TestTags.SCREEN_NOT_FOUND)) {
        PageHeader(title)
        SecondaryButton("Back to companies", TestTags.BACK_TO_COMPANIES, onClick = { state.goHome() })
    }
}

@Composable
fun CompanyScreen(state: AppState, screen: Screen.CompanyDetail) {
    var company by remember(screen) { mutableStateOf<Company?>(null) }
    var notFound by remember(screen) { mutableStateOf(false) }
    LaunchedEffect(screen) {
        try {
            company = state.api.company(screen.companyId)
        } catch (error: ApiException) {
            if (error.status == 404) notFound = true else state.showError(error.message)
        }
    }
    if (notFound) {
        NotFoundScreen(state, "Company not found")
        return
    }
    Column(modifier = Modifier.testTag(TestTags.SCREEN_COMPANY)) {
        val loaded = company
        if (loaded == null) {
            if (state.message == null) Loading()
            return@Column
        }
        PageHeader(loaded.name, loaded.description)
        Column(
            modifier = Modifier.testTag(TestTags.PRODUCT_LIST),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            loaded.products.forEach { product -> ProductCard(state, screen, loaded.id, product) }
        }
    }
}

@Composable
private fun ProductCard(state: AppState, screen: Screen.CompanyDetail, companyId: String, product: Product) {
    val scope = rememberCoroutineScope()
    var selectedOption by remember(screen, product.id) { mutableStateOf(product.options.first()) }

    Card(modifier = Modifier.fillMaxWidth().testTag(TestTags.product(product.id))) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                Text(
                    product.name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.weight(1f).automationId(TestTags.productName(product.id)),
                )
                Text(
                    formatMoney(selectedOption.priceCents),
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.automationId(TestTags.productPrice(product.id)),
                )
            }
            // Size selector, only for products with more than one option (web: <select>).
            if (product.options.size > 1) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.selectableGroup().testTag(TestTags.productSize(product.id)),
                ) {
                    product.options.forEach { option ->
                        val selected = option.id == selectedOption.id
                        FilterChip(
                            selected = selected,
                            onClick = { selectedOption = option },
                            label = { Text(option.label) },
                            modifier = Modifier.testTag(TestTags.productSizeOption(product.id, option.id)),
                        )
                    }
                }
            }
            PrimaryButton(
                text = "Add to cart",
                tag = TestTags.productAdd(product.id),
                onClick = { scope.launch { addToCart(state, screen, companyId, product.id, selectedOption.id) } },
            )
        }
    }
}

private suspend fun addToCart(
    state: AppState,
    screen: Screen.CompanyDetail,
    companyId: String,
    productId: String,
    optionId: String,
) {
    state.clearMessage()
    val username = state.session
    if (username == null) {
        state.navigate(Screen.Login(next = screen))
        state.showError("Sign in to add products to the cart.")
        return
    }
    try {
        val cart = try {
            state.api.addItem(username, companyId, productId, optionId)
        } catch (error: ApiException) {
            if (error.code != "CART_COMPANY_CONFLICT") throw error
            if (!state.askConfirmation(SWITCH_COMPANY_TEXT)) return
            state.api.addItem(username, companyId, productId, optionId, replaceCart = true)
        }
        state.cartCount = cart.totalItems
        state.showMessage("Product added to the cart.")
    } catch (error: ApiException) {
        state.showError(error.message)
    }
}
