
import XCTest
@testable import AdaptivePerfKit

final class AdaptiveConcurrencyConfigurationTests: XCTestCase {

    func testDefaultConfiguration() throws {
        let config = try AdaptiveConcurrencyConfiguration()

        XCTAssertEqual(config.minimumConcurrency, 1)
        XCTAssertEqual(config.maximumConcurrency, 8)
        XCTAssertEqual(config.initialConcurrency, 2)
        XCTAssertEqual(config.measurementWindowSize, 10)
        XCTAssertEqual(config.improvementThreshold, 0.05)
        XCTAssertEqual(config.maximumLatencyMilliseconds, 1000)
    }

    func testValidCustomConfiguration() throws {
        let config = try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: 2,
            maximumConcurrency: 12,
            initialConcurrency: 4,
            measurementWindowSize: 20,
            improvementThreshold: 0.10,
            maximumLatencyMilliseconds: 500
        )

        XCTAssertEqual(config.minimumConcurrency, 2)
        XCTAssertEqual(config.maximumConcurrency, 12)
        XCTAssertEqual(config.initialConcurrency, 4)
        XCTAssertEqual(config.measurementWindowSize, 20)
    }

    func testInvalidMinimumConcurrency() {
        XCTAssertThrowsError(
            try AdaptiveConcurrencyConfiguration(
                minimumConcurrency: 0
            )
        ) { error in
            XCTAssertEqual(
                error as? ConfigurationError,
                .invalidMinimumConcurrency
            )
        }
    }

    func testInvalidMaximumConcurrency() {
        XCTAssertThrowsError(
            try AdaptiveConcurrencyConfiguration(
                minimumConcurrency: 4,
                maximumConcurrency: 2
            )
        ) { error in
            XCTAssertEqual(
                error as? ConfigurationError,
                .invalidMaximumConcurrency
            )
        }
    }

    func testInitialConcurrencyBelowMinimum() {
        XCTAssertThrowsError(
            try AdaptiveConcurrencyConfiguration(
                minimumConcurrency: 2,
                maximumConcurrency: 8,
                initialConcurrency: 1
            )
        ) { error in
            XCTAssertEqual(
                error as? ConfigurationError,
                .invalidInitialConcurrency
            )
        }
    }

    func testInitialConcurrencyAboveMaximum() {
        XCTAssertThrowsError(
            try AdaptiveConcurrencyConfiguration(
                minimumConcurrency: 1,
                maximumConcurrency: 4,
                initialConcurrency: 8
            )
        ) { error in
            XCTAssertEqual(
                error as? ConfigurationError,
                .invalidInitialConcurrency
            )
        }
    }

    func testInvalidMeasurementWindow() {
        XCTAssertThrowsError(
            try AdaptiveConcurrencyConfiguration(
                measurementWindowSize: 0
            )
        ) { error in
            XCTAssertEqual(
                error as? ConfigurationError,
                .invalidMeasurementWindowSize
            )
        }
    }

    func testInvalidImprovementThreshold() {
        XCTAssertThrowsError(
            try AdaptiveConcurrencyConfiguration(
                improvementThreshold: -0.1
            )
        ) { error in
            XCTAssertEqual(
                error as? ConfigurationError,
                .invalidImprovementThreshold
            )
        }
    }

    func testImprovementThresholdAboveLimit() {
        XCTAssertThrowsError(
            try AdaptiveConcurrencyConfiguration(
                improvementThreshold: 1.0
            )
        ) { error in
            XCTAssertEqual(
                error as? ConfigurationError,
                .invalidImprovementThreshold
            )
        }
    }

    func testNonFiniteImprovementThreshold() {
        for value in [Double.nan, Double.infinity] {
            XCTAssertThrowsError(
                try AdaptiveConcurrencyConfiguration(
                    improvementThreshold: value
                )
            )
        }
    }

    func testInvalidMaximumLatency() {
        XCTAssertThrowsError(
            try AdaptiveConcurrencyConfiguration(
                maximumLatencyMilliseconds: 0
            )
        ) { error in
            XCTAssertEqual(
                error as? ConfigurationError,
                .invalidMaximumLatency
            )
        }
    }

    func testNonFiniteMaximumLatency() {
        for value in [Double.nan, Double.infinity] {
            XCTAssertThrowsError(
                try AdaptiveConcurrencyConfiguration(
                    maximumLatencyMilliseconds: value
                )
            )
        }
    }

    func testEqualConcurrencyBoundaries() throws {
        let config = try AdaptiveConcurrencyConfiguration(
            minimumConcurrency: 4,
            maximumConcurrency: 4,
            initialConcurrency: 4
        )

        XCTAssertEqual(config.minimumConcurrency, 4)
        XCTAssertEqual(config.maximumConcurrency, 4)
        XCTAssertEqual(config.initialConcurrency, 4)
    }
}
