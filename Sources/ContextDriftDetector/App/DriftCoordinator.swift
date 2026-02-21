import AppKit
import Combine
import Foundation

@MainActor
final class DriftCoordinator: ObservableObject {
    @Published private(set) var anchorText = ""
    @Published private(set) var anchorAppName = "-"
    @Published private(set) var availableAnchorApps: [TrackedApp] = []
    @Published var selectedAnchorBundleID = ""
    @Published var currentAppName = "-"
    @Published var currentAppBundleID = ""
    @Published var isDriftPromptPresented = false
    @Published var intentionalBreakUntil: Date?
    @Published var statusMessage = "戻る先アプリを選んで、フォーカス開始してください。"
    @Published var summary = DailySummary()

    private let monitor: AppSwitchMonitor
    private var heuristic: DriftHeuristic
    private let store: LocalStore
    private let restorer: AppRestorer
    private let thisAppBundleID = Bundle.main.bundleIdentifier ?? "ContextDriftDetector"
    private var cancellables = Set<AnyCancellable>()
    private var anchorApp: TrackedApp?

    init(
        monitor: AppSwitchMonitor? = nil,
        heuristic: DriftHeuristic = DriftHeuristic(),
        store: LocalStore = LocalStore(),
        restorer: AppRestorer = AppRestorer()
    ) {
        self.monitor = monitor ?? AppSwitchMonitor()
        self.heuristic = heuristic
        self.store = store
        self.restorer = restorer
        summary = store.loadSummary(for: Date())
        refreshAvailableAnchorApps()

        self.monitor.$activeApp
            .compactMap { $0 }
            // Receiving rapid-fire duplicate events can cause issues.
            .removeDuplicates()
            .sink { [weak self] app in
                self?.handleAppChange(app)
            }
            .store(in: &cancellables)

        self.monitor.start()
    }

    func startAnchor(_ text: String, preferredBundleID: String? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        anchorText = trimmed
        heuristic.reset()
        isDriftPromptPresented = false
        intentionalBreakUntil = nil
        refreshAvailableAnchorApps()

        let requestedBundleID = preferredBundleID ?? selectedAnchorBundleID
        if let app = availableAnchorApps.first(where: { $0.bundleID == requestedBundleID }) {
            setAnchorApp(app)
            statusMessage = "アンカーを \(app.localizedName) に設定しました。"
            return
        }

        if let active = monitor.activeApp, active.bundleID != thisAppBundleID {
            setAnchorApp(active)
            statusMessage = "アンカーを \(active.localizedName) に設定しました。"
            return
        }

        setAnchorApp(nil)
        statusMessage = "戻る先アプリを選択してください。"
    }

    func resumeAnchor() {
        isDriftPromptPresented = false
        guard let anchorApp else {
            statusMessage = "戻る先アンカーが未設定です。先にフォーカス開始して作業アプリへ切り替えてください。"
            return
        }

        if restorer.restore(anchorApp) {
            summary.recoveredCount += 1
            persistSummary()
            statusMessage = "\(anchorApp.localizedName) へ戻る操作を実行しました（未起動なら起動します）。"
        } else {
            statusMessage = "\(anchorApp.localizedName) を起動/前面化できませんでした。"
        }
    }

    func snoozeDrift(minutes: Int = 15) {
        intentionalBreakUntil = Calendar.current.date(byAdding: .minute, value: minutes, to: Date())
        heuristic.reset()
        isDriftPromptPresented = false
        statusMessage = "\(minutes)分間は再通知を止めます。"
    }

    func logForLater() {
        summary.loggedForLaterCount += 1
        persistSummary()
        isDriftPromptPresented = false
        statusMessage = "後で対応に記録しました。"
    }

    func clearSummary() {
        summary = DailySummary()
        persistSummary()
    }

    func triggerDriftPromptForTesting() {
        if anchorApp == nil {
            if let app = availableAnchorApps.first(where: { $0.bundleID == selectedAnchorBundleID }) {
                setAnchorApp(app)
            } else if let active = monitor.activeApp, active.bundleID != thisAppBundleID {
                setAnchorApp(active)
            }
        }
        summary.driftPromptCount += 1
        persistSummary()
        isDriftPromptPresented = true
        statusMessage = "テスト表示中: 「タスクに戻る」でアンカーへ戻ります。"
    }

    func refreshAvailableAnchorApps() {
        let apps = NSWorkspace.shared.runningApplications.compactMap { app -> TrackedApp? in
            guard
                app.activationPolicy == .regular,
                let bundleID = app.bundleIdentifier,
                let name = app.localizedName,
                bundleID != thisAppBundleID
            else {
                return nil
            }
            return TrackedApp(bundleID: bundleID, localizedName: name)
        }

        let unique = Dictionary(grouping: apps, by: \.bundleID).compactMap { $0.value.first }
        availableAnchorApps = unique.sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }

        if let selected = availableAnchorApps.first(where: { $0.bundleID == selectedAnchorBundleID }) {
            selectedAnchorBundleID = selected.bundleID
        } else {
            selectedAnchorBundleID = availableAnchorApps.first?.bundleID ?? ""
        }
    }

    private func handleAppChange(_ app: TrackedApp) {
        currentAppName = app.localizedName
        currentAppBundleID = app.bundleID
        refreshAvailableAnchorApps()

        // Do not detect drift until an anchor is set.
        guard let anchorApp else { return }

        // If we returned to the anchor app, the "intentional break" is over.
        if app.bundleID == anchorApp.bundleID {
            intentionalBreakUntil = nil
            heuristic.reset()
            statusMessage = "アンカーアプリ (\(anchorApp.localizedName)) に戻っています。"
            return
        }

        if let until = intentionalBreakUntil, until > Date() {
            return
        }

        if heuristic.recordSwitch(from: anchorApp, to: app, at: Date()) {
            summary.driftPromptCount += 1
            persistSummary()
            isDriftPromptPresented = true
            statusMessage = "脱線を検知しました。戻るかどうか選んでください。"
        }
    }

    private func setAnchorApp(_ app: TrackedApp?) {
        anchorApp = app
        anchorAppName = app?.localizedName ?? "-"
        if let app {
            selectedAnchorBundleID = app.bundleID
        }
    }

    private func persistSummary() {
        store.saveSummary(summary, for: Date())
    }
}
