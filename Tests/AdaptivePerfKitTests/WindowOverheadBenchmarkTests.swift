
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class WindowOverheadBenchmarkTests: XCTestCase {

    // MARK: - Execution Modes

    private enum Mode: String, CaseIterable, Sendable {
        case fixedContinuous
        case fixedWindowed
        case adaptiveV2
    }

    // MARK: - Benchmark Record

    private struct Record {
        let workload: String
        let trial: Int
        let configuration: String
        let durationMS: Double
        let throughput: Double
        let completedTasks: Int
        let windowCount: Int
        let adjustmentCount: Int
        let actualChangeCount: Int
    }

    private struct RunResult {
        let record: Record
        let outputs: [Int]
    }

    // MARK: - Experiment Settings

    private let taskCount = 100
    private let windowSize = 10
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

    func testWindowOverheadBenchmark() async throws {

        guard ProcessInfo.processInfo.environment[
            "RUN_WINDOW_OVERHEAD_BENCHMARK"
        ] == "1" else {
            throw XCTSkip(
                "Set RUN_WINDOW_OVERHEAD_BENCHMARK=1"
            )
        }

        let config = try configuration()
        let inputs = Array(0..<taskCount)
        let directory = try outputDirectory()

        var records: [Record] = []

        print("========================================")
        print("AdaptivePerfKit Window Overhead Benchmark")
        print("========================================")
        print("Tasks: \(taskCount)")
        print("Window size: \(windowSize)")
        print("Warm-up rounds: \(warmupRounds)")
        print("Measured rounds: \(measuredRounds)")

        for workload in ResearchWorkload.allCases {

            print("")
            print("Starting workload: \(workload.rawValue)")

            // Reference outputs are computed once
            // before warm-up and measured executions.
            let expected = try await referenceOutputs(
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
                        expected,
                        "Warm-up output mismatch"
                    )
                }
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

                    XCTAssertEqual(
                        result.outputs,
                        expected,
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

            print("Completed: \(workload.rawValue)")
        }

        // MARK: - Dataset Validation

        let expectedCount =
            ResearchWorkload.allCases.count
            * Mode.allCases.count
            * measuredRounds

        XCTAssertEqual(records.count, expectedCount)

        for workload in ResearchWorkload.allCases {
            for mode in Mode.allCases {

                let subset = records.filter {
                    $0.workload == workload.rawValue
                    && $0.configuration == mode.rawValue
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

        // MARK: - CSV Export

        let csvURL = directory.appendingPathComponent(
            "window_overhead_270_trials.csv"
        )

        try makeCSV(records).write(
            to: csvURL,
            atomically: true,
            encoding: .utf8
        )

        print("")
        print("CSV exported: \(csvURL.path)")
        print("Total measured executions: \(records.count)")

        // MARK: - Summary

        print("")
        print("========== BENCHMARK SUMMARY ==========")

        for workload in ResearchWorkload.allCases {

            for mode in Mode.allCases {

                let durations = records
                    .filter {
                        $0.workload == workload.rawValue
                        && $0.configuration == mode.rawValue
                    }
                    .map(\.durationMS)

                let sorted = durations.sorted()

                let mean = durations.reduce(0, +)
                    / Double(durations.count)

                let median =
                    (sorted[14] + sorted[15]) / 2.0

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
        print("PASS: Window overhead benchmark completed")
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

    // MARK: - Single Execution

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
        let windows: Int
        let adjustments: Int
        let changes: Int

        switch mode {

        // A: Fixed concurrency across all 100 tasks.
        case .fixedContinuous:

            let executor = try FixedConcurrencyExecutor(
                concurrencyLimit: 4
            )

            outputs = try await executor.execute(
                inputs: inputs
            ) { @Sendable input in
                try await workload.execute(input)
            }

            windows = 1
            adjustments = 0
            changes = 0

        // B: Fixed concurrency 4, but split into
        // ten separate 10-task execution windows.
        case .fixedWindowed:

            let executor = try FixedConcurrencyExecutor(
                concurrencyLimit: 4
            )

            var collected: [Int] = []
            collected.reserveCapacity(inputs.count)

            var index = 0
            var count = 0

            while index < inputs.count {

                try Task.checkCancellation()

                let end = min(
                    index + windowSize,
                    inputs.count
                )

                let batch = Array(inputs[index..<end])

                let batchResults = try await executor.execute(
                    inputs: batch
                ) { @Sendable input in
                    try await workload.execute(input)
                }

                collected.append(contentsOf: batchResults)

                index = end
                count += 1
            }

            outputs = collected
            windows = count
            adjustments = 0
            changes = 0

        // C: Existing Adaptive V2 implementation.
        case .adaptiveV2:

            let executor = VersionedAdaptiveExecutor(
                configuration: configuration,
                version: .v2
            )

            let result = try await executor.execute(
                inputs: inputs
            ) { @Sendable input in
                try await workload.execute(input)
            }

            outputs = result.results
            windows = result.feedbackHistory.count
            adjustments = result.adjustments.count

            changes = result.adjustments.filter {
                $0.previousConcurrency
                    != $0.newConcurrency
            }.count
        }

        // Stop timing before output validation,
        // reporting, or CSV construction.
        let duration = Self.milliseconds(
            start.duration(to: clock.now)
        )

        let throughput = duration > 0
            ? Double(outputs.count) / (duration / 1000.0)
            : 0

        let record = Record(
            workload: workload.rawValue,
            trial: trial,
            configuration: mode.rawValue,
            durationMS: duration,
            throughput: throughput,
            completedTasks: outputs.count,
            windowCount: windows,
            adjustmentCount: adjustments,
            actualChangeCount: changes
        )

        return RunResult(
            record: record,
            outputs: outputs
        )
    }

    // MARK: - Reference Results

    private func referenceOutputs(
        inputs: [Int],
        workload: ResearchWorkload
    ) async throws -> [Int] {

        var values: [Int] = []
        values.reserveCapacity(inputs.count)

        for input in inputs {
            values.append(
                try await workload.execute(input)
            )
        }

        return values
    }

    // MARK: - Time Conversion

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
                domain: "WindowOverheadBenchmark",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "BENCHMARK_OUTPUT_DIR is required"
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
                "window_count",
                "adjustment_count",
                "actual_change_count"
            ].joined(separator: ",")
        ]

        for record in records {

            lines.append(
                [
                    record.workload,
                    String(record.trial),
                    record.configuration,
                    Self.format(record.durationMS),
                    Self.format(record.throughput),
                    String(record.completedTasks),
                    String(record.windowCount),
                    String(record.adjustmentCount),
                    String(record.actualChangeCount)
                ].joined(separator: ",")
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
