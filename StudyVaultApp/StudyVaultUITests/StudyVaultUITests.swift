import XCTest

@MainActor
final class StudyVaultUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPrimaryNavigationAndSearchAreReachable() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ar)", "-AppleLocale", "ar_SA"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15))
        XCTAssertEqual(tabBar.buttons.count, 5)

        let discoverTab = tabBar.buttons["اكتشف"]
        XCTAssertTrue(discoverTab.exists)
        discoverTab.tap()

        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 10))
    }
}
