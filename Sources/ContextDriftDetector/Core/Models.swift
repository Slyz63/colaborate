import Foundation

struct TrackedApp: Equatable, Hashable, Identifiable {
    var id: String { bundleID }
    let bundleID: String
    let localizedName: String
}

struct DailySummary: Codable, Equatable {
    var driftPromptCount = 0
    var recoveredCount = 0
    var loggedForLaterCount = 0
}
