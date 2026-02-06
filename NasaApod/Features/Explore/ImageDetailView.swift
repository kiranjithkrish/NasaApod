//
//  ImageDetailView.swift
//  NasaApod
//
//  Created by kiranjith k k on 06/02/2026.
//

import SwiftUI

/// Full-screen image detail view with zoom support
/// Navigation is state-driven via ExploreViewModel.Destination
struct ImageDetailView: View {
    let apod: APOD
    let imageCache: ImageCacheActor

    @Environment(\.theme) private var theme
    @State private var scale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                CachedAsyncImage(
                    url: URL(string: apod.hdurl ?? apod.url),
                    cacheKey: apod.date,
                    imageCache: imageCache
                ) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: geometry.size.width * scale,
                            height: geometry.size.height * scale
                        )
                } placeholder: {
                    ProgressView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .background(theme.backgroundColor)
        .navigationTitle(apod.title)
        .navigationBarTitleDisplayMode(.inline)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = max(1.0, min(value, 5.0))
                }
        )
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ImageDetailView(
            apod: .sample,
            imageCache: ImageCacheActor()
        )
    }
    .theme(DefaultTheme())
}
