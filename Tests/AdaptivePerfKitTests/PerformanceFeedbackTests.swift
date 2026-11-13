
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class PerformanceFeedbackTests: XCTestCase {

    // MARK: - Valid Feedback

    func testValidFeedback() throws {
        let feedback = try PerformanceFeedback(
            completedTaskCount: 20,
            elapsedMilliseconds: 2000,
            meanLatencyMilliseconds: 100,
            concurrencyLimit: 4
        )

        XCTAssertEqual(feedback.completedTaskCount, 20)
        XCTAssertEqual(feedback.elapsedMilliseconds, 2000)
        XCTAssertEqual(feedback.meanLatencyMilliseconds, 100)
        XCTAssertEqual(feedback.concurrencyLimit, 4)
    }

    // MARK: - Throughput

    func testThroughputCalculation() throws {
        let feedback = try PerformanceFeedback(
            completedTaskCount: 20,
            elapsedMilliseconds: 2000,
            meanLatencyMilliseconds: 100,
            concurrencyLimit: 4
        )

        XCTAssertEqual(
            feedback.throughput,
            10.0,
            accuracy: 0.0001
        )
    }

    func testThroughputWithFractionalSeconds() throws {
        let feedback = try PerformanceFeedback(
            completedTaskCount: 15,
            elapsedMilliseconds: 1500,
            meanLatencyMilliseconds: 50,
            concurrencyLimit: 2
        )

        XCTAssertEqual(
            feedback.throughput,
            10.0,
            accuracy: 0.0001
        )
    }

    func testZeroCompletedTasks() throws {
        let feedback = try PerformanceFeedback(
            completedTaskCount: 0,
            elapsedMilliseconds: 1000,
            meanLatencyMilliseconds: 0,
            concurrencyLimit: 1
        )

        XCTAssertEqual(feedback.throughput, 0)
    }

    // MARK: - Validation

    func testNegativeTaskCount() {
        XCTAssertThrowsError(
            try PerformanceFeedback(
                completedTaskCount: -1,
                elapsedMilliseconds: 1000,
                meanLatencyMilliseconds: 100,
                concurrencyLimit: 2
            )
        ) { error in
            XCTAssertEqual(
                error as? PerformanceFeedbackError,
                .invalidTaskCount
            )
        }
    }

    func testZeroElapsedTime() {
        XCTAssertThrowsError(
            try PerformanceFeedback(
                completedTaskCount: 10,
                elapsedMilliseconds: 0,
                meanLatencyMilliseconds: 100,
                concurrencyLimit: 2
            )
        ) { error in
            XCTAssertEqual(
                error as? PerformanceFeedbackError,
                .invalidElapsedTime
            )
        }
    }

    func testNegativeElapsedTime() {
        XCTAssertThrowsError(
            try PerformanceFeedback(
                completedTaskCount: 10,
                elapsedMilliseconds: -100,
                meanLatencyMilliseconds: 100,
                concurrencyLimit: 2
            )
        )
    }

    func testNonFiniteElapsedTime() {
        for value in [Double.nan, Double.infinity,
                      -Double.infinity] {
            XCTAssertThrowsError(
                try PerformanceFeedback(
                    completedTaskCount: 10,
                    elapsedMilliseconds: value,
                    meanLatencyMilliseconds: 100,
                    concurrencyLimit: 2
                )
            )
        }
    }

    func testNegativeMeanLatency() {
        XCTAssertThrowsError(
            try PerformanceFeedback(
                completedTaskCount: 10,
                elapsedMilliseconds: 1000,
                meanLatencyMilliseconds: -1,
                concurrencyLimit: 2
            )
        ) { error in
            XCTAssertEqual(
                error as? PerformanceFeedbackError,
                .invalidMeanLatency
            )
        }
    }

    func testNonFiniteMeanLatency() {
        for value in [Double.nan, Double.infinity,
                      -Double.infinity] {
            XCTAssertThrowsError(
                try PerformanceFeedback(
                    completedTaskCount: 10,
                    elapsedMilliseconds: 1000,
                    meanLatencyMilliseconds: value,
                    concurrencyLimit: 2
                )
            )
        }
    }

    func testInvalidConcurrencyLimit() {
        XCTAssertThrowsError(
            try PerformanceFeedback(
                completedTaskCount: 10,
                elapsedMilliseconds: 1000,
                meanLatencyMilliseconds: 100,
                concurrencyLimit: 0
            )
        ) { error in
            XCTAssertEqual(
                error as? PerformanceFeedbackError,
                .invalidConcurrencyLimit
            )
        }
    }

    // MARK: - Metadata

    func testCustomWindowIDAndTimestamp() throws {
        let id = UUID()
        let timestamp = Date(
            timeIntervalSince1970: 1_700_000_000
        )

        let feedback = try PerformanceFeedback(
            windowID: id,
            completedTaskCount: 10,
            elapsedMilliseconds: 1000,
            meanLatencyMilliseconds: 100,
            concurrencyLimit: 2,
            timestamp: timestamp
        )

        XCTAssertEqual(feedback.windowID, id)
        XCTAssertEqual(feedback.timestamp, timestamp)
    }

    func testFeedbackEquality() throws {
        let id = UUID()
        let timestamp = Date()

        let first = try PerformanceFeedback(
            windowID: id,
            completedTaskCount: 10,
            elapsedMilliseconds: 1000,
            meanLatencyMilliseconds: 100,
            concurrencyLimit: 2,
            timestamp: timestamp
        )

        let second = try PerformanceFeedback(
            windowID: id,
            completedTaskCount: 10,
            elapsedMilliseconds: 1000,
            meanLatencyMilliseconds: 100,
            concurrencyLimit: 2,
            timestamp: timestamp
        )

        XCTAssertEqual(first, second)
    }
}
