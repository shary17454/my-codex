@testable import BatalAlDroob
import XCTest

/// Tests for the 2.7 release: search-reason ranking, drivetrain categorisation,
/// vehicle-profile fitment boost, part-request validation, and the ten-language
/// interface localization.
final class BatalPhase1AndLocalizationTests: XCTestCase {
    /// `CatalogViewModel` mirrors these into `UserDefaults` through `didSet`, and the
    /// whole suite shares one process. Without this reset an owner email or an unlock
    /// left behind by one test would silently grant access inside the next one.
    private static let mutatedDefaultsKeys = [
        "batalCustomerProfile",
        "batalPaidUnlocks",
        "batalVehicleProfile",
        "batalVehicleFilterEnabled"
    ]

    override func setUpWithError() throws {
        try super.setUpWithError()
        Self.mutatedDefaultsKeys.forEach(UserDefaults.standard.removeObject(forKey:))
    }

    override func tearDownWithError() throws {
        Self.mutatedDefaultsKeys.forEach(UserDefaults.standard.removeObject(forKey:))
        try super.tearDownWithError()
    }

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

    // MARK: - Localization coverage
    //
    // The app declares ten languages in `CFBundleLocalizations`. These guard against the
    // table silently regressing back toward "declared but not actually translated".

    func testTranslationTableCoversTheWholeNavigationAndActionSurface() {
        // Every tab, primary action, and status word a user meets in a normal session.
        let coreInterface = [
            "Home", "Catalog", "Assistant", "Request", "Tools", "More",
            "Results", "No results", "Retry", "Dismiss", "Done", "Save", "OK",
            "Welcome", "Sign in", "Register", "Email", "Account",
            "Part number", "Part name", "Year", "Engine", "Transmission",
            "Maintenance", "Wishlist", "Verified stores", "Language"
        ]
        for key in coreInterface {
            for language in BatalLocalization.coveredLanguages {
                XCTAssertNotNil(
                    BatalLocalization.translate(key, to: language),
                    "'\(key)' is not translated for \(language.rawValue)"
                )
            }
        }
    }

    func testEveryTableEntryTranslatesIntoAllEightLanguages() {
        // A partially filled entry would leave one language showing English while its
        // neighbours are translated, which reads as a bug rather than a fallback.
        for key in ["Home", "Welcome", "Content protected", "Restore Purchases", "Smart indicators"] {
            let translations = BatalLocalization.coveredLanguages.compactMap {
                BatalLocalization.translate(key, to: $0)
            }
            XCTAssertEqual(
                translations.count,
                BatalLocalization.coveredLanguages.count,
                "'\(key)' is missing at least one language"
            )
            XCTAssertTrue(translations.allSatisfy { !$0.isEmpty })
        }
    }

    func testTranslationCoverageStaysWellAboveTheOriginalSeed() {
        // 2.7 shipped with 28 translated strings against ~337 inline pairs. This floor
        // keeps the table from being trimmed back to that state.
        XCTAssertGreaterThanOrEqual(BatalLocalization.translatedStringCount, 150)
        XCTAssertEqual(BatalLocalization.coveredLanguages.count, 8)
    }

    @MainActor
    func testPrivacyShieldTextIsLocalizedRatherThanArabicOrEnglishOnly() {
        // `PrivacyShieldView` resolves its own copy because it is drawn without the view
        // model; it must use the same table, not a bare `language == .arabic` ternary.
        XCTAssertEqual(BatalLocalization.translate("Content protected", to: .turkish), "İçerik korunuyor")
        XCTAssertNotNil(BatalLocalization.translate("Content protected", to: .hindi))
    }

    @MainActor
    func testFirstRunOnboardingCopyResolvesThroughTheTranslationTable() {
        // The onboarding screen used to resolve text locally, so a Spanish or Turkish user
        // saw an English welcome. It now goes through `CatalogViewModel.text(ar:en:)`.
        let viewModel = CatalogViewModel(repository: StaticCatalogRepository(), store: TestPurchaseService())
        viewModel.language = .spanish
        XCTAssertEqual(viewModel.text(ar: "مرحبًا", en: "Welcome"), "Bienvenido")
        XCTAssertEqual(viewModel.text(ar: "تسجيل دخول", en: "Sign in"), "Iniciar sesión")
        viewModel.language = .turkish
        XCTAssertEqual(viewModel.text(ar: "مرحبًا", en: "Welcome"), "Hoş geldiniz")
    }

    // MARK: - Derived-state memoization
    //
    // `filteredParts`, the category counters, and the generation counters are read several
    // times per SwiftUI `body`. They are now memoized; these tests pin the memo to the same
    // answers an uncached scan gives, and prove it invalidates when an input changes.

    @MainActor
    func testRepeatedFilteredPartsReadsAgreeAndReflectQueryChanges() async {
        let viewModel = CatalogViewModel(repository: BundledCatalogRepository(), store: TestPurchaseService())
        await viewModel.load()

        viewModel.searchText = "فحمات فرامل"
        let first = viewModel.filteredParts
        let second = viewModel.filteredParts
        XCTAssertEqual(first.map(\.partNumber), second.map(\.partNumber), "Repeated reads must agree")

        // Changing the query must change the answer, i.e. the memo key includes searchText.
        viewModel.searchText = "رديتر"
        let afterQueryChange = viewModel.filteredParts
        XCTAssertNotEqual(
            first.map(\.partNumber),
            afterQueryChange.map(\.partNumber),
            "A new query must not serve the previous cached result"
        )

        // Category is part of the key too.
        viewModel.searchText = ""
        viewModel.selectedCategory = .all
        let allCategories = viewModel.filteredParts
        viewModel.selectedCategory = .brake
        let brakeOnly = viewModel.filteredParts
        XCTAssertNotEqual(allCategories.map(\.partNumber), brakeOnly.map(\.partNumber))
        XCTAssertTrue(brakeOnly.allSatisfy { $0.categoryValue == .brake })
    }

    @MainActor
    func testVehicleFilterChangeInvalidatesTheSearchMemo() async {
        let viewModel = CatalogViewModel(repository: BundledCatalogRepository(), store: TestPurchaseService())
        await viewModel.load()
        viewModel.searchText = ""
        viewModel.selectedCategory = .all
        viewModel.isVehicleFilterEnabled = false
        let unfiltered = viewModel.filteredParts

        viewModel.vehicleProfile = VehicleProfile(generation: "Y61", year: "", vin: "", engine: "", transmission: "")
        viewModel.isVehicleFilterEnabled = true
        let filtered = viewModel.filteredParts
        XCTAssertLessThanOrEqual(filtered.count, unfiltered.count, "Enabling the filter cannot widen the result set")
        XCTAssertTrue(filtered.allSatisfy { viewModel.partFitsVehicleProfile($0) })
    }

    @MainActor
    func testCategoryAndGenerationCountersAreStableAcrossRepeatedReads() async {
        let viewModel = CatalogViewModel(repository: BundledCatalogRepository(), store: TestPurchaseService())
        await viewModel.load()

        for category in CatalogCategory.allCases {
            XCTAssertEqual(
                viewModel.categoryCount(category),
                viewModel.categoryCount(category),
                "Cached \(category.rawValue) count must match the first answer"
            )
        }
        // The counters must still partition the catalog: every part lands in exactly one
        // category, so the non-`all` counts sum to the total.
        let partitioned = CatalogCategory.allCases
            .filter { $0 != .all }
            .reduce(0) { $0 + viewModel.categoryCount($1) }
        XCTAssertEqual(partitioned, viewModel.parts.count)

        for generation in ["Y60", "Y61", "Y62", "Y63"] {
            XCTAssertEqual(
                viewModel.generationRecordCount(for: generation),
                viewModel.generationRecordCount(for: generation)
            )
        }
        XCTAssertGreaterThan(viewModel.generationRecordCount(for: "Y60"), 0)
    }

    @MainActor
    func testExpandedSearchTermMemoReturnsTheSameTermsForTheSameQuery() async {
        let viewModel = CatalogViewModel(repository: BundledCatalogRepository(), store: TestPurchaseService())
        await viewModel.load()

        let first = viewModel.expandedSearchTerms(for: "رديتر")
        let second = viewModel.expandedSearchTerms(for: "رديتر")
        XCTAssertEqual(first, second)
        XCTAssertTrue(first.contains(normalized("radiator")), "Dialect expansion must survive memoization")

        // A different query must not be served from the previous entry.
        let brakes = viewModel.expandedSearchTerms(for: "فرامل")
        XCTAssertNotEqual(first, brakes)
        XCTAssertTrue(brakes.contains(normalized("brake")))
    }

    // MARK: - Locale-independent normalization

    func testNormalizationDoesNotDependOnTheDeviceLocale() {
        // The catalog index is built once and queried on every device. Folding with the
        // current locale let a Turkish device fold `I`/`i` differently from the index.
        XCTAssertEqual(normalized("RADIATOR"), "radiator")
        XCTAssertEqual(normalized("Injector"), normalized("INJECTOR"))
        XCTAssertEqual(normalized("21082-4W000"), "210824w000")
        XCTAssertEqual(normalized("FILTER"), "filter")
        XCTAssertEqual(normalized("IGNITION"), normalized("ignition"))
    }

    func testPartNumberCandidateDetectionStillWorksWithSharedRegexes() {
        // The patterns are compiled once now instead of per call; behaviour must not move.
        XCTAssertTrue(partNumberCandidates(in: "need 21082-4W000 please").contains("21082-4W000"))
        XCTAssertTrue(partNumberCandidates(in: "part 1608253J00").contains("1608253J00"))
        XCTAssertTrue(partNumberCandidates(in: "no numbers here").isEmpty)
        // Repeated calls must agree, proving the shared compiled patterns are reusable.
        XCTAssertEqual(
            partNumberCandidates(in: "21082-4W000 and 1608253J00"),
            partNumberCandidates(in: "21082-4W000 and 1608253J00")
        )
    }

    // MARK: - Assistant redaction

    @MainActor
    func testLockedPartNumbersAreMaskedBeforeLeavingTheDevice() async {
        let viewModel = CatalogViewModel(repository: BundledCatalogRepository(), store: TestPurchaseService())
        await viewModel.load()
        // No entitlement and a non-owner profile: every paid number must stay masked.
        viewModel.paidUnlocks = []
        viewModel.customerProfile = CustomerProfile(
            accessMode: .localEmail,
            displayName: "Tester",
            email: "tester@example.com",
            hasCompletedSignInChoice: true
        )
        XCTAssertFalse(viewModel.hasOwnerAccess)

        guard let locked = viewModel.parts.first(where: { !viewModel.isUnlocked($0) && $0.partNumber.count > 4 }) else {
            return XCTFail("Expected at least one locked part")
        }

        let request = viewModel.assistantContextRequest(message: "Do you have \(locked.partNumber) in stock?")
        XCTAssertFalse(
            request.message.contains(locked.partNumber),
            "A locked part number must never be sent verbatim"
        )
        XCTAssertTrue(request.message.contains(masked(locked.partNumber)))
    }

    @MainActor
    func testUnlockedPartNumbersAreNotMasked() async {
        let viewModel = CatalogViewModel(repository: BundledCatalogRepository(), store: TestPurchaseService())
        await viewModel.load()
        // Owner access unlocks everything, so redaction must step aside.
        viewModel.customerProfile = CustomerProfile(
            accessMode: .localEmail,
            displayName: "Owner",
            email: "sharyalhwaid@gmail.com",
            hasCompletedSignInChoice: true
        )
        XCTAssertTrue(viewModel.hasOwnerAccess)

        guard let part = viewModel.parts.first(where: { $0.partNumber.count > 4 }) else {
            return XCTFail("Bundled catalog has no numbered part")
        }
        let request = viewModel.assistantContextRequest(message: "Do you have \(part.partNumber) in stock?")
        XCTAssertTrue(request.message.contains(part.partNumber))
    }
}
