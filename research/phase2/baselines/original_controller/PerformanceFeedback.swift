
import Foundation

/// Performance measurements collected during one
/// adaptive concurrency evaluation window.
public struct PerformanceFeedback: Sendable, Equatable {

    /// Unique identifier for the measurement window.
    public let windowID: UUID

    /// Number of successfully completed tasks.
    public let completedTaskCount: Int

    /// Total elapsed time for the measurement window.
    public let elapsedMilliseconds: Double

    /// Average execution latency per completed task.
    public let meanLatencyMilliseconds: Double

    /// Concurrency limit used during the window.
    public let concurrencyLimit: Int

    /// Timestamp when feedback was recorded.
    public let timestamp: Date

    /// Completed tasks per second.
    public var throughput: Double {
        guard elapsedMilliseconds > 0 else {
            return 0
        }

        return Double(completedTaskCount) /
            (elapsedMilliseconds / 1000.0)
    }

    /// Creates validated performance feedback.
    public init(
        windowID: UUID = UUID(),
        completedTaskCount: Int,
        elapsedMilliseconds: Double,
        meanLatencyMilliseconds: Double,
        concurrencyLimit: Int,
        timestamp: Date = Date()
    ) throws {

        guard completedTaskCount >= 0 else {
            throw PerformanceFeedbackError.invalidTaskCount
        }

        guard elapsedMilliseconds.isFinite,
              elapsedMilliseconds > 0 else {
            throw PerformanceFeedbackError.invalidElapsedTime
        }

        guard meanLatencyMilliseconds.isFinite,
              meanLatencyMilliseconds >= 0 else {
            throw PerformanceFeedbackError.invalidMeanLatency
        }

        guard concurrencyLimit > 0 else {
            throw PerformanceFeedbackError.invalidConcurrencyLimit
        }

        self.windowID = windowID
        self.completedTaskCount = completedTaskCount
        self.elapsedMilliseconds = elapsedMilliseconds
        self.meanLatencyMilliseconds = meanLatencyMilliseconds
        self.concurrencyLimit = concurrencyLimit
        self.timestamp = timestamp
    }
}

/// Validation errors for performance feedback.
public enum PerformanceFeedbackError: Error, Sendable, Equatable {
    case invalidTaskCount
    case invalidElapsedTime
    case invalidMeanLatency
    case invalidConcurrencyLimit
}
