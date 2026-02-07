//
//  NasaApodUITests.swift
//  NasaApodUITests
//
//  Created by kiranjith k k on 03/02/2026.
//

import XCTest

final class NasaApodUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunchShowsTodayTab() throws {
        // Given app has launched
        // Then Today tab should be selected
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.exists)
        XCTAssertTrue(todayTab.isSelected)
    }

    @MainActor
    func testAppLaunchShowsNavigationTitle() throws {
        // Given app has launched
        // Then navigation title should be visible
        let navTitle = app.navigationBars["Today's APOD"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 2))
    }

    // MARK: - Tab Navigation Tests

    @MainActor
    func testTabBarNavigation() throws {
        // Given app has launched on Today tab
        // When tapping Explore tab
        let exploreTab = app.tabBars.buttons["Explore"]
        XCTAssertTrue(exploreTab.exists)
        exploreTab.tap()

        // Then Explore screen should be visible
        let exploreNavTitle = app.navigationBars["Explore APODs"]
        XCTAssertTrue(exploreNavTitle.waitForExistence(timeout: 2))

        // When tapping Today tab again
        let todayTab = app.tabBars.buttons["Today"]
        todayTab.tap()

        // Then Today screen should be visible
        let todayNavTitle = app.navigationBars["Today's APOD"]
        XCTAssertTrue(todayNavTitle.waitForExistence(timeout: 2))
    }

    // MARK: - Today View Tests

    @MainActor
    func testTodayViewDisplaysAPODContent() throws {
        // Given app has launched
        // When APOD loads (wait for content)
        // Then title and explanation should be visible
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10))

        // Look for any static text (title or explanation)
        let hasContent = app.staticTexts.count > 0
        XCTAssertTrue(hasContent, "Expected APOD content to be displayed")
    }

    // MARK: - Explore View Tests

    @MainActor
    func testExploreDatePickerOpens() throws {
        // Given app is on Explore tab
        let exploreTab = app.tabBars.buttons["Explore"]
        exploreTab.tap()

        // When tapping date picker button
        let dateButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "calendar")).firstMatch
        if dateButton.waitForExistence(timeout: 5) {
            dateButton.tap()

            // Then date picker sheet should appear
            let doneButton = app.buttons["Done"]
            XCTAssertTrue(doneButton.waitForExistence(timeout: 2))

            // Dismiss the sheet
            doneButton.tap()
        }
    }
}
