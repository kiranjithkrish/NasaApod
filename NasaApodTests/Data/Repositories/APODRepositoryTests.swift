//
//  APODRepositoryTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 05/02/2026.
//

import XCTest
@testable import NasaApod

@MainActor
final class APODRepositoryTests: XCTestCase {

    // MARK: - Success Path Tests

    func testFetchAPODReturnsFromNetworkOnSuccess() async throws {
        let expectedAPOD = makeAPOD(date: "2024-01-15", title: "Network APOD")
        let mockAPI = MockAPIServiceForTest(result: .success(expectedAPOD))
        let mockCache = MockCacheServiceForTest()
        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 3,
            resetTimeout: 60
        )

        let result = try await repository.fetchAPOD(for: Date())
        let title = result.title

        XCTAssertEqual(title, "Network APOD")
    }

    func testFetchAPODCachesOnSuccess() async throws {
        let expectedAPOD = makeAPOD(date: "2024-01-15")
        let mockAPI = MockAPIServiceForTest(result: .success(expectedAPOD))
        let mockCache = MockCacheServiceForTest()
        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 3,
            resetTimeout: 60
        )

        _ = try await repository.fetchAPOD(for: Date())

        let savedCount = await mockCache.saveCallCount
        XCTAssertGreaterThan(savedCount, 0)
    }

    // MARK: - Fallback Tests

    func testFetchAPODFallsBackToCacheOnNetworkFailure() async throws {
        let cachedAPOD = makeAPOD(date: "2024-01-15", title: "Cached APOD")
        let mockAPI = MockAPIServiceForTest(result: .failure(APODError.networkUnavailable))
        let mockCache = MockCacheServiceForTest()
        await mockCache.setAPODForKey("2024-01-15", apod: cachedAPOD)

        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 3,
            resetTimeout: 60
        )

        // Use a date that matches our cache key
        let date = makeDateFromString("2024-01-15")
        let result = try await repository.fetchAPOD(for: date)

        let resultTitle = result.title
        XCTAssertEqual(resultTitle, "Cached APOD")
    }

    func testFetchAPODFallsBackToLastSuccessfulWhenDateNotCached() async throws {
        let lastSuccessful = makeAPOD(date: "2024-01-10", title: "Last Successful")
        let mockAPI = MockAPIServiceForTest(result: .failure(APODError.networkUnavailable))
        let mockCache = MockCacheServiceForTest()
        await mockCache.setLastSuccessful(lastSuccessful)

        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 3,
            resetTimeout: 60
        )

        let result = try await repository.fetchAPOD(for: Date())

        let resultTitle = result.title
        XCTAssertEqual(resultTitle, "Last Successful")
    }

    func testFetchAPODThrowsWhenBothNetworkAndCacheFail() async {
        let mockAPI = MockAPIServiceForTest(result: .failure(APODError.networkUnavailable))
        let mockCache = MockCacheServiceForTest()
        // No cache data set

        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 3,
            resetTimeout: 60
        )

        do {
            _ = try await repository.fetchAPOD(for: Date())
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - both network and cache failed
        }
    }

    // MARK: - Circuit Breaker Tests

    func testCircuitBreakerOpensAfterMaxFailures() async throws {
        let mockAPI = MockAPIServiceForTest(result: .failure(APODError.networkUnavailable))
        let mockCache = MockCacheServiceForTest()
        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 2,
            resetTimeout: 60
        )

        // First two failures should open the circuit
        for _ in 0..<2 {
            _ = try? await repository.fetchAPOD(for: Date())
        }

        let isAvailable = await repository.isAvailable()
        XCTAssertFalse(isAvailable)
    }

    func testCircuitBreakerThrowsWhenOpen() async {
        let mockAPI = MockAPIServiceForTest(result: .failure(APODError.networkUnavailable))
        let mockCache = MockCacheServiceForTest()
        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 1,
            resetTimeout: 60
        )

        // First failure opens circuit
        _ = try? await repository.fetchAPOD(for: Date())

        // Second call should throw circuit breaker open error
        do {
            _ = try await repository.fetchAPOD(for: Date())
            XCTFail("Expected circuitBreakerOpen error")
        } catch let error as APODError {
            XCTAssertEqual(error, .circuitBreakerOpen)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testResetClearsCircuitBreaker() async throws {
        let mockAPI = MockAPIServiceForTest(result: .failure(APODError.networkUnavailable))
        let mockCache = MockCacheServiceForTest()
        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 1,
            resetTimeout: 60
        )

        // Open the circuit
        _ = try? await repository.fetchAPOD(for: Date())
        var isAvailable = await repository.isAvailable()
        XCTAssertFalse(isAvailable)

        // Reset
        await repository.reset()

        isAvailable = await repository.isAvailable()
        XCTAssertTrue(isAvailable)
    }

    func testSuccessfulFetchResetsFailureCount() async throws {
        let mockAPI = MockAPIServiceForTest(result: .failure(APODError.networkUnavailable))
        let mockCache = MockCacheServiceForTest()
        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache,
            maxFailures: 3,
            resetTimeout: 60
        )

        // Two failures
        _ = try? await repository.fetchAPOD(for: Date())
        _ = try? await repository.fetchAPOD(for: Date())

        // Now make API succeed
        let successAPOD = makeAPOD(date: "2024-01-15")
        await mockAPI.setResult(.success(successAPOD))

        _ = try await repository.fetchAPOD(for: Date())

        // Two more failures should not open circuit (count was reset)
        await mockAPI.setResult(.failure(APODError.networkUnavailable))
        _ = try? await repository.fetchAPOD(for: Date())
        _ = try? await repository.fetchAPOD(for: Date())

        let isAvailable = await repository.isAvailable()
        XCTAssertTrue(isAvailable)
    }

    // MARK: - isAvailable Tests

    func testIsAvailableReturnsTrueInitially() async {
        let mockAPI = MockAPIServiceForTest(result: .success(makeAPOD()))
        let mockCache = MockCacheServiceForTest()
        let repository = APODRepository(
            apiService: mockAPI,
            cacheService: mockCache
        )

        let isAvailable = await repository.isAvailable()

        XCTAssertTrue(isAvailable)
    }
}

// MARK: - Test Helpers

extension APODRepositoryTests {
    private func makeAPOD(
        date: String = "2024-01-15",
        title: String = "Test APOD"
    ) -> APOD {
        APOD(
            date: date,
            title: title,
            explanation: "Test explanation",
            url: "https://example.com/image.jpg",
            mediaType: .image,
            hdurl: nil,
            copyright: nil
        )
    }

    private func makeDateFromString(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - Mock API Service

actor MockAPIServiceForTest: APIServiceProtocol {
    private var result: Result<APOD, Error>

    init(result: Result<APOD, Error>) {
        self.result = result
    }

    func setResult(_ result: Result<APOD, Error>) {
        self.result = result
    }

    nonisolated func fetchAPOD(for date: Date?) async throws -> APOD {
        let currentResult = await result
        switch currentResult {
        case .success(let apod):
            return apod
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Mock Cache Service

actor MockCacheServiceForTest: CacheServiceProtocol {
    private var storage: [String: APOD] = [:]
    private var lastSuccessful: APOD?
    private(set) var saveCallCount = 0

    func setAPODForKey(_ key: String, apod: APOD) {
        storage[key] = apod
    }

    func setLastSuccessful(_ apod: APOD) {
        lastSuccessful = apod
    }

    nonisolated func save(_ apod: APOD, forKey key: String) async throws {
        await incrementSaveCount()
        await setAPODForKey(key, apod: apod)
    }

    private func incrementSaveCount() {
        saveCallCount += 1
    }

    nonisolated func load(forKey key: String) async throws -> APOD {
        guard let apod = await storage[key] else {
            throw CacheError.noData
        }
        return apod
    }

    nonisolated func saveLastSuccessful(_ apod: APOD) async throws {
        await setLastSuccessful(apod)
    }

    nonisolated func loadLastSuccessful() async throws -> APOD {
        guard let apod = await lastSuccessful else {
            throw CacheError.noData
        }
        return apod
    }

    nonisolated func clearCache() async throws {
        await clearStorage()
    }

    private func clearStorage() {
        storage.removeAll()
        lastSuccessful = nil
    }
}
