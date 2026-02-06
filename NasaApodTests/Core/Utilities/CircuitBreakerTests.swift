//
//  CircuitBreakerTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 03/02/2026.
//

import XCTest
@testable import NasaApod

final class CircuitBreakerTests: XCTestCase {

    // MARK: - Initial State Tests

    func testInitialStateIsClosed() async {
        // Given
        let circuitBreaker = CircuitBreaker()

        // When
        let state = await circuitBreaker.state

        // Then
        XCTAssertEqual(state, .closed)
    }

    func testCanAttemptReturnsTrueWhenClosed() async {
        // Given
        let circuitBreaker = CircuitBreaker()

        // When
        let canAttempt = await circuitBreaker.canAttempt()

        // Then
        XCTAssertTrue(canAttempt)
    }

    // MARK: - Failure Recording Tests

    func testRecordFailureIncrementsFailureCount() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 5)

        // When
        await circuitBreaker.recordFailure()

        // Then
        let count = await circuitBreaker.currentFailureCount
        XCTAssertEqual(count, 1)
    }

    func testCircuitOpensAfterMaxFailures() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 3)

        // When
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()

        // Then
        let state = await circuitBreaker.state
        XCTAssertEqual(state, .open)
    }

    func testCircuitStaysClosedBeforeMaxFailures() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 3)

        // When
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()

        // Then
        let state = await circuitBreaker.state
        XCTAssertEqual(state, .closed)
    }

    func testCanAttemptReturnsFalseWhenOpen() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 1)
        await circuitBreaker.recordFailure()

        // When
        let canAttempt = await circuitBreaker.canAttempt()

        // Then
        XCTAssertFalse(canAttempt)
    }

    // MARK: - Success Recording Tests

    func testRecordSuccessResetsFailureCount() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 5)
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()

        // When
        await circuitBreaker.recordSuccess()

        // Then
        let count = await circuitBreaker.currentFailureCount
        XCTAssertEqual(count, 0)
    }

    func testRecordSuccessInHalfOpenTransitionsToClosed() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 1, resetTimeout: 0.1)
        await circuitBreaker.recordFailure()
        var state = await circuitBreaker.state
        XCTAssertEqual(state, .open)

        // Wait for timeout to transition to half-open
        try? await Task.sleep(for: .milliseconds(150))
        _ = await circuitBreaker.canAttempt()
        state = await circuitBreaker.state
        XCTAssertEqual(state, .halfOpen)

        // When
        await circuitBreaker.recordSuccess()

        // Then
        state = await circuitBreaker.state
        XCTAssertEqual(state, .closed)
    }

    // MARK: - Half-Open State Tests

    func testCircuitTransitionsToHalfOpenAfterTimeout() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 1, resetTimeout: 0.1)
        await circuitBreaker.recordFailure()
        var state = await circuitBreaker.state
        XCTAssertEqual(state, .open)

        // When
        try? await Task.sleep(for: .milliseconds(150))
        let canAttempt = await circuitBreaker.canAttempt()

        // Then
        XCTAssertTrue(canAttempt)
        state = await circuitBreaker.state
        XCTAssertEqual(state, .halfOpen)
    }

    func testFailureInHalfOpenTransitionsBackToOpen() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 1, resetTimeout: 0.1)
        await circuitBreaker.recordFailure()
        try? await Task.sleep(for: .milliseconds(150))
        _ = await circuitBreaker.canAttempt()
        var state = await circuitBreaker.state
        XCTAssertEqual(state, .halfOpen)

        // When
        await circuitBreaker.recordFailure()

        // Then
        state = await circuitBreaker.state
        XCTAssertEqual(state, .open)
    }

    // MARK: - Reset Tests

    func testResetTransitionsToClosed() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 1)
        await circuitBreaker.recordFailure()
        let state = await circuitBreaker.state
        XCTAssertEqual(state, .open)

        // When
        await circuitBreaker.reset()

        // Then
        let currentState = await circuitBreaker.state
        XCTAssertEqual(currentState, .closed)
    }

    func testResetClearsFailureCount() async {
        // Given
        let circuitBreaker = CircuitBreaker(maxFailures: 5)
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()

        // When
        await circuitBreaker.reset()

        // Then
        let count = await circuitBreaker.currentFailureCount
        XCTAssertEqual(count, 0)
    }
}
