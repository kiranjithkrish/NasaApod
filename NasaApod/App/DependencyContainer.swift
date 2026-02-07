//
//  DependencyContainer.swift
//  NasaApod
//
//  Created by kiranjith k k on 04/02/2026.
//

import Foundation

@MainActor
final class DependencyContainer {
    // MARK: - Shared Services (Singletons)

    lazy var apiService: APIServiceProtocol = {
        APIService()
    }()

    lazy var cacheService: CacheServiceProtocol = {
        do {
            return try CacheService()
        } catch {
            fatalError("Failed to initialize CacheService: \(error)")
        }
    }()

    lazy var imageCache: ImageCacheActor = {
        ImageCacheActor()
    }()

    lazy var repository: APODRepositoryProtocol = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
            print("UI TEST MODE: using MockAPODRepository")
            return MockAPODRepository()
        }
        #endif
        return APODRepository(
            apiService: apiService,
            cacheService: cacheService
        )
    }()

    // MARK: - Factory Methods for Features

    func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(repository: repository)
    }

    func makeExploreViewModel() -> ExploreViewModel {
        ExploreViewModel(repository: repository)
    }
}
