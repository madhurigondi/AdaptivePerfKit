
import Foundation

/// Records why the controller changed or retained concurrency.
public enum AdaptiveConcurrencyDecision:
    String, Sendable, Equatable {

    case initialExploration
    case throughputImproved
    case throughputDegraded
    case insufficientImprovement
    case latencyExceeded
    case concurrencyLimitReached
}

/// A recorded concurrency adjustment.
public struct AdaptiveConcurrencyAdjustment:
    Sendable, Equatable {

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

/// V2 experimental feedback-driven concurrency controller.
///
/// Optimization features:
/// - Best-observed throughput tracking
/// - Degradation recovery
/// - Improvement threshold stabilization
/// - Latency protection
///
/// Actor isolation protects mutable controller state.
public actor AdaptiveConcurrencyController {

    public let configuration: AdaptiveConcurrencyConfiguration

    private var concurrency: Int
    private var previousFeedback: PerformanceFeedback?
    private var direction: Int = 1

    private var adjustments: [AdaptiveConcurrencyAdjustment] = []

    // MARK: - V2 State

    private var bestObservedConcurrency: Int
    private var bestObservedThroughput: Double = 0

    public init(
        configuration: AdaptiveConcurrencyConfiguration
    ) {
        self.configuration = configuration
        self.concurrency = configuration.initialConcurrency
        self.bestObservedConcurrency =
            configuration.initialConcurrency
    }

    // MARK: - Public State

    public func currentConcurrency() -> Int {
        concurrency
    }

    public func adjustmentHistory()
        -> [AdaptiveConcurrencyAdjustment] {
        adjustments
    }

    public func bestConcurrency() -> Int {
        bestObservedConcurrency
    }

    public func bestThroughput() -> Double {
        bestObservedThroughput
    }

    // MARK: - Evaluation

    @discardableResult
    public func evaluate(
        feedback: PerformanceFeedback
    ) -> AdaptiveConcurrencyAdjustment {

        let oldConcurrency = concurrency
        let decision: AdaptiveConcurrencyDecision

        // Reject feedback for a different concurrency level.
        guard feedback.concurrencyLimit == concurrency else {

            let adjustment = makeAdjustment(
                previous: oldConcurrency,
                decision: .concurrencyLimitReached,
                feedback: feedback
            )

            adjustments.append(adjustment)
            return adjustment
        }

        let currentThroughput = feedback.throughput

        // Track the best eligible observation.
        // A latency-violating observation cannot become best.
        if feedback.meanLatencyMilliseconds <=
            configuration.maximumLatencyMilliseconds &&
            currentThroughput > bestObservedThroughput {

            bestObservedThroughput = currentThroughput
            bestObservedConcurrency = concurrency
        }

        // MARK: - Latency Protection

        if feedback.meanLatencyMilliseconds >
            configuration.maximumLatencyMilliseconds {

            concurrency = bounded(concurrency - 1)
            direction = -1
            decision = .latencyExceeded

        } else if let previous = previousFeedback {

            // MARK: - Throughput Comparison

            let previousThroughput = previous.throughput

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

                // Continue exploring the current direction.
                concurrency = bounded(
                    concurrency + direction
                )

                decision = concurrency == oldConcurrency
                    ? .concurrencyLimitReached
                    : .throughputImproved

            } else if improvement <
                -configuration.improvementThreshold {

                // V2: Recover toward the best observed level.
                if bestObservedConcurrency != concurrency {

                    concurrency = bounded(
                        bestObservedConcurrency
                    )

                } else {

                    // If already at the best level, explore
                    // the opposite direction.
                    direction *= -1

                    concurrency = bounded(
                        concurrency + direction
                    )
                }

                // Prepare for a future upward exploration.
                if concurrency == bestObservedConcurrency {
                    direction = 1
                }

                decision = .throughputDegraded

            } else {

                // V2: Hold concurrency when improvement
                // is not sufficiently meaningful.
                decision = .insufficientImprovement
            }

        } else {

            // First valid feedback window.
            concurrency = bounded(
                concurrency + direction
            )

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

    // MARK: - Reset

    public func reset() {

        concurrency = configuration.initialConcurrency
        previousFeedback = nil
        direction = 1

        bestObservedConcurrency =
            configuration.initialConcurrency

        bestObservedThroughput = 0

        adjustments.removeAll()
    }

    // MARK: - Helpers

    private func bounded(_ proposed: Int) -> Int {

        min(
            configuration.maximumConcurrency,
            max(
                configuration.minimumConcurrency,
                proposed
            )
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
