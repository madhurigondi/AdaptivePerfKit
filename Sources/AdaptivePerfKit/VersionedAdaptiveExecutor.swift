
import Foundation

/// Selects the adaptive controller implementation.
public enum AdaptiveControllerVersion:
    String, Sendable, CaseIterable {

    case v1
    case v2
}

/// Executes identical workload APIs using either
/// the original V1 or experimental V2 controller.
///
/// A new controller is created for every execution,
/// preventing state leakage between benchmark trials.
public struct VersionedAdaptiveExecutor: Sendable {

    public let configuration: AdaptiveConcurrencyConfiguration
    public let version: AdaptiveControllerVersion

    public init(
        configuration: AdaptiveConcurrencyConfiguration,
        version: AdaptiveControllerVersion
    ) {
        self.configuration = configuration
        self.version = version
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

        let v1Controller: AdaptiveConcurrencyControllerV1?
        let v2Controller: AdaptiveConcurrencyController?

        switch version {
        case .v1:
            v1Controller = AdaptiveConcurrencyControllerV1(
                configuration: configuration
            )
            v2Controller = nil

        case .v2:
            v1Controller = nil
            v2Controller = AdaptiveConcurrencyController(
                configuration: configuration
            )
        }

        var allResults: [Output] = []
        var feedbackHistory: [PerformanceFeedback] = []

        var nextIndex = 0

        let clock = ContinuousClock()

        while nextIndex < inputs.count {

            try Task.checkCancellation()

            let concurrency: Int

            switch version {
            case .v1:
                concurrency = await v1Controller!
                    .currentConcurrency()

            case .v2:
                concurrency = await v2Controller!
                    .currentConcurrency()
            }

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

            let windowStart = clock.now

            let timedResults = try await executor.execute(
                inputs: windowInputs
            ) { input in

                let taskStart = clock.now

                let output = try await operation(input)

                let duration = taskStart.duration(
                    to: clock.now
                )

                return (
                    output,
                    Self.milliseconds(duration)
                )
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
                elapsedMilliseconds: max(
                    elapsed,
                    0.000001
                ),
                meanLatencyMilliseconds: meanLatency,
                concurrencyLimit: concurrency
            )

            feedbackHistory.append(feedback)

            switch version {
            case .v1:
                _ = await v1Controller!.evaluate(
                    feedback: feedback
                )

            case .v2:
                _ = await v2Controller!.evaluate(
                    feedback: feedback
                )
            }

            allResults.append(
                contentsOf: timedResults.map { $0.0 }
            )

            nextIndex = endIndex
        }

        let adjustments: [AdaptiveConcurrencyAdjustment]

        switch version {
        case .v1:
            adjustments = await v1Controller!
                .adjustmentHistory()

        case .v2:
            adjustments = await v2Controller!
                .adjustmentHistory()
        }

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
