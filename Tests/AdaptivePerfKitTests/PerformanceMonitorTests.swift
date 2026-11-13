//
//  PerformanceMonitorTests.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation
import Testing
@testable import AdaptivePerfKit

@Suite("Performance Monitor Tests")
struct PerformanceMonitorTests {

    @Test("Measures asynchronous execution")
    func testAsyncMeasurement() async throws {

        let monitor = PerformanceMonitor()

        let (result, measurement) =
            try await monitor.measure(
                operationName: "Async Test"
            ) {
                try await Task.sleep(
                    for: .milliseconds(100)
                )

                return 42
            }

        #expect(result == 42)

        #expect(
            measurement.operationName == "Async Test"
        )

        #expect(
            measurement.durationMilliseconds >= 50
        )

        #expect(
            measurement.durationMilliseconds.isFinite
        )
    }

    @Test("Measures immediate operations")
    func testImmediateOperation() async throws {

        let monitor = PerformanceMonitor()

        let (result, measurement) =
            try await monitor.measure(
                operationName: "Immediate Test"
            ) {
                return 100
            }

        #expect(result == 100)

        #expect(
            measurement.durationMilliseconds >= 0
        )

        #expect(
            measurement.durationMilliseconds.isFinite
        )
    }

    @Test("Propagates operation errors")
    func testOperationError() async {

        let monitor = PerformanceMonitor()

        do {
            let _ = try await monitor.measure(
                operationName: "Failure Test"
            ) { () async throws -> Int in

                throw TestOperationError.expectedFailure
            }

            Issue.record("Expected operation to throw")

        } catch TestOperationError.expectedFailure {
            // Expected behavior.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private enum TestOperationError: Error {
    case expectedFailure
}
