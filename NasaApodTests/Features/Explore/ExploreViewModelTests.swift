//
//  ExploreViewModelTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 08/02/2026.
//

import XCTest
@testable import NasaApod

@MainActor
final class ExploreViewModelTests: XCTestCase {

    // MARK: - Fresh Result Tests

    func testLoadAPOD_FreshResult_StateContainsFresh() async {
        // Given
        let expectedAPOD = makeAPOD(date: "2024-01-15", title: "Fresh APOD")
        let mock = MockExploreRepository(result: .fresh(expectedAPOD))
        let viewModel = ExploreViewModel(repository: mock)

        // When
        await viewModel.loadAPOD()

        // Then
        XCTAssertEqual(viewModel.state.value, .fresh(expectedAPOD))
        XCTAssertFalse(viewModel.state.value?.isCachedFallback ?? true)
    }

    // MARK: - Cached Fallback Tests

    func testLoadAPOD_CachedFallback_StateContainsCachedFallback() async {
        // Given
        let cachedAPOD = makeAPOD(date: "2024-01-10", title: "Cached APOD")
        let mock = MockExploreRepository(result: .cachedFallback(cachedAPOD))
        let viewModel = ExploreViewModel(repository: mock)
        viewModel.selectedDate = makeDateFromString("2024-01-15")

        // When
        await viewModel.loadAPOD()

        // Then
        XCTAssertTrue(viewModel.state.value?.isCachedFallback ?? false)
        XCTAssertEqual(viewModel.state.value?.apod.title, "Cached APOD")
    }

    func testLoadAPOD_CachedFallback_SyncsDatePickerToCachedDate() async {
        // Given
        let cachedAPOD = makeAPOD(date: "2024-01-10", title: "Cached APOD")
        let mock = MockExploreRepository(result: .cachedFallback(cachedAPOD))
        let viewModel = ExploreViewModel(repository: mock)
        viewModel.selectedDate = makeDateFromString("2024-01-15")

        // When
        await viewModel.loadAPOD()

        // Then - selectedDate should sync to the cached APOD's date
        let expectedDate = makeDateFromString("2024-01-10")
        XCTAssertEqual(
            Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate),
            Calendar.current.dateComponents([.year, .month, .day], from: expectedDate)
        )
    }

    func testLoadAPOD_FreshResult_DoesNotChangeSelectedDate() async {
        // Given
        let freshAPOD = makeAPOD(date: "2024-01-15", title: "Fresh APOD")
        let mock = MockExploreRepository(result: .fresh(freshAPOD))
        let viewModel = ExploreViewModel(repository: mock)
        let originalDate = makeDateFromString("2024-01-15")
        viewModel.selectedDate = originalDate

        // When
        await viewModel.loadAPOD()

        // Then - selectedDate unchanged
        XCTAssertEqual(
            Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate),
            Calendar.current.dateComponents([.year, .month, .day], from: originalDate)
        )
    }

    // MARK: - Error Tests

    func testLoadAPOD_Error_StateIsFailed() async {
        // Given
        let mock = MockExploreRepository(error: APODError.networkUnavailable)
        let viewModel = ExploreViewModel(repository: mock)

        // When
        await viewModel.loadAPOD()

        // Then
        XCTAssertNotNil(viewModel.state.error)
        XCTAssertNil(viewModel.state.value)
    }

    // MARK: - Date Changed Tests

    func testDateChanged_TriggersLoad() async {
        // Given
        let apod = makeAPOD(date: "2024-01-20", title: "New Date APOD")
        let mock = MockExploreRepository(result: .fresh(apod))
        let viewModel = ExploreViewModel(repository: mock)
        viewModel.selectedDate = makeDateFromString("2024-01-20")

        // When
        await viewModel.dateChanged()

        // Then
        XCTAssertEqual(viewModel.state.value?.apod.title, "New Date APOD")
    }
}

// MARK: - Test Helpers

extension ExploreViewModelTests {
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
            copyright: nil,
            thumbnailUrl: nil
        )
    }

    private func makeDateFromString(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - Mock Repository

private struct MockExploreRepository: APODRepositoryProtocol {
    private let result: FetchResult?
    private let error: APODError?

    init(result: FetchResult) {
        self.result = result
        self.error = nil
    }

    init(error: APODError) {
        self.result = nil
        self.error = error
    }

    func fetchAPOD(for date: Date) async throws -> FetchResult {
        if let error {
            throw error
        }
        return result!
    }

    func isAvailable() async -> Bool { true }

    func reset() async {}
}
