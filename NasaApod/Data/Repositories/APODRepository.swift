//
//  APODRepository.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Repository for APOD data with circuit breaker pattern
struct APODRepository: APODRepositoryProtocol {
    // MARK: - Dependencies

    private let apiService: APIServiceProtocol
    private let cacheService: CacheServiceProtocol

    // MARK: - Circuit Breaker

    /// Actor to manage circuit breaker state (thread-safe)
    private let circuitBreaker: CircuitBreaker

    // MARK: - Initialization

    nonisolated init(
        apiService: APIServiceProtocol,
        cacheService: CacheServiceProtocol,
        maxFailures: Int = 5,
        resetTimeout: TimeInterval = 60
    ) {
        self.apiService = apiService
        self.cacheService = cacheService
        self.circuitBreaker = CircuitBreaker(
            maxFailures: maxFailures,
            resetTimeout: resetTimeout
        )
    }

    // MARK: - Public Methods

    func fetchAPOD(for date: Date) async throws -> APOD {
        // Check circuit breaker
        guard await circuitBreaker.canAttempt() else {
            AppLogger.warning("Circuit breaker open, using cache", category: .network)
            throw APODError.circuitBreakerOpen
        }

        // Try network first
        do {
            let apod = try await apiService.fetchAPOD(for: date)

            // Success: save to cache and reset circuit breaker
            try? await cacheService.save(apod, forKey: cacheKey(for: date))
            try? await cacheService.saveLastSuccessful(apod)
            await circuitBreaker.recordSuccess()

            return apod

        } catch let error as APODError {
            // Record failure
            await circuitBreaker.recordFailure()
            AppLogger.warning("Network fetch failed: \(error.localizedDescription)", category: .network)

            // Fallback to cache
            return try await loadFromCache(for: date, originalError: error)

        } catch {
            // Record failure
            await circuitBreaker.recordFailure()
            AppLogger.error("Unexpected error", error: error, category: .network)

            // Fallback to cache
            return try await loadFromCache(for: date, originalError: error)
        }
    }

    func isAvailable() async -> Bool {
        return await circuitBreaker.canAttempt()
    }

    func reset() async {
        await circuitBreaker.reset()
        AppLogger.info("Circuit breaker reset", category: .network)
    }

    // MARK: - Private Helpers

    private func loadFromCache(for date: Date, originalError: Error) async throws -> APOD {
        let key = cacheKey(for: date)

        do {
            let cachedAPOD = try await cacheService.load(forKey: key)
            AppLogger.info("Using cached APOD for \(date)", category: .cache)
            return cachedAPOD

        } catch {
            // Try last successful as final fallback
            do {
                let lastSuccessful = try await cacheService.loadLastSuccessful()
                AppLogger.warning("Using last successful APOD as fallback", category: .cache)
                return lastSuccessful

            } catch {
                // Both network and cache failed
                throw originalError
            }
        }
    }

    private func cacheKey(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
}

// MARK: - Preview/Testing Mock

#if DEBUG
/// Mock repository for previews and testing
struct MockAPODRepository: APODRepositoryProtocol {
    var mockAPOD: APOD = .sample
    var shouldFail: Bool = false
    var errorToThrow: APODError = .networkUnavailable

    func fetchAPOD(for date: Date) async throws -> APOD {
        try await Task.sleep(for: .seconds(0.5))

        if shouldFail {
            throw errorToThrow
        }

        return mockAPOD
    }

    func isAvailable() async -> Bool {
        return !shouldFail
    }

    func reset() async {
        // No-op for mock
    }
}
#endif
