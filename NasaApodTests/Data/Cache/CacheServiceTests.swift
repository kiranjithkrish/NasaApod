//
//  CacheServiceTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 05/02/2026.
//

import XCTest
@testable import NasaApod

@MainActor
final class CacheServiceTests: XCTestCase {

    private var cacheService: CacheService!

    override func setUp() async throws {
        try await super.setUp()
        cacheService = try CacheService()
        // Clear cache before each test
        try await cacheService.clearCache()
    }

    override func tearDown() async throws {
        // Clear cache after each test
        try? await cacheService.clearCache()
        cacheService = nil
        try await super.tearDown()
    }

    // MARK: - Save and Load Tests

    func testSaveAndLoadReturnsAPOD() async throws {
        let apod = makeAPOD(date: "2024-01-15")

        try await cacheService.save(apod, forKey: "test-key")
        let loaded = try await cacheService.load(forKey: "test-key")

        let loadedDate = loaded.date
        let loadedTitle = loaded.title
        XCTAssertEqual(loadedDate, apod.date)
        XCTAssertEqual(loadedTitle, apod.title)
    }

    func testLoadWithEmptyKeyThrowsError() async {
        do {
            _ = try await cacheService.load(forKey: "")
            XCTFail("Expected error to be thrown")
        } catch let error as CacheError {
            XCTAssertEqual(error, .invalidKey)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSaveWithEmptyKeyThrowsError() async {
        let apod = makeAPOD()

        do {
            try await cacheService.save(apod, forKey: "")
            XCTFail("Expected error to be thrown")
        } catch let error as CacheError {
            XCTAssertEqual(error, .invalidKey)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testLoadNonExistentKeyThrowsNoDataError() async {
        do {
            _ = try await cacheService.load(forKey: "non-existent-key")
            XCTFail("Expected error to be thrown")
        } catch let error as CacheError {
            XCTAssertEqual(error, .noData)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Last Successful Tests

    func testSaveAndLoadLastSuccessful() async throws {
        let apod = makeAPOD(date: "2024-02-20", title: "Last Successful APOD")

        try await cacheService.saveLastSuccessful(apod)
        let loaded = try await cacheService.loadLastSuccessful()

        let loadedDate = loaded.date
        let loadedTitle = loaded.title
        XCTAssertEqual(loadedDate, "2024-02-20")
        XCTAssertEqual(loadedTitle, "Last Successful APOD")
    }

    func testLoadLastSuccessfulWhenNoneExistsThrowsError() async {
        do {
            _ = try await cacheService.loadLastSuccessful()
            XCTFail("Expected error to be thrown")
        } catch let error as CacheError {
            XCTAssertEqual(error, .noData)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSaveLastSuccessfulOverwritesPrevious() async throws {
        let firstAPOD = makeAPOD(date: "2024-01-01", title: "First")
        let secondAPOD = makeAPOD(date: "2024-02-02", title: "Second")

        try await cacheService.saveLastSuccessful(firstAPOD)
        try await cacheService.saveLastSuccessful(secondAPOD)

        let loaded = try await cacheService.loadLastSuccessful()

        let loadedDate = loaded.date
        let loadedTitle = loaded.title
        XCTAssertEqual(loadedDate, "2024-02-02")
        XCTAssertEqual(loadedTitle, "Second")
    }

    // MARK: - Clear Cache Tests

    func testClearCacheRemovesAllData() async throws {
        let apod1 = makeAPOD(date: "2024-01-01")
        let apod2 = makeAPOD(date: "2024-01-02")

        try await cacheService.save(apod1, forKey: "key1")
        try await cacheService.save(apod2, forKey: "key2")
        try await cacheService.saveLastSuccessful(apod1)

        try await cacheService.clearCache()

        // All loads should fail after clearing
        do {
            _ = try await cacheService.load(forKey: "key1")
            XCTFail("Expected error after clearing cache")
        } catch {
            // Expected
        }

        do {
            _ = try await cacheService.load(forKey: "key2")
            XCTFail("Expected error after clearing cache")
        } catch {
            // Expected
        }

        do {
            _ = try await cacheService.loadLastSuccessful()
            XCTFail("Expected error after clearing cache")
        } catch {
            // Expected
        }
    }

    // MARK: - Memory and Disk Cache Tests

    func testDataPersistsToDisk() async throws {
        let apod = makeAPOD(date: "2024-03-15")

        try await cacheService.save(apod, forKey: "persist-test")

        // Create new cache service instance (simulates app restart)
        let newCacheService = try CacheService()
        let loaded = try await newCacheService.load(forKey: "persist-test")

        let loadedDate = loaded.date
        XCTAssertEqual(loadedDate, "2024-03-15")
    }

    // MARK: - Multiple Keys Tests

    func testMultipleKeysStoredIndependently() async throws {
        let apod1 = makeAPOD(date: "2024-01-01", title: "First")
        let apod2 = makeAPOD(date: "2024-01-02", title: "Second")

        try await cacheService.save(apod1, forKey: "key1")
        try await cacheService.save(apod2, forKey: "key2")

        let loaded1 = try await cacheService.load(forKey: "key1")
        let loaded2 = try await cacheService.load(forKey: "key2")

        let loaded1Title = loaded1.title
        let loaded2Title = loaded2.title
        XCTAssertEqual(loaded1Title, "First")
        XCTAssertEqual(loaded2Title, "Second")
    }
}

// MARK: - Test Helpers

extension CacheServiceTests {
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
}

// MARK: - CacheError Equatable

extension CacheError: Equatable {
    public static func == (lhs: CacheError, rhs: CacheError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidKey, .invalidKey),
             (.noData, .noData),
             (.dataCorrupted, .dataCorrupted):
            return true
        case (.saveFailed, .saveFailed),
             (.loadFailed, .loadFailed):
            return true
        default:
            return false
        }
    }
}
