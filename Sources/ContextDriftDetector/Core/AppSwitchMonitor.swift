import AppKit
import Combine
import Foundation

@MainActor
final class AppSwitchMonitor: ObservableObject {
    @Published private(set) var activeApp: TrackedApp?

    private var observer: NSObjectProtocol?

    func start() {
        if observer != nil {
            return
        }

        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                let bundleID = app.bundleIdentifier,
                let appName = app.localizedName
            else {
                return
            }

            let newApp = TrackedApp(bundleID: bundleID, localizedName: appName)
            // Avoid publishing duplicate events for the same app.
            if self?.activeApp?.bundleID != newApp.bundleID {
                self?.activeApp = newApp
            }
        }
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
}
