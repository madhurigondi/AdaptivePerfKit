
import XCTest
@testable import AdaptivePerfKit

final class AdaptiveWindowDiagnosticTests: XCTestCase {

    private func makeConfiguration(
        windowSize: Int = 5
    ) throws -> AdaptiveConcurrencyConfiguration {
        try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: 1,
            maximumConcurrency: 4,
            initialConcurrency: 2,
            measurementWindowSize: windowSize,
            improvementThreshold: 0.05,
            maximumLatencyMilliseconds: 1000
        )
    }

    func testDiagnosticRecordCount() async throws {
        let executor = AdaptiveExecutor(
            configuration: try makeConfiguration()
        )

        let result = try await executor.execute(
            inputs: Array(1...12)
        ) { input in
            input * 2
        }

        XCTAssertEqual(result.windowDiagnostics.count, 3)
        XCTAssertEqual(result.feedbackHistory.count, 3)
        XCTAssertEqual(result.adjustments.count, 3)
    }

    func testWindowTaskCounts() async throws {
        let executor = AdaptiveExecutor(
            configuration: try makeConfiguration()
        )

        let result = try await executor.execute(
            inputs: Array(1...12)
        ) { input in
            input
        }

        XCTAssertEqual(
            result.windowDiagnostics.map(\.completedTaskCount),
            [5, 5, 2]
        )

        XCTAssertEqual(
            result.windowDiagnostics.map(\.windowNumber),
            [1, 2, 3]
        )
    }

    func testConcurrencyWithinBounds() async throws {
        let executor = AdaptiveExecutor(
            configuration: try makeConfiguration()
        )

        let result = try await executor.execute(
            inputs: Array(1...30)
        ) { input in
            input
        }

        for diagnostic in result.windowDiagnostics {
            XCTAssertTrue((1...4).contains(
                diagnostic.concurrencyLimit
            ))

            XCTAssertTrue((1...4).contains(
                diagnostic.nextConcurrencyLimit
            ))
        }
    }

    func testDiagnosticsMatchFeedback() async throws {
        let executor = AdaptiveExecutor(
            configuration: try makeConfiguration()
        )

        let result = try await executor.execute(
            inputs: Array(1...15)
        ) { input in
            input
        }

        for (diagnostic, feedback) in zip(
            result.windowDiagnostics,
            result.feedbackHistory
        ) {
            XCTAssertEqual(
                diagnostic.concurrencyLimit,
                feedback.concurrencyLimit
            )

            XCTAssertEqual(
                diagnostic.completedTaskCount,
                feedback.completedTaskCount
            )

            XCTAssertEqual(
                diagnostic.throughput,
                feedback.throughput,
                accuracy: 0.000001
            )

            XCTAssertEqual(
                diagnostic.meanLatencyMilliseconds,
                feedback.meanLatencyMilliseconds,
                accuracy: 0.000001
            )
        }
    }

    func testDiagnosticsMatchAdjustments() async throws {
        let executor = AdaptiveExecutor(
            configuration: try makeConfiguration()
        )

        let result = try await executor.execute(
            inputs: Array(1...15)
        ) { input in
            input
        }

        for (diagnostic, adjustment) in zip(
            result.windowDiagnostics,
            result.adjustments
        ) {
            XCTAssertEqual(
                diagnostic.concurrencyLimit,
                adjustment.previousConcurrency
            )

            XCTAssertEqual(
                diagnostic.nextConcurrencyLimit,
                adjustment.newConcurrency
            )

            XCTAssertEqual(
                diagnostic.decision,
                adjustment.decision
            )
        }
    }

    func testMeasurementsAreValid() async throws {
        let executor = AdaptiveExecutor(
            configuration: try makeConfiguration()
        )

        let result = try await executor.execute(
            inputs: Array(1...10)
        ) { input in
            input
        }

        for diagnostic in result.windowDiagnostics {
            XCTAssertTrue(diagnostic.elapsedMilliseconds.isFinite)
            XCTAssertGreaterThanOrEqual(
                diagnostic.elapsedMilliseconds, 0
            )

            XCTAssertTrue(diagnostic.throughput.isFinite)
            XCTAssertGreaterThanOrEqual(
                diagnostic.throughput, 0
            )

            XCTAssertTrue(
                diagnostic.meanLatencyMilliseconds.isFinite
            )
        }
    }

    func testEmptyInputsProduceNoDiagnostics() async throws {
        let executor = AdaptiveExecutor(
            configuration: try makeConfiguration()
        )

        let result = try await executor.execute(
            inputs: [Int]()
        ) { input in
            input
        }

        XCTAssertTrue(result.results.isEmpty)
        XCTAssertTrue(result.windowDiagnostics.isEmpty)
        XCTAssertTrue(result.feedbackHistory.isEmpty)
        XCTAssertTrue(result.adjustments.isEmpty)
    }

    func testResultsPreserveInputOrder() async throws {
        let executor = AdaptiveExecutor(
            configuration: try makeConfiguration()
        )

        let inputs = Array(1...20)

        let result = try await executor.execute(
            inputs: inputs
        ) { input in
            input * input
        }

        XCTAssertEqual(
            result.results,
            inputs.map { $0 * $0 }
        )
    }
}
