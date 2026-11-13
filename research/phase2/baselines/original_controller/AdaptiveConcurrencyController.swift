
import Foundation

/// Records why the controller changed or retained concurrency.
public enum AdaptiveConcurrencyDecision: String, Sendable, Equatable {
    case initialExploration
    case throughputImproved
    case throughputDegraded
    case insufficientImprovement
    case latencyExceeded
    case concurrencyLimitReached
}

/// A recorded concurrency adjustment.
public struct AdaptiveConcurrencyAdjustment: Sendable, Equatable {

    public let previousConcurrency: Int
    public let newConcurrency: Int
    public let decision: AdaptiveConcurrencyDecision
    public let observedThroughput: Double
    public let observedLatencyMilliseconds: Double
    public let timestamp: Date

    public init(
        previousConcurrency: Int,
        newConcurrency: Int,
        decision: AdaptiveConcurrencyDecision,
        observedThroughput: Double,
        observedLatencyMilliseconds: Double,
        timestamp: Date = Date()
    ) {
        self.previousConcurrency = previousConcurrency
        self.newConcurrency = newConcurrency
        self.decision = decision
        self.observedThroughput = observedThroughput
        self.observedLatencyMilliseconds =
            observedLatencyMilliseconds
        self.timestamp = timestamp
    }
}

/// Feedback-driven concurrency controller.
///
/// This actor protects mutable controller state from
/// concurrent access.
public actor AdaptiveConcurrencyController {

    public let configuration: AdaptiveConcurrencyConfiguration

    private var concurrency: Int
    private var previousFeedback: PerformanceFeedback?
    private var direction: Int = 1
    private var adjustments: [AdaptiveConcurrencyAdjustment] = []

    public init(
        configuration: AdaptiveConcurrencyConfiguration
    ) {
        self.configuration = configuration
        self.concurrency = configuration.initialConcurrency
    }

    /// Returns the currently recommended concurrency limit.
    public func currentConcurrency() -> Int {
        concurrency
    }

    /// Returns recorded concurrency decisions.
    public func adjustmentHistory() -> [AdaptiveConcurrencyAdjustment] {
        adjustments
    }

    /// Evaluates one completed measurement window.
    ///
    /// The supplied feedback must correspond to the
    /// concurrency limit that was active for that window.
    @discardableResult
    public func evaluate(
        feedback: PerformanceFeedback
    ) -> AdaptiveConcurrencyAdjustment {

        let oldConcurrency = concurrency
        let decision: AdaptiveConcurrencyDecision

        // Reject stale or mismatched measurements.
        guard feedback.concurrencyLimit == concurrency else {
            let adjustment = makeAdjustment(
                previous: oldConcurrency,
                decision: .concurrencyLimitReached,
                feedback: feedback
            )
            adjustments.append(adjustment)
            return adjustment
        }

        if feedback.meanLatencyMilliseconds >
            configuration.maximumLatencyMilliseconds {

            concurrency = max(
                configuration.minimumConcurrency,
                concurrency - 1
            )

            direction = -1
            decision = .latencyExceeded

        } else if let previous = previousFeedback {

            let previousThroughput = previous.throughput
            let currentThroughput = feedback.throughput

            let improvement: Double

            if previousThroughput > 0 {
                improvement =
                    (currentThroughput - previousThroughput)
                    / previousThroughput
            } else {
                improvement = currentThroughput > 0 ? 1 : 0
            }

            if improvement >
                configuration.improvementThreshold {

                concurrency = bounded(concurrency + direction)
                decision = .throughputImproved

            } else if improvement <
                -configuration.improvementThreshold {

                direction *= -1
                concurrency = bounded(concurrency + direction)
                decision = .throughputDegraded

            } else {
                decision = .insufficientImprovement
            }

        } else {

            concurrency = bounded(concurrency + direction)

            decision = concurrency == oldConcurrency
                ? .concurrencyLimitReached
                : .initialExploration
        }

        previousFeedback = feedback

        let adjustment = makeAdjustment(
            previous: oldConcurrency,
            decision: decision,
            feedback: feedback
        )

        adjustments.append(adjustment)

        return adjustment
    }

    /// Resets the controller for a new experiment.
    public func reset() {
        concurrency = configuration.initialConcurrency
        previousFeedback = nil
        direction = 1
        adjustments.removeAll()
    }

    private func bounded(_ proposed: Int) -> Int {
        min(
            configuration.maximumConcurrency,
            max(configuration.minimumConcurrency, proposed)
        )
    }

    private func makeAdjustment(
        previous: Int,
        decision: AdaptiveConcurrencyDecision,
        feedback: PerformanceFeedback
    ) -> AdaptiveConcurrencyAdjustment {

        AdaptiveConcurrencyAdjustment(
            previousConcurrency: previous,
            newConcurrency: concurrency,
            decision: decision,
            observedThroughput: feedback.throughput,
            observedLatencyMilliseconds:
                feedback.meanLatencyMilliseconds
        )
    }
}
