
import Foundation

/// Executes asynchronous workloads with a fixed upper
/// bound on the number of in-flight tasks.
public struct FixedConcurrencyExecutor: Sendable {

    public let concurrencyLimit: Int

    public enum ExecutorError: Error, Equatable {
        case invalidConcurrencyLimit
    }

    public init(concurrencyLimit: Int) throws {
        guard concurrencyLimit > 0 else {
            throw ExecutorError.invalidConcurrencyLimit
        }

        self.concurrencyLimit = concurrencyLimit
    }

    /// Executes all inputs using bounded concurrency.
    ///
    /// Results are returned in the original input order.
    /// A thrown error cancels the remaining task group.
    public func execute<Input: Sendable, Output: Sendable>(
        inputs: [Input],
        operation: @escaping @Sendable (Input) async throws -> Output
    ) async throws -> [Output] {

        guard !inputs.isEmpty else {
            return []
        }

        let limit = min(concurrencyLimit, inputs.count)

        return try await withThrowingTaskGroup(
            of: (Int, Output).self,
            returning: [Output].self
        ) { group in

            var results = Array<Output?>(
                repeating: nil,
                count: inputs.count
            )

            var nextIndex = 0

            // Submit the initial bounded task window.
            for _ in 0..<limit {
                let index = nextIndex
                let input = inputs[index]

                group.addTask {
                    try Task.checkCancellation()
                    return (
                        index,
                        try await operation(input)
                    )
                }

                nextIndex += 1
            }

            // Replenish the group as tasks complete.
            while let (index, output) = try await group.next() {

                results[index] = output

                try Task.checkCancellation()

                if nextIndex < inputs.count {
                    let newIndex = nextIndex
                    let input = inputs[newIndex]

                    group.addTask {
                        try Task.checkCancellation()
                        return (
                            newIndex,
                            try await operation(input)
                        )
                    }

                    nextIndex += 1
                }
            }

            // All tasks have completed successfully.
            return results.map { $0! }
        }
    }
}
