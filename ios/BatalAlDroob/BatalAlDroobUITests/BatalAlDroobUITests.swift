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
            "-batalLang", "ar",
            "-skipPermissionOnboardingForUITests"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["الرئيسية"].waitForExistence(timeout: 20))

        let heroY60 = app.buttons["home.hero.generation.Y60"]
        XCTAssertTrue(heroY60.waitForExistence(timeout: 10))
        heroY60.tap()
        let focusedCatalogSearch = app.textFields["catalog.search.inline"]
        XCTAssertTrue(focusedCatalogSearch.waitForExistence(timeout: 10))
        XCTAssertEqual(focusedCatalogSearch.value as? String, "Y60")

        let homeTab = navigationItem(named: "الرئيسية", in: app)
        XCTAssertTrue(homeTab.waitForExistence(timeout: 10))
        homeTab.tap()
        XCTAssertTrue(app.navigationBars["الرئيسية"].waitForExistence(timeout: 10))

        let quickCatalog = app.buttons["home.quick.catalog"]
        XCTAssertTrue(reveal(quickCatalog, in: app))
        quickCatalog.tap()
        let catalogSearch = app.textFields["catalog.search.inline"]
        XCTAssertTrue(catalogSearch.waitForExistence(timeout: 10))

        catalogSearch.tap()
        catalogSearch.typeText("081210401F")
        XCTAssertTrue(app.staticTexts["النتائج"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["23378-M4901"].exists)
        dismissKeyboardIfVisible(in: app)

        let requestTab = navigationItem(named: "طلب قطعة", in: app)
        XCTAssertTrue(requestTab.waitForExistence(timeout: 10))
        requestTab.tap()
        XCTAssertTrue(app.navigationBars["طلب قطعة"].waitForExistence(timeout: 10))

        let partNumberField = app.textFields["request.partNumber"]
        XCTAssertTrue(reveal(partNumberField, in: app))
        partNumberField.tap()
        partNumberField.typeText("21082-4W000")

        let saveButton = app.buttons["request.save"]
        XCTAssertTrue(reveal(saveButton, in: app))
        saveButton.tap()
        XCTAssertTrue(app.staticTexts["تم تجهيز طلب القطعة وحفظه."].waitForExistence(timeout: 10))

        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["الرئيسية"].waitForExistence(timeout: 20))

        let toolsTab = navigationItem(named: "الأدوات", in: app)
        XCTAssertTrue(toolsTab.waitForExistence(timeout: 10))
        toolsTab.tap()

        let actionCenter = app.staticTexts["more.section.action-center"]
        XCTAssertTrue(reveal(actionCenter, in: app, requireHittable: false))

        let smartSearchAction = app.buttons["tools.action.smart-search"]
        XCTAssertTrue(reveal(smartSearchAction, in: app))
        smartSearchAction.tap()
        XCTAssertTrue(app.staticTexts["النتائج"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(reveal(actionCenter, in: app, requireHittable: false))

        let maintenanceAction = app.buttons["tools.action.maintenance"]
        XCTAssertTrue(reveal(maintenanceAction, in: app))
        maintenanceAction.tap()
        XCTAssertTrue(app.navigationBars["الصيانة"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(reveal(actionCenter, in: app, requireHittable: false))
    }

    @MainActor
    func testEnglishLayoutAndInAppLanguageSwitch() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-batalLang", "en",
            "-skipPermissionOnboardingForUITests"
        ]
        app.launch()

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 20))
        XCTAssertTrue(reveal(app.staticTexts["Start quickly"], in: app, requireHittable: false))
        XCTAssertFalse(app.staticTexts["ylkciuq tratS"].exists)
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
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maximumSwipes: Int = 8, requireHittable: Bool = true) -> Bool {
        if element.waitForExistence(timeout: 2), !requireHittable || element.isHittable {
            return true
        }

        for _ in 0 ..< maximumSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1), !requireHittable || element.isHittable {
                return true
            }
        }

        return false
    }

    @MainActor
    private func dismissKeyboardIfVisible(in app: XCUIApplication) {
        guard app.keyboards.firstMatch.exists else { return }

        app.typeText("\n")
    }
}
