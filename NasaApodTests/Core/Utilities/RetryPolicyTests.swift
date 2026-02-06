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
        // Given
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 10.0)

        // When
        let delay = policy.delay(for: 0)

        // Then
        XCTAssertEqual(delay, 1.0, accuracy: 0.001)
    }

    func testDelayCalculationWithFirstAttemptReturnsDoubleBaseDelay() {
        // Given
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 10.0)

        // When
        let delay = policy.delay(for: 1)

        // Then
        XCTAssertEqual(delay, 2.0, accuracy: 0.001)
    }

    func testDelayCalculationWithSecondAttemptReturnsQuadrupleBaseDelay() {
        // Given
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 1.0, maxDelay: 10.0)

        // When
        let delay = policy.delay(for: 2)

        // Then
        XCTAssertEqual(delay, 4.0, accuracy: 0.001)
    }

    func testDelayCalculationDoesNotExceedMaxDelay() {
        // Given
        let policy = RetryPolicy(maxAttempts: 10, baseDelay: 1.0, maxDelay: 5.0)

        // When
        let delay = policy.delay(for: 10)

        // Then
        XCTAssertEqual(delay, 5.0, accuracy: 0.001)
    }

    func testDefaultRetryPolicyHasExpectedConfiguration() {
        // Given/When
        let defaultPolicy = RetryPolicy.default

        // Then
        XCTAssertEqual(defaultPolicy.maxAttempts, 3)
        XCTAssertEqual(defaultPolicy.baseDelay, 1.0)
        XCTAssertEqual(defaultPolicy.maxDelay, 10.0)
    }

    func testExecuteWithImmediatelySuccessfulOperation() async throws {
        // Given
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(failOnAttempts: [])

        // When
        let result = try await policy.execute {
            try await operationSpy.execute()
        }

        // Then
        XCTAssertEqual(result, "success")
        XCTAssertEqual(operationSpy.callCount, 1)
    }

    func testExecuteWithEventuallySuccessfulOperation() async throws {
        // Given
        let policy = RetryPolicy(maxAttempts: 5, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(failOnAttempts: [0, 1])

        // When
        let result = try await policy.execute {
            try await operationSpy.execute()
        }

        // Then
        XCTAssertEqual(result, "success")
        XCTAssertEqual(operationSpy.callCount, 3)
    }

    func testExecuteWithConsistentlyFailingOperationThrowsError() async {
        // Given
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(failOnAttempts: [0, 1, 2])

        // When/Then
        do {
            _ = try await policy.execute {
                try await operationSpy.execute()
            }
            XCTFail("Expected operation to throw an error after all retries")
        } catch {
            XCTAssertEqual(operationSpy.callCount, 3)
        }
    }

    // MARK: - Non-Retryable Error Tests

    func testExecuteWithNonRetryableError_FailsImmediately() async {
        // Given - 429 is non-retryable
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(
            failOnAttempts: [0, 1, 2],
            customError: NetworkError.httpError(statusCode: 429)
        )

        // When/Then
        do {
            _ = try await policy.execute {
                try await operationSpy.execute()
            }
            XCTFail("Expected operation to throw immediately")
        } catch {
            // Then - Should fail on first attempt, no retries
            XCTAssertEqual(operationSpy.callCount, 1, "Non-retryable error should not trigger retries")
        }
    }

    func testExecuteWith401_FailsImmediately() async {
        // Given - 401 Unauthorized is non-retryable
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(
            failOnAttempts: [0],
            customError: NetworkError.httpError(statusCode: 401)
        )

        // When/Then
        do {
            _ = try await policy.execute {
                try await operationSpy.execute()
            }
            XCTFail("Expected operation to throw immediately")
        } catch {
            XCTAssertEqual(operationSpy.callCount, 1, "401 should not trigger retries")
        }
    }

    func testExecuteWith403_FailsImmediately() async {
        // Given - 403 Forbidden is non-retryable
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(
            failOnAttempts: [0],
            customError: NetworkError.httpError(statusCode: 403)
        )

        // When/Then
        do {
            _ = try await policy.execute {
                try await operationSpy.execute()
            }
            XCTFail("Expected operation to throw immediately")
        } catch {
            XCTAssertEqual(operationSpy.callCount, 1, "403 should not trigger retries")
        }
    }

    func testExecuteWith500_RetriesBeforeFailing() async {
        // Given - 500 Server Error IS retryable
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.1, maxDelay: 1.0)
        var operationSpy = OperationSpy(
            failOnAttempts: [0, 1, 2],
            customError: NetworkError.httpError(statusCode: 500)
        )

        // When/Then
        do {
            _ = try await policy.execute {
                try await operationSpy.execute()
            }
            XCTFail("Expected operation to throw after retries")
        } catch {
            // Then - Should retry all 3 attempts for server errors
            XCTAssertEqual(operationSpy.callCount, 3, "500 error SHOULD trigger retries")
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
