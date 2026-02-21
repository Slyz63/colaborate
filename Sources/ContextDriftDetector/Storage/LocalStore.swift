import Foundation

struct LocalStore {
    private let directoryURL: URL

    init(fileManager: FileManager = .default, storageDirectoryURL: URL? = nil) {
        if let storageDirectoryURL {
            directoryURL = storageDirectoryURL
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.homeDirectoryForCurrentUser
            directoryURL = base.appendingPathComponent("ContextDriftDetector", isDirectory: true)
        }

        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func saveSummary(_ summary: DailySummary, for date: Date) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(summary) else {
            return
        }
        try? data.write(to: summaryURL(for: date), options: .atomic)
    }

    func loadSummary(for date: Date) -> DailySummary {
        let url = summaryURL(for: date)
        guard let data = try? Data(contentsOf: url) else {
            return DailySummary()
        }
        let decoder = JSONDecoder()
        return (try? decoder.decode(DailySummary.self, from: data)) ?? DailySummary()
    }

    private func summaryURL(for date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "summary-\(formatter.string(from: date)).json"
        return directoryURL.appendingPathComponent(filename)
    }
}
