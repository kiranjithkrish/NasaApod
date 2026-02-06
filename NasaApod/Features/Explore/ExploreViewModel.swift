//
//  ExploreViewModel.swift
//  NasaApod
//
//  Created by kiranjith k k on 05/02/2026.
//

import Foundation

@MainActor
@Observable
final class ExploreViewModel {
    // MARK: - Navigation Destination

    /// State-driven navigation - enum prevents impossible states
    /// Extensible for deep linking: set destination from URL handler
    enum Destination: Hashable {
        case imageDetail(APOD)
    }

    // MARK: - State

    /// Navigation destination (nil = no navigation active)
    var destination: Destination?

    /// Loading state using enum (prevents impossible states)
    var state: LoadingState<APOD> = .idle

    /// Selected date for APOD lookup
    var selectedDate: Date = Date()

    /// Valid date range for APOD (June 16, 1995 to today)
    let earliestDate: Date = Constants.API.earliestDate
    var latestDate: Date { Date() }

    // MARK: - Dependencies

    private let repository: APODRepositoryProtocol

    // MARK: - Initialization

    init(repository: APODRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Load APOD for selected date
    func loadAPOD() async {
        state = .loading

        do {
            let apod = try await repository.fetchAPOD(for: selectedDate)
            state = .loaded(apod)
            AppLogger.info("Loaded APOD for \(selectedDate): \(apod.title)", category: .ui)

        } catch let error as APODError {
            state = .failed(error)
            AppLogger.error("Failed to load APOD for \(selectedDate)", error: error, category: .ui)

        } catch {
            let apodError = APODError.repositoryFailed(underlyingError: error)
            state = .failed(apodError)
            AppLogger.error("Unexpected error loading APOD", error: error, category: .ui)
        }
    }

    /// Called when date picker value changes
    func dateChanged() async {
        await loadAPOD()
    }

    /// Retry loading after error
    func retry() async {
        await loadAPOD()
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ExploreViewModel {
    /// Create ViewModel with mock repository for previews
    static func preview(state: LoadingState<APOD> = .idle) -> ExploreViewModel {
        let viewModel = ExploreViewModel(repository: MockAPODRepository())
        viewModel.state = state
        return viewModel
    }

    /// Create ViewModel in loading state
    static func previewLoading() -> ExploreViewModel {
        preview(state: .loading)
    }

    /// Create ViewModel with loaded data
    static func previewLoaded() -> ExploreViewModel {
        preview(state: .loaded(.sample))
    }

    /// Create ViewModel with error
    static func previewError() -> ExploreViewModel {
        preview(state: .failed(APODError.networkUnavailable))
    }
}
#endif
