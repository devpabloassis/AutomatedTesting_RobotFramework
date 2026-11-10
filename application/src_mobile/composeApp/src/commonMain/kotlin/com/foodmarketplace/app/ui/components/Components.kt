package com.foodmarketplace.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.foodmarketplace.app.platform.exposeTestTags
import com.foodmarketplace.app.state.AppState
import com.foodmarketplace.app.state.Message
import com.foodmarketplace.app.ui.TestTags

/**
 * Gives the element a stable id for the automation and keeps it as its own node in the
 * accessibility tree. Without the merge boundary, a tagged text inside a clickable card would be
 * merged into the card and its id would not be visible to UiAutomator2/XCUITest.
 */
fun Modifier.automationId(id: String): Modifier = this.semantics(mergeDescendants = true) {}.testTag(id)

@Composable
fun Header(state: AppState) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.primary)
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        TextButton(onClick = { state.goHome() }, modifier = Modifier.weight(1f).testTag(TestTags.HEADER_BRAND)) {
            Text("Food Marketplace", color = Color.White, fontWeight = FontWeight.Bold)
        }
        TextButton(onClick = { state.navigate(com.foodmarketplace.app.state.Screen.Cart()) }, modifier = Modifier.testTag(TestTags.HEADER_CART_LINK)) {
            Text("Cart", color = Color.White)
        }
        Text(
            text = state.cartCount.toString(),
            color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.Bold,
            modifier = Modifier
                .automationId(TestTags.CART_COUNT)
                .background(Color.White, RoundedCornerShape(10.dp))
                .padding(horizontal = 8.dp, vertical = 2.dp),
        )
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.primaryContainer)
            .padding(horizontal = 16.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.End,
    ) {
        val username = state.session
        if (username != null) {
            Text(
                text = username,
                modifier = Modifier.weight(1f).automationId(TestTags.LOGGED_USER),
                fontWeight = FontWeight.SemiBold,
            )
            TextButton(onClick = { state.signOut() }, modifier = Modifier.testTag(TestTags.LOGOUT_BUTTON)) {
                Text("Sign out")
            }
        } else {
            TextButton(
                onClick = { state.navigate(com.foodmarketplace.app.state.Screen.Login()) },
                modifier = Modifier.testTag(TestTags.LOGIN_LINK),
            ) {
                Text("Sign in")
            }
        }
    }
}

@Composable
fun MessageBox(message: Message?) {
    if (message == null) return
    val background = if (message.isError) Color(0xFFFDECEA) else Color(0xFFE7F5EA)
    val foreground = if (message.isError) Color(0xFF8A1C12) else Color(0xFF1B5E20)
    Text(
        text = message.text,
        color = foreground,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .background(background, RoundedCornerShape(8.dp))
            .padding(12.dp)
            .automationId(TestTags.MESSAGE),
    )
}

@Composable
fun PageHeader(title: String, subtitle: String? = null) {
    Column(modifier = Modifier.padding(bottom = 12.dp)) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.automationId(TestTags.PAGE_TITLE),
        )
        if (subtitle != null) {
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.automationId(TestTags.PAGE_SUBTITLE),
            )
        }
    }
}

@Composable
fun PrimaryButton(text: String, tag: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Button(onClick = onClick, modifier = modifier.testTag(tag)) { Text(text) }
}

@Composable
fun SecondaryButton(text: String, tag: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    OutlinedButton(onClick = onClick, modifier = modifier.testTag(tag)) { Text(text) }
}

/** Company switch warning. Back button / tap outside closes it, which counts as "No". */
@Composable
fun ConfirmDialog(state: AppState) {
    val confirmation = state.confirmation ?: return
    AlertDialog(
        onDismissRequest = { state.answerConfirmation(false) },
        modifier = Modifier.exposeTestTags().testTag(TestTags.CONFIRM_DIALOG),
        title = { Text("Switch company?", modifier = Modifier.automationId(TestTags.CONFIRM_TITLE)) },
        text = { Text(confirmation.text, modifier = Modifier.automationId(TestTags.CONFIRM_TEXT)) },
        dismissButton = {
            TextButton(onClick = { state.answerConfirmation(false) }, modifier = Modifier.testTag(TestTags.CONFIRM_NO)) {
                Text("No")
            }
        },
        confirmButton = {
            Button(onClick = { state.answerConfirmation(true) }, modifier = Modifier.testTag(TestTags.CONFIRM_YES)) {
                Text("Yes")
            }
        },
    )
}
