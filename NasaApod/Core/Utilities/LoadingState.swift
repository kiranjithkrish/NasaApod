//
//  LoadingState.swift
//  NasaApod
//
//  Created by kiranjith k k on 03/02/2026.
//

import Foundation

/// Generic state enum for async operations
/// Prevents impossible states by making each state mutually exclusive
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
}

// MARK: - Convenience Properties

extension LoadingState {
    /// Returns true if currently loading
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    /// Returns the loaded value if available
    var value: T? {
        if case .loaded(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the error if failed
    var error: Error? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }

    /// Returns true if idle (no operation started)
    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }
}



// MARK: - Equatable conformance for testability

extension LoadingState: Equatable where T: Equatable {
    nonisolated static func == (lhs: LoadingState<T>, rhs: LoadingState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let lhsValue), .loaded(let rhsValue)):
            return lhsValue == rhsValue
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
