//
//  NetworkError.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Network layer errors
enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case httpError(statusCode: Int)
    case noData
    case decodingFailed(Error)
    case networkUnavailable
    case timeout
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .noData:
            return "No data received from server."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network connection unavailable."
        case .timeout:
            return "Request timed out."
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
