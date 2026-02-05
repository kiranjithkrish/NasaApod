//
//  CircuitBreaker.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Circuit breaker implementation for fault tolerance
/// Prevents cascading failures by stopping requests after repeated failures
actor CircuitBreaker {

    // MARK: - State

    enum State: Equatable {
        case closed    // Normal operation
        case open      // Too many failures, reject requests
        case halfOpen  // Testing if service recovered
    }

    // MARK: - Configuration

    private let maxFailures: Int
    private let resetTimeout: TimeInterval

    // MARK: - Internal State

    private(set) var state: State = .closed
    private var failureCount: Int = 0
    private var lastFailureTime: Date?

    // MARK: - Initialization

    init(maxFailures: Int = 5, resetTimeout: TimeInterval = 60) {
        self.maxFailures = maxFailures
        self.resetTimeout = resetTimeout
    }

    // MARK: - Public Methods

    /// Check if a request can be attempted
    func canAttempt() -> Bool {
        switch state {
        case .closed:
            return true

        case .open:
            // Check if reset timeout has elapsed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > resetTimeout {
                state = .halfOpen
                AppLogger.info("Circuit breaker: open → half-open", category: .network)
                return true
            }
            return false

        case .halfOpen:
            return true
        }
    }

    /// Record a successful request
    func recordSuccess() {
        switch state {
        case .closed:
            failureCount = 0

        case .halfOpen:
            state = .closed
            failureCount = 0
            lastFailureTime = nil
            AppLogger.info("Circuit breaker: half-open → closed", category: .network)

        case .open:
            state = .closed
            failureCount = 0
            lastFailureTime = nil
        }
    }

    /// Record a failed request
    func recordFailure() {
        lastFailureTime = Date()
        failureCount += 1

        if state == .halfOpen {
            state = .open
            AppLogger.warning("Circuit breaker: half-open → open", category: .network)

        } else if failureCount >= maxFailures {
            state = .open
            AppLogger.warning("Circuit breaker opened after \(failureCount) failures", category: .network)
        }
    }

    /// Reset the circuit breaker to closed state
    func reset() {
        state = .closed
        failureCount = 0
        lastFailureTime = nil
    }

    // MARK: - Testing Helpers

    /// Current failure count (for testing)
    var currentFailureCount: Int {
        failureCount
    }
}
