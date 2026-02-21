import SwiftUI

@main
struct ContextDriftDetectorApp: App {
    @StateObject private var coordinator = DriftCoordinator()

    var body: some Scene {
        WindowGroup("Context Drift Detector") {
            DashboardView(coordinator: coordinator)
                .frame(minWidth: 700, minHeight: 480)
        }
        .windowResizability(.contentSize)
    }
}
