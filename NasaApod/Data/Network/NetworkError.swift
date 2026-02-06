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
            switch statusCode {
            case 400:
                return "Invalid request. Please try again."
            case 401:
                return "Invalid API key. Please check your configuration."
            case 403:
                return "API access denied. You may have exceeded the rate limit."
            case 404:
                return "No APOD available for this date. NASA publishes daily on US Eastern Time."
            case 429:
                return "Too many requests. Please wait a moment and try again."
            case 400...499:
                return "Request failed (error \(statusCode)). Please try again."
            case 500...599:
                return "NASA server is temporarily unavailable. Please try again later."
            default:
                return "Unexpected response (status code: \(statusCode))"
            }
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
