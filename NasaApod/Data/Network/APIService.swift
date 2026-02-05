//
//  APIService.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Protocol for API service (enables testing with mocks)
protocol APIServiceProtocol: Sendable {
    func fetchAPOD(for date: Date?) async throws -> APOD
}

/// API service implementation
struct APIService: APIServiceProtocol {
    private let session: URLSession
    private let retryPolicy: RetryPolicy

    // MARK: - Initialization

    init(
        session: URLSession = .shared,
        retryPolicy: RetryPolicy = .default
    ) {
        self.session = session
        self.retryPolicy = retryPolicy
    }

    // MARK: - API Methods

    /// Fetch APOD for a specific date
    /// - Parameter date: Date to fetch APOD for (nil = today)
    /// - Returns: APOD model
    /// - Throws: NetworkError or APODError
    func fetchAPOD(for date: Date?) async throws -> APOD {
        let endpoint = APODEndpoint.apod(date: date)
        let url = try endpoint.makeURL()

        // Enforce HTTPS
        guard url.scheme == "https" else {
            AppLogger.error("Attempted to use non-HTTPS URL: \(url)", category: .network)
            throw NetworkError.invalidURL
        }

        // Execute with retry logic
        return try await retryPolicy.execute {
            try await performRequest(url: url)
        }
    }

    // MARK: - Private Helpers

    private func performRequest(url: URL) async throws -> APOD {
        var request = URLRequest(url: url)
        request.timeoutInterval = Constants.API.timeoutInterval

        // Log request
        let startTime = Date()
        AppLogger.logRequest(url: url)

        do {
            // Perform network request
            let (data, response) = try await session.data(for: request)

            // Log response
            let duration = Date().timeIntervalSince(startTime)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            AppLogger.logResponse(url: url, statusCode: statusCode, duration: duration)

            // Validate HTTP response
            try validateResponse(response)

            // Decode APOD
            let apod = try decodeAPOD(from: data)

            // Validate APOD data
            try apod.validate()

            AppLogger.info("Successfully fetched APOD for date: \(apod.date)", category: .network)

            return apod

        } catch let urlError as URLError {
            AppLogger.logNetworkError(urlError, url: url)
            throw mapURLError(urlError)
        } catch let error {
            AppLogger.error("Request failed", error: error, category: .network)
            throw error
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(
                domain: "APIService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]
            ))
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    private func decodeAPOD(from data: Data) throws -> APOD {
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(APOD.self, from: data)
        } catch {
            AppLogger.error("JSON decoding failed", error: error, category: .network)

            #if DEBUG
            if let jsonString = String(data: data, encoding: .utf8) {
                AppLogger.debug("Response JSON: \(jsonString)", category: .network)
            }
            #endif

            throw NetworkError.decodingFailed(error)
        }
    }

    private func mapURLError(_ error: URLError) -> Error {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return APODError.networkUnavailable
        case .timedOut:
            return APODError.requestTimeout
        case .badURL, .unsupportedURL:
            return APODError.invalidURL
        default:
            return APODError.repositoryFailed(underlyingError: error)
        }
    }
}

// MARK: - Preview/Testing Mock

#if DEBUG
/// Mock API service for previews and testing
struct MockAPIService: APIServiceProtocol {
    var mockAPOD: APOD = .sample
    var shouldFail: Bool = false
    var errorToThrow: Error = APODError.networkUnavailable

    func fetchAPOD(for date: Date?) async throws -> APOD {
        // Simulate network delay
        try await Task.sleep(for: .seconds(0.5))

        if shouldFail {
            throw errorToThrow
        }

        return mockAPOD
    }
}
#endif
