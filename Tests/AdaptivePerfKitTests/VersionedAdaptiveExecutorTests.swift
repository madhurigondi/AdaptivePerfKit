
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class VersionedAdaptiveExecutorTests: XCTestCase {

    private enum TestFailure: Error {
        case intentional
    }

    private func makeConfiguration(
        windowSize: Int = 5
    ) throws -> AdaptiveConcurrencyConfiguration {

        try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: 1,
            maximumConcurrency: 8,
            initialConcurrency: 2,
            measurementWindowSize: windowSize,
            improvementThreshold: 0.05,
            maximumLatencyMilliseconds: 1000
        )
    }

    // MARK: - Empty Input

    func testEmptyInputV1() async throws {
        try await verifyEmptyInput(version: .v1)
    }

    func testEmptyInputV2() async throws {
        try await verifyEmptyInput(version: .v2)
    }

    private func verifyEmptyInput(
        version: AdaptiveControllerVersion
    ) async throws {

        let executor = VersionedAdaptiveExecutor(
            configuration: try makeConfiguration(),
            version: version
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

    // MARK: - Input Ordering

    func testPreservesInputOrderV1() async throws {
        try await verifyInputOrder(version: .v1)
    }

    func testPreservesInputOrderV2() async throws {
        try await verifyInputOrder(version: .v2)
    }

    private func verifyInputOrder(
        version: AdaptiveControllerVersion
    ) async throws {

        let executor = VersionedAdaptiveExecutor(
            configuration: try makeConfiguration(),
            version: version
        )

        let inputs = Array(0..<20)

        let result = try await executor.execute(
            inputs: inputs
        ) { value in

            let delay = UInt64(20 - value) * 100_000

            try await Task.sleep(nanoseconds: delay)

            return value * 2
        }

        XCTAssertEqual(
            result.results,
            inputs.map { $0 * 2 }
        )
    }

    // MARK: - Feedback History

    func testFeedbackHistoryV1() async throws {
        try await verifyFeedbackHistory(version: .v1)
    }

    func testFeedbackHistoryV2() async throws {
        try await verifyFeedbackHistory(version: .v2)
    }

    private func verifyFeedbackHistory(
        version: AdaptiveControllerVersion
    ) async throws {

        let executor = VersionedAdaptiveExecutor(
            configuration: try makeConfiguration(),
            version: version
        )

        let result = try await executor.execute(
            inputs: Array(0..<20)
        ) { value in
            value
        }

        // 20 inputs, 5 tasks per window = 4 windows.
        XCTAssertEqual(result.feedbackHistory.count, 4)
        XCTAssertEqual(result.adjustments.count, 4)

        let completed = result.feedbackHistory.reduce(0) {
            $0 + $1.completedTaskCount
        }

        XCTAssertEqual(completed, 20)

        for feedback in result.feedbackHistory {
            XCTAssertGreaterThan(
                feedback.elapsedMilliseconds,
                0
            )

            XCTAssertGreaterThanOrEqual(
                feedback.meanLatencyMilliseconds,
                0
            )

            XCTAssertTrue(
                feedback.throughput.isFinite
            )

            XCTAssertTrue(
                (1...8).contains(feedback.concurrencyLimit)
            )
        }
    }

    // MARK: - Partial Final Window

    func testPartialWindowV1() async throws {
        try await verifyPartialWindow(version: .v1)
    }

    func testPartialWindowV2() async throws {
        try await verifyPartialWindow(version: .v2)
    }

    private func verifyPartialWindow(
        version: AdaptiveControllerVersion
    ) async throws {

        let executor = VersionedAdaptiveExecutor(
            configuration: try makeConfiguration(),
            version: version
        )

        let result = try await executor.execute(
            inputs: Array(0..<12)
        ) { value in
            value
        }

        XCTAssertEqual(result.results.count, 12)
        XCTAssertEqual(result.feedbackHistory.count, 3)

        XCTAssertEqual(
            result.feedbackHistory.map {
                $0.completedTaskCount
            },
            [5, 5, 2]
        )
    }

    // MARK: - Error Propagation

    func testErrorPropagationV1() async throws {
        try await verifyErrorPropagation(version: .v1)
    }

    func testErrorPropagationV2() async throws {
        try await verifyErrorPropagation(version: .v2)
    }

    private func verifyErrorPropagation(
        version: AdaptiveControllerVersion
    ) async throws {

        let executor = VersionedAdaptiveExecutor(
            configuration: try makeConfiguration(),
            version: version
        )

        do {
            _ = try await executor.execute(
                inputs: Array(0..<10)
            ) { value in

                if value == 3 {
                    throw TestFailure.intentional
                }

                return value
            }

            XCTFail("Expected operation to throw")

        } catch TestFailure.intentional {
            // Expected failure.
        }
    }

    // MARK: - Fresh Controller State

    func testFreshControllerStateV1() async throws {
        try await verifyFreshState(version: .v1)
    }

    func testFreshControllerStateV2() async throws {
        try await verifyFreshState(version: .v2)
    }

    private func verifyFreshState(
        version: AdaptiveControllerVersion
    ) async throws {

        let executor = VersionedAdaptiveExecutor(
            configuration: try makeConfiguration(),
            version: version
        )

        let first = try await executor.execute(
            inputs: Array(0..<10)
        ) { value in
            value
        }

        let second = try await executor.execute(
            inputs: Array(0..<10)
        ) { value in
            value
        }

        XCTAssertEqual(
            first.feedbackHistory.first?.concurrencyLimit,
            2
        )

        XCTAssertEqual(
            second.feedbackHistory.first?.concurrencyLimit,
            2
        )

        XCTAssertEqual(first.results, second.results)
    }

    // MARK: - Version Selection

    func testBothVersionsAvailable() {

        XCTAssertEqual(
            AdaptiveControllerVersion.allCases.count,
            2
        )

        XCTAssertTrue(
            AdaptiveControllerVersion.allCases.contains(.v1)
        )

        XCTAssertTrue(
            AdaptiveControllerVersion.allCases.contains(.v2)
        )
    }
}
