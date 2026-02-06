//
//  RetryPolicy.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Retry policy with exponential backoff
struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval

    /// Default retry policy: 3 attempts with exponential backoff
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 10.0
    )

    /// Calculate delay for a given attempt using exponential backoff
    /// - Parameter attempt: Current attempt number (0-indexed)
    /// - Returns: Delay in seconds before next retry
    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        return min(exponentialDelay, maxDelay)
    }

    /// Execute operation with retry logic
    /// - Parameter operation: Async throwing operation to retry
    /// - Returns: Result of successful operation
    /// - Throws: Last error if all attempts fail, or immediately for non-retryable errors
    func execute<T>(_ operation: @Sendable () async throws -> T) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            do {
                let result = try await operation()

                if attempt > 0 {
                    AppLogger.info("Operation succeeded on attempt \(attempt + 1)/\(maxAttempts)", category: .network)
                }

                return result
            } catch {
                lastError = error

                // Don't retry non-retryable errors (401, 403, 404, 429, etc.)
                if let networkError = error as? NetworkError, !networkError.isRetryable {
                    AppLogger.warning("Non-retryable error (\(networkError)), skipping retry", category: .network)
                    throw error
                }

                let isLastAttempt = attempt == maxAttempts - 1
                if isLastAttempt {
                    AppLogger.error("Operation failed after \(maxAttempts) attempts", error: error, category: .network)
                    throw error
                }

                let delaySeconds = delay(for: attempt)
                AppLogger.warning("Attempt \(attempt + 1)/\(maxAttempts) failed. Retrying in \(String(format: "%.1f", delaySeconds))s...", category: .network)

                try await Task.sleep(for: .seconds(delaySeconds))
            }
        }

        throw lastError ?? NSError(domain: "RetryPolicy", code: -1, userInfo: [NSLocalizedDescriptionKey: "All retry attempts failed"])
    }
}
