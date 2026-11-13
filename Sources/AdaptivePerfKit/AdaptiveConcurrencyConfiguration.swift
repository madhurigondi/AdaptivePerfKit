
import Foundation

/// Configuration for AdaptivePerfKit's adaptive concurrency system.
///
/// Defines concurrency boundaries and feedback evaluation parameters.
public struct AdaptiveConcurrencyConfiguration: Sendable, Equatable {

    /// Minimum number of concurrent tasks.
    public let minimumConcurrency: Int

    /// Maximum number of concurrent tasks.
    public let maximumConcurrency: Int

    /// Initial concurrency level.
    public let initialConcurrency: Int

    /// Number of completed tasks per measurement window.
    public let measurementWindowSize: Int

    /// Minimum relative throughput improvement required
    /// before considering an adjustment beneficial.
    public let improvementThreshold: Double

    /// Maximum acceptable mean task latency in milliseconds.
    public let maximumLatencyMilliseconds: Double

    /// Creates a validated adaptive concurrency configuration.
    ///
    /// - Throws: ConfigurationError for invalid parameters.
    public init(
        minimumConcurrency: Int = 1,
        maximumConcurrency: Int = 8,
        initialConcurrency: Int = 2,
        measurementWindowSize: Int = 10,
        improvementThreshold: Double = 0.05,
        maximumLatencyMilliseconds: Double = 1000
    ) throws {

        guard minimumConcurrency >= 1 else {
            throw ConfigurationError.invalidMinimumConcurrency
        }

        guard maximumConcurrency >= minimumConcurrency else {
            throw ConfigurationError.invalidMaximumConcurrency
        }

        guard initialConcurrency >= minimumConcurrency,
              initialConcurrency <= maximumConcurrency else {
            throw ConfigurationError.invalidInitialConcurrency
        }

        guard measurementWindowSize >= 1 else {
            throw ConfigurationError.invalidMeasurementWindowSize
        }

        guard improvementThreshold.isFinite,
              improvementThreshold >= 0,
              improvementThreshold < 1 else {
            throw ConfigurationError.invalidImprovementThreshold
        }

        guard maximumLatencyMilliseconds.isFinite,
              maximumLatencyMilliseconds > 0 else {
            throw ConfigurationError.invalidMaximumLatency
        }

        self.minimumConcurrency = minimumConcurrency
        self.maximumConcurrency = maximumConcurrency
        self.initialConcurrency = initialConcurrency
        self.measurementWindowSize = measurementWindowSize
        self.improvementThreshold = improvementThreshold
        self.maximumLatencyMilliseconds = maximumLatencyMilliseconds
    }
}

/// Validation errors for adaptive concurrency configuration.
public enum ConfigurationError: Error, Sendable, Equatable {
    case invalidMinimumConcurrency
    case invalidMaximumConcurrency
    case invalidInitialConcurrency
    case invalidMeasurementWindowSize
    case invalidImprovementThreshold
    case invalidMaximumLatency
}
