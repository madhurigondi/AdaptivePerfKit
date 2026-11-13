//
//  BenchmarkPersistenceTests.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation
import Testing
@testable import AdaptivePerfKit

@Suite("Benchmark Persistence Integrity Tests")
struct BenchmarkPersistenceTests {

    @Test("Records survive save and reload")
    func testSaveAndRestore() async throws {

        let directory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let fileURL = directory.appendingPathComponent(
            "benchmark_records.json"
        )

        let persistence = BenchmarkPersistence(
            fileURL: fileURL
        )

        let originalStore = BenchmarkDataStore(
            persistence: persistence
        )

        let batchID = UUID()

        let environment = BenchmarkEnvironment(
            deviceModel: "Test Simulator",
            operatingSystem: "iOS Test",
            sdkVersion: "0.1.0",
            isSimulator: true
        )

        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)

        let originalRecords = (1...5).map { run in
            BenchmarkRecord(
                batchID: batchID,
                runNumber: run,
                workloadName: "CPU Benchmark",
                durationMilliseconds:
                    Double(600 + run * 10),
                timestamp: timestamp,
                environment: environment
            )
        }

        await originalStore.add(
            contentsOf: originalRecords
        )

        try await originalStore.saveToDisk()

        // Simulate a fresh store after app restart.
        let restoredStore = BenchmarkDataStore(
            persistence: persistence
        )

        try await restoredStore.loadFromDisk()

        let restoredRecords =
            await restoredStore.getAllRecords()

        #expect(restoredRecords.count == 5)

        for (original, restored) in zip(
            originalRecords,
            restoredRecords
        ) {
            #expect(original.id == restored.id)
            #expect(original.batchID == restored.batchID)
            #expect(original.runNumber == restored.runNumber)

            #expect(
                original.workloadName ==
                restored.workloadName
            )

            #expect(
                original.durationMilliseconds ==
                restored.durationMilliseconds
            )

            #expect(
                original.timestamp ==
                restored.timestamp
            )

            #expect(
                original.environment.deviceModel ==
                restored.environment.deviceModel
            )

            #expect(
                original.environment.operatingSystem ==
                restored.environment.operatingSystem
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

        let recordCount =
            await restoredStore.getRecordCount()

        let batchCount =
            await restoredStore.getBatchCount()

        #expect(recordCount == 5)
        #expect(batchCount == 1)
    }

    @Test("Missing file returns empty records")
    func testMissingFile() throws {

        let fileURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString
            )
            .appendingPathComponent(
                "missing.json"
            )

        let persistence = BenchmarkPersistence(
            fileURL: fileURL
        )

        let records = try persistence.load()

        #expect(records.isEmpty)
    }

    @Test("Corrupted JSON reports an error")
    func testCorruptedFile() throws {

        let directory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let fileURL = directory.appendingPathComponent(
            "corrupted.json"
        )

        try Data("invalid json".utf8).write(
            to: fileURL
        )

        let persistence = BenchmarkPersistence(
            fileURL: fileURL
        )

        #expect(throws: Error.self) {
            try persistence.load()
        }
    }
}

