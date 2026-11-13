//
//  BenchmarkPersistence.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation

/// Provides persistent JSON storage for benchmark records.
public struct BenchmarkPersistence: Sendable {

    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    // MARK: - Save

    /// Saves a complete snapshot of benchmark records.
    /// Replaces the previous snapshot atomically.
    public func save(
        records: [BenchmarkRecord]
    ) throws {

        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(records)

        let directory = fileURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        try data.write(
            to: fileURL,
            options: .atomic
        )
    }

    // MARK: - Load

    /// Loads previously saved records.
    /// Returns an empty array if no file exists yet.
    public func load() throws -> [BenchmarkRecord] {

        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(
            [BenchmarkRecord].self,
            from: data
        )
    }
}
