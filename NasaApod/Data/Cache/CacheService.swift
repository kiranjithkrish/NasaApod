//
//  CacheService.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Protocol for cache service (enables testing)
protocol CacheServiceProtocol: Sendable {
    func save(_ apod: APOD, forKey key: String) async throws
    func load(forKey key: String) async throws -> APOD
    func saveLastSuccessful(_ apod: APOD) async throws
    func loadLastSuccessful() async throws -> APOD
    func clearCache() async throws
}

/// Thread-safe cache service using actor isolation
/// Note: Uses FileManager.default directly rather than injecting - see README for rationale
actor CacheService: CacheServiceProtocol {
    // MARK: - Properties

    /// In-memory cache for fast access
    private var memoryCache: [String: APOD] = [:]

    /// Cache directory URL
    private let cacheDirectory: URL

    // MARK: - Initialization

    init() throws {
        let fileManager = FileManager.default

        // Get caches directory
        guard let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw CacheError.saveFailed(underlyingError: NSError(
                domain: "CacheService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not access caches directory"]
            ))
        }

        // Create APOD cache subdirectory
        self.cacheDirectory = cachesURL.appendingPathComponent(Constants.Cache.directoryName)

        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        AppLogger.info("Cache directory: \(cacheDirectory.path)", category: .cache)
    }

    // MARK: - Public Methods

    /// Save APOD to cache (memory + disk)
    func save(_ apod: APOD, forKey key: String) async throws {
        guard !key.isEmpty else {
            throw CacheError.invalidKey
        }

        // Save to memory cache
        memoryCache[key] = apod
        AppLogger.logCacheSave(key: key)

        // Save to disk asynchronously
        try await saveToDisk(apod, forKey: key)
    }

    /// Load APOD from cache (memory → disk)
    func load(forKey key: String) async throws -> APOD {
        guard !key.isEmpty else {
            throw CacheError.invalidKey
        }

        // Check memory cache first
        if let cached = memoryCache[key] {
            AppLogger.logCacheHit(key: key)
            return cached
        }

        // Load from disk
        AppLogger.logCacheMiss(key: key)
        let apod = try await loadFromDisk(forKey: key)

        // Update memory cache
        memoryCache[key] = apod

        return apod
    }

    /// Save last successful APOD (for offline fallback)
    /// Clears previous cache to ensure only one APOD is stored
    func saveLastSuccessful(_ apod: APOD) async throws {
        // Clear previous cache (only keep last successful)
        try await clearCache()
        // Save with date as key
        try await save(apod, forKey: apod.date)
        AppLogger.info("Saved last successful APOD: \(apod.date)", category: .cache)
    }

    /// Load last successful APOD
    /// Loads the single cached APOD (scans directory for the one file)
    func loadLastSuccessful() async throws -> APOD {
        let fileManager = FileManager.default

        // Find the single cached file
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        let jsonFiles = contents.filter { $0.pathExtension == "json" }

        guard let firstFile = jsonFiles.first else {
            throw CacheError.noData
        }

        // Extract key from filename (e.g., "2024-02-06.json" → "2024-02-06")
        let key = firstFile.deletingPathExtension().lastPathComponent
        return try await load(forKey: key)
    }

    /// Clear all cached data
    func clearCache() async throws {
        // Clear memory cache
        memoryCache.removeAll()

        // Clear disk cache
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }

        AppLogger.info("Cache cleared", category: .cache)
    }

    // MARK: - Private Disk Operations

    /// Save APOD to disk with atomic write
    private func saveToDisk(_ apod: APOD, forKey key: String) async throws {
        let fileManager = FileManager.default
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        let tempURL = cacheDirectory.appendingPathComponent("\(key).tmp")

        do {
            // Encode APOD
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(apod)

            // Write to temp file
            try data.write(to: tempURL, options: .atomic)

            // Atomic rename (prevents corruption)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            try fileManager.moveItem(at: tempURL, to: fileURL)

            AppLogger.debug("Saved to disk: \(key)", category: .cache)

        } catch {
            // Clean up temp file if exists
            try? fileManager.removeItem(at: tempURL)
            throw CacheError.saveFailed(underlyingError: error)
        }
    }

    /// Load APOD from disk with validation
    private func loadFromDisk(forKey key: String) async throws -> APOD {
        let fileManager = FileManager.default
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw CacheError.noData
        }

        do {
            // Read data
            let data = try Data(contentsOf: fileURL)

            // Validate data is not empty
            guard !data.isEmpty else {
                throw CacheError.dataCorrupted
            }

            // Decode APOD
            let decoder = JSONDecoder()
            let apod = try decoder.decode(APOD.self, from: data)

            // Validate APOD
            try apod.validate()

            AppLogger.debug("Loaded from disk: \(key)", category: .cache)

            return apod

        } catch let decodingError as DecodingError {
            AppLogger.error("Cache data corrupted", error: decodingError, category: .cache)
            // Delete corrupted file
            try? fileManager.removeItem(at: fileURL)
            throw CacheError.dataCorrupted

        } catch {
            throw CacheError.loadFailed(underlyingError: error)
        }
    }
}

// MARK: - Preview/Testing Mock

#if DEBUG
/// Mock cache service for previews and testing
actor MockCacheService: CacheServiceProtocol {
    private var storage: [String: APOD] = [:]
    var shouldFail: Bool = false

    func save(_ apod: APOD, forKey key: String) async throws {
        if shouldFail {
            throw CacheError.saveFailed(underlyingError: NSError(domain: "Mock", code: -1))
        }
        storage[key] = apod
    }

    func load(forKey key: String) async throws -> APOD {
        if shouldFail {
            throw CacheError.loadFailed(underlyingError: NSError(domain: "Mock", code: -1))
        }
        guard let apod = storage[key] else {
            throw CacheError.noData
        }
        return apod
    }

    func saveLastSuccessful(_ apod: APOD) async throws {
        storage.removeAll()  // Clear previous (only keep last successful)
        try await save(apod, forKey: apod.date)
    }

    func loadLastSuccessful() async throws -> APOD {
        guard let firstEntry = storage.values.first else {
            throw CacheError.noData
        }
        return firstEntry
    }

    func clearCache() async throws {
        if shouldFail {
            throw CacheError.saveFailed(underlyingError: NSError(domain: "Mock", code: -1))
        }
        storage.removeAll()
    }
}
#endif
