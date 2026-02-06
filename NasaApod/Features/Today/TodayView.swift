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
                .navigationTitle("Today")
                .refreshable {
                    await viewModel.refresh()
                }
        }
        .task {
            // Load on appear if idle
            if viewModel.state.isIdle {
                await viewModel.loadAPOD()
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
            description: Text("Pull down to load today's Astronomy Picture of the Day")
        )
    }

    private var loadingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing) {
                // Image placeholder
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.cardBackground)
                    .frame(height: 300)

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
                } else {
                    // Video placeholder (will be implemented in Task #11)
                    VStack {
                        Image(systemName: "play.rectangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100)
                            .foregroundColor(theme.primaryColor)

                        Text("Video: \(apod.title)")
                            .font(theme.headlineFont)

                        Text("Video support coming soon")
                            .font(theme.captionFont)
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .background(theme.cardBackground)
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
            Label("Failed to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
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
