import AppKit
import Combine
import Foundation

@MainActor
final class DriftCoordinator: ObservableObject {
    @Published var anchorText = ""
    @Published var currentAppName = "-"
    @Published var currentAppBundleID = ""
    @Published var isDriftPromptPresented = false
    @Published var intentionalBreakUntil: Date?
    @Published var summary = DailySummary()

    private let monitor: AppSwitchMonitor
    private let heuristic: DriftHeuristic
    private let store: LocalStore
    private let restorer: AppRestorer
    private var cancellables = Set<AnyCancellable>()
    private var anchorApp: TrackedApp?

    init(
        monitor: AppSwitchMonitor = AppSwitchMonitor(),
        heuristic: DriftHeuristic = DriftHeuristic(),
        store: LocalStore = LocalStore(),
        restorer: AppRestorer = AppRestorer()
    ) {
        self.monitor = monitor
        self.heuristic = heuristic
        self.store = store
        self.restorer = restorer
        summary = store.loadSummary(for: Date())

        monitor.$activeApp
            .compactMap { $0 }
            // Receiving rapid-fire duplicate events can cause issues.
            .removeDuplicates()
            .sink { [weak self] app in
                self?.handleAppChange(app)
            }
            .store(in: &cancellables)

        monitor.start()
    }

    func startAnchor() {
        guard !anchorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        anchorApp = monitor.activeApp
        heuristic.reset()
        isDriftPromptPresented = false
        intentionalBreakUntil = nil
    }

    func resumeAnchor() {
        guard let anchorApp else { return }
        _ = restorer.restore(anchorApp)
        summary.recoveredCount += 1
        persistSummary()
        isDriftPromptPresented = false
    }

    func snoozeDrift(minutes: Int = 15) {
        intentionalBreakUntil = Calendar.current.date(byAdding: .minute, value: minutes, to: Date())
        heuristic.reset()
        isDriftPromptPresented = false
    }

    func logForLater() {
        summary.loggedForLaterCount += 1
        persistSummary()
        isDriftPromptPresented = false
    }

    func clearSummary() {
        summary = DailySummary()
        persistSummary()
    }

    private func handleAppChange(_ app: TrackedApp) {
        currentAppName = app.localizedName
        currentAppBundleID = app.bundleID

        // Do not detect drift until an anchor is set.
        guard let anchorApp else { return }

        // If we returned to the anchor app, the "intentional break" is over.
        if app.bundleID == anchorApp.bundleID {
            intentionalBreakUntil = nil
            heuristic.reset()
            return
        }

        if let until = intentionalBreakUntil, until > Date() {
            return
        }

        if heuristic.recordSwitch(from: anchorApp, to: app, at: Date()) {
            summary.driftPromptCount += 1
            persistSummary()
            isDriftPromptPresented = true
        }
    }

    private func persistSummary() {
        store.saveSummary(summary, for: Date())
    }
}
