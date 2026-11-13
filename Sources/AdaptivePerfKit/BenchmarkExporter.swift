//
//  BenchmarkExporter.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation

/// Exports benchmark records for research analysis.
public struct BenchmarkExporter: Sendable {

    public init() {}

    // MARK: - JSON Export

    /// Converts benchmark records to JSON data.
    public func exportJSON(
        records: [BenchmarkRecord]
    ) throws -> Data {

        let encoder = JSONEncoder()

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        encoder.dateEncodingStrategy = .iso8601

        return try encoder.encode(records)
    }

    // MARK: - CSV Export

    /// Converts benchmark records to UTF-8 CSV data.
    public func exportCSV(
        records: [BenchmarkRecord]
    ) -> Data {

        let header = [
            "record_id",
            "batch_id",
            "run_number",
            "workload_name",
            "duration_ms",
            "timestamp",
            "device_model",
            "operating_system",
            "sdk_version",
            "is_simulator"
        ]

        var rows: [[String]] = [header]

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        for record in records {

            let row = [
                record.id.uuidString,
                record.batchID.uuidString,
                String(record.runNumber),
                record.workloadName,
                String(record.durationMilliseconds),
                formatter.string(from: record.timestamp),
                record.environment.deviceModel,
                record.environment.operatingSystem,
                record.environment.sdkVersion,
                String(record.environment.isSimulator)
            ]

            rows.append(row)
        }

        let csv = rows
            .map { row in
                row.map(Self.escapeCSVField)
                    .joined(separator: ",")
            }
            .joined(separator: "\r\n") + "\r\n"

        return Data(csv.utf8)
    }

    // MARK: - CSV Escaping

    /// Escapes commas, quotes, and line breaks.
    private static func escapeCSVField(
        _ value: String
    ) -> String {

        let escaped = value.replacingOccurrences(
            of: "\"",
            with: "\"\""
        )

        if value.contains(",") ||
           value.contains("\"") ||
           value.contains("\n") ||
           value.contains("\r") {

            return "\"\(escaped)\""
        }

        return escaped
    }
}
