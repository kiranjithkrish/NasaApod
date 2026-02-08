//
//  APODRepositoryProtocol.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Protocol for APOD repository
protocol APODRepositoryProtocol: Sendable {
    /// Fetch APOD for a specific date
    /// Network → Cache fallback strategy
    /// - Parameter date: Date to fetch APOD for
    /// - Returns: FetchResult indicating fresh data or cached fallback
    /// - Throws: APODError if both network and cache fail
    func fetchAPOD(for date: Date) async throws -> FetchResult

    /// Check if repository is available (not in circuit breaker open state)
    func isAvailable() async -> Bool

    /// Reset circuit breaker (for manual recovery)
    func reset() async
}
