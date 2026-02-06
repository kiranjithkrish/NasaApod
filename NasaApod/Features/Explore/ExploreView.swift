//
//  ExploreView.swift
//  NasaApod
//
//  Created by kiranjith k k on 05/02/2026.
//

import SwiftUI

struct ExploreView: View {
    @State private var viewModel: ExploreViewModel
    @State private var activeSheet: Sheet?
    @Environment(\.theme) private var theme

    private let imageCache: ImageCacheActor

    // MARK: - Sheet Types

    enum Sheet: Identifiable {
        case datePicker

        var id: Self { self }
    }

    // MARK: - Initialization

    init(viewModel: ExploreViewModel, imageCache: ImageCacheActor) {
        self._viewModel = State(initialValue: viewModel)
        self.imageCache = imageCache
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date picker section
                datePickerSection

                Divider()

                // Content section
                content
            }
            .navigationTitle("Explore APODs")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $viewModel.destination) { destination in
                switch destination {
                case .imageDetail(let apod):
                    ImageDetailView(apod: apod, imageCache: imageCache)
                }
            }
        }
        .task {
            // Load on appear if idle
            if viewModel.state.isIdle {
                await viewModel.loadAPOD()
            }
        }
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing / 2) {
            Text("Travel Through Time")
                .font(theme.headlineFont)
                .foregroundColor(theme.textPrimary)

            Text("Select a date to see that day's astronomy picture")
                .font(theme.captionFont)
                .foregroundColor(theme.textSecondary)

            Button {
                activeSheet = .datePicker
            } label: {
                HStack {
                    Image(systemName: "calendar")
                    Text(viewModel.selectedDate, style: .date)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.textSecondary)
                }
                .padding(theme.spacing)
                .background(theme.backgroundColor)
                .cornerRadius(theme.cornerRadius)
            }
            .buttonStyle(.plain)
        }
        .padding(theme.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .datePicker:
                datePickerSheet
            }
        }
    }

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker(
                "Select Date",
                selection: $viewModel.selectedDate,
                in: viewModel.earliestDate...viewModel.latestDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        activeSheet = nil
                        Task {
                            await viewModel.dateChanged()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
            "Select a Date",
            systemImage: "calendar",
            description: Text("Choose a date above to explore past astronomy pictures")
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
                    .onTapGesture {
                        viewModel.destination = .imageDetail(apod)
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
    ExploreView(viewModel: .preview(), imageCache: ImageCacheActor())
        .theme(DefaultTheme())
}

#Preview("Loading") {
    ExploreView(viewModel: .previewLoading(), imageCache: ImageCacheActor())
        .theme(DefaultTheme())
}

#Preview("Loaded") {
    ExploreView(viewModel: .previewLoaded(), imageCache: ImageCacheActor())
        .theme(DefaultTheme())
}

#Preview("Error") {
    ExploreView(viewModel: .previewError(), imageCache: ImageCacheActor())
        .theme(DefaultTheme())
}
