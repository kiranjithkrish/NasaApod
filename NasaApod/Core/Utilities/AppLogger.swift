//
//  AppLogger.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation
import OSLog

/// Centralized logging system with structured levels
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.nasa.apod"

    // MARK: - Log Categories

    private static let general = Logger(subsystem: subsystem, category: "general")
    private static let network = Logger(subsystem: subsystem, category: "network")
    private static let cache = Logger(subsystem: subsystem, category: "cache")
    private static let ui = Logger(subsystem: subsystem, category: "ui")

    // MARK: - Log Levels

    /// Debug-level logging (disabled in Release)
    static func debug(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        logger(for: category).debug("\(message)")
        #endif
    }

    /// Info-level logging
    static func info(_ message: String, category: LogCategory = .general) {
        logger(for: category).info("\(message)")
    }

    /// Warning-level logging
    static func warning(_ message: String, category: LogCategory = .general) {
        logger(for: category).warning("\(message)")
    }

    /// Error-level logging
    static func error(_ message: String, error: Error? = nil, category: LogCategory = .general) {
        if let error = error {
            logger(for: category).error("\(message): \(error.localizedDescription)")
        } else {
            logger(for: category).error("\(message)")
        }
    }

    // MARK: - Network-Specific Logging

    /// Log network request
    static func logRequest(url: URL, method: String = "GET") {
        #if DEBUG
        network.debug("→ \(method) \(url.absoluteString)")
        #endif
    }

    /// Log network response
    static func logResponse(url: URL, statusCode: Int, duration: TimeInterval) {
        #if DEBUG
        network.debug("← \(statusCode) \(url.absoluteString) (\(String(format: "%.2f", duration))s)")
        #endif
    }

    /// Log network error
    static func logNetworkError(_ error: Error, url: URL) {
        network.error("Network error for \(url.absoluteString): \(error.localizedDescription)")
    }

    // MARK: - Cache-Specific Logging

    /// Log cache hit
    static func logCacheHit(key: String) {
        #if DEBUG
        cache.debug("✓ Cache HIT: \(key)")
        #endif
    }

    /// Log cache miss
    static func logCacheMiss(key: String) {
        #if DEBUG
        cache.debug("✗ Cache MISS: \(key)")
        #endif
    }

    /// Log cache save
    static func logCacheSave(key: String) {
        #if DEBUG
        cache.debug("💾 Cache SAVE: \(key)")
        #endif
    }

    // MARK: - Private Helpers

    private static func logger(for category: LogCategory) -> Logger {
        switch category {
        case .general:
            return general
        case .network:
            return network
        case .cache:
            return cache
        case .ui:
            return ui
        }
    }
}

// MARK: - Log Categories

enum LogCategory {
    case general
    case network
    case cache
    case ui
}
