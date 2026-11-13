
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class V3DiagnosticValidationTests: XCTestCase {

    private actor ActiveTaskTracker {
        private var active = 0
        private var maximum = 0

        func begin() {
            active += 1
            maximum = max(maximum, active)
        }

        func end() {
            active -= 1
        }

        func peak() -> Int { maximum }
        func remaining() -> Int { active }
    }

    private func configuration() throws
        -> AdaptiveConcurrencyConfiguration {

        try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: 1,
            maximumConcurrency: 8,
            initialConcurrency: 2,
            measurementWindowSize: 10,
            improvementThreshold: 0.05,
            maximumLatencyMilliseconds: 1000
        )
    }

    func testV3DiagnosticIntegrity() async throws {

        let tracker = ActiveTaskTracker()

        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration()
        )

        let inputs = Array(0..<100)

        let result = try await executor.execute(
            inputs: inputs
        ) { @Sendable input in

            await tracker.begin()

            // Use nonthrowing sleep so task accounting
            // remains balanced.
            try? await Task.sleep(
                nanoseconds: 2_000_000
            )

            await tracker.end()

            return input * 2
        }

        XCTAssertEqual(
            result.results,
            inputs.map { $0 * 2 }
        )

        XCTAssertEqual(
            result.feedbackHistory.count,
            10
        )

        XCTAssertEqual(
            result.adjustments.count,
            10
        )

        let completed = result.feedbackHistory.reduce(0) {
            $0 + $1.completedTaskCount
        }

        XCTAssertEqual(completed, 100)

        for index in result.feedbackHistory.indices {

            let feedback = result.feedbackHistory[index]
            let adjustment = result.adjustments[index]

            XCTAssertEqual(
                feedback.completedTaskCount,
                10
            )

            XCTAssertTrue(
                feedback.elapsedMilliseconds.isFinite
            )

            XCTAssertGreaterThan(
                feedback.elapsedMilliseconds,
                0
            )

            XCTAssertTrue(
                feedback.meanLatencyMilliseconds.isFinite
            )

            XCTAssertGreaterThanOrEqual(
                feedback.meanLatencyMilliseconds,
                0
            )

            XCTAssertGreaterThanOrEqual(
                feedback.concurrencyLimit,
                1
            )

            XCTAssertLessThanOrEqual(
                feedback.concurrencyLimit,
                8
            )

            XCTAssertEqual(
                adjustment.previousConcurrency,
                feedback.concurrencyLimit
            )

            XCTAssertGreaterThanOrEqual(
                adjustment.newConcurrency,
                1
            )

            XCTAssertLessThanOrEqual(
                adjustment.newConcurrency,
                8
            )
        }

        let peak = await tracker.peak()
        let remaining = await tracker.remaining()

        XCTAssertLessThanOrEqual(peak, 8)
        XCTAssertEqual(remaining, 0)

        print("V3 diagnostic integrity: PASS")
        print("Completed tasks: \(completed)")
        print("Feedback windows: \(result.feedbackHistory.count)")
        print("Peak concurrency: \(peak)")
    }
}
