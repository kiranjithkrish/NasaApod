//
//  NetworkErrorTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 06/02/2026.
//

import XCTest
@testable import NasaApod

final class NetworkErrorTests: XCTestCase {

    // MARK: - isRetryable Tests

    func testIsRetryable_ClientErrors_NotRetryable() {
        // Given - Client errors (4xx) should NOT be retried
        let clientErrors = [400, 401, 403, 404, 429]

        for statusCode in clientErrors {
            // When
            let error = NetworkError.httpError(statusCode: statusCode)

            // Then
            XCTAssertFalse(error.isRetryable, "HTTP \(statusCode) should NOT be retryable")
        }
    }

    func testIsRetryable_ServerErrors_Retryable() {
        // Given - Server errors (5xx) SHOULD be retried
        let serverErrors = [500, 502, 503, 504]

        for statusCode in serverErrors {
            // When
            let error = NetworkError.httpError(statusCode: statusCode)

            // Then
            XCTAssertTrue(error.isRetryable, "HTTP \(statusCode) SHOULD be retryable")
        }
    }

    func testIsRetryable_TransientNetworkErrors_Retryable() {
        // Given - Transient network issues SHOULD be retried
        let transientErrors: [NetworkError] = [.timeout, .networkUnavailable]

        for error in transientErrors {
            // Then
            XCTAssertTrue(error.isRetryable, "\(error) SHOULD be retryable")
        }
    }

    func testIsRetryable_PermanentErrors_NotRetryable() {
        // Given - Permanent/parsing errors should NOT be retried
        let permanentErrors: [NetworkError] = [
            .invalidURL,
            .noData,
            .decodingFailed(NSError(domain: "test", code: 0)),
            .unknown(NSError(domain: "test", code: 0))
        ]

        for error in permanentErrors {
            // Then
            XCTAssertFalse(error.isRetryable, "\(error) should NOT be retryable")
        }
    }

    // MARK: - Error Description Tests

    func testErrorDescription_429_MentionsRateLimit() {
        // Given
        let error = NetworkError.httpError(statusCode: 429)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.lowercased().contains("too many requests"))
    }

    func testErrorDescription_401_MentionsAPIKey() {
        // Given
        let error = NetworkError.httpError(statusCode: 401)

        // When
        let description = error.errorDescription

        // Then
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.lowercased().contains("api key"))
    }
}
