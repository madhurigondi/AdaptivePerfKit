//
//  BenchmarkDataStoreTests.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation
import Testing
@testable import AdaptivePerfKit

@Suite("Benchmark Data Store Tests")
struct BenchmarkDataStoreTests {

    private func makeRecord(
        batchID: UUID,
        runNumber: Int,
        workloadName: String = "CPU Benchmark"
    ) -> BenchmarkRecord {

        BenchmarkRecord(
            batchID: batchID,
            runNumber: runNumber,
            workloadName: workloadName,
            durationMilliseconds: Double(runNumber * 100),
            timestamp: Date(
                timeIntervalSince1970: 1_700_000_000
            ),
            environment: BenchmarkEnvironment(
                deviceModel: "Test Simulator",
                operatingSystem: "iOS Test",
                sdkVersion: "0.1.0",
                isSimulator: true
            )
        )
    }

    @Test("Adds and counts records")
    func testAddRecords() async {

        let store = BenchmarkDataStore()
        let batchID = UUID()

        await store.add(
            makeRecord(batchID: batchID, runNumber: 1)
        )

        await store.add(
            makeRecord(batchID: batchID, runNumber: 2)
        )

        let count = await store.getRecordCount()
        let batches = await store.getBatchCount()

        #expect(count == 2)
        #expect(batches == 1)
    }

    @Test("Counts separate batches")
    func testBatchCount() async {

        let store = BenchmarkDataStore()

        await store.add(
            makeRecord(batchID: UUID(), runNumber: 1)
        )

        await store.add(
            makeRecord(batchID: UUID(), runNumber: 1)
        )

        let count = await store.getBatchCount()

        #expect(count == 2)
    }

    @Test("Filters records by batch")
    func testBatchFiltering() async {

        let store = BenchmarkDataStore()

        let batchA = UUID()
        let batchB = UUID()

        await store.add(
            makeRecord(batchID: batchA, runNumber: 1)
        )

        await store.add(
            makeRecord(batchID: batchA, runNumber: 2)
        )

        await store.add(
            makeRecord(batchID: batchB, runNumber: 1)
        )

        let records = await store.getRecords(
            for: batchA
        )

        #expect(records.count == 2)

        #expect(
            records.allSatisfy { $0.batchID == batchA }
        )
    }

    @Test("Filters records by workload")
    func testWorkloadFiltering() async {

        let store = BenchmarkDataStore()
        let batchID = UUID()

        await store.add(
            makeRecord(
                batchID: batchID,
                runNumber: 1,
                workloadName: "CPU Benchmark"
            )
        )

        await store.add(
            makeRecord(
                batchID: batchID,
                runNumber: 2,
                workloadName: "JSON Parsing"
            )
        )

        let records = await store.getRecords(
            forWorkload: "CPU Benchmark"
        )

        #expect(records.count == 1)
        #expect(records[0].workloadName == "CPU Benchmark")
    }

    @Test("Removes a specific batch")
    func testRemoveBatch() async {

        let store = BenchmarkDataStore()

        let batchA = UUID()
        let batchB = UUID()

        await store.add(
            makeRecord(batchID: batchA, runNumber: 1)
        )

        await store.add(
            makeRecord(batchID: batchB, runNumber: 1)
        )

        await store.removeRecords(for: batchA)

        let count = await store.getRecordCount()
        let batches = await store.getBatchCount()

        #expect(count == 1)
        #expect(batches == 1)
    }

    @Test("Removes all records")
    func testRemoveAllRecords() async {

        let store = BenchmarkDataStore()

        await store.add(
            makeRecord(batchID: UUID(), runNumber: 1)
        )

        await store.removeAllRecords()

        let count = await store.getRecordCount()
        let batches = await store.getBatchCount()

        #expect(count == 0)
        #expect(batches == 0)
    }
}
