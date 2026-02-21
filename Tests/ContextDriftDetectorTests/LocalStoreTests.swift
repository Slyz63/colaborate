import Foundation
import XCTest
@testable import ContextDriftDetector

final class LocalStoreTests: XCTestCase {
    private var fileManager: FileManager!
    private var tempRoot: URL!
    private var storageDirectory: URL!
    private var store: LocalStore!

    override func setUp() {
        super.setUp()
        fileManager = .default
        tempRoot = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        storageDirectory = tempRoot.appendingPathComponent("ContextDriftDetector", isDirectory: true)
        store = LocalStore(fileManager: fileManager, storageDirectoryURL: storageDirectory)
    }

    override func tearDown() {
        try? fileManager.removeItem(at: tempRoot)
        super.tearDown()
    }

    func testSaveAndLoadRoundTrip() {
        let date = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-06
        let summary = DailySummary(driftPromptCount: 7, recoveredCount: 4, loggedForLaterCount: 2)

        store.saveSummary(summary, for: date)
        let loaded = store.loadSummary(for: date)

        XCTAssertEqual(loaded, summary)
    }

    func testLoadMissingDateReturnsDefaultSummary() {
        let date = Date(timeIntervalSince1970: 1_704_153_600) // 2024-01-07

        let loaded = store.loadSummary(for: date)

        XCTAssertEqual(loaded, DailySummary())
    }

    func testDifferentDatesCreateDifferentFiles() throws {
        let date1 = Date(timeIntervalSince1970: 1_704_240_000) // 2024-01-08
        let date2 = Date(timeIntervalSince1970: 1_704_326_400) // 2024-01-09

        store.saveSummary(DailySummary(driftPromptCount: 1, recoveredCount: 0, loggedForLaterCount: 0), for: date1)
        store.saveSummary(DailySummary(driftPromptCount: 2, recoveredCount: 0, loggedForLaterCount: 0), for: date2)

        let files = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 2)
    }

    func testSavedJSONUsesStableSortedKeys() throws {
        let date = Date(timeIntervalSince1970: 1_704_412_800) // 2024-01-10
        let summary = DailySummary(driftPromptCount: 3, recoveredCount: 2, loggedForLaterCount: 1)
        store.saveSummary(summary, for: date)

        let files = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1)

        let json = try String(contentsOf: files[0], encoding: .utf8)
        let driftIndex = try XCTUnwrap(json.range(of: "\"driftPromptCount\"")?.lowerBound)
        let loggedIndex = try XCTUnwrap(json.range(of: "\"loggedForLaterCount\"")?.lowerBound)
        let recoveredIndex = try XCTUnwrap(json.range(of: "\"recoveredCount\"")?.lowerBound)

        XCTAssertLessThan(driftIndex, loggedIndex)
        XCTAssertLessThan(loggedIndex, recoveredIndex)
    }
}
