//
//  BenchmarkRecord.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation

/// Identifies the environment used for a benchmark.
public struct BenchmarkEnvironment: Codable, Sendable {

    public let deviceModel: String
    public let operatingSystem: String
    public let sdkVersion: String
    public let isSimulator: Bool

    public init(
        deviceModel: String,
        operatingSystem: String,
        sdkVersion: String,
        isSimulator: Bool
    ) {
        self.deviceModel = deviceModel
        self.operatingSystem = operatingSystem
        self.sdkVersion = sdkVersion
        self.isSimulator = isSimulator
    }
}

/// Represents a single benchmark execution.
public struct BenchmarkRecord: Identifiable, Codable, Sendable {

    public let id: UUID
    public let batchID: UUID
    public let runNumber: Int
    public let workloadName: String
    public let durationMilliseconds: Double
    public let timestamp: Date
    public let environment: BenchmarkEnvironment

    public init(
        id: UUID = UUID(),
        batchID: UUID,
        runNumber: Int,
        workloadName: String,
        durationMilliseconds: Double,
        timestamp: Date,
        environment: BenchmarkEnvironment
    ) {
        self.id = id
        self.batchID = batchID
        self.runNumber = runNumber
        self.workloadName = workloadName
        self.durationMilliseconds = durationMilliseconds
        self.timestamp = timestamp
        self.environment = environment
    }
}
