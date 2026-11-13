
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class AdaptiveExecutorTests: XCTestCase {

    private actor TaskTracker {
        private var active = 0
        private var maximumActive = 0

        func started() {
            active += 1
            maximumActive = max(maximumActive, active)
        }

        func finished() {
            active -= 1
        }

        func maximum() -> Int {
            maximumActive
        }

        func current() -> Int {
            active
        }
    }

    private enum TestError: Error {
        case expected
    }

    private func configuration(
        minimum: Int = 1,
        maximum: Int = 4,
        initial: Int = 2,
        window: Int = 5
    ) throws -> AdaptiveConcurrencyConfiguration {
        try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: minimum,
            maximumConcurrency: maximum,
            initialConcurrency: initial,
            measurementWindowSize: window,
            improvementThreshold: 0.05,
            maximumLatencyMilliseconds: 1000
        )
    }

    // MARK: - Empty Workloads

    func testEmptyInputs() async throws {
        let executor = AdaptiveExecutor(
            configuration: try configuration()
        )

        let result = try await executor.execute(
            inputs: [Int]()
        ) { value in
            value * 2
        }

        XCTAssertTrue(result.results.isEmpty)
        XCTAssertTrue(result.adjustments.isEmpty)
        XCTAssertTrue(result.feedbackHistory.isEmpty)
    }

    // MARK: - Result Correctness

    func testResultsPreserveInputOrder() async throws {
        let executor = AdaptiveExecutor(
            configuration: try configuration()
        )

        let inputs = Array(1...20)

        let result = try await executor.execute(
            inputs: inputs
        ) { value in
            try await Task.sleep(
                nanoseconds: UInt64(21 - value) * 1_000_000
            )
            return value * 2
        }

        XCTAssertEqual(
            result.results,
            inputs.map { $0 * 2 }
        )
    }

    // MARK: - Measurement Windows

    func testFeedbackWindowCount() async throws {
        let executor = AdaptiveExecutor(
            configuration: try configuration(window: 5)
        )

        let result = try await executor.execute(
            inputs: Array(1...20)
        ) { value in
            value
        }

        XCTAssertEqual(result.feedbackHistory.count, 4)
        XCTAssertEqual(result.adjustments.count, 4)

        XCTAssertEqual(
            result.feedbackHistory.map(\.completedTaskCount),
            [5, 5, 5, 5]
        )
    }

    func testPartialFinalWindow() async throws {
        let executor = AdaptiveExecutor(
            configuration: try configuration(window: 5)
        )

        let result = try await executor.execute(
            inputs: Array(1...12)
        ) { value in
            value
        }

        XCTAssertEqual(
            result.feedbackHistory.map(\.completedTaskCount),
            [5, 5, 2]
        )

        XCTAssertEqual(result.results.count, 12)
    }

    // MARK: - Adaptive Decisions

    func testInitialExploration() async throws {
        let executor = AdaptiveExecutor(
            configuration: try configuration(window: 5)
        )

        let result = try await executor.execute(
            inputs: Array(1...10)
        ) { value in
            value
        }

        XCTAssertEqual(result.adjustments.count, 2)

        XCTAssertEqual(
            result.adjustments[0].decision,
            .initialExploration
        )

        XCTAssertEqual(
            result.adjustments[0].previousConcurrency,
            2
        )

        XCTAssertEqual(
            result.adjustments[0].newConcurrency,
            3
        )

        XCTAssertEqual(
            result.feedbackHistory[1].concurrencyLimit,
            3
        )
    }

    // MARK: - Concurrency Limits

    func testMaximumConcurrencyIsRespected() async throws {
        let maximum = 3
        let tracker = TaskTracker()

        let executor = AdaptiveExecutor(
            configuration: try configuration(
                minimum: 1,
                maximum: maximum,
                initial: 2,
                window: 6
            )
        )

        let result = try await executor.execute(
            inputs: Array(1...24)
        ) { value in

            await tracker.started()

            try await Task.sleep(
                nanoseconds: 5_000_000
            )

            await tracker.finished()

            return value
        }

        let observed = await tracker.maximum()

        XCTAssertLessThanOrEqual(observed, maximum)
        XCTAssertEqual(result.results.count, 24)

        for feedback in result.feedbackHistory {
            XCTAssertLessThanOrEqual(
                feedback.concurrencyLimit,
                maximum
            )
        }
    }

    // MARK: - Error Propagation

    func testOperationErrorPropagates() async throws {
        let executor = AdaptiveExecutor(
            configuration: try configuration()
        )

        do {
            _ = try await executor.execute(
                inputs: Array(1...10)
            ) { value in

                if value == 3 {
                    throw TestError.expected
                }

                return value
            }

            XCTFail("Expected an error")

        } catch TestError.expected {
            // Expected failure propagated correctly.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Cancellation

    func testPreCancelledExecutionThrows() async throws {
        let executor = AdaptiveExecutor(
            configuration: try configuration()
        )

        let task = Task {
            withUnsafeCurrentTask { current in
                current?.cancel()
            }

            return try await executor.execute(
                inputs: Array(1...10)
            ) { value in
                try Task.checkCancellation()
                return value
            }
        }

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
