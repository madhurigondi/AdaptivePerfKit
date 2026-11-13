//
//  BenchmarkStatisticsTests.swift
//  AdaptivePerfKit
//
//  Created by Madhuri Latha Gondi on 11/12/26.
//


import Foundation
import Testing
@testable import AdaptivePerfKit

@Suite("Benchmark Statistics Tests")
struct BenchmarkStatisticsTests {

    // MARK: - Helpers

    private func makeMeasurements(
        _ durations: [Double]
    ) -> [PerformanceMeasurement] {

        durations.map { duration in
            PerformanceMeasurement(
                operationName: "CPU Benchmark",
                durationMilliseconds: duration,
                timestamp: Date(
                    timeIntervalSince1970: 1_700_000_000
                )
            )
        }
    }

    // MARK: - Basic Statistics

    @Test("Calculates average, minimum and maximum")
    func testBasicStatistics() throws {

        let measurements = makeMeasurements([
            100, 200, 300, 400, 500
        ])

        let stats = try #require(
            BenchmarkStatistics(measurements: measurements)
        )

        #expect(stats.sampleCount == 5)
        #expect(stats.averageMilliseconds == 300)
        #expect(stats.minimumMilliseconds == 100)
        #expect(stats.maximumMilliseconds == 500)
    }

    // MARK: - Median

    @Test("Calculates median for odd sample count")
    func testOddMedian() throws {

        let stats = try #require(
            BenchmarkStatistics(
                measurements: makeMeasurements([
                    300, 100, 500, 200, 400
                ])
            )
        )

        #expect(stats.medianMilliseconds == 300)
    }

    @Test("Calculates median for even sample count")
    func testEvenMedian() throws {

        let stats = try #require(
            BenchmarkStatistics(
                measurements: makeMeasurements([
                    100, 200, 300, 400
                ])
            )
        )

        #expect(stats.medianMilliseconds == 250)
    }

    // MARK: - P95

    @Test("Calculates nearest-rank P95")
    func testP95() throws {

        let durations = (1...100).map {
            Double($0)
        }

        let stats = try #require(
            BenchmarkStatistics(
                measurements: makeMeasurements(durations)
            )
        )

        #expect(stats.p95Milliseconds == 95)
    }

    // MARK: - Edge Cases

    @Test("Handles a single measurement")
    func testSingleMeasurement() throws {

        let stats = try #require(
            BenchmarkStatistics(
                measurements: makeMeasurements([125])
            )
        )

        #expect(stats.sampleCount == 1)
        #expect(stats.averageMilliseconds == 125)
        #expect(stats.minimumMilliseconds == 125)
        #expect(stats.maximumMilliseconds == 125)
        #expect(stats.medianMilliseconds == 125)
        #expect(stats.p95Milliseconds == 125)
    }

    @Test("Returns nil for empty measurements")
    func testEmptyMeasurements() {

        let stats = BenchmarkStatistics(
            measurements: []
        )

        #expect(stats == nil)
    }

    @Test("Filters invalid measurements")
    func testInvalidMeasurements() throws {

        let stats = try #require(
            BenchmarkStatistics(
                measurements: makeMeasurements([
                    100,
                    -50,
                    .nan,
                    .infinity,
                    200
                ])
            )
        )

        #expect(stats.sampleCount == 2)
        #expect(stats.averageMilliseconds == 150)
        #expect(stats.minimumMilliseconds == 100)
        #expect(stats.maximumMilliseconds == 200)
    }

    @Test("Handles zero duration")
    func testZeroDuration() throws {

        let stats = try #require(
            BenchmarkStatistics(
                measurements: makeMeasurements([
                    0, 10, 20
                ])
            )
        )

        #expect(stats.sampleCount == 3)
        #expect(stats.minimumMilliseconds == 0)
        #expect(stats.averageMilliseconds == 10)
    }
}
