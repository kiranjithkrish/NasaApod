//
//  ImageCacheActor.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation
import UIKit

/// Thread-safe image cache using actor isolation
/// Provides hybrid memory + disk caching for offline support
/// Images are keyed by APOD date for proper linking with APOD data
actor ImageCacheActor {
    // MARK: - Properties

    /// Underlying NSCache for memory caching (not Sendable, so isolated in actor)
    private let cache = NSCache<NSString, UIImage>()

    /// Maximum memory cost (50 MB)
    private let maxMemoryCost = 50 * 1024 * 1024

    /// File manager for disk operations
    private let fileManager = FileManager.default

    // MARK: - Initialization

    init() {
        cache.totalCostLimit = maxMemoryCost
        AppLogger.debug("Image cache initialized with \(maxMemoryCost / 1024 / 1024) MB limit", category: .cache)
    }

    // MARK: - Memory Cache Methods

    /// Store image in memory cache
    func setImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
        cache.setObject(image, forKey: key as NSString, cost: cost)
        AppLogger.debug("Cached image in memory: \(key) (cost: \(cost / 1024) KB)", category: .cache)
    }

    /// Retrieve image from memory cache
    func image(forKey key: String) -> UIImage? {
        let image = cache.object(forKey: key as NSString)

        if image != nil {
            AppLogger.logCacheHit(key: "image:\(key)")
        } else {
            AppLogger.logCacheMiss(key: "image:\(key)")
        }

        return image
    }

    /// Remove image from memory cache
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        AppLogger.debug("Removed image from memory cache: \(key)", category: .cache)
    }

    /// Clear all cached images from memory
    func clearAll() {
        cache.removeAllObjects()
        AppLogger.info("Memory image cache cleared", category: .cache)
    }

    // MARK: - Last Successful Image (Only ONE cached at a time)
    //
    // Requirement: "Last service call including image should be cached"
    // Only the LAST successful image is stored, not every image loaded.

    /// Save as last successful image - clears previous and saves new
    /// This ensures only ONE image is cached at a time (the last successful one)
    func saveLastSuccessfulImage(_ image: UIImage, forKey key: String) {
        clearAllFromDisk()
        saveImageToDisk(image, forKey: key)
    }

    // MARK: - Disk Cache Methods (Keyed by APOD identifier)

    /// Save image to disk for offline access, keyed by APOD identifier (e.g., date)
    func saveImageToDisk(_ image: UIImage, forKey key: String) {
        // Also save to memory cache
        setImage(image, forKey: key)

        // Save to disk
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            AppLogger.warning("Failed to convert image to JPEG data for key: \(key)", category: .cache)
            return
        }

        do {
            let url = try diskImageURL(forKey: key)
            try data.write(to: url, options: .atomic)
            AppLogger.info("Saved image to disk for key: \(key) (\(data.count / 1024) KB)", category: .cache)
        } catch {
            AppLogger.error("Failed to save image to disk for key: \(key)", error: error, category: .cache)
        }
    }

    /// Load image from cache (checks memory first, then disk)
    func loadImage(forKey key: String) -> UIImage? {
        // Check memory first
        if let memoryImage = cache.object(forKey: key as NSString) {
            AppLogger.logCacheHit(key: "image:\(key) (memory)")
            return memoryImage
        }

        // Fall back to disk
        do {
            let url = try diskImageURL(forKey: key)
            guard fileManager.fileExists(atPath: url.path) else {
                AppLogger.logCacheMiss(key: "image:\(key) (disk)")
                return nil
            }

            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else {
                AppLogger.warning("Failed to decode image from disk for key: \(key)", category: .cache)
                return nil
            }

            // Restore to memory cache
            setImage(image, forKey: key)
            AppLogger.logCacheHit(key: "image:\(key) (disk)")
            return image
        } catch {
            AppLogger.error("Failed to load image from disk for key: \(key)", error: error, category: .cache)
            return nil
        }
    }

    /// Check if image exists in cache (memory or disk)
    func hasImage(forKey key: String) -> Bool {
        // Check memory
        if cache.object(forKey: key as NSString) != nil {
            return true
        }

        // Check disk
        do {
            let url = try diskImageURL(forKey: key)
            return fileManager.fileExists(atPath: url.path)
        } catch {
            return false
        }
    }

    /// Clear image from both memory and disk for a specific key
    func clearImage(forKey key: String) {
        // Clear from memory
        cache.removeObject(forKey: key as NSString)

        // Clear from disk
        do {
            let url = try diskImageURL(forKey: key)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
                AppLogger.info("Cleared image from disk for key: \(key)", category: .cache)
            }
        } catch {
            AppLogger.error("Failed to clear image from disk for key: \(key)", error: error, category: .cache)
        }
    }

    /// Clear all images from both memory and disk cache
    func clearAllFromDisk() {
        // Clear memory cache first
        cache.removeAllObjects()

        // Clear disk cache
        do {
            let cacheDirectory = try imageCacheDirectory()
            if fileManager.fileExists(atPath: cacheDirectory.path) {
                try fileManager.removeItem(at: cacheDirectory)
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
                AppLogger.info("Cleared all images from memory and disk cache", category: .cache)
            }
        } catch {
            AppLogger.error("Failed to clear all images from disk", error: error, category: .cache)
        }
    }

    // MARK: - Private Helpers

    private func imageCacheDirectory() throws -> URL {
        let cacheDirectory = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let imageDir = cacheDirectory.appendingPathComponent("APODImages", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: imageDir.path) {
            try fileManager.createDirectory(at: imageDir, withIntermediateDirectories: true)
        }

        return imageDir
    }

    private func diskImageURL(forKey key: String) throws -> URL {
        let directory = try imageCacheDirectory()
        // Sanitize key for filename (replace invalid characters)
        let sanitizedKey = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return directory.appendingPathComponent("\(sanitizedKey).jpg")
    }
}
