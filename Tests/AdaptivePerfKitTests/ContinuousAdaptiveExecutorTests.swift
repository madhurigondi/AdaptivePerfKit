
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class ContinuousAdaptiveExecutorTests: XCTestCase {

    private actor ConcurrencyTracker {
        private var active = 0
        private var peak = 0

        func begin() {
            active += 1
            peak = max(peak, active)
        }

        func end() {
            active -= 1
        }

        func maximum() -> Int {
            peak
        }

        func remaining() -> Int {
            active
        }
    }

    private enum TestError: Error {
        case expectedFailure
    }

    private func configuration(
        initial: Int = 2,
        windowSize: Int = 10
    ) throws -> AdaptiveConcurrencyConfiguration {

        try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: 1,
            maximumConcurrency: 8,
            initialConcurrency: initial,
            measurementWindowSize: windowSize,
            improvementThreshold: 0.05,
            maximumLatencyMilliseconds: 1000
        )
    }

    func testEmptyInputs() async throws {
        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration()
        )

        let result = try await executor.execute(
            inputs: [Int]()
        ) { @Sendable value in
            value
        }

        XCTAssertTrue(result.results.isEmpty)
        XCTAssertTrue(result.adjustments.isEmpty)
        XCTAssertTrue(result.feedbackHistory.isEmpty)
    }

    func testPreservesOriginalInputOrder() async throws {
        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration()
        )

        let inputs = Array(0..<40)

        let result = try await executor.execute(
            inputs: inputs
        ) { @Sendable value in
            let delay = UInt64((40 - value) % 7 + 1)
                * 1_000_000

            try await Task.sleep(nanoseconds: delay)
            return value * 2
        }

        XCTAssertEqual(
            result.results,
            inputs.map { $0 * 2 }
        )
    }

    func testRespectsMaximumConcurrency() async throws {
        let tracker = ConcurrencyTracker()

        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration(
                initial: 4
            )
        )

        let result = try await executor.execute(
            inputs: Array(0..<100)
        ) { @Sendable value in
            await tracker.begin()

            try await Task.sleep(
                nanoseconds: 2_000_000
            )

            await tracker.end()
            return value
        }

        XCTAssertEqual(result.results.count, 100)

        let peak = await tracker.maximum()
        let remaining = await tracker.remaining()

        XCTAssertLessThanOrEqual(peak, 8)
        XCTAssertEqual(remaining, 0)
    }

    func testFeedbackWindowCounts() async throws {
        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration(
                windowSize: 10
            )
        )

        let result = try await executor.execute(
            inputs: Array(0..<100)
        ) { @Sendable value in
            try await Task.sleep(
                nanoseconds: 1_000_000
            )
            return value
        }

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

        for feedback in result.feedbackHistory {
            XCTAssertEqual(
                feedback.completedTaskCount,
                10
            )
            XCTAssertGreaterThan(
                feedback.elapsedMilliseconds,
                0
            )
            XCTAssertGreaterThan(
                feedback.throughput,
                0
            )
        }
    }

    func testFinalPartialWindow() async throws {
        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration(
                windowSize: 10
            )
        )

        let result = try await executor.execute(
            inputs: Array(0..<25)
        ) { @Sendable value in
            value
        }

        XCTAssertEqual(
            result.feedbackHistory.map {
                $0.completedTaskCount
            },
            [10, 10, 5]
        )

        XCTAssertEqual(result.adjustments.count, 3)
        XCTAssertEqual(result.results.count, 25)
    }

    func testPropagatesOperationFailure() async throws {
        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration()
        )

        do {
            _ = try await executor.execute(
                inputs: Array(0..<30)
            ) { @Sendable value in
                if value == 5 {
                    throw TestError.expectedFailure
                }
                return value
            }

            XCTFail("Expected operation failure")
        } catch TestError.expectedFailure {
            // Expected.
        }
    }

    func testCancellation() async throws {
        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration()
        )

        let task = Task {
            try await executor.execute(
                inputs: Array(0..<1000)
            ) { @Sendable value in
                try await Task.sleep(
                    nanoseconds: 50_000_000
                )
                return value
            }
        }

        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        }
    }

    func testFreshControllerForEachExecution() async throws {
        let executor = ContinuousAdaptiveExecutor(
            configuration: try configuration()
        )

        for _ in 0..<2 {
            let result = try await executor.execute(
                inputs: Array(0..<20)
            ) { @Sendable value in
                value
            }

            XCTAssertEqual(
                result.feedbackHistory.first?
                    .concurrencyLimit,
                2
            )
        }
    }
}
