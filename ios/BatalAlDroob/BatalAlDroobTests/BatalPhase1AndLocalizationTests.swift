@testable import BatalAlDroob
import XCTest

/// Tests for the 2.7 release: search-reason ranking, drivetrain categorisation,
/// vehicle-profile fitment boost, part-request validation, and the ten-language
/// interface localization.
final class BatalPhase1AndLocalizationTests: XCTestCase {
    // MARK: - Phase 1: search ranking reason, drivetrain category, vehicle fitment, request validation

    @MainActor
    func testExactPartNumberSearchIsExplainedAsNumberMatch() async {
        let viewModel = CatalogViewModel(
            repository: BundledCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()

        let sample = try? XCTUnwrap(viewModel.parts.first { !$0.partNumber.isEmpty })
        guard let sample else { return XCTFail("Bundled catalog has no numbered part") }

        let detailed = viewModel.rankedCatalogMatchesDetailed(for: sample.partNumber, limit: 5)
        XCTAssertEqual(detailed.first?.part.partNumber, sample.partNumber, "Exact number should rank first")
        XCTAssertEqual(detailed.first?.reason, .exactNumber)
        XCTAssertEqual(viewModel.matchReason(for: sample, query: sample.partNumber), .exactNumber)
    }

    @MainActor
    func testDescriptionSearchIsExplainedAsDescriptionOrSynonym() async {
        let viewModel = CatalogViewModel(
            repository: BundledCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()

        viewModel.searchText = "فحمات فرامل"
        guard let top = viewModel.filteredParts.first else { return XCTFail("Expected results") }
        let reason = viewModel.matchReason(for: top, query: "فحمات فرامل")
        XCTAssertTrue(reason == .description || reason == .synonym, "Text query should read as description/synonym, got \(String(describing: reason))")
    }

    func testDrivetrainCategoryIsRecognizedAndLabeled() {
        XCTAssertEqual(CatalogCategory(rawValue: "drivetrain"), .drivetrain)
        XCTAssertEqual(CatalogCategory.drivetrain.title(.arabic), "نقل الحركة")
        XCTAssertEqual(CatalogCategory.drivetrain.title(.english), "Drivetrain")
        XCTAssertTrue(CatalogCategory.allCases.contains(.drivetrain))
    }

    @MainActor
    func testDrivetrainPartsNoLongerFallIntoGeneral() async {
        let viewModel = CatalogViewModel(
            repository: BundledCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()

        // The bundled catalog contains ~700 drivetrain parts that previously mapped to general.
        XCTAssertGreaterThan(viewModel.categoryCount(.drivetrain), 0, "Drivetrain parts should be categorized, not dropped into general")
        XCTAssertTrue(viewModel.parts.contains { $0.categoryValue == .drivetrain })
    }

    @MainActor
    func testVehicleProfileFitBoostsMatchingPart() async {
        let viewModel = CatalogViewModel(
            repository: BundledCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()

        guard let part = viewModel.parts.first(where: { ($0.model?.isEmpty == false) }) else {
            return XCTFail("Bundled catalog has no part with a model")
        }

        // An empty profile must not influence ranking. Note VehicleProfile.generation
        // defaults to "Y60", so the profile has to be cleared explicitly here.
        viewModel.vehicleProfile = VehicleProfile(generation: "", year: "", vin: "", engine: "", transmission: "")
        XCTAssertFalse(viewModel.hasMeaningfulVehicleProfile)
        XCTAssertEqual(viewModel.vehicleFitmentBonus(for: part), 0, "No bonus before a profile is set")

        // A profile matching this part's model must boost it.
        viewModel.vehicleProfile.generation = part.model ?? ""
        XCTAssertTrue(viewModel.hasMeaningfulVehicleProfile)
        XCTAssertTrue(viewModel.partFitsVehicleProfile(part))
        XCTAssertGreaterThan(viewModel.vehicleFitmentBonus(for: part), 0, "Matching part should get a ranking boost")
    }

    func testAmbiguousPartRequestReportsMissingRequirements() {
        // Part name but no vehicle context -> flagged as missing vehicle context.
        let nameOnly = SavedPartRequest(generation: "", year: "", partName: "Water outlet")
        XCTAssertEqual(partRequestMissingRequirements(nameOnly), [.vehicleContext])
        XCTAssertFalse(partRequestHasRequiredInput(nameOnly))

        // No part identity and no vehicle context -> both missing.
        let empty = SavedPartRequest(generation: "", year: "", partNumber: "  ", partName: "")
        XCTAssertEqual(Set(partRequestMissingRequirements(empty)), Set([.partIdentity, .vehicleContext]))

        // Part number + generation -> complete.
        let complete = SavedPartRequest(generation: "Y60", partNumber: "21082-4W000")
        XCTAssertTrue(partRequestMissingRequirements(complete).isEmpty)
        XCTAssertTrue(partRequestHasRequiredInput(complete))
    }

    func testPartRequestDraftIncludesSupplierClosingLine() {
        let plan = PartRequestPlan(id: "basic", titleAr: "طلب أساسي", titleEn: "Basic request", descriptionAr: "", descriptionEn: "")
        let request = SavedPartRequest(generation: "Y60", year: "1997", partName: "Water outlet")
        let arabic = partRequestDraft(for: request, plan: plan, language: .arabic)
        let english = partRequestDraft(for: request, plan: plan, language: .english)
        XCTAssertTrue(arabic.contains("تأكيد التوفر والسعر"))
        XCTAssertTrue(english.lowercased().contains("availability and price"))
    }

    // MARK: - Localization

    func testAppSupportsTenInterfaceLanguages() {
        XCTAssertEqual(AppLanguage.allCases.count, 10)
        // Every language needs a non-empty endonym and a distinct locale.
        XCTAssertTrue(AppLanguage.allCases.allSatisfy { !$0.title.isEmpty })
        let identifiers = Set(AppLanguage.allCases.map(\.locale.identifier))
        XCTAssertEqual(identifiers.count, AppLanguage.allCases.count, "Each language needs its own locale")
        // Arabic is the only right-to-left language in this set.
        XCTAssertEqual(AppLanguage.allCases.filter(\.isRTL), [.arabic])
    }

    func testEveryTranslatedStringCoversAllNonDefaultLanguages() {
        let nonDefault = AppLanguage.allCases.filter { $0 != .arabic && $0 != .english }
        XCTAssertEqual(nonDefault.count, 8)
        for language in nonDefault {
            XCTAssertNotNil(BatalLocalization.translate("Home", to: language), "Missing 'Home' for \(language.rawValue)")
            XCTAssertNotNil(BatalLocalization.translate("Catalog", to: language), "Missing 'Catalog' for \(language.rawValue)")
        }
        XCTAssertGreaterThanOrEqual(BatalLocalization.translatedStringCount, 25)
    }

    @MainActor
    func testInterfaceTextFallsBackToEnglishWhenUntranslated() {
        let viewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService()
        )
        viewModel.language = .turkish
        // Translated key resolves to the target language.
        XCTAssertEqual(viewModel.text(ar: "الكتالوج", en: "Catalog"), "Katalog")
        // Untranslated string must fall back to English, never to a raw key or Arabic.
        let untranslated = viewModel.text(ar: "نص عربي غير مترجم", en: "An untranslated interface string")
        XCTAssertEqual(untranslated, "An untranslated interface string")

        viewModel.language = .arabic
        XCTAssertEqual(viewModel.text(ar: "الكتالوج", en: "Catalog"), "الكتالوج")
        viewModel.language = .english
        XCTAssertEqual(viewModel.text(ar: "الكتالوج", en: "Catalog"), "Catalog")
    }
}
