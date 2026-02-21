import Foundation

struct DriftHeuristic {
    var thresholdSwitches: Int = 5
    var thresholdWindow: TimeInterval = 90

    private(set) var switchTimestamps: [Date] = []

    mutating func recordSwitch(from anchor: TrackedApp, to destination: TrackedApp, at date: Date) -> Bool {
        // Don't count switches back to the anchor app.
        guard anchor.bundleID != destination.bundleID else {
            reset()
            return false
        }

        switchTimestamps.append(date)
        prune(now: date)
        return switchTimestamps.count >= thresholdSwitches
    }

    mutating func reset() {
        switchTimestamps.removeAll(keepingCapacity: true)
    }

    mutating func prune(now: Date) {
        let lowerBound = now.addingTimeInterval(-thresholdWindow)
        switchTimestamps.removeAll { $0 < lowerBound }
    }
}
