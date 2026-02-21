import AppKit
import Foundation

struct AppRestorer {
    @discardableResult
    func restore(_ app: TrackedApp) -> Bool {
        if activateRunningApp(bundleID: app.bundleID) {
            return true
        }

        if launchViaWorkspace(bundleID: app.bundleID) {
            // Try one more foreground activation after launch.
            _ = activateRunningApp(bundleID: app.bundleID)
            return true
        }

        // Last resort: shell open command often brings existing app to front.
        return launchViaOpenCommand(bundleID: app.bundleID)
    }

    private func activateRunningApp(bundleID: String) -> Bool {
        for runningApp in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID) {
            runningApp.unhide()
            if runningApp.activate(options: [.activateIgnoringOtherApps, .activateAllWindows]) {
                return true
            }
        }
        return false
    }

    private func launchViaWorkspace(bundleID: String) -> Bool {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return false
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.createsNewApplicationInstance = false
        config.addsToRecentItems = false

        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
            if let error {
                NSLog("Failed to open app %@: %@", bundleID, error.localizedDescription)
            } else {
                success = true
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 2.0)
        return success
    }

    private func launchViaOpenCommand(bundleID: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-b", bundleID]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            NSLog("Failed to run open command for %@: %@", bundleID, error.localizedDescription)
            return false
        }
    }
}
