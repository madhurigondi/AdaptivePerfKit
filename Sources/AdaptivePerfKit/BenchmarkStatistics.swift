
import Foundation

/// Statistical summary of benchmark execution times.
public struct BenchmarkStatistics: Sendable {

    public let sampleCount: Int
    public let averageMilliseconds: Double
    public let minimumMilliseconds: Double
    public let maximumMilliseconds: Double
    public let medianMilliseconds: Double
    public let p95Milliseconds: Double

    /// Creates statistics from valid, finite,
    /// nonnegative execution durations.
    ///
    /// Returns nil when there are no valid samples.
    public init?(measurements: [PerformanceMeasurement]) {

        let durations = measurements
            .map(\.durationMilliseconds)
            .filter { $0.isFinite && $0 >= 0 }
            .sorted()

        guard !durations.isEmpty else {
            return nil
        }

        let count = durations.count

        sampleCount = count

        averageMilliseconds =
            durations.reduce(0.0, +) / Double(count)

        minimumMilliseconds = durations[0]

        maximumMilliseconds = durations[count - 1]

        // Median: midpoint for odd sample counts,
        // average of the middle two for even counts.
        if count.isMultiple(of: 2) {
            medianMilliseconds =
                (durations[count / 2 - 1] +
                 durations[count / 2]) / 2.0
        } else {
            medianMilliseconds = durations[count / 2]
        }

        // Nearest-rank 95th percentile.
        // For small samples, this may equal the maximum.
        let p95Rank = Int(
            ceil(0.95 * Double(count))
        )

        let p95Index = min(
            max(p95Rank - 1, 0),
            count - 1
        )

        p95Milliseconds = durations[p95Index]
    }
}
