//
//  TodayViewModel.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

@MainActor
@Observable
final class TodayViewModel {
    // MARK: - State

    /// Loading state using enum (prevents impossible states)
    var state: LoadingState<APOD> = .idle

    // MARK: - Dependencies

    private let repository: APODRepositoryProtocol

    // MARK: - Initialization

    init(repository: APODRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Load today's APOD
    func loadAPOD() async {
        state = .loading

        do {
            let result = try await repository.fetchAPOD(for: Date())
            state = .loaded(result.apod)
            AppLogger.info("Loaded today's APOD: \(result.apod.title)", category: .ui)

        } catch let error as APODError {
            state = .failed(error)
            AppLogger.error("Failed to load APOD", error: error, category: .ui)

        } catch {
            let apodError = APODError.repositoryFailed(underlyingError: error)
            state = .failed(apodError)
            AppLogger.error("Unexpected error loading APOD", error: error, category: .ui)
        }
    }

    /// Retry loading after error
    func retry() async {
        await loadAPOD()
    }

    /// Refresh (called by pull-to-refresh)
    func refresh() async {
        // Reset repository if circuit breaker is open
        await repository.reset()
        await loadAPOD()
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension TodayViewModel {
    /// Create ViewModel with mock repository for previews
    static func preview(state: LoadingState<APOD> = .idle) -> TodayViewModel {
        let viewModel = TodayViewModel(repository: MockAPODRepository())
        viewModel.state = state
        return viewModel
    }

    /// Create ViewModel in loading state
    static func previewLoading() -> TodayViewModel {
        preview(state: .loading)
    }

    /// Create ViewModel with loaded data
    static func previewLoaded() -> TodayViewModel {
        preview(state: .loaded(.sample))
    }

    /// Create ViewModel with error
    static func previewError() -> TodayViewModel {
        preview(state: .failed(APODError.networkUnavailable))
    }
}
#endif
