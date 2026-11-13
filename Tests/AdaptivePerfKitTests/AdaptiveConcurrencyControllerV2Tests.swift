
import XCTest
@testable import AdaptivePerfKit

final class AdaptiveConcurrencyControllerV2Tests: XCTestCase {

    private func makeConfiguration() throws
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

    private func makeFeedback(
        concurrency: Int,
        throughput: Double,
        latency: Double = 10
    ) throws -> PerformanceFeedback {

        try PerformanceFeedback(
            completedTaskCount: 10,
            elapsedMilliseconds: 10_000 / throughput,
            meanLatencyMilliseconds: latency,
            concurrencyLimit: concurrency
        )
    }

    func testInitialExploration() async throws {

        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        let feedback = try makeFeedback(
            concurrency: 2,
            throughput: 100
        )

        let adjustment = await controller.evaluate(
            feedback: feedback
        )

        XCTAssertEqual(
            adjustment.previousConcurrency, 2
        )

        XCTAssertEqual(
            adjustment.newConcurrency, 3
        )

        XCTAssertEqual(
            adjustment.decision, .initialExploration
        )
    }

    func testBestThroughputTracking() async throws {

        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                throughput: 100
            )
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 3,
                throughput: 150
            )
        )

        let best = await controller.bestConcurrency()
        let throughput = await controller.bestThroughput()

        XCTAssertEqual(best, 3)
        XCTAssertEqual(throughput, 150, accuracy: 0.001)
    }

    func testRecoveryAfterDegradation() async throws {

        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                throughput: 100
            )
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 3,
                throughput: 150
            )
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 4,
                throughput: 90
            )
        )

        XCTAssertEqual(
            adjustment.decision, .throughputDegraded
        )

        XCTAssertEqual(
            adjustment.newConcurrency, 3
        )
    }

    func testSmallImprovementHoldsConcurrency() async throws {

        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                throughput: 100
            )
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 3,
                throughput: 103
            )
        )

        XCTAssertEqual(
            adjustment.decision, .insufficientImprovement
        )

        XCTAssertEqual(
            adjustment.newConcurrency, 3
        )
    }

    func testLatencyProtection() async throws {

        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                throughput: 100,
                latency: 1500
            )
        )

        XCTAssertEqual(
            adjustment.decision, .latencyExceeded
        )

        XCTAssertEqual(
            adjustment.newConcurrency, 1
        )

        XCTAssertEqual(
            awaitValuePlaceholder(),
            true
        )
    }

    private func awaitValuePlaceholder() -> Bool {
        true
    }

    func testResetClearsBestObservation() async throws {

        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                throughput: 100
            )
        )

        await controller.reset()

        let current = await controller.currentConcurrency()
        let best = await controller.bestConcurrency()
        let throughput = await controller.bestThroughput()
        let history = await controller.adjustmentHistory()

        XCTAssertEqual(current, 2)
        XCTAssertEqual(best, 2)
        XCTAssertEqual(throughput, 0)
        XCTAssertTrue(history.isEmpty)
    }

    func testStaleFeedbackDoesNotChangeState() async throws {

        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        let adjustment = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 7,
                throughput: 100
            )
        )

        let current = await controller.currentConcurrency()
        let bestThroughput = await controller.bestThroughput()

        XCTAssertEqual(current, 2)
        XCTAssertEqual(bestThroughput, 0)

        XCTAssertEqual(
            adjustment.newConcurrency, 2
        )
    }

    func testAdjustmentHistoryRecorded() async throws {

        let controller = AdaptiveConcurrencyController(
            configuration: try makeConfiguration()
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 2,
                throughput: 100
            )
        )

        _ = await controller.evaluate(
            feedback: try makeFeedback(
                concurrency: 3,
                throughput: 150
            )
        )

        let history = await controller.adjustmentHistory()

        XCTAssertEqual(history.count, 2)
    }
}
