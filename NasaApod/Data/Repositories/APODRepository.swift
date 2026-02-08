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

    func fetchAPOD(for date: Date) async throws -> FetchResult {
        // Check circuit breaker - use cache if open
        guard await circuitBreaker.canAttempt() else {
            AppLogger.warning("Circuit breaker open, using cache", category: .network)
            return .cachedFallback(try await loadFromCache(for: date, originalError: APODError.circuitBreakerOpen))
        }

        // Try network first
        do {
            let apod = try await apiService.fetchAPOD(for: date)

            // Success: save as last successful and reset circuit breaker
            try? await cacheService.saveLastSuccessful(apod)
            await circuitBreaker.recordSuccess()

            return .fresh(apod)

        } catch let error as NetworkError {
            // Only fall back to cache for connectivity errors, not HTTP errors
            if shouldFallbackToCache(for: error) {
                await circuitBreaker.recordFailure()
                AppLogger.warning("Network unavailable, falling back to cache", category: .network)
                return .cachedFallback(try await loadFromCache(for: date, originalError: error))
            } else {
                // HTTP errors (404, etc.) - don't use cache, show error
                AppLogger.warning("HTTP error: \(error.localizedDescription)", category: .network)
                throw error
            }

        } catch let error as APODError {
            // Only fall back to cache for network-related APOD errors
            if shouldFallbackToCache(for: error) {
                await circuitBreaker.recordFailure()
                AppLogger.warning("Network fetch failed: \(error.localizedDescription)", category: .network)
                return .cachedFallback(try await loadFromCache(for: date, originalError: error))
            } else {
                throw error
            }

        } catch {
            // Unknown errors - try cache as fallback
            await circuitBreaker.recordFailure()
            AppLogger.error("Unexpected error", error: error, category: .network)
            return .cachedFallback(try await loadFromCache(for: date, originalError: error))
        }
    }

    /// Determine if we should fall back to cache for this error
    /// Only network connectivity errors should use cache fallback
    private func shouldFallbackToCache(for error: NetworkError) -> Bool {
        switch error {
        case .networkUnavailable, .timeout:
            return true  // Connectivity issues - use cache
        case .httpError, .invalidURL, .noData, .decodingFailed, .unknown:
            return false // Server responded - don't mask with old cache
        }
    }

    private func shouldFallbackToCache(for error: APODError) -> Bool {
        switch error {
        case .networkUnavailable, .requestTimeout, .circuitBreakerOpen:
            return true  // Connectivity issues - use cache
        case .requestFailed, .invalidURL, .invalidData, .decodingFailed,
             .invalidDateRange, .cacheUnavailable, .cacheCorrupted,
             .noCachedData, .repositoryFailed:
            return false // Don't mask actual errors with old cache
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
    var simulateCachedFallback: Bool = false
    var errorToThrow: APODError = .networkUnavailable

    func fetchAPOD(for date: Date) async throws -> FetchResult {
        try await Task.sleep(for: .seconds(0.5))

        if shouldFail {
            throw errorToThrow
        }

        return simulateCachedFallback ? .cachedFallback(mockAPOD) : .fresh(mockAPOD)
    }

    func isAvailable() async -> Bool {
        return !shouldFail
    }

    func reset() async {
        // No-op for mock
    }
}
#endif
