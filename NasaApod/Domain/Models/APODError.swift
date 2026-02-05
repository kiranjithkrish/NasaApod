//
//  APODError.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Errors specific to APOD domain
enum APODError: Error, LocalizedError, Sendable {
    // MARK: - Network Errors

    case networkUnavailable
    case requestFailed(statusCode: Int)
    case requestTimeout
    case invalidURL

    // MARK: - Data Errors

    case invalidData(reason: String)
    case decodingFailed(underlyingError: Error)
    case invalidDateRange(earliest: Date, latest: Date)

    // MARK: - Cache Errors

    case cacheUnavailable
    case cacheCorrupted
    case noCachedData

    // MARK: - Repository Errors

    case repositoryFailed(underlyingError: Error)
    case circuitBreakerOpen

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        // Network
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .requestFailed(let statusCode):
            return "Request failed with status code \(statusCode)."
        case .requestTimeout:
            return "The request timed out. Please try again."
        case .invalidURL:
            return "The URL is invalid."

        // Data
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .invalidDateRange(let earliest, let latest):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Date must be between \(formatter.string(from: earliest)) and \(formatter.string(from: latest))."

        // Cache
        case .cacheUnavailable:
            return "Cache is not available."
        case .cacheCorrupted:
            return "Cached data is corrupted."
        case .noCachedData:
            return "No cached data available. Please connect to the internet to load fresh data."

        // Repository
        case .repositoryFailed(let error):
            return "Repository error: \(error.localizedDescription)"
        case .circuitBreakerOpen:
            return "Service temporarily unavailable. Please try again later."
        }
    }

    var failureReason: String? {
        switch self {
        case .networkUnavailable:
            return "The device is not connected to the internet."
        case .requestFailed:
            return "The server returned an error response."
        case .requestTimeout:
            return "The request took too long to complete."
        case .invalidURL:
            return "The provided URL is malformed."
        case .invalidData:
            return "The data received from the server is invalid."
        case .decodingFailed:
            return "The data could not be decoded into the expected format."
        case .invalidDateRange:
            return "The date is outside the valid range for APOD data."
        case .cacheUnavailable:
            return "The caching system is not accessible."
        case .cacheCorrupted:
            return "The cached data failed validation checks."
        case .noCachedData:
            return "No data has been cached yet."
        case .repositoryFailed:
            return "An error occurred in the data repository."
        case .circuitBreakerOpen:
            return "Too many failures have occurred. The system is temporarily disabled."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Connect to Wi-Fi or cellular data and try again."
        case .requestFailed:
            return "Please try again. If the problem persists, contact support."
        case .requestTimeout:
            return "Check your internet connection and try again."
        case .invalidURL:
            return "This appears to be a configuration error. Please contact support."
        case .invalidData, .decodingFailed:
            return "Try again later. If the problem persists, the API may have changed."
        case .invalidDateRange:
            return "Choose a date within the valid range."
        case .cacheUnavailable, .cacheCorrupted:
            return "The app will attempt to reload fresh data."
        case .noCachedData:
            return "Connect to the internet to download the latest data."
        case .repositoryFailed:
            return "Please try again."
        case .circuitBreakerOpen:
            return "Wait a few moments and try again."
        }
    }
}

// MARK: - Error Conversion

extension APODError {
    /// Convert URLError to APODError
    static func from(urlError: URLError) -> APODError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .requestTimeout
        case .badURL, .unsupportedURL:
            return .invalidURL
        default:
            return .repositoryFailed(underlyingError: urlError)
        }
    }

    /// Convert DecodingError to APODError
    static func from(decodingError: DecodingError) -> APODError {
        return .decodingFailed(underlyingError: decodingError)
    }
}

// MARK: - Equatable

extension APODError: Equatable {
    static func == (lhs: APODError, rhs: APODError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable),
             (.requestTimeout, .requestTimeout),
             (.invalidURL, .invalidURL),
             (.cacheUnavailable, .cacheUnavailable),
             (.cacheCorrupted, .cacheCorrupted),
             (.noCachedData, .noCachedData),
             (.circuitBreakerOpen, .circuitBreakerOpen):
            return true
        case (.requestFailed(let lhsCode), .requestFailed(let rhsCode)):
            return lhsCode == rhsCode
        case (.invalidData(let lhsReason), .invalidData(let rhsReason)):
            return lhsReason == rhsReason
        case (.invalidDateRange(let lhsEarliest, let lhsLatest), .invalidDateRange(let rhsEarliest, let rhsLatest)):
            return lhsEarliest == rhsEarliest && lhsLatest == rhsLatest
        case (.decodingFailed, .decodingFailed),
             (.repositoryFailed, .repositoryFailed):
            // Only compare case type, not underlying error
            return true
        default:
            return false
        }
    }
}
