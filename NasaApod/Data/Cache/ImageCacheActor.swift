//
//  ImageCacheActor.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation
import UIKit

/// Thread-safe image cache using actor isolation
actor ImageCacheActor {
    // MARK: - Properties

    /// Underlying NSCache (not Sendable, so isolated in actor)
    private let cache = NSCache<NSString, UIImage>()

    /// Maximum memory cost (50 MB)
    private let maxMemoryCost = 50 * 1024 * 1024

    // MARK: - Initialization

    init() {
        cache.totalCostLimit = maxMemoryCost
        AppLogger.debug("Image cache initialized with \(maxMemoryCost / 1024 / 1024) MB limit", category: .cache)
    }

    // MARK: - Public Methods

    /// Store image in cache
    func setImage(_ image: UIImage, forKey key: String) {
        // Estimate cost based on image size
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
        cache.setObject(image, forKey: key as NSString, cost: cost)
        AppLogger.debug("Cached image: \(key) (cost: \(cost / 1024) KB)", category: .cache)
    }

    /// Retrieve image from cache
    func image(forKey key: String) -> UIImage? {
        let image = cache.object(forKey: key as NSString)

        if image != nil {
            AppLogger.logCacheHit(key: "image:\(key)")
        } else {
            AppLogger.logCacheMiss(key: "image:\(key)")
        }

        return image
    }

    /// Remove image from cache
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        AppLogger.debug("Removed image from cache: \(key)", category: .cache)
    }

    /// Clear all cached images
    func clearAll() {
        cache.removeAllObjects()
        AppLogger.info("Image cache cleared", category: .cache)
    }
}
