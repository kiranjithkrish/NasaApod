//
//  CacheError.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Cache layer errors
enum CacheError: Error, LocalizedError, Sendable {
    case saveFailed(underlyingError: Error)
    case loadFailed(underlyingError: Error)
    case dataCorrupted
    case noData
    case invalidKey

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save to cache: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load from cache: \(error.localizedDescription)"
        case .dataCorrupted:
            return "Cached data is corrupted."
        case .noData:
            return "No data found in cache."
        case .invalidKey:
            return "Invalid cache key."
        }
    }
}
