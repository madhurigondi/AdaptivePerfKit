
import Foundation

/// Reproducible synthetic workloads used for
/// adaptive concurrency research experiments.
public enum ResearchWorkload: String, CaseIterable, Sendable {
    case cpuIntensive
    case variableLatency
    case mixed

    /// Executes one workload item.
    ///
    /// Each workload is deterministic with respect
    /// to its input, although execution timing
    /// depends on the runtime environment.
    public func execute(_ input: Int) async throws -> Int {
        try Task.checkCancellation()

        switch self {
        case .cpuIntensive:
            return Self.cpuWork(input, iterations: 150_000)

        case .variableLatency:
            let delay = Self.delayMilliseconds(for: input)
            try await Task.sleep(for: .milliseconds(delay))
            return input

        case .mixed:
            let result = Self.cpuWork(
                input,
                iterations: 75_000
            )

            let delay = Self.delayMilliseconds(for: input)
            try await Task.sleep(for: .milliseconds(delay))

            return result
        }
    }

    /// Deterministic CPU-bound calculation.
    ///
    /// Uses wrapping arithmetic to avoid overflow traps.
    /// The result depends on the input and iteration count.
    private static func cpuWork(
        _ input: Int,
        iterations: Int
    ) -> Int {
        var value = UInt64(bitPattern: Int64(input)) &+ 1

        for index in 0..<iterations {
            value = value &* 2_862_933_555_777_941_757
                &+ 3_037_000_493
                &+ UInt64(index)
        }

        return Int(truncatingIfNeeded: value)
    }

    /// Deterministic variation from 2 to 20 ms.
    private static func delayMilliseconds(
        for input: Int
    ) -> Int {
        let bucket = input % 10
        return 2 + bucket * 2
    }
}
