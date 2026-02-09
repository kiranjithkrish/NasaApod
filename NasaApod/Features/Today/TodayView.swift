//
//  TodayView.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import SwiftUI

struct TodayView: View {
    @State private var viewModel: TodayViewModel
    @Environment(\.theme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    private let imageCache: ImageCacheActor

    // MARK: - Initialization

    init(viewModel: TodayViewModel, imageCache: ImageCacheActor) {
        self._viewModel = State(initialValue: viewModel)
        self.imageCache = imageCache
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Today's APOD")
                .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            // Load on appear if idle
            if viewModel.state.isIdle {
                await viewModel.loadAPOD()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await viewModel.refreshIfStale() }
            }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            emptyStateView

        case .loading:
            loadingView

        case .loaded(let apod):
            apodContentView(apod: apod)

        case .failed(let error):
            errorView(error: error)
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No APOD Loaded",
            systemImage: "photo",
            description: Text("Today's Astronomy Picture of the Day will load automatically")
        )
    }

    private var loadingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing) {
                // Image placeholder
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.cardBackground)
                    .frame(height: 300)
                    .shimmer()

                // Title placeholder
                Text("Loading Amazing Space Photo")
                    .font(theme.titleFont)

                // Date placeholder
                Text("February 6, 2026")
                    .font(theme.captionFont)

                Divider()

                // Explanation placeholder
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.")
                    .font(theme.bodyFont)
            }
            .padding(theme.padding)
        }
        .redacted(reason: .placeholder)
    }

    private func apodContentView(apod: APOD) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing) {
                // Media (image or video)
                if apod.isImage {
                    CachedAsyncImage(
                        url: URL(string: apod.url),
                        cacheKey: apod.date,
                        imageCache: imageCache
                    ) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(theme.cornerRadius)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: theme.cornerRadius)
                            .fill(theme.cardBackground)
                            .frame(height: 300)
                            .shimmer()
                    }
                } else if let videoURL = URL(string: apod.url) {
                    // Video with thumbnail - tap to open in YouTube/Safari
                    VideoPlayerView(
                        url: videoURL,
                        title: apod.title,
                        thumbnailUrl: apod.thumbnailUrl.flatMap { URL(string: $0) },
                        cacheKey: apod.date,
                        imageCache: imageCache
                    )
                    .frame(height: 300)
                    .cornerRadius(theme.cornerRadius)
                }

                // Title
                Text(apod.title)
                    .font(theme.titleFont)
                    .foregroundColor(theme.textPrimary)

                // Date
                if let date = apod.parsedDate {
                    Text(date, style: .date)
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }

                // Copyright
                if let copyright = apod.copyright {
                    Text("© \(copyright)")
                        .font(theme.captionFont)
                        .foregroundColor(theme.textSecondary)
                }

                Divider()

                // Explanation
                Text(apod.explanation)
                    .font(theme.bodyFont)
                    .foregroundColor(theme.textPrimary)
            }
            .padding(theme.padding)
        }
    }

    private func errorView(error: Error) -> some View {
        ContentUnavailableView {
            Label("Picture Unavailable", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("The picture for this date may not be available yet. Try again later.")
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Previews

#Preview("Idle") {
    TodayView(viewModel: .preview(), imageCache: ImageCacheActor())
        .theme(DefaultTheme())
}

#Preview("Loading") {
    TodayView(viewModel: .previewLoading(), imageCache: ImageCacheActor())
        .theme(DefaultTheme())
}

#Preview("Loaded") {
    TodayView(viewModel: .previewLoaded(), imageCache: ImageCacheActor())
        .theme(DefaultTheme())
}

#Preview("Error") {
    TodayView(viewModel: .previewError(), imageCache: ImageCacheActor())
        .theme(DefaultTheme())
}
