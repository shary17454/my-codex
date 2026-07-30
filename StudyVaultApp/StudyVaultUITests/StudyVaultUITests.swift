import XCTest

@MainActor
final class StudyVaultUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPrimaryNavigationAndSearchAreReachable() {
        let app = XCUIApplication()
        app.launchArguments += ["-WeshSkipOnboarding", "-AppleLanguages", "(ar)", "-AppleLocale", "ar_SA"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))

        XCTAssertTrue(app.otherElements["main-tab-bar"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["tab.home"].exists)
        XCTAssertTrue(app.buttons["tab.library"].exists)
        XCTAssertTrue(app.buttons["tab.account"].exists)
        XCTAssertTrue(app.buttons["tab.createComparison"].exists)

        let discoverTab = app.buttons["tab.questions"]
        XCTAssertTrue(discoverTab.exists)
        discoverTab.tap()

        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 10))
    }

    func testCreateComparisonFlowIsReachable() {
        let app = XCUIApplication()
        app.launchArguments += ["-WeshSkipOnboarding", "-AppleLanguages", "(ar)", "-AppleLocale", "ar_SA"]
        app.launch()

        let createButton = app.buttons["tab.createComparison"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 15))
        createButton.tap()

        let titleField = app.textFields["comparison-title-field"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["وش حاب تقارن؟"].exists)
    }

    func testFeaturedDecisionOpensDecisionSummary() {
        let app = XCUIApplication()
        app.launchArguments += ["-WeshSkipOnboarding", "-AppleLanguages", "(ar)", "-AppleLocale", "ar_SA"]
        app.launch()

        let summaryButton = app.buttons["home.featuredDecision"]
        XCTAssertTrue(summaryButton.waitForExistence(timeout: 15))
        summaryButton.tap()

        XCTAssertTrue(app.scrollViews["decision-summary-screen"].waitForExistence(timeout: 10))

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Decision Summary Reference Design"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
