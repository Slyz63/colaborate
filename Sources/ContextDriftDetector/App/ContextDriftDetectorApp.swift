import SwiftUI
import AppKit

@main
struct ContextDriftDetectorApp: App {
    @StateObject private var coordinator = DriftCoordinator()

    init() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup("Context Drift Detector") {
            DashboardView(coordinator: coordinator)
                .frame(minWidth: 700, minHeight: 480)
        }
        .windowResizability(.contentSize)
    }
}
