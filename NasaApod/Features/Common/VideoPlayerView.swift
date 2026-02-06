//
//  VideoPlayerView.swift
//  NasaApod
//
//  Created by kiranjith k k on 06/02/2026.
//

import SwiftUI

/// Video thumbnail with tap-to-play in Safari/YouTube app
struct VideoPlayerView: View {
    let url: URL
    let title: String
    let thumbnailUrl: URL?
    let cacheKey: String
    let imageCache: ImageCacheActor

    @Environment(\.theme) private var theme
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(watchURL)
        } label: {
            GeometryReader { geometry in
                ZStack {
                    // Thumbnail from API (cached)
                    if let thumbnailUrl = thumbnailUrl {
                        CachedAsyncImage(
                            url: thumbnailUrl,
                            cacheKey: "thumb_\(cacheKey)",
                            imageCache: imageCache
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(theme.cardBackground)
                                .overlay { ProgressView() }
                        }
                    } else {
                        // Fallback placeholder
                        Rectangle()
                            .fill(theme.cardBackground)
                            .overlay {
                                Image(systemName: "video")
                                    .font(.largeTitle)
                                    .foregroundColor(theme.textSecondary)
                            }
                    }

                    // Play button overlay
                    Circle()
                        .fill(.black.opacity(0.6))
                        .frame(width: 70, height: 70)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .offset(x: 3)
                        }

                    // Video title at bottom
                    VStack {
                        Spacer()
                        Text(title)
                            .font(theme.captionFont)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(.black.opacity(0.6))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// Convert embed URL to watch URL for opening
    private var watchURL: URL {
        let urlString = url.absoluteString

        // Convert YouTube embed to watch URL
        if urlString.contains("/embed/") {
            let videoID = url.lastPathComponent
            return URL(string: "https://www.youtube.com/watch?v=\(videoID)") ?? url
        }

        return url
    }
}

// MARK: - Preview

#Preview {
    VideoPlayerView(
        url: URL(string: APOD.sampleVideo.url)!,
        title: APOD.sampleVideo.title,
        thumbnailUrl: APOD.sampleVideo.thumbnailUrl.flatMap { URL(string: $0) },
        cacheKey: APOD.sampleVideo.date,
        imageCache: ImageCacheActor()
    )
    .frame(height: 300)
    .theme(DefaultTheme())
}
