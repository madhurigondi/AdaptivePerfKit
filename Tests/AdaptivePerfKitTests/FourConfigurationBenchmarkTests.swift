
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class FourConfigurationBenchmarkTests: XCTestCase {

    private enum Mode: String, CaseIterable, Sendable {
        case fixed4
        case adaptiveV1
        case adaptiveV2
        case adaptiveV3
    }

    private struct Record {
        let workload: String
        let configuration: String
        let trial: Int
        let durationMS: Double
        let throughput: Double
        let completedTasks: Int
        let feedbackWindows: Int
        let adjustmentCount: Int
        let actualChanges: Int
    }

    private struct RunResult {
        let outputs: [Int]
        let feedbackWindows: Int
        let adjustmentCount: Int
        let actualChanges: Int
    }

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

    func testFourConfigurationBenchmark() async throws {

        guard ProcessInfo.processInfo.environment[
            "RUN_FOUR_CONFIGURATION_BENCHMARK"
        ] == "1" else {
            throw XCTSkip(
                "Set RUN_FOUR_CONFIGURATION_BENCHMARK=1"
            )
        }

        let config = try configuration()
        let inputs = Array(0..<taskCount)
        let directory = try outputDirectory()

        var records: [Record] = []

        print("FOUR-CONFIGURATION BENCHMARK STARTED")

        for workload in ResearchWorkload.allCases {

            // Verify reference output outside timed runs.
            var expected: [Int] = []

            for input in inputs {
                expected.append(
                    try await workload.execute(input)
                )
            }

            // Warm-up rounds are not recorded.
            for round in 1...warmupRounds {

                for mode in orderedModes(round: round) {

                    let result = try await execute(
                        mode: mode,
                        workload: workload,
                        inputs: inputs,
                        configuration: config
                    )

                    XCTAssertEqual(
                        result.outputs,
                        expected
                    )
                }
            }

            // Measured experimental rounds.
            for trial in 1...measuredRounds {

                for mode in orderedModes(round: trial) {

                    let clock = ContinuousClock()
                    let start = clock.now

                    let result = try await execute(
                        mode: mode,
                        workload: workload,
                        inputs: inputs,
                        configuration: config
                    )

                    let duration = Self.milliseconds(
                        start.duration(to: clock.now)
                    )

                    XCTAssertEqual(
                        result.outputs,
                        expected
                    )

                    XCTAssertGreaterThan(duration, 0)

                    XCTAssertEqual(
                        result.outputs.count,
                        taskCount
                    )

                    let throughput =
                        Double(taskCount) / (duration / 1000)

                    let record = Record(
                        workload: workload.rawValue,
                        configuration: mode.rawValue,
                        trial: trial,
                        durationMS: duration,
                        throughput: throughput,
                        completedTasks: taskCount,
                        feedbackWindows:
                            result.feedbackWindows,
                        adjustmentCount:
                            result.adjustmentCount,
                        actualChanges:
                            result.actualChanges
                    )

                    records.append(record)

                    print(
                        String(
                            format:
                                "%@ | %@ | Trial %02d | %.3f ms",
                            workload.rawValue,
                            mode.rawValue,
                            trial,
                            duration
                        )
                    )
                }
            }

            print("Completed workload: \(workload.rawValue)")
        }

        XCTAssertEqual(records.count, 360)

        for workload in ResearchWorkload.allCases {
            for mode in Mode.allCases {

                let subset = records.filter {
                    $0.workload == workload.rawValue &&
                    $0.configuration == mode.rawValue
                }

                XCTAssertEqual(subset.count, 30)

                XCTAssertEqual(
                    subset.map(\.trial).sorted(),
                    Array(1...30)
                )
            }
        }

        let url = directory.appendingPathComponent(
            "four_configuration_360_trials.csv"
        )

        try makeCSV(records).write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        print("")
        print("Total measured executions: \(records.count)")
        print("CSV exported: \(url.path)")
        print("PASS: 360-trial benchmark completed")
    }

    // MARK: - Execution

    private func execute(
        mode: Mode,
        workload: ResearchWorkload,
        inputs: [Int],
        configuration: AdaptiveConcurrencyConfiguration
    ) async throws -> RunResult {

        switch mode {

        case .fixed4:

            let executor = try FixedConcurrencyExecutor(
                concurrencyLimit: 4
            )

            let outputs = try await executor.execute(
                inputs: inputs
            ) { @Sendable input in
                try await workload.execute(input)
            }

            return RunResult(
                outputs: outputs,
                feedbackWindows: 0,
                adjustmentCount: 0,
                actualChanges: 0
            )

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

            return RunResult(
                outputs: result.results,
                feedbackWindows: result.feedbackHistory.count,
                adjustmentCount: result.adjustments.count,
                actualChanges: result.adjustments.filter {
                    $0.previousConcurrency != $0.newConcurrency
                }.count
            )

        case .adaptiveV3:

            let executor = ContinuousAdaptiveExecutor(
                configuration: configuration
            )

            let result = try await executor.execute(
                inputs: inputs
            ) { @Sendable input in
                try await workload.execute(input)
            }

            return RunResult(
                outputs: result.results,
                feedbackWindows: result.feedbackHistory.count,
                adjustmentCount: result.adjustments.count,
                actualChanges: result.adjustments.filter {
                    $0.previousConcurrency != $0.newConcurrency
                }.count
            )
        }
    }

    // MARK: - Rotated Execution Order

    private func orderedModes(
        round: Int
    ) -> [Mode] {

        let modes = Mode.allCases
        let offset = (round - 1) % modes.count

        return Array(modes[offset...])
            + Array(modes[..<offset])
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
                domain: "FourConfigurationBenchmark",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "BENCHMARK_OUTPUT_DIR is required"
                ]
            )
        }

        let url = URL(
            fileURLWithPath: path,
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )

        return url
    }

    // MARK: - CSV Export

    private func makeCSV(
        _ records: [Record]
    ) -> String {

        var lines = [
            [
                "workload",
                "configuration",
                "trial",
                "duration_ms",
                "throughput_tasks_per_second",
                "completed_tasks",
                "feedback_windows",
                "adjustment_count",
                "actual_changes"
            ].joined(separator: ",")
        ]

        for record in records {

            let row = [
                record.workload,
                record.configuration,
                String(record.trial),
                Self.format(record.durationMS),
                Self.format(record.throughput),
                String(record.completedTasks),
                String(record.feedbackWindows),
                String(record.adjustmentCount),
                String(record.actualChanges)
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
