
import Foundation

/// Executes workloads using a single continuously
/// replenished task group with feedback-driven
/// concurrency adjustment.
///
/// Unlike the windowed V1/V2 executors, V3 does not
/// drain all running tasks at measurement boundaries.
public struct ContinuousAdaptiveExecutor: Sendable {

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

        let controller = AdaptiveConcurrencyController(
            configuration: configuration
        )

        let clock = ContinuousClock()
        let windowSize = configuration.measurementWindowSize

        var orderedResults = Array<Output?>(
            repeating: nil,
            count: inputs.count
        )

        var feedbackHistory: [PerformanceFeedback] = []

        var nextIndex = 0
        var activeTasks = 0
        var completedInWindow = 0
        var latencySum = 0.0

        var currentLimit = await controller.currentConcurrency()
        var windowStart = clock.now

        try await withThrowingTaskGroup(
            of: (Int, Output, Double).self
        ) { group in

            // Start the initial bounded task set.
            let initialCount = min(
                currentLimit,
                inputs.count
            )

            for _ in 0..<initialCount {
                let index = nextIndex
                let input = inputs[index]

                group.addTask {
                    try Task.checkCancellation()

                    let start = clock.now
                    let output = try await operation(input)

                    let duration = Self.milliseconds(
                        start.duration(to: clock.now)
                    )

                    return (index, output, duration)
                }

                nextIndex += 1
                activeTasks += 1
            }

            // Process completions continuously.
            while let (index, output, latency) =
                try await group.next() {

                try Task.checkCancellation()

                activeTasks -= 1
                orderedResults[index] = output

                completedInWindow += 1
                latencySum += latency

                // Evaluate after each completed window.
                if completedInWindow >= windowSize {

                    let elapsed = Self.milliseconds(
                        windowStart.duration(to: clock.now)
                    )

                    let feedback = try PerformanceFeedback(
                        completedTaskCount: completedInWindow,
                        elapsedMilliseconds: max(
                            elapsed,
                            0.000001
                        ),
                        meanLatencyMilliseconds:
                            latencySum / Double(completedInWindow),
                        concurrencyLimit: currentLimit
                    )

                    feedbackHistory.append(feedback)

                    _ = await controller.evaluate(
                        feedback: feedback
                    )

                    currentLimit = await controller.currentConcurrency()

                    completedInWindow = 0
                    latencySum = 0
                    windowStart = clock.now
                }

                // Replenish without draining the task group.
                while activeTasks < currentLimit
                    && nextIndex < inputs.count {

                    let newIndex = nextIndex
                    let input = inputs[newIndex]

                    group.addTask {
                        try Task.checkCancellation()

                        let start = clock.now
                        let result = try await operation(input)

                        let duration = Self.milliseconds(
                            start.duration(to: clock.now)
                        )

                        return (
                            newIndex,
                            result,
                            duration
                        )
                    }

                    nextIndex += 1
                    activeTasks += 1
                }
            }
        }

        // Record a final partial measurement window.
        if completedInWindow > 0 {

            let elapsed = Self.milliseconds(
                windowStart.duration(to: clock.now)
            )

            let feedback = try PerformanceFeedback(
                completedTaskCount: completedInWindow,
                elapsedMilliseconds: max(elapsed, 0.000001),
                meanLatencyMilliseconds:
                    latencySum / Double(completedInWindow),
                concurrencyLimit: currentLimit
            )

            feedbackHistory.append(feedback)

            _ = await controller.evaluate(
                feedback: feedback
            )
        }

        let adjustments = await controller.adjustmentHistory()

        return AdaptiveExecutionResult(
            results: orderedResults.map { $0! },
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
