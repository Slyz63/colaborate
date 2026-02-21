import AppKit
import Foundation

struct AppRestorer {
    @discardableResult
    func restore(_ app: TrackedApp) -> Bool {
        // If app is running, just activate it.
        if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleID).first {
            return runningApp.activate(options: [.activateIgnoringOtherApps])
        }

        // If app is not running, launch it by its bundle ID.
        let didLaunch = NSWorkspace.shared.launchApplication(
            withBundleIdentifier: app.bundleID,
            options: [.async],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
        
        return didLaunch
    }
}
