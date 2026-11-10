package com.foodmarketplace.app

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.foodmarketplace.app.platform.exposeTestTags
import com.foodmarketplace.app.state.AppState
import com.foodmarketplace.app.state.Screen
import com.foodmarketplace.app.ui.components.ConfirmDialog
import com.foodmarketplace.app.ui.components.Header
import com.foodmarketplace.app.ui.components.MessageBox
import com.foodmarketplace.app.ui.screens.CartScreen
import com.foodmarketplace.app.ui.screens.CompanyScreen
import com.foodmarketplace.app.ui.screens.HomeScreen
import com.foodmarketplace.app.ui.screens.LoginScreen
import com.foodmarketplace.app.ui.screens.NotFoundScreen

private val colors = lightColorScheme(
    primary = Color(0xFFB23A1E),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFFFE3D9),
    secondary = Color(0xFF5C4033),
)

/** Root of the Food Marketplace app, shared by Android and iOS. */
@Composable
fun App(state: AppState) {
    MaterialTheme(colorScheme = colors) {
        Surface(modifier = Modifier.fillMaxSize().exposeTestTags()) {
            Column(modifier = Modifier.fillMaxSize().safeDrawingPadding()) {
                Header(state)
                MessageBox(state.message)
                val screen = state.current
                key(screen) {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .verticalScroll(rememberScrollState())
                            .padding(16.dp),
                    ) {
                        when (screen) {
                            is Screen.Home -> HomeScreen(state, screen)
                            is Screen.CompanyDetail -> CompanyScreen(state, screen)
                            is Screen.Login -> LoginScreen(state, screen)
                            is Screen.Cart -> CartScreen(state, screen)
                            is Screen.NotFound -> NotFoundScreen(state, screen.title)
                        }
                    }
                }
            }
            ConfirmDialog(state)
        }
    }
}
