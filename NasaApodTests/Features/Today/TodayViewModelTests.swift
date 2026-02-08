//
//  TodayViewModelTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 08/02/2026.
//

import XCTest
@testable import NasaApod

@MainActor
final class TodayViewModelTests: XCTestCase {

    // MARK: - refreshIfStale Tests

    func testRefreshIfStale_WhenAPODIsFromYesterday_Reloads() async {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let yesterdayString = formatter.string(from: yesterday)

        let staleAPOD = makeAPOD(date: yesterdayString, title: "Yesterday's APOD")
        let freshAPOD = makeAPOD(date: formatter.string(from: Date()), title: "Today's APOD")
        let mock = MockTodayRepository(result: .fresh(freshAPOD))
        let viewModel = TodayViewModel(repository: mock)
        viewModel.state = .loaded(staleAPOD)

        // When
        await viewModel.refreshIfStale()

        // Then
        XCTAssertEqual(viewModel.state.value?.title, "Today's APOD")
    }

    func testRefreshIfStale_WhenAPODIsFromToday_DoesNotReload() async {
        // Given
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let todayString = formatter.string(from: Date())

        let todayAPOD = makeAPOD(date: todayString, title: "Today's APOD")
        let mock = MockTodayRepository(result: .fresh(todayAPOD))
        let viewModel = TodayViewModel(repository: mock)
        viewModel.state = .loaded(todayAPOD)

        // When
        await viewModel.refreshIfStale()

        // Then - state unchanged, still the same APOD
        XCTAssertEqual(viewModel.state.value?.title, "Today's APOD")
        XCTAssertEqual(mock.fetchCallCount, 0)
    }

    func testRefreshIfStale_WhenIdle_DoesNothing() async {
        // Given
        let mock = MockTodayRepository(result: .fresh(makeAPOD()))
        let viewModel = TodayViewModel(repository: mock)

        // When
        await viewModel.refreshIfStale()

        // Then
        XCTAssertTrue(viewModel.state.isIdle)
        XCTAssertEqual(mock.fetchCallCount, 0)
    }

    func testRefreshIfStale_WhenFailed_DoesNothing() async {
        // Given
        let mock = MockTodayRepository(result: .fresh(makeAPOD()))
        let viewModel = TodayViewModel(repository: mock)
        viewModel.state = .failed(APODError.networkUnavailable)

        // When
        await viewModel.refreshIfStale()

        // Then
        XCTAssertNotNil(viewModel.state.error)
        XCTAssertEqual(mock.fetchCallCount, 0)
    }
}

// MARK: - Test Helpers

extension TodayViewModelTests {
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
}

// MARK: - Mock Repository

private final class MockTodayRepository: APODRepositoryProtocol, @unchecked Sendable {
    private let result: FetchResult
    private(set) var fetchCallCount = 0

    init(result: FetchResult) {
        self.result = result
    }

    func fetchAPOD(for date: Date) async throws -> FetchResult {
        fetchCallCount += 1
        return result
    }

    func isAvailable() async -> Bool { true }

    func reset() async {}
}
