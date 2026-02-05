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
        let circuitBreaker = CircuitBreaker()

        let state = await circuitBreaker.state

        XCTAssertEqual(state, .closed)
    }

    func testCanAttemptReturnsTrueWhenClosed() async {
        let circuitBreaker = CircuitBreaker()

        let canAttempt = await circuitBreaker.canAttempt()

        XCTAssertTrue(canAttempt)
    }

    // MARK: - Failure Recording Tests

    func testRecordFailureIncrementsFailureCount() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 5)

        await circuitBreaker.recordFailure()

        let count = await circuitBreaker.currentFailureCount
        XCTAssertEqual(count, 1)
    }

    func testCircuitOpensAfterMaxFailures() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 3)

        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()

        let state = await circuitBreaker.state
        XCTAssertEqual(state, .open)
    }

    func testCircuitStaysClosedBeforeMaxFailures() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 3)

        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()

        let state = await circuitBreaker.state
        XCTAssertEqual(state, .closed)
    }

    func testCanAttemptReturnsFalseWhenOpen() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 1)

        await circuitBreaker.recordFailure()

        let canAttempt = await circuitBreaker.canAttempt()
        XCTAssertFalse(canAttempt)
    }

    // MARK: - Success Recording Tests

    func testRecordSuccessResetsFailureCount() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 5)

        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()
        await circuitBreaker.recordSuccess()

        let count = await circuitBreaker.currentFailureCount
        XCTAssertEqual(count, 0)
    }

    func testRecordSuccessInHalfOpenTransitionsToClosed() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 1, resetTimeout: 0.1)

        // Open the circuit
        await circuitBreaker.recordFailure()
        var state = await circuitBreaker.state
        XCTAssertEqual(state, .open)

        // Wait for timeout to transition to half-open
        try? await Task.sleep(for: .milliseconds(150))
        _ = await circuitBreaker.canAttempt()
        state = await circuitBreaker.state
        XCTAssertEqual(state, .halfOpen)

        // Record success
        await circuitBreaker.recordSuccess()

        state = await circuitBreaker.state
        XCTAssertEqual(state, .closed)
    }

    // MARK: - Half-Open State Tests

    func testCircuitTransitionsToHalfOpenAfterTimeout() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 1, resetTimeout: 0.1)

        // Open the circuit
        await circuitBreaker.recordFailure()
        var state = await circuitBreaker.state
        XCTAssertEqual(state, .open)

        // Wait for timeout
        try? await Task.sleep(for: .milliseconds(150))

        // Attempt should transition to half-open
        let canAttempt = await circuitBreaker.canAttempt()

        XCTAssertTrue(canAttempt)
        state = await circuitBreaker.state
        XCTAssertEqual(state, .halfOpen)
    }

    func testFailureInHalfOpenTransitionsBackToOpen() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 1, resetTimeout: 0.1)

        // Open the circuit
        await circuitBreaker.recordFailure()

        // Wait for timeout to get to half-open
        try? await Task.sleep(for: .milliseconds(150))
        _ = await circuitBreaker.canAttempt()
        var state = await circuitBreaker.state
        XCTAssertEqual(state, .halfOpen)

        // Record another failure
        await circuitBreaker.recordFailure()

        state = await circuitBreaker.state
        XCTAssertEqual(state, .open)
    }

    // MARK: - Reset Tests

    func testResetTransitionsToClosed() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 1)

        await circuitBreaker.recordFailure()
        let state = await circuitBreaker.state
        XCTAssertEqual(state, .open)

        await circuitBreaker.reset()

        let currentState = await circuitBreaker.state
        XCTAssertEqual(currentState, .closed)
    }

    func testResetClearsFailureCount() async {
        let circuitBreaker = CircuitBreaker(maxFailures: 5)

        await circuitBreaker.recordFailure()
        await circuitBreaker.recordFailure()
        await circuitBreaker.reset()

        let count = await circuitBreaker.currentFailureCount
        XCTAssertEqual(count, 0)
    }
}
