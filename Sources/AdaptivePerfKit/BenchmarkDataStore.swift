//
//  BenchmarkDataStore.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation

/// A concurrency-safe store for benchmark records.
public actor BenchmarkDataStore {

    private var records: [BenchmarkRecord] = []

    private let persistence: BenchmarkPersistence?

    /// Creates a benchmark data store.
    ///
    /// Pass a persistence instance to enable
    /// explicit saving and loading from disk.
    public init(
        persistence: BenchmarkPersistence? = nil
    ) {
        self.persistence = persistence
    }

    // MARK: - Add Records

    public func add(_ record: BenchmarkRecord) {
        records.append(record)
    }

    public func add(
        contentsOf newRecords: [BenchmarkRecord]
    ) {
        records.append(contentsOf: newRecords)
    }

    // MARK: - Retrieve Records

    public func getAllRecords() -> [BenchmarkRecord] {
        records
    }

    public func getRecords(
        for batchID: UUID
    ) -> [BenchmarkRecord] {
        records.filter {
            $0.batchID == batchID
        }
    }

    public func getRecords(
        forWorkload workloadName: String
    ) -> [BenchmarkRecord] {
        records.filter {
            $0.workloadName == workloadName
        }
    }

    // MARK: - Summary

    public func getRecordCount() -> Int {
        records.count
    }

    public func getBatchCount() -> Int {
        Set(records.map(\.batchID)).count
    }

    // MARK: - Remove Records

    public func removeRecords(
        for batchID: UUID
    ) {
        records.removeAll {
            $0.batchID == batchID
        }
    }

    public func removeAllRecords() {
        records.removeAll()
    }

    // MARK: - Persistence

    /// Saves the current in-memory snapshot to disk.
    public func saveToDisk() throws {

        guard let persistence else {
            throw BenchmarkStoreError.persistenceNotConfigured
        }

        try persistence.save(records: records)
    }

    /// Restores previously saved records from disk.
    ///
    /// Replaces the current in-memory records.
    public func loadFromDisk() throws {

        guard let persistence else {
            throw BenchmarkStoreError.persistenceNotConfigured
        }

        records = try persistence.load()
    }
}

// MARK: - Store Errors

public enum BenchmarkStoreError: Error, Sendable {
    case persistenceNotConfigured
}
