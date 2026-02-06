//
//  APODEndpointTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 05/02/2026.
//

import XCTest
@testable import NasaApod

final class APODEndpointTests: XCTestCase {

    // MARK: - URL Construction Tests

    func testMakeURLWithNilDateReturnsValidURL() throws {
        // Given
        let endpoint = APODEndpoint.apod(date: nil)

        // When
        let url = try endpoint.makeURL()

        // Then
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "api.nasa.gov")
        XCTAssertTrue(url.path.contains("apod"))
    }

    func testMakeURLContainsAPIKey() throws {
        // Given
        let endpoint = APODEndpoint.apod(date: nil)

        // When
        let url = try endpoint.makeURL()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let apiKeyItem = components?.queryItems?.first { $0.name == "api_key" }

        // Then
        XCTAssertNotNil(apiKeyItem)
        XCTAssertEqual(apiKeyItem?.value, Constants.API.apiKey)
    }

    func testMakeURLWithDateContainsDateParameter() throws {
        // Given
        let date = makeDate(year: 2024, month: 6, day: 15)
        let endpoint = APODEndpoint.apod(date: date)

        // When
        let url = try endpoint.makeURL()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let dateItem = components?.queryItems?.first { $0.name == "date" }

        // Then
        XCTAssertNotNil(dateItem)
        XCTAssertEqual(dateItem?.value, "2024-06-15")
    }

    func testMakeURLWithNilDateDoesNotContainDateParameter() throws {
        // Given
        let endpoint = APODEndpoint.apod(date: nil)

        // When
        let url = try endpoint.makeURL()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let dateItem = components?.queryItems?.first { $0.name == "date" }

        // Then
        XCTAssertNil(dateItem)
    }

    // MARK: - Date Formatting Tests

    func testDateFormattingUsesISO8601Format() throws {
        // Given
        let date = makeDate(year: 1995, month: 6, day: 16)
        let endpoint = APODEndpoint.apod(date: date)

        // When
        let url = try endpoint.makeURL()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let dateItem = components?.queryItems?.first { $0.name == "date" }

        // Then
        XCTAssertEqual(dateItem?.value, "1995-06-16")
    }

    func testDateFormattingHandlesSingleDigitMonthAndDay() throws {
        // Given
        let date = makeDate(year: 2024, month: 1, day: 5)
        let endpoint = APODEndpoint.apod(date: date)

        // When
        let url = try endpoint.makeURL()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let dateItem = components?.queryItems?.first { $0.name == "date" }

        // Then
        XCTAssertEqual(dateItem?.value, "2024-01-05")
    }
}

// MARK: - Test Helpers

extension APODEndpointTests {
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }
}
