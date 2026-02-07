//
//  APODEndpoint.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// APOD API endpoints
enum APODEndpoint {
    case apod(date: Date?)

    // MARK: - URL Construction

    /// Construct full URL with query parameters
    nonisolated func makeURL() throws -> URL {
        guard var components = URLComponents(string: Constants.API.baseURL) else {
            throw NetworkError.invalidURL
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        return url
    }

    // MARK: - Query Parameters

    private nonisolated var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: Constants.API.apiKey),
            URLQueryItem(name: "thumbs", value: "true")  // Request video thumbnails
        ]

        switch self {
        case .apod(let date):
            if let date = date {
                let dateString = formatDate(date)
                items.append(URLQueryItem(name: "date", value: dateString))
            }
        }

        return items
    }

    // MARK: - Date Formatting

    private nonisolated func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }
}
