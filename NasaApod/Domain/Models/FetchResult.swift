//
//  FetchResult.swift
//  NasaApod
//
//  Created by kiranjith k k on 08/02/2026.
//

import Foundation

/// Result of an APOD fetch, distinguishing fresh network data from cached fallback
enum FetchResult: Sendable, Equatable {
    /// Fresh data from the network
    case fresh(APOD)

    /// Cached fallback returned because the network was unavailable
    case cachedFallback(APOD)

    /// The APOD regardless of source
    var apod: APOD {
        switch self {
        case .fresh(let apod), .cachedFallback(let apod):
            return apod
        }
    }

    /// Whether this result is a cached fallback
    var isCachedFallback: Bool {
        if case .cachedFallback = self { return true }
        return false
    }
}
