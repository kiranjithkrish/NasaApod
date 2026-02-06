//
//  APODTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 03/02/2026.
//

import XCTest
@testable import NasaApod

@MainActor
final class APODTests: XCTestCase {

    // MARK: - JSON Decoding Tests

    func testDecodeAPODFromValidJSON() throws {
        // Given
        let json = """
        {
            "date": "2024-01-15",
            "title": "Test Title",
            "explanation": "Test explanation",
            "url": "https://example.com/image.jpg",
            "media_type": "image",
            "hdurl": "https://example.com/image_hd.jpg",
            "copyright": "NASA"
        }
        """.data(using: .utf8)!

        // When
        let apod = try JSONDecoder().decode(APOD.self, from: json)

        // Then
        XCTAssertEqual(apod.date, "2024-01-15")
        XCTAssertEqual(apod.title, "Test Title")
        XCTAssertEqual(apod.explanation, "Test explanation")
        XCTAssertEqual(apod.url, "https://example.com/image.jpg")
        XCTAssertEqual(apod.mediaType, .image)
        XCTAssertEqual(apod.hdurl, "https://example.com/image_hd.jpg")
        XCTAssertEqual(apod.copyright, "NASA")
    }

    func testDecodeAPODWithOptionalFieldsMissing() throws {
        // Given
        let json = """
        {
            "date": "2024-01-15",
            "title": "Test Title",
            "explanation": "Test explanation",
            "url": "https://example.com/video",
            "media_type": "video"
        }
        """.data(using: .utf8)!

        // When
        let apod = try JSONDecoder().decode(APOD.self, from: json)

        // Then
        XCTAssertNil(apod.hdurl)
        XCTAssertNil(apod.copyright)
    }

    func testDecodeAPODWithSnakeCaseMediaType() throws {
        // Given
        let json = """
        {
            "date": "2024-01-15",
            "title": "Test",
            "explanation": "Test",
            "url": "https://example.com",
            "media_type": "video"
        }
        """.data(using: .utf8)!

        // When
        let apod = try JSONDecoder().decode(APOD.self, from: json)

        // Then
        XCTAssertEqual(apod.mediaType, .video)
    }

    // MARK: - Identifiable Tests

    func testIdReturnsDate() {
        // Given
        let apod = makeAPOD(date: "2024-01-15")

        // Then
        XCTAssertEqual(apod.id, "2024-01-15")
    }

    // MARK: - Computed Properties Tests

    func testParsedDateReturnsValidDate() {
        // Given
        let apod = makeAPOD(date: "2024-01-15")

        // When
        let parsedDate = apod.parsedDate

        // Then
        XCTAssertNotNil(parsedDate)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: parsedDate!), 2024)
        XCTAssertEqual(calendar.component(.month, from: parsedDate!), 1)
        XCTAssertEqual(calendar.component(.day, from: parsedDate!), 15)
    }

    func testParsedDateReturnsNilForInvalidFormat() {
        // Given
        let apod = makeAPOD(date: "invalid-date")

        // Then
        XCTAssertNil(apod.parsedDate)
    }

    func testParsedDateReturnsNilForEmptyString() {
        // Given
        let apod = makeAPOD(date: "")

        // Then
        XCTAssertNil(apod.parsedDate)
    }

    func testHasHDVersionReturnsTrueWhenHdurlPresent() {
        // Given
        let apod = makeAPOD(hdurl: "https://example.com/hd.jpg")

        // Then
        XCTAssertTrue(apod.hasHDVersion)
    }

    func testHasHDVersionReturnsFalseWhenHdurlNil() {
        // Given
        let apod = makeAPOD(hdurl: nil)

        // Then
        XCTAssertFalse(apod.hasHDVersion)
    }

    func testHasHDVersionReturnsFalseWhenHdurlEmpty() {
        // Given
        let apod = makeAPOD(hdurl: "")

        // Then
        XCTAssertFalse(apod.hasHDVersion)
    }

    func testBestQualityURLReturnsHdurlWhenPresent() {
        // Given
        let apod = makeAPOD(url: "https://example.com/standard.jpg", hdurl: "https://example.com/hd.jpg")

        // Then
        XCTAssertEqual(apod.bestQualityURL, "https://example.com/hd.jpg")
    }

    func testBestQualityURLReturnsUrlWhenHdurlNil() {
        // Given
        let apod = makeAPOD(url: "https://example.com/standard.jpg", hdurl: nil)

        // Then
        XCTAssertEqual(apod.bestQualityURL, "https://example.com/standard.jpg")
    }

    func testIsImageReturnsTrueForImageMediaType() {
        // Given
        let apod = makeAPOD(mediaType: .image)

        // Then
        XCTAssertTrue(apod.isImage)
        XCTAssertFalse(apod.isVideo)
    }

    func testIsVideoReturnsTrueForVideoMediaType() {
        // Given
        let apod = makeAPOD(mediaType: .video)

        // Then
        XCTAssertTrue(apod.isVideo)
        XCTAssertFalse(apod.isImage)
    }

    // MARK: - Validation Tests

    func testValidatePassesForValidAPOD() throws {
        // Given
        let apod = makeAPOD(date: "2024-01-15")

        // Then
        XCTAssertNoThrow(try apod.validate())
    }

    func testValidateThrowsForEmptyDate() {
        // Given
        let apod = makeAPOD(date: "")

        // When/Then
        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidData(let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(reason, "Date is empty")
        }
    }

    func testValidateThrowsForEmptyTitle() {
        // Given
        let apod = makeAPOD(title: "")

        // When/Then
        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidData(let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(reason, "Title is empty")
        }
    }

    func testValidateThrowsForInvalidURL() {
        // Given
        let apod = makeAPOD(url: "")

        // When/Then
        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidData(let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(reason, "Invalid URL")
        }
    }

    func testValidateThrowsForInvalidDateFormat() {
        // Given
        let apod = makeAPOD(date: "01-15-2024") // Wrong format

        // When/Then
        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidData(let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(reason, "Invalid date format")
        }
    }

    func testValidateThrowsForDateBeforeEarliest() {
        // Given
        let apod = makeAPOD(date: "1990-01-01") // Before June 16, 1995

        // When/Then
        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidDateRange = error else {
                XCTFail("Expected invalidDateRange error")
                return
            }
        }
    }

    func testValidateThrowsForFutureDate() {
        // Given
        let apod = makeAPOD(date: "2099-01-01") // Far future

        // When/Then
        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidDateRange = error else {
                XCTFail("Expected invalidDateRange error")
                return
            }
        }
    }

    func testValidatePassesForEarliestValidDate() throws {
        // Given
        let apod = makeAPOD(date: "1995-06-16") // First APOD ever

        // Then
        XCTAssertNoThrow(try apod.validate())
    }
}

// MARK: - Test Helpers

extension APODTests {
    private func makeAPOD(
        date: String = "2024-01-15",
        title: String = "Test Title",
        explanation: String = "Test explanation",
        url: String = "https://example.com/image.jpg",
        mediaType: MediaType = .image,
        hdurl: String? = "https://example.com/hd.jpg",
        copyright: String? = "NASA"
    ) -> APOD {
        APOD(
            date: date,
            title: title,
            explanation: explanation,
            url: url,
            mediaType: mediaType,
            hdurl: hdurl,
            copyright: copyright
        )
    }
}
