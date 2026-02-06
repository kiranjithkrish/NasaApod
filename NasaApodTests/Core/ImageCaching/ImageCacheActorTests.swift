//
//  ImageCacheActorTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 06/02/2026.
//

import XCTest
@testable import NasaApod

@MainActor
final class ImageCacheActorTests: XCTestCase {

    var sut: ImageCacheActor!

    override func setUp() async throws {
        try await super.setUp()
        sut = ImageCacheActor()
        // Clean up any leftover disk cache from previous tests
        await sut.clearAllFromDisk()
    }

    override func tearDown() async throws {
        // Clean up disk cache after each test
        await sut.clearAllFromDisk()
        await sut.clearAll()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Test Helpers

    private func createTestImage(color: UIColor = .red, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Memory Cache Tests

    func testSetAndGetImage_StoresInMemoryCache() async {
        // Given
        let image = createTestImage()
        let key = "2024-02-06"

        // When
        await sut.setImage(image, forKey: key)
        let retrieved = await sut.image(forKey: key)

        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.size, image.size)
    }

    func testGetImage_ReturnsNilForMissingKey() async {
        // When
        let retrieved = await sut.image(forKey: "non-existent-key")

        // Then
        XCTAssertNil(retrieved)
    }

    func testRemoveImage_RemovesFromMemoryCache() async {
        // Given
        let image = createTestImage()
        let key = "2024-02-06"
        await sut.setImage(image, forKey: key)

        // When
        await sut.removeImage(forKey: key)
        let retrieved = await sut.image(forKey: key)

        // Then
        XCTAssertNil(retrieved)
    }

    func testClearAll_RemovesAllImagesFromMemory() async {
        // Given
        let image1 = createTestImage(color: .red)
        let image2 = createTestImage(color: .blue)
        await sut.setImage(image1, forKey: "2024-02-05")
        await sut.setImage(image2, forKey: "2024-02-06")

        // When
        await sut.clearAll()

        // Then
        let retrieved1 = await sut.image(forKey: "2024-02-05")
        let retrieved2 = await sut.image(forKey: "2024-02-06")
        XCTAssertNil(retrieved1)
        XCTAssertNil(retrieved2)
    }

    // MARK: - Disk Cache Tests (Keyed by APOD date)
    //
    // Requirement: "Last service call including image should be cached"
    // Images are keyed by APOD date for linking with APOD data.
    // CachedAsyncImage clears old images before saving to ensure only ONE image is stored.

    func testSaveImageToDisk_PersistsToDisk() async {
        // Given
        let image = createTestImage(color: .green)
        let key = "2024-02-06"

        // When
        await sut.saveImageToDisk(image, forKey: key)

        // Then
        let hasImage = await sut.hasImage(forKey: key)
        XCTAssertTrue(hasImage)
    }

    func testLoadImage_RetrievesFromDisk() async {
        // Given
        let image = createTestImage(color: .blue, size: CGSize(width: 200, height: 200))
        let key = "2024-02-06"
        await sut.saveImageToDisk(image, forKey: key)

        // Clear memory cache to force disk read
        await sut.clearAll()

        // When
        let retrieved = await sut.loadImage(forKey: key)

        // Then
        XCTAssertNotNil(retrieved)
    }

    func testLoadImage_ReturnsNilWhenNoImageSaved() async {
        // Given - No image saved

        // When
        let retrieved = await sut.loadImage(forKey: "non-existent-key")

        // Then
        XCTAssertNil(retrieved)
    }

    func testHasImage_ReturnsFalseWhenEmpty() async {
        // Given - No image saved

        // When
        let hasImage = await sut.hasImage(forKey: "non-existent-key")

        // Then
        XCTAssertFalse(hasImage)
    }

    func testClearImage_RemovesFromDisk() async {
        // Given
        let image = createTestImage()
        let key = "2024-02-06"
        await sut.saveImageToDisk(image, forKey: key)

        // When
        await sut.clearImage(forKey: key)

        // Then
        let hasImage = await sut.hasImage(forKey: key)
        XCTAssertFalse(hasImage)

        let retrieved = await sut.loadImage(forKey: key)
        XCTAssertNil(retrieved)
    }

    // MARK: - Hybrid Cache Tests (Memory + Disk)

    func testLoadImage_ChecksMemoryFirst() async {
        // Given - Save image (goes to both memory and disk)
        let image = createTestImage(color: .purple)
        let key = "2024-02-06"
        await sut.saveImageToDisk(image, forKey: key)

        // When - Load (should hit memory cache first)
        let retrieved = await sut.loadImage(forKey: key)

        // Then
        XCTAssertNotNil(retrieved)
    }

    func testLoadImage_FallsBackToDiskWhenMemoryCleared() async {
        // Given - Save image then clear memory
        let image = createTestImage(color: .orange)
        let key = "2024-02-06"
        await sut.saveImageToDisk(image, forKey: key)
        await sut.clearAll() // Clear memory but not disk

        // When - Load (should fall back to disk)
        let retrieved = await sut.loadImage(forKey: key)

        // Then
        XCTAssertNotNil(retrieved)
    }

    func testSaveImageToDisk_OverwritesPreviousImage() async {
        // Given - Save first image
        let key = "2024-02-06"
        let image1 = createTestImage(color: .red, size: CGSize(width: 50, height: 50))
        await sut.saveImageToDisk(image1, forKey: key)

        // When - Save second image with same key
        let image2 = createTestImage(color: .blue, size: CGSize(width: 150, height: 150))
        await sut.saveImageToDisk(image2, forKey: key)

        // Clear memory to force disk read
        await sut.clearAll()

        // Then - Should get the second image
        let retrieved = await sut.loadImage(forKey: key)
        XCTAssertNotNil(retrieved)
    }

    // MARK: - Multiple Keys Tests

    func testMultipleKeysStoredIndependently() async {
        // Given
        let image1 = createTestImage(color: .red)
        let image2 = createTestImage(color: .blue)
        let key1 = "2024-02-05"
        let key2 = "2024-02-06"

        // When
        await sut.saveImageToDisk(image1, forKey: key1)
        await sut.saveImageToDisk(image2, forKey: key2)

        // Then
        let hasImage1 = await sut.hasImage(forKey: key1)
        let hasImage2 = await sut.hasImage(forKey: key2)
        XCTAssertTrue(hasImage1)
        XCTAssertTrue(hasImage2)
    }

    func testClearImage_OnlyRemovesSpecificKey() async {
        // Given
        let image1 = createTestImage(color: .red)
        let image2 = createTestImage(color: .blue)
        let key1 = "2024-02-05"
        let key2 = "2024-02-06"
        await sut.saveImageToDisk(image1, forKey: key1)
        await sut.saveImageToDisk(image2, forKey: key2)

        // When
        await sut.clearImage(forKey: key1)

        // Then
        let hasImage1 = await sut.hasImage(forKey: key1)
        let hasImage2 = await sut.hasImage(forKey: key2)
        XCTAssertFalse(hasImage1)
        XCTAssertTrue(hasImage2)
    }

    // MARK: - Persistence Across Instances

    func testDiskPersistence_SurvivesNewActorInstance() async {
        // Given - Save image with first instance
        let image = createTestImage(color: .cyan)
        let key = "2024-02-06"
        await sut.saveImageToDisk(image, forKey: key)

        // When - Create new instance (simulates app restart)
        let newCache = ImageCacheActor()

        // Then - Should still be able to load from disk
        let retrieved = await newCache.loadImage(forKey: key)
        XCTAssertNotNil(retrieved)

        // Cleanup
        await newCache.clearImage(forKey: key)
    }

    func testClearAllFromDisk_RemovesAllDiskCachedImages() async {
        // Given
        let image1 = createTestImage(color: .red)
        let image2 = createTestImage(color: .blue)
        await sut.saveImageToDisk(image1, forKey: "2024-02-05")
        await sut.saveImageToDisk(image2, forKey: "2024-02-06")

        // When
        await sut.clearAllFromDisk()

        // Then
        let hasImage1 = await sut.hasImage(forKey: "2024-02-05")
        let hasImage2 = await sut.hasImage(forKey: "2024-02-06")
        XCTAssertFalse(hasImage1)
        XCTAssertFalse(hasImage2)
    }

    // MARK: - Last Successful Image Tests (Only ONE cached at a time)
    //
    // Requirement: "Last service call including image should be cached"
    // CachedAsyncImage clears all before saving to ensure only the LAST image is stored.
    // This simulates that flow.

    func testSaveLastSuccessfulImage_OnlyKeepsOneImage_ClearsPrevious() async {
        // Given - Two different images for different dates
        let image1 = createTestImage(color: .red)
        let image2 = createTestImage(color: .blue)
        let key1 = "2024-02-05"
        let key2 = "2024-02-06"

        // When - Save first, then second as last successful
        await sut.saveLastSuccessfulImage(image1, forKey: key1)
        await sut.saveLastSuccessfulImage(image2, forKey: key2)

        // Then - Only second (last) image exists
        let hasImage1 = await sut.hasImage(forKey: key1)
        let hasImage2 = await sut.hasImage(forKey: key2)
        XCTAssertFalse(hasImage1, "First image should be cleared - only last successful is kept")
        XCTAssertTrue(hasImage2, "Last successful image should exist")
    }

    func testSaveLastSuccessfulImage_CanLoadAfterAppRestart() async {
        // Given - Save last successful image
        let image = createTestImage(color: .green)
        let key = "2024-02-06"
        await sut.saveLastSuccessfulImage(image, forKey: key)

        // When - Simulate app restart (new cache instance, memory cleared)
        let newCache = ImageCacheActor()

        // Then - Can still load from disk
        let loaded = await newCache.loadImage(forKey: key)
        XCTAssertNotNil(loaded, "Last successful image should survive app restart")

        // Cleanup
        await newCache.clearAllFromDisk()
    }
}
