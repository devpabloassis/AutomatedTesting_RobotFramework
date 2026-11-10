package com.foodmarketplace.app

import androidx.compose.ui.window.ComposeUIViewController
import com.foodmarketplace.app.platform.UserDefaultsStore
import com.foodmarketplace.app.platform.createHttpClient
import com.foodmarketplace.app.state.AppState
import platform.UIKit.UIViewController

private val appState by lazy { AppState(UserDefaultsStore(), createHttpClient()) }

/** Entry point used by the SwiftUI app (iosApp/iosApp/ContentView.swift). */
fun MainViewController(): UIViewController = ComposeUIViewController { App(appState) }

/** Called by the SwiftUI app from `onOpenURL`, with links in the `foodmarket://open/...` format. */
fun handleDeepLink(url: String) = appState.handleDeepLink(url)
