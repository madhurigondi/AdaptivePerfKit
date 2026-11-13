
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class FixedConcurrencyExecutorTests: XCTestCase {

    // MARK: - Test Helpers

    actor ConcurrencyTracker {

        private var active = 0
        private var maximumObserved = 0

        func taskStarted() {
            active += 1
            maximumObserved = max(maximumObserved, active)
        }

        func taskFinished() {
            active -= 1
        }

        func maximum() -> Int {
            maximumObserved
        }

        func current() -> Int {
            active
        }
    }

    enum TestError: Error, Equatable {
        case expectedFailure
    }

    // MARK: - Configuration Tests

    func testInvalidConcurrencyLimit() {
        XCTAssertThrowsError(
            try FixedConcurrencyExecutor(concurrencyLimit: 0)
        ) { error in
            XCTAssertEqual(
                error as? FixedConcurrencyExecutor.ExecutorError,
                .invalidConcurrencyLimit
            )
        }
    }

    func testNegativeConcurrencyLimit() {
        XCTAssertThrowsError(
            try FixedConcurrencyExecutor(concurrencyLimit: -1)
        )
    }

    // MARK: - Execution Tests

    func testEmptyInputs() async throws {
        let executor = try FixedConcurrencyExecutor(
            concurrencyLimit: 4
        )

        let results = try await executor.execute(
            inputs: [Int]()
        ) { value in
            value * 2
        }

        XCTAssertTrue(results.isEmpty)
    }

    func testSingleTaskExecution() async throws {
        let executor = try FixedConcurrencyExecutor(
            concurrencyLimit: 1
        )

        let results = try await executor.execute(
            inputs: [5]
        ) { value in
            value * 2
        }

        XCTAssertEqual(results, [10])
    }

    func testMultipleTaskExecution() async throws {
        let executor = try FixedConcurrencyExecutor(
            concurrencyLimit: 4
        )

        let inputs = Array(1...20)

        let results = try await executor.execute(
            inputs: inputs
        ) { value in
            value * value
        }

        XCTAssertEqual(
            results,
            inputs.map { $0 * $0 }
        )
    }

    // MARK: - Ordering

    func testResultsPreserveInputOrder() async throws {
        let executor = try FixedConcurrencyExecutor(
            concurrencyLimit: 4
        )

        let inputs = Array(1...10)

        let results = try await executor.execute(
            inputs: inputs
        ) { value in

            // Different delays encourage out-of-order
            // task completion.
            let delay = UInt64(11 - value) * 5_000_000

            try await Task.sleep(nanoseconds: delay)

            return value
        }

        XCTAssertEqual(results, inputs)
    }

    // MARK: - Concurrency Bound

    func testConcurrencyLimitIsRespected() async throws {
        let limit = 3

        let executor = try FixedConcurrencyExecutor(
            concurrencyLimit: limit
        )

        let tracker = ConcurrencyTracker()

        let inputs = Array(1...30)

        let results = try await executor.execute(
            inputs: inputs
        ) { value in

            await tracker.taskStarted()

            // Simulate asynchronous work.
            try await Task.sleep(
                nanoseconds: 10_000_000
            )

            await tracker.taskFinished()

            return value
        }

        let maximum = await tracker.maximum()

        XCTAssertLessThanOrEqual(maximum, limit)
        XCTAssertEqual(results.count, inputs.count)
    }

    // MARK: - Error Propagation

    func testOperationErrorIsPropagated() async throws {
        let executor = try FixedConcurrencyExecutor(
            concurrencyLimit: 2
        )

        do {
            _ = try await executor.execute(
                inputs: [1, 2, 3, 4]
            ) { value in

                if value == 2 {
                    throw TestError.expectedFailure
                }

                return value
            }

            XCTFail("Expected the operation to throw")

        } catch let error as TestError {
            XCTAssertEqual(error, .expectedFailure)

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Large Workload

    func testLargeWorkload() async throws {
        let executor = try FixedConcurrencyExecutor(
            concurrencyLimit: 8
        )

        let inputs = Array(1...100)

        let results = try await executor.execute(
            inputs: inputs
        ) { value in
            value + 1
        }

        XCTAssertEqual(
            results,
            inputs.map { $0 + 1 }
        )
    }
}
