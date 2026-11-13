
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class ControllerComparisonRunnerTests: XCTestCase {

    // MARK: - Benchmark Modes

    private enum BenchmarkMode: String, CaseIterable {
        case fixed4
        case adaptiveV1
        case adaptiveV2
    }

    // MARK: - Benchmark Record

    private struct BenchmarkRecord {
        let trial: Int
        let mode: BenchmarkMode
        let durationMilliseconds: Double
        let throughput: Double
        let completedTasks: Int
        let adjustmentCount: Int
        let feedbackWindowCount: Int
        let meanTaskLatencyMilliseconds: Double?
    }

    private struct ExecutionMetrics {
        let completedTasks: Int
        let adjustmentCount: Int
        let feedbackWindowCount: Int
        let meanTaskLatencyMilliseconds: Double?
    }

    // MARK: - Experiment Configuration

    private let taskCount = 100
    private let warmupTrials = 3
    private let measuredTrials = 30

    private func makeConfiguration() throws
        -> AdaptiveConcurrencyConfiguration {

        try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: 1,
            maximumConcurrency: 8,
            initialConcurrency: 2,
            measurementWindowSize: 10,
            improvementThreshold: 0.05,
            maximumLatencyMilliseconds: 1000
        )
    }

    // MARK: - Main Benchmark

    func testThirtyTrialControllerComparison() async throws {

        guard ProcessInfo.processInfo.environment[
            "RUN_CONTROLLER_BENCHMARK"
        ] == "1" else {

            throw XCTSkip(
                "Set RUN_CONTROLLER_BENCHMARK=1 to run."
            )
        }

        let configuration = try makeConfiguration()
        let inputs = Array(0..<taskCount)

        var records: [BenchmarkRecord] = []

        print("Starting controller comparison")
        print("Tasks per execution: \(taskCount)")
        print("Warm-up rounds: \(warmupTrials)")
        print("Measured rounds: \(measuredTrials)")

        // MARK: Warm-up Runs

        for round in 1...warmupTrials {

            for mode in orderedModes(for: round) {

                _ = try await runOne(
                    mode: mode,
                    trial: round,
                    inputs: inputs,
                    configuration: configuration
                )
            }

            print("Warm-up round \(round) complete")
        }

        // MARK: Measured Runs

        for trial in 1...measuredTrials {

            for mode in orderedModes(for: trial) {

                let record = try await runOne(
                    mode: mode,
                    trial: trial,
                    inputs: inputs,
                    configuration: configuration
                )

                records.append(record)

                print(
                    String(
                        format: "Trial %02d | %@ | %.3f ms",
                        trial,
                        mode.rawValue,
                        record.durationMilliseconds
                    )
                )
            }
        }

        XCTAssertEqual(
            records.count,
            measuredTrials * BenchmarkMode.allCases.count
        )

        // MARK: CSV Export

        let outputDirectory = try makeOutputDirectory()

        let csvURL = outputDirectory.appendingPathComponent(
            "controller_comparison_30_trials.csv"
        )

        let csv = makeCSV(records: records)

        try csv.write(
            to: csvURL,
            atomically: true,
            encoding: .utf8
        )

        print("CSV exported: \(csvURL.path)")

        // MARK: Summary

        for mode in BenchmarkMode.allCases {

            let durations = records
                .filter { $0.mode == mode }
                .map { $0.durationMilliseconds }

            let mean = durations.reduce(0, +)
                / Double(durations.count)

            let sorted = durations.sorted()

            let median = (
                sorted[14] + sorted[15]
            ) / 2

            let p95Index = Int(
                ceil(Double(sorted.count) * 0.95)
            ) - 1

            let p95 = sorted[p95Index]

            print(
                String(
                    format:
                        "%@ | Mean %.3f ms | Median %.3f ms | P95 %.3f ms",
                    mode.rawValue,
                    mean,
                    median,
                    p95
                )
            )
        }

        print("PASS: Controller comparison completed")
    }

    // MARK: - Balanced Execution Order

    private func orderedModes(
        for round: Int
    ) -> [BenchmarkMode] {

        let modes = BenchmarkMode.allCases
        let offset = (round - 1) % modes.count

        return Array(modes[offset...])
            + Array(modes[..<offset])
    }

    // MARK: - Single Benchmark Execution

    private func runOne(
        mode: BenchmarkMode,
        trial: Int,
        inputs: [Int],
        configuration: AdaptiveConcurrencyConfiguration
    ) async throws -> BenchmarkRecord {

        let clock = ContinuousClock()
        let start = clock.now

        let metrics: ExecutionMetrics

        switch mode {

        // MARK: Fixed Concurrency

        case .fixed4:

            let executor = try FixedConcurrencyExecutor(
                concurrencyLimit: 4
            )

            let results = try await executor.execute(
                inputs: inputs
            ) { @Sendable input in

                try await Self.workload(input)
            }

            XCTAssertEqual(results, inputs)

            metrics = ExecutionMetrics(
                completedTasks: results.count,
                adjustmentCount: 0,
                feedbackWindowCount: 0,
                meanTaskLatencyMilliseconds: nil
            )

        // MARK: Adaptive V1 / V2

        case .adaptiveV1, .adaptiveV2:

            let version: AdaptiveControllerVersion =
                mode == .adaptiveV1 ? .v1 : .v2

            let executor = VersionedAdaptiveExecutor(
                configuration: configuration,
                version: version
            )

            let result = try await executor.execute(
                inputs: inputs
            ) { @Sendable input in

                try await Self.workload(input)
            }

            XCTAssertEqual(result.results, inputs)

            let totalCompleted = result.feedbackHistory.reduce(0) {
                $0 + $1.completedTaskCount
            }

            XCTAssertEqual(totalCompleted, inputs.count)

            let weightedLatency = result.feedbackHistory.reduce(0.0) {
                $0 + (
                    $1.meanLatencyMilliseconds
                    * Double($1.completedTaskCount)
                )
            }

            let meanLatency = totalCompleted > 0
                ? weightedLatency / Double(totalCompleted)
                : nil

            metrics = ExecutionMetrics(
                completedTasks: result.results.count,
                adjustmentCount: result.adjustments.count,
                feedbackWindowCount: result.feedbackHistory.count,
                meanTaskLatencyMilliseconds: meanLatency
            )
        }

        let duration = Self.milliseconds(
            start.duration(to: clock.now)
        )

        XCTAssertEqual(
            metrics.completedTasks,
            taskCount
        )

        XCTAssertGreaterThan(duration, 0)

        return BenchmarkRecord(
            trial: trial,
            mode: mode,
            durationMilliseconds: duration,
            throughput: Double(metrics.completedTasks)
                / (duration / 1000.0),
            completedTasks: metrics.completedTasks,
            adjustmentCount: metrics.adjustmentCount,
            feedbackWindowCount: metrics.feedbackWindowCount,
            meanTaskLatencyMilliseconds:
                metrics.meanTaskLatencyMilliseconds
        )
    }

    // MARK: - Swift 6 Sendable Workload

    /// Static method avoids capturing the XCTest instance.
    ///
    /// This is a suspension-heavy synthetic workload,
    /// not a CPU-intensive operation.

    private static func workload(
        _ input: Int
    ) async throws -> Int {

        try await Task.sleep(
            for: .milliseconds(5)
        )

        return input
    }

    // MARK: - Duration Conversion

    private static func milliseconds(
        _ duration: Duration
    ) -> Double {

        let components = duration.components

        return Double(components.seconds) * 1000.0
            + Double(components.attoseconds) / 1e15
    }

    // MARK: - Output Directory

    private func makeOutputDirectory() throws -> URL {

        let environment = ProcessInfo.processInfo.environment

        guard let path = environment["BENCHMARK_OUTPUT_DIR"],
              !path.isEmpty else {

            throw NSError(
                domain: "ControllerComparisonRunner",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "BENCHMARK_OUTPUT_DIR is required."
                ]
            )
        }

        let directory = URL(
            fileURLWithPath: path,
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }

    // MARK: - CSV Export

    private func makeCSV(
        records: [BenchmarkRecord]
    ) -> String {

        var lines = [
            [
                "trial",
                "configuration",
                "duration_ms",
                "throughput_tasks_per_second",
                "completed_tasks",
                "adjustment_count",
                "feedback_window_count",
                "mean_task_latency_ms"
            ].joined(separator: ",")
        ]

        for record in records {

            let latency = record.meanTaskLatencyMilliseconds
                .map { Self.format($0) } ?? ""

            let row = [
                String(record.trial),
                record.mode.rawValue,
                Self.format(record.durationMilliseconds),
                Self.format(record.throughput),
                String(record.completedTasks),
                String(record.adjustmentCount),
                String(record.feedbackWindowCount),
                latency
            ]

            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func format(
        _ value: Double
    ) -> String {

        String(
            format: "%.6f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
    }
}
