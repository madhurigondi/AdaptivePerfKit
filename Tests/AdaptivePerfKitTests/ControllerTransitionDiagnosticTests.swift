
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class ControllerTransitionDiagnosticTests: XCTestCase {

    private struct DiagnosticRecord {
        let workload: String
        let version: String
        let trial: Int
        let window: Int
        let previousConcurrency: Int
        let nextConcurrency: Int
        let decision: String
        let throughput: Double
        let meanLatencyMS: Double
        let elapsedMS: Double
        let completedTasks: Int
        let changed: Bool
    }

    private let taskCount = 100
    private let trials = 30
    private let warmupRounds = 3

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

    func testControllerTransitions() async throws {

        guard ProcessInfo.processInfo.environment[
            "RUN_CONTROLLER_DIAGNOSTICS"
        ] == "1" else {
            throw XCTSkip(
                "Set RUN_CONTROLLER_DIAGNOSTICS=1"
            )
        }

        let config = try configuration()
        let inputs = Array(0..<taskCount)

        var records: [DiagnosticRecord] = []

        for workload in ResearchWorkload.allCases {

            print("Starting: \(workload.rawValue)")

            for version in AdaptiveControllerVersion.allCases {

                let executor = VersionedAdaptiveExecutor(
                    configuration: config,
                    version: version
                )

                // Warm-up runs are excluded from the CSV.
                for _ in 0..<warmupRounds {
                    let warmup = try await executor.execute(
                        inputs: inputs
                    ) { @Sendable input in
                        try await workload.execute(input)
                    }

                    XCTAssertEqual(
                        warmup.results.count,
                        taskCount
                    )
                }

                for trial in 1...trials {

                    let result = try await executor.execute(
                        inputs: inputs
                    ) { @Sendable input in
                        try await workload.execute(input)
                    }

                    XCTAssertEqual(
                        result.results.count,
                        taskCount
                    )

                    XCTAssertEqual(
                        result.adjustments.count,
                        result.feedbackHistory.count
                    )

                    XCTAssertEqual(
                        result.adjustments.count,
                        10
                    )

                    for (index, adjustment)
                        in result.adjustments.enumerated() {

                        let feedback =
                            result.feedbackHistory[index]

                        XCTAssertEqual(
                            adjustment.previousConcurrency,
                            feedback.concurrencyLimit
                        )

                        let changed =
                            adjustment.previousConcurrency
                            != adjustment.newConcurrency

                        records.append(
                            DiagnosticRecord(
                                workload: workload.rawValue,
                                version: version.rawValue,
                                trial: trial,
                                window: index + 1,
                                previousConcurrency:
                                    adjustment.previousConcurrency,
                                nextConcurrency:
                                    adjustment.newConcurrency,
                                decision:
                                    adjustment.decision.rawValue,
                                throughput:
                                    feedback.throughput,
                                meanLatencyMS:
                                    feedback.meanLatencyMilliseconds,
                                elapsedMS:
                                    feedback.elapsedMilliseconds,
                                completedTasks:
                                    feedback.completedTaskCount,
                                changed: changed
                            )
                        )
                    }
                }

                print(
                    "Completed \(workload.rawValue) / " +
                    "\(version.rawValue)"
                )
            }
        }

        // 3 workloads x 2 versions x 30 trials
        // x 10 measurement windows.
        XCTAssertEqual(records.count, 1800)

        let directory = try outputDirectory()

        let csvURL = directory.appendingPathComponent(
            "controller_transitions_1800_windows.csv"
        )

        try makeCSV(records).write(
            to: csvURL,
            atomically: true,
            encoding: .utf8
        )

        print("CSV exported: \(csvURL.path)")
        print("Total windows: \(records.count)")
        print("PASS: Controller transitions exported")
    }

    private func outputDirectory() throws -> URL {

        guard let path = ProcessInfo.processInfo.environment[
            "BENCHMARK_OUTPUT_DIR"
        ], !path.isEmpty else {
            throw NSError(
                domain: "ControllerTransitionDiagnostics",
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

    private func makeCSV(
        _ records: [DiagnosticRecord]
    ) -> String {

        var lines = [
            [
                "workload",
                "version",
                "trial",
                "window",
                "previous_concurrency",
                "next_concurrency",
                "decision",
                "throughput_tasks_per_second",
                "mean_latency_ms",
                "elapsed_ms",
                "completed_tasks",
                "changed"
            ].joined(separator: ",")
        ]

        for record in records {

            let row = [
                record.workload,
                record.version,
                String(record.trial),
                String(record.window),
                String(record.previousConcurrency),
                String(record.nextConcurrency),
                record.decision,
                Self.format(record.throughput),
                Self.format(record.meanLatencyMS),
                Self.format(record.elapsedMS),
                String(record.completedTasks),
                record.changed ? "1" : "0"
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
