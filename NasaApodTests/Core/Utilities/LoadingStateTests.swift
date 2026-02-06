//
//  LoadingStateTests.swift
//  NasaApodTests
//
//  Created by kiranjith k k on 03/02/2026.
//

import XCTest
@testable import NasaApod

final class LoadingStateTests: XCTestCase {

    // MARK: - State Checks

    func testIdleStateIsIdle() {
        // Given
        let state: LoadingState<String> = .idle

        // Then
        XCTAssertTrue(state.isIdle)
    }

    func testLoadingStateIsLoading() {
        // Given
        let state: LoadingState<String> = .loading

        // Then
        XCTAssertTrue(state.isLoading)
    }

    func testLoadedStateHasValue() {
        // Given
        let expectedValue = "test data"

        // When
        let state: LoadingState<String> = .loaded(expectedValue)

        // Then
        XCTAssertEqual(state.value, expectedValue)
    }

    func testFailedStateHasError() {
        // Given
        let expectedError = TestError.sample

        // When
        let state: LoadingState<String> = .failed(expectedError)

        // Then
        XCTAssertNotNil(state.error)
        XCTAssertEqual(state.error?.localizedDescription, expectedError.localizedDescription)
    }

    // MARK: - isLoading Returns False for Other States

    func testIsLoadingReturnsFalseForIdleState() {
        // Given
        let state: LoadingState<String> = .idle

        // Then
        XCTAssertFalse(state.isLoading)
    }

    func testIsLoadingReturnsFalseForLoadedState() {
        // Given
        let state: LoadingState<String> = .loaded("data")

        // Then
        XCTAssertFalse(state.isLoading)
    }

    func testIsLoadingReturnsFalseForFailedState() {
        // Given
        let state: LoadingState<String> = .failed(TestError.sample)

        // Then
        XCTAssertFalse(state.isLoading)
    }

    // MARK: - value Returns Nil for Other States

    func testValueReturnsNilForIdleState() {
        // Given
        let state: LoadingState<String> = .idle

        // Then
        XCTAssertNil(state.value)
    }

    func testValueReturnsNilForLoadingState() {
        // Given
        let state: LoadingState<String> = .loading

        // Then
        XCTAssertNil(state.value)
    }

    func testValueReturnsNilForFailedState() {
        // Given
        let state: LoadingState<String> = .failed(TestError.sample)

        // Then
        XCTAssertNil(state.value)
    }

    // MARK: - error Returns Nil for Other States

    func testErrorReturnsNilForIdleState() {
        // Given
        let state: LoadingState<String> = .idle

        // Then
        XCTAssertNil(state.error)
    }

    func testErrorReturnsNilForLoadingState() {
        // Given
        let state: LoadingState<String> = .loading

        // Then
        XCTAssertNil(state.error)
    }

    func testErrorReturnsNilForLoadedState() {
        // Given
        let state: LoadingState<String> = .loaded("data")

        // Then
        XCTAssertNil(state.error)
    }

    // MARK: - isIdle Returns False for Other States

    func testIsIdleReturnsFalseForLoadingState() {
        // Given
        let state: LoadingState<String> = .loading

        // Then
        XCTAssertFalse(state.isIdle)
    }

    func testIsIdleReturnsFalseForLoadedState() {
        // Given
        let state: LoadingState<String> = .loaded("data")

        // Then
        XCTAssertFalse(state.isIdle)
    }

    func testIsIdleReturnsFalseForFailedState() {
        // Given
        let state: LoadingState<String> = .failed(TestError.sample)

        // Then
        XCTAssertFalse(state.isIdle)
    }

    // MARK: - Equatable Conformance

    func testIdleStatesAreEqual() {
        // Given
        let state1: LoadingState<String> = .idle
        let state2: LoadingState<String> = .idle

        // Then
        XCTAssertEqual(state1, state2)
    }

    func testLoadingStatesAreEqual() {
        // Given
        let state1: LoadingState<String> = .loading
        let state2: LoadingState<String> = .loading

        // Then
        XCTAssertEqual(state1, state2)
    }

    func testLoadedStatesWithSameValueAreEqual() {
        // Given
        let state1: LoadingState<String> = .loaded("same")
        let state2: LoadingState<String> = .loaded("same")

        // Then
        XCTAssertEqual(state1, state2)
    }

    func testLoadedStatesWithDifferentValuesAreNotEqual() {
        // Given
        let state1: LoadingState<String> = .loaded("value1")
        let state2: LoadingState<String> = .loaded("value2")

        // Then
        XCTAssertNotEqual(state1, state2)
    }

    func testFailedStatesWithSameErrorDescriptionAreEqual() {
        // Given
        let state1: LoadingState<String> = .failed(TestError.sample)
        let state2: LoadingState<String> = .failed(TestError.sample)

        // Then
        XCTAssertEqual(state1, state2)
    }

    func testDifferentStatesAreNotEqual() {
        // Given
        let idle: LoadingState<String> = .idle
        let loading: LoadingState<String> = .loading
        let loaded: LoadingState<String> = .loaded("data")
        let failed: LoadingState<String> = .failed(TestError.sample)

        // Then
        XCTAssertNotEqual(idle, loading)
        XCTAssertNotEqual(idle, loaded)
        XCTAssertNotEqual(idle, failed)
        XCTAssertNotEqual(loading, loaded)
        XCTAssertNotEqual(loading, failed)
        XCTAssertNotEqual(loaded, failed)
    }

    // MARK: - Generic Type Tests

    func testLoadedStateWithIntValue() {
        // Given
        let expectedValue = 42

        // When
        let state: LoadingState<Int> = .loaded(expectedValue)

        // Then
        XCTAssertEqual(state.value, expectedValue)
    }

    func testLoadedStateWithArrayValue() {
        // Given
        let expectedArray = [1, 2, 3]

        // When
        let state: LoadingState<[Int]> = .loaded(expectedArray)

        // Then
        XCTAssertEqual(state.value, expectedArray)
    }

    func testLoadedStateWithOptionalValue() {
        // Given/When
        let state: LoadingState<String?> = .loaded(nil)

        // Then
        XCTAssertNotNil(state.value) // value property returns the optional
        XCTAssertNil(state.value!)   // the actual value is nil
    }
}

// MARK: - Test Helpers

private enum TestError: Error, LocalizedError {
    case sample

    var errorDescription: String? {
        "Sample test error"
    }
}
