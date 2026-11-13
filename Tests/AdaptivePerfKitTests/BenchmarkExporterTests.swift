//
//  BenchmarkExporterTests.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation
import Testing
@testable import AdaptivePerfKit

@Suite("Benchmark Exporter Tests")
struct BenchmarkExporterTests {

    // MARK: - Test Data

    private func makeRecords(
        count: Int = 5,
        workloadName: String = "CPU Benchmark"
    ) -> [BenchmarkRecord] {

        let batchID = UUID()

        let environment = BenchmarkEnvironment(
            deviceModel: "iPhone Simulator",
            operatingSystem: "iOS 26",
            sdkVersion: "0.1.0",
            isSimulator: true
        )

        return (1...count).map { run in
            BenchmarkRecord(
                batchID: batchID,
                runNumber: run,
                workloadName: workloadName,
                durationMilliseconds:
                    Double(run) * 125.5,
                timestamp: Date(
                    timeIntervalSince1970:
                        1_700_000_000 + Double(run)
                ),
                environment: environment
            )
        }
    }

    // MARK: - JSON Tests

    @Test("Exports valid JSON")
    func testJSONExport() throws {

        let records = makeRecords()
        let exporter = BenchmarkExporter()

        let data = try exporter.exportJSON(
            records: records
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(
            [BenchmarkRecord].self,
            from: data
        )

        #expect(decoded.count == 5)
    }

    @Test("JSON preserves measurement values")
    func testJSONIntegrity() throws {

        let records = makeRecords()
        let exporter = BenchmarkExporter()

        let data = try exporter.exportJSON(
            records: records
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(
            [BenchmarkRecord].self,
            from: data
        )

        for (original, restored) in zip(
            records,
            decoded
        ) {
            #expect(original.id == restored.id)
            #expect(original.batchID == restored.batchID)
            #expect(original.runNumber == restored.runNumber)

            #expect(
                original.durationMilliseconds ==
                restored.durationMilliseconds
            )

            #expect(
                original.workloadName ==
                restored.workloadName
            )

            #expect(
                original.timestamp ==
                restored.timestamp
            )

            #expect(
                original.environment.sdkVersion ==
                restored.environment.sdkVersion
            )

            #expect(
                original.environment.isSimulator ==
                restored.environment.isSimulator
            )
        }
    }

    @Test("Exports an empty JSON array")
    func testEmptyJSON() throws {

        let exporter = BenchmarkExporter()

        let data = try exporter.exportJSON(
            records: []
        )

        let decoded = try JSONDecoder().decode(
            [BenchmarkRecord].self,
            from: data
        )

        #expect(decoded.isEmpty)
    }

    // MARK: - CSV Tests

    @Test("CSV contains header and five data rows")
    func testCSVRowCount() throws {

        let exporter = BenchmarkExporter()

        let data = exporter.exportCSV(
            records: makeRecords()
        )

        let csv = try #require(
            String(data: data, encoding: .utf8)
        )

        let lines = csv.components(
            separatedBy: "\r\n"
        ).filter { !$0.isEmpty }

        #expect(lines.count == 6)
    }

    @Test("CSV includes required research columns")
    func testCSVHeaders() throws {

        let exporter = BenchmarkExporter()

        let data = exporter.exportCSV(
            records: makeRecords()
        )

        let csv = try #require(
            String(data: data, encoding: .utf8)
        )

        let header = try #require(
            csv.components(separatedBy: "\r\n").first
        )

        let columns = header.components(
            separatedBy: ","
        )

        #expect(columns.contains("record_id"))
        #expect(columns.contains("batch_id"))
        #expect(columns.contains("run_number"))
        #expect(columns.contains("duration_ms"))
        #expect(columns.contains("timestamp"))
        #expect(columns.contains("is_simulator"))
    }

    @Test("CSV escapes commas and quotes")
    func testCSVEscaping() throws {

        let exporter = BenchmarkExporter()

        let records = makeRecords(
            count: 1,
            workloadName: "CPU, \"Heavy\" Benchmark"
        )

        let data = exporter.exportCSV(
            records: records
        )

        let csv = try #require(
            String(data: data, encoding: .utf8)
        )

        #expect(
            csv.contains(
                "\"CPU, \"\"Heavy\"\" Benchmark\""
            )
        )
    }

    @Test("CSV preserves duration values")
    func testCSVDurations() throws {

        let exporter = BenchmarkExporter()

        let records = makeRecords(count: 3)

        let data = exporter.exportCSV(
            records: records
        )

        let csv = try #require(
            String(data: data, encoding: .utf8)
        )

        for record in records {
            #expect(
                csv.contains(
                    String(record.durationMilliseconds)
                )
            )
        }
    }

    @Test("Empty CSV contains only headers")
    func testEmptyCSV() throws {

        let exporter = BenchmarkExporter()

        let data = exporter.exportCSV(
            records: []
        )

        let csv = try #require(
            String(data: data, encoding: .utf8)
        )

        let lines = csv.components(
            separatedBy: "\r\n"
        ).filter { !$0.isEmpty }

        #expect(lines.count == 1)
        #expect(csv.contains("record_id"))
    }
}
