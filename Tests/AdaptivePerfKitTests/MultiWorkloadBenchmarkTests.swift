
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class MultiWorkloadBenchmarkTests: XCTestCase {

    // MARK: - Benchmark Modes

    private enum Mode: String, CaseIterable {
        case fixed4
        case adaptiveV1
        case adaptiveV2
    }

    // MARK: - Benchmark Record

    private struct Record {
        let workload: String
        let trial: Int
        let mode: String
        let durationMS: Double
        let throughput: Double
        let completedTasks: Int
        let adjustmentCount: Int
        let feedbackWindowCount: Int
    }

    private struct RunResult {
        let record: Record
        let outputs: [Int]
    }

    // MARK: - Experiment Settings

    private let taskCount = 100
    private let warmupRounds = 3
    private let measuredRounds = 30

    private func configuration() throws
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

    func testMultiWorkloadBenchmark() async throws {

        guard ProcessInfo.processInfo.environment[
            "RUN_MULTI_WORKLOAD_BENCHMARK"
        ] == "1" else {
            throw XCTSkip(
                "Set RUN_MULTI_WORKLOAD_BENCHMARK=1 to run."
            )
        }

        let config = try configuration()
        let inputs = Array(0..<taskCount)

        let directory = try outputDirectory()

        var records: [Record] = []

        print("========================================")
        print("AdaptivePerfKit Multi-Workload Benchmark")
        print("========================================")
        print("Tasks per execution: \(taskCount)")
        print("Warm-up rounds: \(warmupRounds)")
        print("Measured rounds: \(measuredRounds)")
        print("Configurations: Fixed 4, V1, V2")

        for workload in ResearchWorkload.allCases {

            print("")
            print("Starting workload: \(workload.rawValue)")

            // Compute reference outputs once, outside
            // all timed trials.
            let expectedOutputs = try await referenceOutputs(
                inputs: inputs,
                workload: workload
            )

            // MARK: Warm-up

            for round in 1...warmupRounds {

                for mode in orderedModes(round: round) {

                    let result = try await run(
                        workload: workload,
                        mode: mode,
                        trial: round,
                        inputs: inputs,
                        configuration: config
                    )

                    XCTAssertEqual(
                        result.outputs,
                        expectedOutputs,
                        "Warm-up output mismatch: \(mode.rawValue)"
                    )
                }

                print("Warm-up round \(round) completed")
            }

            // MARK: Measured Trials

            for trial in 1...measuredRounds {

                for mode in orderedModes(round: trial) {

                    let result = try await run(
                        workload: workload,
                        mode: mode,
                        trial: trial,
                        inputs: inputs,
                        configuration: config
                    )

                    // Correctness validation occurs
                    // outside the measured interval.
                    XCTAssertEqual(
                        result.outputs,
                        expectedOutputs,
                        "Output mismatch: \(workload.rawValue), " +
                        "\(mode.rawValue), trial \(trial)"
                    )

                    XCTAssertEqual(
                        result.record.completedTasks,
                        taskCount
                    )

                    XCTAssertGreaterThan(
                        result.record.durationMS,
                        0
                    )

                    records.append(result.record)

                    print(
                        String(
                            format: "%@ | %@ | Trial %02d | %.3f ms",
                            workload.rawValue,
                            mode.rawValue,
                            trial,
                            result.record.durationMS
                        )
                    )
                }
            }

            print("Completed workload: \(workload.rawValue)")
        }

        // MARK: Validate Dataset

        let expectedRecordCount =
            ResearchWorkload.allCases.count
            * Mode.allCases.count
            * measuredRounds

        XCTAssertEqual(
            records.count,
            expectedRecordCount
        )

        for workload in ResearchWorkload.allCases {
            for mode in Mode.allCases {

                let subset = records.filter {
                    $0.workload == workload.rawValue
                        && $0.mode == mode.rawValue
                }

                XCTAssertEqual(
                    subset.count,
                    measuredRounds
                )

                XCTAssertEqual(
                    subset.map(\.trial).sorted(),
                    Array(1...measuredRounds)
                )
            }
        }

        // MARK: Export CSV

        let csvURL = directory.appendingPathComponent(
            "multi_workload_270_trials.csv"
        )

        try makeCSV(records).write(
            to: csvURL,
            atomically: true,
            encoding: .utf8
        )

        print("")
        print("CSV exported: \(csvURL.path)")
        print("Total measured executions: \(records.count)")

        // MARK: Summary

        print("")
        print("========== BENCHMARK SUMMARY ==========")

        for workload in ResearchWorkload.allCases {

            for mode in Mode.allCases {

                let durations = records
                    .filter {
                        $0.workload == workload.rawValue
                            && $0.mode == mode.rawValue
                    }
                    .map(\.durationMS)

                let mean = durations.reduce(0, +)
                    / Double(durations.count)

                let sorted = durations.sorted()

                let median = (
                    sorted[14] + sorted[15]
                ) / 2.0

                let p95Index = Int(
                    ceil(Double(sorted.count) * 0.95)
                ) - 1

                let p95 = sorted[p95Index]

                print(
                    String(
                        format:
                            "%@ | %@ | Mean %.3f ms | Median %.3f ms | P95 %.3f ms",
                        workload.rawValue,
                        mode.rawValue,
                        mean,
                        median,
                        p95
                    )
                )
            }
        }

        print("=======================================")
        print("PASS: Multi-workload benchmark completed")
    }

    // MARK: - Balanced Execution Order

    private func orderedModes(
        round: Int
    ) -> [Mode] {

        let modes = Mode.allCases
        let offset = (round - 1) % modes.count

        return Array(modes[offset...])
            + Array(modes[..<offset])
    }

    // MARK: - Single Benchmark Execution

    private func run(
        workload: ResearchWorkload,
        mode: Mode,
        trial: Int,
        inputs: [Int],
        configuration: AdaptiveConcurrencyConfiguration
    ) async throws -> RunResult {

        let clock = ContinuousClock()
        let start = clock.now

        let outputs: [Int]
        let adjustmentCount: Int
        let feedbackWindowCount: Int

        switch mode {

        case .fixed4:

            let executor = try FixedConcurrencyExecutor(
                concurrencyLimit: 4
            )

            outputs = try await executor.execute(
                inputs: inputs
            ) { @Sendable input in
                try await workload.execute(input)
            }

            adjustmentCount = 0
            feedbackWindowCount = 0

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
                try await workload.execute(input)
            }

            outputs = result.results
            adjustmentCount = result.adjustments.count
            feedbackWindowCount = result.feedbackHistory.count
        }

        // Stop timing before validation or CSV work.
        let duration = Self.milliseconds(
            start.duration(to: clock.now)
        )

        let throughput = duration > 0
            ? Double(outputs.count) / (duration / 1000.0)
            : 0

        let record = Record(
            workload: workload.rawValue,
            trial: trial,
            mode: mode.rawValue,
            durationMS: duration,
            throughput: throughput,
            completedTasks: outputs.count,
            adjustmentCount: adjustmentCount,
            feedbackWindowCount: feedbackWindowCount
        )

        return RunResult(
            record: record,
            outputs: outputs
        )
    }

    // MARK: - Reference Results

    /// Computes expected results before timed runs.
    ///
    /// This avoids repeating expensive reference
    /// calculations between measured trials.
    private func referenceOutputs(
        inputs: [Int],
        workload: ResearchWorkload
    ) async throws -> [Int] {

        var results: [Int] = []
        results.reserveCapacity(inputs.count)

        for input in inputs {
            results.append(
                try await workload.execute(input)
            )
        }

        return results
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

    private func outputDirectory() throws -> URL {

        guard let path = ProcessInfo.processInfo.environment[
            "BENCHMARK_OUTPUT_DIR"
        ], !path.isEmpty else {

            throw NSError(
                domain: "MultiWorkloadBenchmark",
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
        _ records: [Record]
    ) -> String {

        var lines = [
            [
                "workload",
                "trial",
                "configuration",
                "duration_ms",
                "throughput_tasks_per_second",
                "completed_tasks",
                "adjustment_count",
                "feedback_window_count"
            ].joined(separator: ",")
        ]

        for record in records {

            let row = [
                record.workload,
                String(record.trial),
                record.mode,
                Self.format(record.durationMS),
                Self.format(record.throughput),
                String(record.completedTasks),
                String(record.adjustmentCount),
                String(record.feedbackWindowCount)
            ]

            lines.append(
                row.joined(separator: ",")
            )
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
