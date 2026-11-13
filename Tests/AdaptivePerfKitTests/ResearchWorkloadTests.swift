
import Foundation
import XCTest
@testable import AdaptivePerfKit

final class ResearchWorkloadTests: XCTestCase {

    func testAllWorkloadsAvailable() {
        XCTAssertEqual(
            ResearchWorkload.allCases.count,
            3
        )
    }

    func testCPUWorkloadIsDeterministic() async throws {
        let first = try await ResearchWorkload
            .cpuIntensive.execute(42)

        let second = try await ResearchWorkload
            .cpuIntensive.execute(42)

        XCTAssertEqual(first, second)
    }

    func testVariableLatencyPreservesInput() async throws {
        let result = try await ResearchWorkload
            .variableLatency.execute(7)

        XCTAssertEqual(result, 7)
    }

    func testMixedWorkloadIsDeterministic() async throws {
        let first = try await ResearchWorkload
            .mixed.execute(10)

        let second = try await ResearchWorkload
            .mixed.execute(10)

        XCTAssertEqual(first, second)
    }

    func testDifferentCPUInputsProduceDifferentResults()
        async throws {

        let first = try await ResearchWorkload
            .cpuIntensive.execute(1)

        let second = try await ResearchWorkload
            .cpuIntensive.execute(2)

        XCTAssertNotEqual(first, second)
    }
}
