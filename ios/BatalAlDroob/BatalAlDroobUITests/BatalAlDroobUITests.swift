import XCTest

final class BatalAlDroobUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCriticalNavigationAndLocalRequestFlow() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ar)",
            "-AppleLocale", "ar_SA",
            "-batalLang", "ar"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["الرئيسية"].waitForExistence(timeout: 20))

        let catalogTab = navigationItem(named: "الكتالوج", in: app)
        XCTAssertTrue(catalogTab.waitForExistence(timeout: 10))
        catalogTab.tap()
        let resultsLabel = app.staticTexts["النتائج"]
        XCTAssertTrue(reveal(resultsLabel, in: app))

        let requestTab = navigationItem(named: "طلب قطعة", in: app)
        XCTAssertTrue(requestTab.waitForExistence(timeout: 10))
        requestTab.tap()
        XCTAssertTrue(app.navigationBars["طلب قطعة"].waitForExistence(timeout: 10))

        let partNumberField = app.textFields["رقم القطعة"]
        XCTAssertTrue(reveal(partNumberField, in: app))
        partNumberField.tap()
        partNumberField.typeText("21082-4W000")

        let saveButton = app.buttons["تجهيز الطلب وحفظه"]
        XCTAssertTrue(reveal(saveButton, in: app))
        saveButton.tap()
        XCTAssertTrue(app.staticTexts["تم تجهيز طلب القطعة وحفظه."].waitForExistence(timeout: 10))

        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["الرئيسية"].waitForExistence(timeout: 20))

        let toolsTab = navigationItem(named: "الأدوات", in: app)
        if toolsTab.waitForExistence(timeout: 3) {
            XCTAssertTrue(navigationItem(named: "الصيانة", in: app).waitForExistence(timeout: 10))
            toolsTab.tap()
            XCTAssertTrue(app.navigationBars["المزيد"].waitForExistence(timeout: 10))
        } else {
            let compactMoreTab = firstExistingNavigationItem(named: ["المزيد", "More"], in: app)
            XCTAssertTrue(compactMoreTab.waitForExistence(timeout: 3))
            compactMoreTab.tap()

            let maintenanceItem = app.staticTexts["الصيانة"]
            let toolsItem = app.staticTexts["الأدوات"]
            XCTAssertTrue(maintenanceItem.waitForExistence(timeout: 10))
            XCTAssertTrue(toolsItem.waitForExistence(timeout: 10))
            toolsItem.tap()
            XCTAssertTrue(app.navigationBars["المزيد"].waitForExistence(timeout: 10))
        }

        let trackingSection = app.staticTexts["more.section.tracking"]
        XCTAssertTrue(reveal(trackingSection, in: app))
    }

    @MainActor
    func testEnglishLayoutAndInAppLanguageSwitch() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-batalLang", "en"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 20))
        XCTAssertTrue(navigationItem(named: "Catalog", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(navigationItem(named: "Request", in: app).waitForExistence(timeout: 10))

        let languageMenu = app.buttons["language.menu"]
        XCTAssertTrue(languageMenu.waitForExistence(timeout: 10))
        languageMenu.tap()

        let arabicOption = app.buttons["language.option.ar"]
        XCTAssertTrue(arabicOption.waitForExistence(timeout: 10))
        arabicOption.tap()

        XCTAssertTrue(app.navigationBars["الرئيسية"].waitForExistence(timeout: 10))
        XCTAssertTrue(navigationItem(named: "الكتالوج", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(navigationItem(named: "طلب قطعة", in: app).waitForExistence(timeout: 10))
    }

    @MainActor
    private func navigationItem(named name: String, in app: XCUIApplication) -> XCUIElement {
        let tabBarItem = app.tabBars.buttons[name]
        if tabBarItem.exists {
            return tabBarItem
        }

        return app.buttons.matching(identifier: name).firstMatch
    }

    @MainActor
    private func firstExistingNavigationItem(named names: [String], in app: XCUIApplication) -> XCUIElement {
        for name in names {
            let item = navigationItem(named: name, in: app)
            if item.waitForExistence(timeout: 2) {
                return item
            }
        }

        return navigationItem(named: names[0], in: app)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maximumSwipes: Int = 8) -> Bool {
        if element.waitForExistence(timeout: 2), element.isHittable {
            return true
        }

        for _ in 0 ..< maximumSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1), element.isHittable {
                return true
            }
        }

        return false
    }
}
