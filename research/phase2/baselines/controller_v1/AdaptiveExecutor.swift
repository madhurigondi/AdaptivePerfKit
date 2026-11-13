
import Foundation

/// Diagnostic measurements for one adaptive execution window.
public struct AdaptiveWindowDiagnostic: Sendable, Equatable {

    public let windowNumber: Int
    public let concurrencyLimit: Int
    public let completedTaskCount: Int
    public let elapsedMilliseconds: Double
    public let throughput: Double
    public let meanLatencyMilliseconds: Double
    public let decision: AdaptiveConcurrencyDecision
    public let nextConcurrencyLimit: Int

    public init(
        windowNumber: Int,
        concurrencyLimit: Int,
        completedTaskCount: Int,
        elapsedMilliseconds: Double,
        throughput: Double,
        meanLatencyMilliseconds: Double,
        decision: AdaptiveConcurrencyDecision,
        nextConcurrencyLimit: Int
    ) {
        self.windowNumber = windowNumber
        self.concurrencyLimit = concurrencyLimit
        self.completedTaskCount = completedTaskCount
        self.elapsedMilliseconds = elapsedMilliseconds
        self.throughput = throughput
        self.meanLatencyMilliseconds = meanLatencyMilliseconds
        self.decision = decision
        self.nextConcurrencyLimit = nextConcurrencyLimit
    }
}

/// Result of an adaptive workload execution.
public struct AdaptiveExecutionResult<Output: Sendable>: Sendable {

    public let results: [Output]
    public let adjustments: [AdaptiveConcurrencyAdjustment]
    public let feedbackHistory: [PerformanceFeedback]
    public let windowDiagnostics: [AdaptiveWindowDiagnostic]

    public init(
        results: [Output],
        adjustments: [AdaptiveConcurrencyAdjustment],
        feedbackHistory: [PerformanceFeedback],
        windowDiagnostics: [AdaptiveWindowDiagnostic] = []
    ) {
        self.results = results
        self.adjustments = adjustments
        self.feedbackHistory = feedbackHistory
        self.windowDiagnostics = windowDiagnostics
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
                feedbackHistory: [],
                windowDiagnostics: []
            )
        }

        // A fresh controller for each independent execution.
        let controller = AdaptiveConcurrencyController(
            configuration: configuration
        )

        var allResults: [Output] = []
        var feedbackHistory: [PerformanceFeedback] = []
        var windowDiagnostics: [AdaptiveWindowDiagnostic] = []

        var nextIndex = 0
        var windowNumber = 0

        while nextIndex < inputs.count {

            try Task.checkCancellation()

            windowNumber += 1

            let concurrency =
                await controller.currentConcurrency()

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

                let milliseconds = Self.milliseconds(duration)

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

            let adjustment = await controller.evaluate(
                feedback: feedback
            )

            windowDiagnostics.append(
                AdaptiveWindowDiagnostic(
                    windowNumber: windowNumber,
                    concurrencyLimit: concurrency,
                    completedTaskCount: timedResults.count,
                    elapsedMilliseconds: elapsed,
                    throughput: feedback.throughput,
                    meanLatencyMilliseconds: meanLatency,
                    decision: adjustment.decision,
                    nextConcurrencyLimit:
                        adjustment.newConcurrency
                )
            )

            allResults.append(
                contentsOf: timedResults.map { $0.0 }
            )

            nextIndex = endIndex
        }

        let adjustments =
            await controller.adjustmentHistory()

        return AdaptiveExecutionResult(
            results: allResults,
            adjustments: adjustments,
            feedbackHistory: feedbackHistory,
            windowDiagnostics: windowDiagnostics
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
