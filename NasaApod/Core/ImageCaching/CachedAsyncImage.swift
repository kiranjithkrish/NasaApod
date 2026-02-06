//
//  CachedAsyncImage.swift
//  NasaApod
//
//  Created by kiranjith k k on 06/02/2026.
//

import SwiftUI

/// A cached version of AsyncImage that uses ImageCacheActor for hybrid memory + disk caching
/// Images are keyed by APOD identifier (date) to link with APOD data for offline support
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let cacheKey: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    private let imageCache: ImageCacheActor

    /// Initialize with URL to fetch and cache key to store/retrieve
    /// - Parameters:
    ///   - url: The URL to fetch the image from
    ///   - cacheKey: The key to use for caching (typically APOD date for linking with APOD data)
    ///   - imageCache: The image cache actor
    ///   - content: View builder for displaying the loaded image
    ///   - placeholder: View builder for displaying while loading or on failure
    init(
        url: URL?,
        cacheKey: String,
        imageCache: ImageCacheActor,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.cacheKey = cacheKey
        self.imageCache = imageCache
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else { return }

        // 1. Check cache first (memory → disk)
        if let cachedImage = await imageCache.loadImage(forKey: cacheKey) {
            self.image = cachedImage
            return
        }

        // 2. Fetch from network
        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                // Save to cache (memory + disk) with the APOD key
                await imageCache.saveImageToDisk(downloadedImage, forKey: cacheKey)
                self.image = downloadedImage
            }
        } catch {
            // 3. Network failed - show placeholder (image stays nil)
            AppLogger.error("Failed to load image for key: \(cacheKey)", error: error, category: .network)
        }
    }
}
