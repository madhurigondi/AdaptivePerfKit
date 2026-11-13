
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class AdaptiveConcurrencyControllerTests: XCTestCase {

    // MARK: - Helpers

    private func makeConfiguration(
        minimum: Int = 1,
        maximum: Int = 8,
        initial: Int = 2
    ) throws -> AdaptiveConcurrencyConfiguration {
        try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: minimum,
            maximumConcurrency: maximum,
            initialConcurrency: initial,
            measurementWindowSize: 10,
            improvementThreshold: 0.05,
            maximumLatencyMilliseconds: 1000
        )
    }

    private func makeFeedback(
        concurrency: Int,
        completed: Int = 10,
        elapsed: Double = 1000,
        latency: Double = 100
    ) throws -> PerformanceFeedback {
        try PerformanceFeedback(
            completedTaskCount: completed,
            elapsedMilliseconds: elapsed,
            meanLatencyMilliseconds: latency,
            concurrencyLimit: concurrency
        )
    }

    // MARK: - Initial State

    func testInitialConcurrency() async throws {
        let config = try makeConfiguration()
        let controller = AdaptiveConcurrencyController(
            configuration: config
        )

        let current = await controller.currentConcurrency()

        XCTAssertEqual(current, 2)
    }

    func testInitialExploration() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        let feedback = try makeFeedback(concurrency: 2)
        let adjustment = await controller.evaluate(
            feedback: feedback
        )

        XCTAssertEqual(adjustment.previousConcurrency, 2)
        XCTAssertEqual(adjustment.newConcurrency, 3)
        XCTAssertEqual(adjustment.decision, .initialExploration)
    }

    // MARK: - Throughput Decisions

    func testThroughputImprovementIncreasesConcurrency() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                elapsed: 1000
            )
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 3,
                elapsed: 800
            )
        )

        XCTAssertEqual(adjustment.newConcurrency, 4)
        XCTAssertEqual(adjustment.decision, .throughputImproved)
    }

    func testThroughputDegradationReversesDirection() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                elapsed: 1000
            )
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 3,
                elapsed: 1500
            )
        )

        XCTAssertEqual(adjustment.newConcurrency, 2)
        XCTAssertEqual(adjustment.decision, .throughputDegraded)
    }

    func testInsufficientImprovementMaintainsConcurrency() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                elapsed: 1000
            )
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 3,
                elapsed: 980
            )
        )

        XCTAssertEqual(adjustment.newConcurrency, 3)
        XCTAssertEqual(
            adjustment.decision,
            .insufficientImprovement
        )
    }

    // MARK: - Latency Constraint

    func testLatencyExceededDecreasesConcurrency() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                latency: 1500
            )
        )

        XCTAssertEqual(adjustment.newConcurrency, 1)
        XCTAssertEqual(adjustment.decision, .latencyExceeded)
    }

    func testLatencyAtThresholdDoesNotTriggerReduction() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                latency: 1000
            )
        )

        XCTAssertEqual(adjustment.newConcurrency, 3)
        XCTAssertEqual(adjustment.decision, .initialExploration)
    }

    // MARK: - Concurrency Boundaries

    func testMaximumConcurrencyIsRespected() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration(
                minimum: 1,
                maximum: 3,
                initial: 3
            )
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(concurrency: 3)
        )

        XCTAssertEqual(adjustment.newConcurrency, 3)
        XCTAssertEqual(
            adjustment.decision,
            .concurrencyLimitReached
        )
    }

    func testMinimumConcurrencyIsRespected() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration(
                minimum: 2,
                maximum: 8,
                initial: 2
            )
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                latency: 1500
            )
        )

        XCTAssertEqual(adjustment.newConcurrency, 2)
        XCTAssertEqual(adjustment.decision, .latencyExceeded)
    }

    // MARK: - Feedback Validation

    func testMismatchedConcurrencyDoesNotChangeState() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(concurrency: 5)
        )

        XCTAssertEqual(adjustment.previousConcurrency, 2)
        XCTAssertEqual(adjustment.newConcurrency, 2)
        XCTAssertEqual(
            adjustment.decision,
            .concurrencyLimitReached
        )

        let current = await controller.currentConcurrency()
        XCTAssertEqual(current, 2)
    }

    // MARK: - History

    func testAdjustmentHistory() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(concurrency: 2)
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 3,
                elapsed: 800
            )
        )

        let history = await controller.adjustmentHistory()

        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(
            history[0].decision,
            .initialExploration
        )
        XCTAssertEqual(
            history[1].decision,
            .throughputImproved
        )
    }

    // MARK: - Reset

    func testResetRestoresInitialState() async throws {
        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(concurrency: 2)
        )

        await controller.reset()

        let current = await controller.currentConcurrency()
        let history = await controller.adjustmentHistory()

        XCTAssertEqual(current, 2)
        XCTAssertTrue(history.isEmpty)

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(concurrency: 2)
        )

        XCTAssertEqual(adjustment.decision, .initialExploration)
    }
}
