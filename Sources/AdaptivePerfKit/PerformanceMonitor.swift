//
//  PerformanceMonitor.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation

/// Represents the measured execution time of an operation.
public struct PerformanceMeasurement: Sendable {

    public let operationName: String
    public let durationMilliseconds: Double
    public let timestamp: Date

    public init(
        operationName: String,
        durationMilliseconds: Double,
        timestamp: Date
    ) {
        self.operationName = operationName
        self.durationMilliseconds = durationMilliseconds
        self.timestamp = timestamp
    }
}

/// Measures the execution duration of asynchronous operations.
public struct PerformanceMonitor: Sendable {

    public init() {}

    public func measure<T: Sendable>(
        operationName: String,
        operation: @Sendable () async throws -> T
    ) async throws -> (result: T, measurement: PerformanceMeasurement) {

        let clock = ContinuousClock()
        let start = clock.now

        let result = try await operation()

        let elapsed = start.duration(to: clock.now)
        let components = elapsed.components

        let milliseconds =
            Double(components.seconds) * 1_000 +
            Double(components.attoseconds) / 1_000_000_000_000_000

        let measurement = PerformanceMeasurement(
            operationName: operationName,
            durationMilliseconds: milliseconds,
            timestamp: Date()
        )

        return (result, measurement)
    }
}
