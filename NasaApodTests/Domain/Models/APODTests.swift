//
//  APODTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 03/02/2026.
//

import XCTest
@testable import NasaApod

final class APODTests: XCTestCase {

    // MARK: - JSON Decoding Tests

    func testDecodeAPODFromValidJSON() throws {
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

        let apod = try JSONDecoder().decode(APOD.self, from: json)

        XCTAssertEqual(apod.date, "2024-01-15")
        XCTAssertEqual(apod.title, "Test Title")
        XCTAssertEqual(apod.explanation, "Test explanation")
        XCTAssertEqual(apod.url, "https://example.com/image.jpg")
        XCTAssertEqual(apod.mediaType, .image)
        XCTAssertEqual(apod.hdurl, "https://example.com/image_hd.jpg")
        XCTAssertEqual(apod.copyright, "NASA")
    }

    func testDecodeAPODWithOptionalFieldsMissing() throws {
        let json = """
        {
            "date": "2024-01-15",
            "title": "Test Title",
            "explanation": "Test explanation",
            "url": "https://example.com/video",
            "media_type": "video"
        }
        """.data(using: .utf8)!

        let apod = try JSONDecoder().decode(APOD.self, from: json)

        XCTAssertNil(apod.hdurl)
        XCTAssertNil(apod.copyright)
    }

    func testDecodeAPODWithSnakeCaseMediaType() throws {
        let json = """
        {
            "date": "2024-01-15",
            "title": "Test",
            "explanation": "Test",
            "url": "https://example.com",
            "media_type": "video"
        }
        """.data(using: .utf8)!

        let apod = try JSONDecoder().decode(APOD.self, from: json)

        XCTAssertEqual(apod.mediaType, .video)
    }

    // MARK: - Identifiable Tests

    func testIdReturnsDate() {
        let apod = makeAPOD(date: "2024-01-15")

        XCTAssertEqual(apod.id, "2024-01-15")
    }

    // MARK: - Computed Properties Tests

    func testParsedDateReturnsValidDate() {
        let apod = makeAPOD(date: "2024-01-15")

        let parsedDate = apod.parsedDate

        XCTAssertNotNil(parsedDate)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.year, from: parsedDate!), 2024)
        XCTAssertEqual(calendar.component(.month, from: parsedDate!), 1)
        XCTAssertEqual(calendar.component(.day, from: parsedDate!), 15)
    }

    func testParsedDateReturnsNilForInvalidFormat() {
        let apod = makeAPOD(date: "invalid-date")

        XCTAssertNil(apod.parsedDate)
    }

    func testParsedDateReturnsNilForEmptyString() {
        let apod = makeAPOD(date: "")

        XCTAssertNil(apod.parsedDate)
    }

    func testHasHDVersionReturnsTrueWhenHdurlPresent() {
        let apod = makeAPOD(hdurl: "https://example.com/hd.jpg")

        XCTAssertTrue(apod.hasHDVersion)
    }

    func testHasHDVersionReturnsFalseWhenHdurlNil() {
        let apod = makeAPOD(hdurl: nil)

        XCTAssertFalse(apod.hasHDVersion)
    }

    func testHasHDVersionReturnsFalseWhenHdurlEmpty() {
        let apod = makeAPOD(hdurl: "")

        XCTAssertFalse(apod.hasHDVersion)
    }

    func testBestQualityURLReturnsHdurlWhenPresent() {
        let apod = makeAPOD(url: "https://example.com/standard.jpg", hdurl: "https://example.com/hd.jpg")

        XCTAssertEqual(apod.bestQualityURL, "https://example.com/hd.jpg")
    }

    func testBestQualityURLReturnsUrlWhenHdurlNil() {
        let apod = makeAPOD(url: "https://example.com/standard.jpg", hdurl: nil)

        XCTAssertEqual(apod.bestQualityURL, "https://example.com/standard.jpg")
    }

    func testIsImageReturnsTrueForImageMediaType() {
        let apod = makeAPOD(mediaType: .image)

        XCTAssertTrue(apod.isImage)
        XCTAssertFalse(apod.isVideo)
    }

    func testIsVideoReturnsTrueForVideoMediaType() {
        let apod = makeAPOD(mediaType: .video)

        XCTAssertTrue(apod.isVideo)
        XCTAssertFalse(apod.isImage)
    }

    // MARK: - Validation Tests

    func testValidatePassesForValidAPOD() throws {
        let apod = makeAPOD(date: "2024-01-15")

        XCTAssertNoThrow(try apod.validate())
    }

    func testValidateThrowsForEmptyDate() {
        let apod = makeAPOD(date: "")

        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidData(let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(reason, "Date is empty")
        }
    }

    func testValidateThrowsForEmptyTitle() {
        let apod = makeAPOD(title: "")

        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidData(let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(reason, "Title is empty")
        }
    }

    func testValidateThrowsForInvalidURL() {
        let apod = makeAPOD(url: "")

        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidData(let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(reason, "Invalid URL")
        }
    }

    func testValidateThrowsForInvalidDateFormat() {
        let apod = makeAPOD(date: "01-15-2024") // Wrong format

        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidData(let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(reason, "Invalid date format")
        }
    }

    func testValidateThrowsForDateBeforeEarliest() {
        let apod = makeAPOD(date: "1990-01-01") // Before June 16, 1995

        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidDateRange = error else {
                XCTFail("Expected invalidDateRange error")
                return
            }
        }
    }

    func testValidateThrowsForFutureDate() {
        let apod = makeAPOD(date: "2099-01-01") // Far future

        XCTAssertThrowsError(try apod.validate()) { error in
            guard case APODError.invalidDateRange = error else {
                XCTFail("Expected invalidDateRange error")
                return
            }
        }
    }

    func testValidatePassesForEarliestValidDate() throws {
        let apod = makeAPOD(date: "1995-06-16") // First APOD ever

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
