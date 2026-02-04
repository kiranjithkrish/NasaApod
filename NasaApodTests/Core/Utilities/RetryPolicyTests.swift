//
//  RetryPolicyTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 03/02/2026.
//

import XCTest
@testable import NasaApod

final class RetryPolicyTests: XCTestCase {
    
    func testDelayCalculationWithZeroAttemptReturnsBaseDelay() {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 10.0)
        
        let delay = policy.delay(for: 0)
        
        XCTAssertEqual(delay, 1.0, accuracy: 0.001)
    }
    
    func testDelayCalculationWithFirstAttemptReturnsDoubleBaseDelay() {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 10.0)
        
        let delay = policy.delay(for: 1)
        
        XCTAssertEqual(delay, 2.0, accuracy: 0.001)
    }
    
    func testDelayCalculationWithSecondAttemptReturnsQuadrupleBaseDelay() {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 10.0)
        
        let delay = policy.delay(for: 2)
        
        XCTAssertEqual(delay, 4.0, accuracy: 0.001)
    }
    
    func testDelayCalculationDoesNotExceedMaxDelay() {
        let policy = RetryPolicy(maxAttempts: 10, baseDelay: 1.0, maxDelay: 5.0)
        
        let delay = policy.delay(for: 10)  
        
        XCTAssertEqual(delay, 5.0, accuracy: 0.001)  // Should be capped at maxDelay
    }
    
    func testDefaultRetryPolicyHasExpectedConfiguration() {
        let defaultPolicy = RetryPolicy.default
        
        XCTAssertEqual(defaultPolicy.maxAttempts, 3)
        XCTAssertEqual(defaultPolicy.baseDelay, 1.0)
        XCTAssertEqual(defaultPolicy.maxDelay, 10.0)
    }
    
    func testExecuteWithImmediatelySuccessfulOperation() async throws {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(failOnAttempts: [])

        let result = try await policy.execute {
            try await operationSpy.execute()
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(operationSpy.callCount, 1)
    }
    
    func testExecuteWithEventuallySuccessfulOperation() async throws {
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(failOnAttempts: [0, 1])  // Fail on first 2 attempts, succeed on 3rd

        let result = try await policy.execute {
            try await operationSpy.execute()
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(operationSpy.callCount, 3)  // Should succeed on 3rd attempt
    }
    
    func testExecuteWithConsistentlyFailingOperationThrowsError() async {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(failOnAttempts: [0, 1, 2])  // Fail on all attempts

        do {
            _ = try await policy.execute {
                try await operationSpy.execute()
            }
            XCTFail("Expected operation to throw an error after all retries")
        } catch {
            XCTAssertEqual(operationSpy.callCount, 3)  // Should try 3 times
        }
    }
    
}

// MARK: - Test Helpers

private struct OperationSpy {
    private(set) var callCount = 0
    let failOnAttempts: Set<Int>
    let customError: Error?
    
    init(failOnAttempts: Set<Int>, customError: Error? = nil) {
        self.failOnAttempts = failOnAttempts
        self.customError = customError
    }
    
    mutating func execute() async throws -> String {
        defer { callCount += 1 }

        if failOnAttempts.contains(callCount) {
            if let customError = customError {
                throw customError
            } else {
                throw TestError.simulatedFailure
            }
        }

        return "success"
    }
}

private enum TestError: Error {
    case simulatedFailure
}

private enum CustomTestError: Error, Equatable {
    case specificError

    static func == (lhs: CustomTestError, rhs: CustomTestError) -> Bool {
        switch (lhs, rhs) {
        case (.specificError, .specificError):
            return true
        }
    }
}
