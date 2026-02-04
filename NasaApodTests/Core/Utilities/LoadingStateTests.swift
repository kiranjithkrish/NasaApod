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
        let state: LoadingState<String> = .idle

        XCTAssertTrue(state.isIdle)
    }

    func testLoadingStateIsLoading() {
        let state: LoadingState<String> = .loading

        XCTAssertTrue(state.isLoading)
    }

    func testLoadedStateHasValue() {
        let expectedValue = "test data"
        let state: LoadingState<String> = .loaded(expectedValue)

        XCTAssertEqual(state.value, expectedValue)
    }

    func testFailedStateHasError() {
        let expectedError = TestError.sample
        let state: LoadingState<String> = .failed(expectedError)

        XCTAssertNotNil(state.error)
        XCTAssertEqual(state.error?.localizedDescription, expectedError.localizedDescription)
    }

    // MARK: - isLoading Returns False for Other States

    func testIsLoadingReturnsFalseForIdleState() {
        let state: LoadingState<String> = .idle

        XCTAssertFalse(state.isLoading)
    }

    func testIsLoadingReturnsFalseForLoadedState() {
        let state: LoadingState<String> = .loaded("data")

        XCTAssertFalse(state.isLoading)
    }

    func testIsLoadingReturnsFalseForFailedState() {
        let state: LoadingState<String> = .failed(TestError.sample)

        XCTAssertFalse(state.isLoading)
    }

    // MARK: - value Returns Nil for Other States

    func testValueReturnsNilForIdleState() {
        let state: LoadingState<String> = .idle

        XCTAssertNil(state.value)
    }

    func testValueReturnsNilForLoadingState() {
        let state: LoadingState<String> = .loading

        XCTAssertNil(state.value)
    }

    func testValueReturnsNilForFailedState() {
        let state: LoadingState<String> = .failed(TestError.sample)

        XCTAssertNil(state.value)
    }

    // MARK: - error Returns Nil for Other States

    func testErrorReturnsNilForIdleState() {
        let state: LoadingState<String> = .idle

        XCTAssertNil(state.error)
    }

    func testErrorReturnsNilForLoadingState() {
        let state: LoadingState<String> = .loading

        XCTAssertNil(state.error)
    }

    func testErrorReturnsNilForLoadedState() {
        let state: LoadingState<String> = .loaded("data")

        XCTAssertNil(state.error)
    }

    // MARK: - isIdle Returns False for Other States

    func testIsIdleReturnsFalseForLoadingState() {
        let state: LoadingState<String> = .loading

        XCTAssertFalse(state.isIdle)
    }

    func testIsIdleReturnsFalseForLoadedState() {
        let state: LoadingState<String> = .loaded("data")

        XCTAssertFalse(state.isIdle)
    }

    func testIsIdleReturnsFalseForFailedState() {
        let state: LoadingState<String> = .failed(TestError.sample)

        XCTAssertFalse(state.isIdle)
    }

    // MARK: - Equatable Conformance

    func testIdleStatesAreEqual() {
        let state1: LoadingState<String> = .idle
        let state2: LoadingState<String> = .idle

        XCTAssertEqual(state1, state2)
    }

    func testLoadingStatesAreEqual() {
        let state1: LoadingState<String> = .loading
        let state2: LoadingState<String> = .loading

        XCTAssertEqual(state1, state2)
    }

    func testLoadedStatesWithSameValueAreEqual() {
        let state1: LoadingState<String> = .loaded("same")
        let state2: LoadingState<String> = .loaded("same")

        XCTAssertEqual(state1, state2)
    }

    func testLoadedStatesWithDifferentValuesAreNotEqual() {
        let state1: LoadingState<String> = .loaded("value1")
        let state2: LoadingState<String> = .loaded("value2")

        XCTAssertNotEqual(state1, state2)
    }

    func testFailedStatesWithSameErrorDescriptionAreEqual() {
        let state1: LoadingState<String> = .failed(TestError.sample)
        let state2: LoadingState<String> = .failed(TestError.sample)

        XCTAssertEqual(state1, state2)
    }

    func testDifferentStatesAreNotEqual() {
        let idle: LoadingState<String> = .idle
        let loading: LoadingState<String> = .loading
        let loaded: LoadingState<String> = .loaded("data")
        let failed: LoadingState<String> = .failed(TestError.sample)

        XCTAssertNotEqual(idle, loading)
        XCTAssertNotEqual(idle, loaded)
        XCTAssertNotEqual(idle, failed)
        XCTAssertNotEqual(loading, loaded)
        XCTAssertNotEqual(loading, failed)
        XCTAssertNotEqual(loaded, failed)
    }

    // MARK: - Generic Type Tests

    func testLoadedStateWithIntValue() {
        let state: LoadingState<Int> = .loaded(42)

        XCTAssertEqual(state.value, 42)
    }

    func testLoadedStateWithArrayValue() {
        let expectedArray = [1, 2, 3]
        let state: LoadingState<[Int]> = .loaded(expectedArray)

        XCTAssertEqual(state.value, expectedArray)
    }

    func testLoadedStateWithOptionalValue() {
        let state: LoadingState<String?> = .loaded(nil)

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
