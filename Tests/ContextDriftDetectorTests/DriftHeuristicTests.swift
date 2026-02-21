import Foundation
import XCTest
@testable import ContextDriftDetector

final class DriftHeuristicTests: XCTestCase {
    private let anchor = TrackedApp(bundleID: "com.example.anchor", localizedName: "Anchor")
    private let appA = TrackedApp(bundleID: "com.example.a", localizedName: "AppA")
    private let appB = TrackedApp(bundleID: "com.example.b", localizedName: "AppB")

    func testDetectsDriftWhenThresholdReached() {
        var heuristic = DriftHeuristic(thresholdSwitches: 3, thresholdWindow: 10)
        let base = Date(timeIntervalSince1970: 1_000)

        XCTAssertFalse(heuristic.recordSwitch(from: anchor, to: appA, at: base))
        XCTAssertFalse(heuristic.recordSwitch(from: anchor, to: appB, at: base.addingTimeInterval(1)))
        XCTAssertTrue(heuristic.recordSwitch(from: anchor, to: appA, at: base.addingTimeInterval(2)))
    }

    func testPrunesOldSwitches() {
        var heuristic = DriftHeuristic(thresholdSwitches: 3, thresholdWindow: 10)
        let base = Date(timeIntervalSince1970: 1_000)

        _ = heuristic.recordSwitch(from: anchor, to: appA, at: base)
        _ = heuristic.recordSwitch(from: anchor, to: appB, at: base.addingTimeInterval(5))
        XCTAssertFalse(heuristic.recordSwitch(from: anchor, to: appA, at: base.addingTimeInterval(20)))
        XCTAssertEqual(heuristic.switchTimestamps.count, 1)
    }

    func testDoesNotDetectDriftBelowThreshold() {
        var heuristic = DriftHeuristic(thresholdSwitches: 5, thresholdWindow: 60)
        let base = Date(timeIntervalSince1970: 1_000_000)

        for i in 0..<4 {
            let destination = i.isMultiple(of: 2) ? appA : appB
            XCTAssertFalse(
                heuristic.recordSwitch(
                    from: anchor,
                    to: destination,
                    at: base.addingTimeInterval(TimeInterval(i * 10))
                )
            )
        }
        XCTAssertEqual(heuristic.switchTimestamps.count, 4)
    }

    func testSwitchAtWindowEdgeIsKept() {
        var heuristic = DriftHeuristic(thresholdSwitches: 2, thresholdWindow: 30)
        let base = Date(timeIntervalSince1970: 1_000_000)

        _ = heuristic.recordSwitch(from: anchor, to: appA, at: base)
        _ = heuristic.recordSwitch(from: anchor, to: appB, at: base.addingTimeInterval(30))
        heuristic.prune(now: base.addingTimeInterval(30))

        XCTAssertEqual(heuristic.switchTimestamps.count, 2)
    }

    func testResetClearsHistory() {
        var heuristic = DriftHeuristic(thresholdSwitches: 3, thresholdWindow: 60)
        let base = Date(timeIntervalSince1970: 1_000_000)

        _ = heuristic.recordSwitch(from: anchor, to: appA, at: base)
        _ = heuristic.recordSwitch(from: anchor, to: appB, at: base.addingTimeInterval(10))
        heuristic.reset()

        XCTAssertTrue(heuristic.switchTimestamps.isEmpty)
        XCTAssertFalse(heuristic.recordSwitch(from: anchor, to: appA, at: base.addingTimeInterval(20)))
    }

    func testSwitchBackToAnchorDoesNotCountAndResets() {
        var heuristic = DriftHeuristic(thresholdSwitches: 2, thresholdWindow: 30)
        let base = Date(timeIntervalSince1970: 1_000_000)

        _ = heuristic.recordSwitch(from: anchor, to: appA, at: base)
        XCTAssertFalse(heuristic.recordSwitch(from: anchor, to: anchor, at: base.addingTimeInterval(5)))
        XCTAssertTrue(heuristic.switchTimestamps.isEmpty)
    }
}
