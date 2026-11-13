
import Foundation

/// Result of an adaptive workload execution.
public struct AdaptiveExecutionResult<Output: Sendable>: Sendable {

    public let results: [Output]
    public let adjustments: [AdaptiveConcurrencyAdjustment]
    public let feedbackHistory: [PerformanceFeedback]

    public init(
        results: [Output],
        adjustments: [AdaptiveConcurrencyAdjustment],
        feedbackHistory: [PerformanceFeedback]
    ) {
        self.results = results
        self.adjustments = adjustments
        self.feedbackHistory = feedbackHistory
    }
}

/// Executes asynchronous workloads using feedback-driven
/// concurrency limits.
///
/// Concurrency changes are applied between measurement
/// windows rather than while tasks are running.
public struct AdaptiveExecutor: Sendable {

    public let configuration: AdaptiveConcurrencyConfiguration

    public init(
        configuration: AdaptiveConcurrencyConfiguration
    ) {
        self.configuration = configuration
    }

    public func execute<Input: Sendable, Output: Sendable>(
        inputs: [Input],
        operation: @escaping @Sendable (Input) async throws -> Output
    ) async throws -> AdaptiveExecutionResult<Output> {

        guard !inputs.isEmpty else {
            return AdaptiveExecutionResult(
                results: [],
                adjustments: [],
                feedbackHistory: []
            )
        }

        // A fresh controller prevents state from leaking
        // between independent benchmark runs.
        let controller = AdaptiveConcurrencyController(
            configuration: configuration
        )

        var allResults: [Output] = []
        var feedbackHistory: [PerformanceFeedback] = []

        var nextIndex = 0

        while nextIndex < inputs.count {

            try Task.checkCancellation()

            let concurrency = await controller.currentConcurrency()

            let endIndex = min(
                nextIndex + configuration.measurementWindowSize,
                inputs.count
            )

            let windowInputs = Array(
                inputs[nextIndex..<endIndex]
            )

            let executor = try FixedConcurrencyExecutor(
                concurrencyLimit: concurrency
            )

            let clock = ContinuousClock()
            let windowStart = clock.now

            let timedResults = try await executor.execute(
                inputs: windowInputs
            ) { input in

                let taskStart = clock.now

                let output = try await operation(input)

                let duration = taskStart.duration(to: clock.now)

                let milliseconds =
                    Self.milliseconds(duration)

                return (output, milliseconds)
            }

            let elapsed = Self.milliseconds(
                windowStart.duration(to: clock.now)
            )

            let totalLatency = timedResults.reduce(0.0) {
                $0 + $1.1
            }

            let meanLatency =
                totalLatency / Double(timedResults.count)

            let feedback = try PerformanceFeedback(
                completedTaskCount: timedResults.count,
                elapsedMilliseconds: max(elapsed, 0.000001),
                meanLatencyMilliseconds: meanLatency,
                concurrencyLimit: concurrency
            )

            feedbackHistory.append(feedback)

            _ = await controller.evaluate(feedback: feedback)

            allResults.append(
                contentsOf: timedResults.map { $0.0 }
            )

            nextIndex = endIndex
        }

        let adjustments = await controller.adjustmentHistory()

        return AdaptiveExecutionResult(
            results: allResults,
            adjustments: adjustments,
            feedbackHistory: feedbackHistory
        )
    }

    private static func milliseconds(
        _ duration: Duration
    ) -> Double {

        let components = duration.components

        return Double(components.seconds) * 1000.0
            + Double(components.attoseconds) / 1e15
    }
}
