import SwiftUI
import UIKit
import ComposeApp

/// Hosts the shared Compose Multiplatform UI (composeApp/src/commonMain).
struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        MainViewControllerKt.MainViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
