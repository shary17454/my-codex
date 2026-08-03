@testable import BatalAlDroob
import CryptoKit
import XCTest

final class BatalCatalogResourceTests: XCTestCase {
    private var bundle: Bundle {
        Bundle.main
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        UserDefaults.standard.removeObject(forKey: "batalVehicleFilterEnabled")
        UserDefaults.standard.removeObject(forKey: "batalVehicleProfile")
    }

    func testBundledCatalogJSONHasUsableRecords() throws {
        let catalog = try loadJSONObject(named: "y60_app_catalog", subdirectory: "data")

        XCTAssertEqual(catalog["app_name"] as? String, "بطل الدروب")
        XCTAssertGreaterThan(catalog["part_count"] as? Int ?? 0, 0)
        XCTAssertGreaterThan(catalog["record_count"] as? Int ?? 0, 0)

        let parts = try XCTUnwrap(catalog["parts"] as? [[String: Any]])
        XCTAssertFalse(parts.isEmpty)
        XCTAssertNotNil(parts.first?["part_number"] as? String)
    }

    func testBundledStoreDirectoryHasVerifiedStores() throws {
        let directory = try loadJSONObject(named: "store_directory", subdirectory: "data")
        let stores = try XCTUnwrap(directory["verified_stores"] as? [[String: Any]])

        XCTAssertFalse(stores.isEmpty)
        XCTAssertNotNil(stores.first?["name_ar"] as? String)
        XCTAssertNotNil(stores.first?["website"] as? String)
        for store in stores {
            let website = try XCTUnwrap(store["website"] as? String)
            XCTAssertTrue(try isAllowedExternalURL(XCTUnwrap(URL(string: website))))
            if let template = store["search_url_template"] as? String {
                let resolved = template.replacingOccurrences(of: "{part_number}", with: "21082-4W000")
                XCTAssertTrue(try isAllowedExternalURL(XCTUnwrap(URL(string: resolved))))
            }
        }
    }

    func testRemovedSupplierCannotReturnInBundledDirectory() throws {
        let directoryURL = try XCTUnwrap(bundle.url(
            forResource: "store_directory",
            withExtension: "json",
            subdirectory: "data"
        ))
        let normalizedDirectory = try String(contentsOf: directoryURL, encoding: .utf8).lowercased()

        XCTAssertFalse(normalizedDirectory.contains("enhanced offroad solutions"))
        XCTAssertFalse(normalizedDirectory.contains("enhancedoffroadsolutions.com.au"))
    }

    func testUAEOEMPartsApprovalIsBundledWithSafeLimitations() throws {
        let directory = try loadJSONObject(named: "store_directory", subdirectory: "data")
        let stores = try XCTUnwrap(directory["verified_stores"] as? [[String: Any]])
        let supplier = try XCTUnwrap(stores.first { ($0["id"] as? String) == "uae-oem-parts" })

        XCTAssertEqual(supplier["website"] as? String, "https://uaeoemparts.com/contact/")
        let verification = try XCTUnwrap(supplier["verification"] as? [String: Any])
        XCTAssertEqual(verification["status"] as? String, "approved_by_written_email")
        XCTAssertTrue((verification["source"] as? String)?.contains("19f8067318b9910c") == true)
        let limitations = try XCTUnwrap(supplier["limitations"] as? [String: Any])
        XCTAssertTrue((limitations["ar"] as? String)?.contains("ليس وكيل نيسان") == true)
        XCTAssertTrue((limitations["en"] as? String)?.contains("Not a Nissan dealer") == true)
    }

    func testBundledSupportDataExists() {
        XCTAssertNotNil(bundle.url(forResource: "part_fitment_index", withExtension: "json", subdirectory: "data"))
        XCTAssertNotNil(bundle.url(forResource: "patrol_catalog_manifest", withExtension: "json", subdirectory: "data"))
        XCTAssertNotNil(bundle.url(forResource: "patrol_catalog_database", withExtension: "json", subdirectory: "data"))
        XCTAssertNotNil(bundle.url(
            forResource: "part_request_business_model",
            withExtension: "json",
            subdirectory: "data"
        ))
    }

    func testPatrolGenerationImagesAreBundledAndDocumented() throws {
        let resourceBundle = Bundle.main
        let documentedSources = try String(contentsOf: XCTUnwrap(resourceBundle.url(
            forResource: "IMAGE_SOURCES",
            withExtension: "md",
            subdirectory: "models"
        )), encoding: .utf8)

        for imageName in ["patrol-y60", "patrol-y61", "patrol-y62", "patrol-y63"] {
            let imageURL = try XCTUnwrap(resourceBundle.url(
                forResource: imageName,
                withExtension: "jpg",
                subdirectory: "models"
            ))
            let imageData = try Data(contentsOf: imageURL)

            XCTAssertGreaterThan(
                imageData.count,
                100_000,
                "\(imageName) should be a real optimized photo, not a placeholder."
            )
            XCTAssertLessThan(
                imageData.count,
                350_000,
                "\(imageName) should stay compressed enough for the app bundle."
            )
            XCTAssertTrue(documentedSources.contains("`\(imageName).jpg`"))
        }

        XCTAssertTrue(documentedSources.contains("Wikimedia Commons"))
        XCTAssertTrue(documentedSources.contains("Owner-provided app asset"))
        XCTAssertTrue(documentedSources.contains("Public domain") || documentedSources.contains("CC0"))
    }

    func testY60DetailYearsDisplayFullModelRange() {
        XCTAssertEqual(
            orderedModelYears(for: "Y60", years: ["1988", "1989", "1990", "1991", "1992", "1993"]),
            ["1988", "1989", "1990", "1991", "1992", "1993", "1994", "1995", "1996", "1997"]
        )
        XCTAssertEqual(
            fullYearListText(for: "Y60", years: ["1991"]),
            "1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997"
        )
    }

    func testPartNumberCandidatesRecognizePrintedOEMFormats() {
        let candidates = partNumberCandidates(in: "NISSAN 21082 – 4W000 / REF A123456789")

        XCTAssertTrue(candidates.contains("21082-4W000"))
        XCTAssertTrue(candidates.contains("A123456789"))
    }

    func testBundledCatalogContainsCompactAlternatePartNumber() throws {
        let catalogURL = try XCTUnwrap(bundle.url(
            forResource: "y60_app_catalog",
            withExtension: "json",
            subdirectory: "data"
        ))
        let catalogData = try Data(contentsOf: catalogURL)
        let catalog = try JSONDecoder().decode(CatalogPayload.self, from: catalogData)

        let matches = catalog.parts.filter { part in
            part.allNumbers.map(normalized).contains("081210401f")
        }

        XCTAssertFalse(matches.isEmpty)
        XCTAssertTrue(matches.contains { $0.partNumber == "23378-M4901" || $0.partNumber == "23378-03J00" })
    }

    func testBundledCatalogContainsMergedY61IABParts() throws {
        let catalogURL = try XCTUnwrap(bundle.url(
            forResource: "y60_app_catalog",
            withExtension: "json",
            subdirectory: "data"
        ))
        let catalogData = try Data(contentsOf: catalogURL)
        let catalog = try JSONDecoder().decode(CatalogPayload.self, from: catalogData)
        let y61Parts = catalog.parts.filter { ($0.model ?? "").uppercased() == "Y61" }

        XCTAssertGreaterThan(y61Parts.count, 5000)

        let engineAssembly = try XCTUnwrap(y61Parts.first { $0.partNumber == "10102VB050" })
        XCTAssertEqual(engineAssembly.nameEn, "ENGINE ASSY-BARE")
        XCTAssertTrue(engineAssembly.years.contains("1997"))
        XCTAssertTrue(engineAssembly.engines.contains("TB45E"))
        XCTAssertEqual(engineAssembly.category, "engine")
        XCTAssertTrue(engineAssembly.evidence.contains { $0.sourceID?.hasPrefix("y61_partsouq_iab_1997") == true })
    }

    @MainActor
    func testNaturalArabicSteeringArmSearchFindsCatalogParts() async {
        let viewModel = CatalogViewModel(
            repository: BundledCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()

        viewModel.searchText = "ذراع دركسون"
        let results = viewModel.filteredParts

        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { part in
            let text = viewModel.searchableText(for: part)
            return text.contains(normalized("arm pitman"))
                || text.contains(normalized("drag link"))
                || text.contains(normalized("pwr strg"))
        })
    }

    @MainActor
    func testDialectSynonymsExpandCommonPartSearchTerms() {
        let viewModel = CatalogViewModel(
            repository: BundledCatalogRepository(),
            store: TestPurchaseService()
        )

        XCTAssertTrue(viewModel.expandedSearchTerms(for: "اديتر ماء").contains(normalized("radiator")))
        XCTAssertTrue(viewModel.expandedSearchTerms(for: "طرمبة بنزين").contains(normalized("fuel pump")))
        XCTAssertTrue(viewModel.expandedSearchTerms(for: "فحمات فرامل").contains(normalized("brake")))
        XCTAssertTrue(viewModel.expandedSearchTerms(for: "سلف").contains(normalized("starter")))
        XCTAssertTrue(viewModel.expandedSearchTerms(for: "كمبروسر مكيف").contains(normalized("compressor")))
    }

    @MainActor
    func testDialectPartSearchFindsBundledCatalogResults() async {
        let viewModel = CatalogViewModel(
            repository: BundledCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()

        for query in ["رديتر ماء", "فحمات فرامل", "سير دينمو", "سلف", "مساعدات"] {
            viewModel.searchText = query
            XCTAssertFalse(viewModel.filteredParts.isEmpty, "Expected catalog results for dialect query: \(query)")
        }
    }

    func testDiagnosticKeywordsMapArabicAndEnglishDescriptions() {
        XCTAssertEqual(diagnosticKeywords("مشكلة في الفرامل"), ["brake"])
        XCTAssertEqual(diagnosticKeywords("radiator heat issue"), ["cooling", "fan", "radiator"])
    }

    func testTireDiameterParsesValidSizeAndRejectsInvalidInput() {
        XCTAssertEqual(tireDiameter("265/70R16") ?? 0, 30.606, accuracy: 0.001)
        XCTAssertNil(tireDiameter("not-a-size"))
    }

    func testPartRequestDraftUsesSelectedLanguageAndOmitsEmptyFields() {
        let plan = PartRequestPlan(
            id: "basic",
            titleAr: "طلب أساسي",
            titleEn: "Basic request",
            descriptionAr: "",
            descriptionEn: ""
        )
        let request = SavedPartRequest(
            generation: "Y60",
            year: "1997",
            partNumber: "21082-4W000",
            partName: "Water outlet"
        )

        let arabic = partRequestDraft(for: request, plan: plan, language: .arabic)
        let english = partRequestDraft(for: request, plan: plan, language: .english)

        XCTAssertTrue(arabic.contains("بطل الدروب - طلب أساسي"))
        XCTAssertTrue(arabic.contains("رقم القطعة: 21082-4W000"))
        XCTAssertTrue(english.contains("Batal Al-Droob - Basic request"))
        XCTAssertTrue(english.contains("Part number: 21082-4W000"))
        XCTAssertFalse(english.contains("VIN:"))
    }

    @MainActor
    func testBlankPartRequestCannotBeSaved() {
        let defaultsKey = "batalPartRequests"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService()
        )
        let plan = PartRequestPlan(
            id: "basic",
            titleAr: "طلب أساسي",
            titleEn: "Basic request",
            descriptionAr: "",
            descriptionEn: ""
        )
        let blankRequest = SavedPartRequest(partNumber: "   ", partName: "\n")

        XCTAssertFalse(partRequestHasRequiredInput(blankRequest))
        viewModel.saveRequestPlan(plan, request: blankRequest)
        XCTAssertTrue(viewModel.savedRequests.isEmpty)
    }

    func testExternalStoreLinksRequireHTTPSHost() throws {
        XCTAssertTrue(try isAllowedExternalURL(XCTUnwrap(URL(string: "https://example.com/parts?q=21082-4W000"))))
        XCTAssertFalse(try isAllowedExternalURL(XCTUnwrap(URL(string: "http://example.com/parts"))))
        XCTAssertFalse(try isAllowedExternalURL(XCTUnwrap(URL(string: "javascript:alert(1)"))))
        XCTAssertFalse(try isAllowedExternalURL(XCTUnwrap(URL(string: "https:///missing-host"))))
    }

    func testStoreSpecificLinksStayWithinVerifiedStoreDomains() throws {
        let store = VerifiedStore(
            id: "verified-store",
            nameAr: "متجر موثق",
            nameEn: "Verified Store",
            category: "global",
            website: "https://example.com",
            searchURLTemplate: "https://parts.example.com/search?q={part_number}"
        )

        XCTAssertTrue(try isAllowedExternalURL(XCTUnwrap(URL(string: "https://example.com")), for: store))
        let searchURL = try XCTUnwrap(URL(string: "https://parts.example.com/search?q=21082"))
        let unrelatedURL = try XCTUnwrap(URL(string: "https://evil.example/search?q=21082"))
        let insecureURL = try XCTUnwrap(URL(string: "http://example.com/search?q=21082"))

        XCTAssertTrue(isAllowedExternalURL(searchURL, for: store))
        XCTAssertFalse(isAllowedExternalURL(unrelatedURL, for: store))
        XCTAssertFalse(isAllowedExternalURL(insecureURL, for: store))
    }

    @MainActor
    func testCatalogLoadRetriesStoreDirectoryAfterPartialFailure() async {
        let repository = RetryStoreDirectoryRepository()
        let viewModel = CatalogViewModel(
            repository: repository,
            store: TestPurchaseService()
        )

        await viewModel.load()
        XCTAssertTrue(viewModel.stores.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)

        await viewModel.load()
        XCTAssertEqual(viewModel.stores.map(\.id), ["verified-store"])
        XCTAssertNil(viewModel.errorMessage)
        let attempts = await repository.storeLoadAttempts()
        XCTAssertEqual(attempts, 2)
    }

    @MainActor
    func testStoreKitEntitlementsAreTheUnlockSourceOfTruth() async {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let entitledViewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService(entitlements: [StoreProductID.catalogPermanentUnlock])
        )
        await entitledViewModel.load()
        XCTAssertTrue(entitledViewModel.paidUnlocks.contains("__catalog_unlock__"))

        let revokedViewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService(entitlements: [])
        )
        await revokedViewModel.load()
        XCTAssertFalse(revokedViewModel.paidUnlocks.contains("__catalog_unlock__"))
    }

    @MainActor
    func testCatalogUnlockUsesApprovedProductIdentifiers() {
        let viewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService()
        )

        XCTAssertEqual(
            viewModel.purchaseProductIDs,
            [
                "batal.catalog.single.unlock",
                "batal.catalog.permanent.unlock",
                "batal.catalog.full.unlock"
            ]
        )
        XCTAssertEqual(StoreProductID.singleCatalogUnlock, "batal.catalog.single.unlock")
        XCTAssertEqual(StoreProductID.catalogFullUnlock, "batal.catalog.permanent.unlock")
        XCTAssertEqual(StoreProductID.catalogPermanentUnlock, "batal.catalog.permanent.unlock")
        XCTAssertEqual(StoreProductID.legacyCatalogFullUnlock, "batal.catalog.full.unlock")
        XCTAssertEqual(CatalogAccessLevel.fullCatalog.productID, "batal.catalog.permanent.unlock")
    }

    @MainActor
    func testPurchaseRefreshesProductsBeforeFailingUnavailableUnlock() async throws {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let store = ProductRefreshPurchaseService(
            availabilityResponses: [
                [],
                [StoreProductID.singleCatalogUnlock, StoreProductID.catalogFullUnlock]
            ]
        )
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: store
        )
        await viewModel.load()
        viewModel.availableProductIDs = []
        let part = try XCTUnwrap(viewModel.parts.first { $0.partNumber == "21082-4W000" })

        await viewModel.unlock(part, level: .singleUnlock)

        XCTAssertEqual(store.availableProductLookupCount(), 2)
        XCTAssertEqual(store.purchasedProductIDs(), [StoreProductID.singleCatalogUnlock])
        XCTAssertTrue(viewModel.isUnlocked(part))
        XCTAssertTrue(viewModel.paymentMessage?.contains("تم الدفع") == true)
    }

    @MainActor
    func testPurchaseActionStaysEnabledWhenProductsNeedRefresh() async {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: ProductRefreshPurchaseService(availabilityResponses: [[], []])
        )
        await viewModel.load()
        viewModel.availableProductIDs = []

        XCTAssertFalse(viewModel.isPurchaseActionDisabled(for: .singleUnlock))
        viewModel.isLoadingPurchases = true
        XCTAssertTrue(viewModel.isPurchaseActionDisabled(for: .singleUnlock))
    }

    @MainActor
    func testSingleCatalogUnlockOpensOnlySelectedPart() async throws {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()
        let part = try XCTUnwrap(viewModel.parts.first { $0.partNumber == "21082-4W000" })
        let otherPart = try XCTUnwrap(viewModel.parts.first { $0.partNumber == "99999-TEST" })

        XCTAssertFalse(viewModel.isUnlocked(part))
        XCTAssertFalse(viewModel.isUnlocked(otherPart))

        await viewModel.unlock(part, level: .singleUnlock)

        XCTAssertTrue(viewModel.isUnlocked(part))
        XCTAssertFalse(viewModel.isUnlocked(otherPart))
        XCTAssertFalse(viewModel.isFullCatalogUnlocked())
        XCTAssertEqual(CatalogAccessLevel.singleUnlock.title(.arabic), "فتح صفحة كتالوج واحدة")
        XCTAssertEqual(CatalogAccessLevel.singleUnlock.title(.english), "Unlock one catalog page")
        XCTAssertEqual(CatalogAccessLevel.singleUnlock.priceText(.arabic), "4 ر.س")
    }

    @MainActor
    func testCancelledSinglePagePurchaseKeepsUnlockActionRetryable() async throws {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let store = FixedOutcomePurchaseService(outcome: .cancelled)
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: store
        )
        await viewModel.load()
        let part = try XCTUnwrap(viewModel.parts.first { $0.partNumber == "21082-4W000" })

        await viewModel.unlock(part, level: .singleUnlock)

        XCTAssertFalse(viewModel.isUnlocked(part))
        XCTAssertFalse(viewModel.isPurchaseActionDisabled(for: .singleUnlock))
        XCTAssertEqual(store.purchasedProductIDs(), [StoreProductID.singleCatalogUnlock])
        XCTAssertTrue(viewModel.paymentMessage?.contains("تم إلغاء عملية الدفع") == true)
    }

    @MainActor
    func testAssistantPrepareRequestSavesClosestCatalogResult() async throws {
        let defaultsKey = "batalPartRequests"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()
        viewModel.isVehicleFilterEnabled = false
        viewModel.selectedCategory = .all
        viewModel.searchText = "21082-4W000"
        let topResult = try XCTUnwrap(viewModel.assistantTopResult)

        viewModel.prepareAssistantPartRequest()

        let saved = try XCTUnwrap(viewModel.savedRequests.first)
        XCTAssertEqual(saved.partNumber, viewModel.protectedNumber(topResult))
        XCTAssertEqual(saved.partName, viewModel.title(for: topResult))
        XCTAssertEqual(saved.planID, "basic")
        XCTAssertTrue(saved.draft.contains(saved.partName))
        XCTAssertTrue(viewModel.aiMessages.last?.text.contains("تم حفظ طلب قطعة") == true)
    }

    @MainActor
    func testPhotoAndFitmentResultsMaskPartNumberUntilSingleUnlock() async throws {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()

        viewModel.applyRecognizedPhotoText(["NISSAN 21082-4W000"])
        let part = try XCTUnwrap(viewModel.selectedPart)

        XCTAssertEqual(viewModel.protectedNumber(part), "21••••00")
        XCTAssertFalse(viewModel.selectedPhotoName?.contains("21082-4W000") ?? true)
        XCTAssertTrue(viewModel.selectedPhotoName?.contains("سبب الترشيح") ?? false)

        let lockedSummary = viewModel.fitmentSummary(for: "21082-4W000")
        XCTAssertTrue(lockedSummary.contains("21••••00"))
        XCTAssertFalse(lockedSummary.contains("الرقم الأساسي: 21082-4W000"))

        await viewModel.unlock(part, level: .singleUnlock)

        XCTAssertEqual(viewModel.protectedNumber(part), "21082-4W000")
        XCTAssertTrue(viewModel.fitmentSummary(for: "21082-4W000").contains("21082-4W000"))
    }

    @MainActor
    func testVehicleProfileFilterNarrowsCatalogResults() async {
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()

        viewModel.searchText = ""
        XCTAssertEqual(Set(viewModel.filteredParts.map(\.partNumber)), ["99999-TEST", "21082-4W000"])

        viewModel.vehicleProfile.generation = "Y60"
        viewModel.vehicleProfile.year = "1997"
        viewModel.vehicleProfile.engine = "TB48"
        viewModel.isVehicleFilterEnabled = true

        XCTAssertEqual(viewModel.filteredParts.map(\.partNumber), ["21082-4W000"])
        XCTAssertEqual(viewModel.vehicleMatchSummary(for: viewModel.filteredParts[0]), "متوافق مع ملف سيارتك")
    }

    @MainActor
    func testInteriorGearTrimSearchDoesNotRankHardwareAsTopResult() async throws {
        let viewModel = CatalogViewModel(
            repository: InteriorTrimCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()
        viewModel.isVehicleFilterEnabled = false
        viewModel.selectedCategory = .all
        viewModel.searchText = "رقم ديكور القير العنابي لنيسان 1992"

        let results = viewModel.filteredParts
        let debugResults = results.map { "\($0.partNumber): \(viewModel.title(for: $0))" }.joined(separator: " | ")

        XCTAssertEqual(results.first?.partNumber, "96935-TRIM", debugResults)
        XCTAssertFalse(try viewModel.title(for: XCTUnwrap(results.first)).contains("صامولة"), debugResults)
        XCTAssertFalse(results.prefix(2).contains { viewModel.title(for: $0).contains("صامولة") }, debugResults)
    }

    @MainActor
    func testFullCatalogUnlockOpensAllParts() async throws {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )
        await viewModel.load()
        let part = try XCTUnwrap(viewModel.parts.first)

        await viewModel.unlock(part, level: .fullCatalog)

        XCTAssertTrue(viewModel.isFullCatalogUnlocked())
        XCTAssertTrue(viewModel.parts.allSatisfy { viewModel.isUnlocked($0) })
        XCTAssertEqual(CatalogAccessLevel.fullCatalog.title(.arabic), "فتح الكتالوج الكامل")
        XCTAssertEqual(CatalogAccessLevel.fullCatalog.title(.english), "Unlock full catalog")
        XCTAssertEqual(CatalogAccessLevel.fullCatalog.priceText(.arabic), "100 ر.س")
    }

    @MainActor
    func testOfferCodeRedemptionUsesStoreKitWithoutLocalBypass() async {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let store = OfferCodeTrackingPurchaseService(entitlementsAfterRedemption: [])
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: store
        )
        await viewModel.load()

        await viewModel.redeemOfferCode()

        XCTAssertEqual(store.redemptionPresentationCount(), 1)
        XCTAssertFalse(viewModel.isFullCatalogUnlocked())
        XCTAssertTrue(viewModel.paymentMessage?.contains("استعادة المشتريات") == true)
    }

    @MainActor
    func testOfferCodeRedemptionUnlocksWhenAppleEntitlementExists() async {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let store = OfferCodeTrackingPurchaseService(
            entitlementsAfterRedemption: [StoreProductID.catalogPermanentUnlock]
        )
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: store
        )
        await viewModel.load()

        await viewModel.redeemOfferCode()

        XCTAssertEqual(store.redemptionPresentationCount(), 1)
        XCTAssertTrue(viewModel.isFullCatalogUnlocked())
        XCTAssertTrue(viewModel.paymentMessage?.contains("تم استرداد الكود") == true)
    }

    @MainActor
    func testLocalCustomerEmailSavesNormalizedDeviceOnlyProfile() {
        let defaultsKey = "batalCustomerProfile"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )

        XCTAssertTrue(viewModel.saveLocalCustomer(name: "  مالك التطبيق  ", email: "  OWNER@Example.COM  "))
        XCTAssertEqual(viewModel.customerProfile.accessMode, .localEmail)
        XCTAssertEqual(viewModel.customerProfile.displayName, "مالك التطبيق")
        XCTAssertEqual(viewModel.customerProfile.email, "owner@example.com")
        XCTAssertTrue(viewModel.customerProfile.hasCompletedSignInChoice)
        XCTAssertFalse(
            viewModel.isFullCatalogUnlocked(),
            "Regular local customer email must not bypass StoreKit catalog access."
        )
    }

    @MainActor
    func testConfiguredOwnerEmailUnlocksCatalogWithoutStoreKitPurchase() async throws {
        let profileKey = "batalCustomerProfile"
        let unlocksKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: unlocksKey)
        defer {
            UserDefaults.standard.removeObject(forKey: profileKey)
            UserDefaults.standard.removeObject(forKey: unlocksKey)
        }

        let store = ProductRefreshPurchaseService(availabilityResponses: [[]])
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: store,
            ownerAccess: DefaultOwnerAccessAuthorizer(ownerEmails: ["owner@example.com"])
        )

        await viewModel.load()
        XCTAssertTrue(viewModel.saveLocalCustomer(name: "Owner", email: " OWNER@example.com "))

        let part = try XCTUnwrap(viewModel.parts.first { part in part.partNumber == "21082-4W000" })
        XCTAssertTrue(viewModel.hasOwnerAccess)
        XCTAssertTrue(viewModel.isFullCatalogUnlocked())
        XCTAssertTrue(viewModel.parts.allSatisfy { part in viewModel.isUnlocked(part) })
        XCTAssertEqual(viewModel.protectedNumber(part), "21082-4W000")

        await viewModel.unlock(part, level: .fullCatalog)

        XCTAssertEqual(store.purchasedProductIDs(), [])
        XCTAssertEqual(store.availableProductLookupCount(), 1)
        XCTAssertTrue(viewModel.paymentMessage?.contains("وضع المالك مفعل") == true)
    }

    @MainActor
    func testInvalidLocalCustomerEmailIsRejectedWithoutChangingProfile() {
        let defaultsKey = "batalCustomerProfile"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )

        XCTAssertFalse(viewModel.saveLocalCustomer(name: "Bad", email: "not-an-email"))
        XCTAssertEqual(viewModel.customerProfile.accessMode, .localEmail)
        XCTAssertEqual(viewModel.customerProfile.email, "")
        XCTAssertFalse(viewModel.customerProfile.hasCompletedSignInChoice)
    }

    @MainActor
    func testValidLocalCustomerEmailCompletesRequiredSignInChoice() {
        let defaultsKey = "batalCustomerProfile"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )

        XCTAssertTrue(viewModel.saveLocalCustomer(name: "Owner", email: "owner@example.com"))
        XCTAssertEqual(viewModel.customerProfile.accessMode, .localEmail)
        XCTAssertEqual(viewModel.customerProfile.displayName, "Owner")
        XCTAssertEqual(viewModel.customerProfile.email, "owner@example.com")
        XCTAssertTrue(viewModel.customerProfile.hasCompletedSignInChoice)
    }

    @MainActor
    func testLegacyFullCatalogEntitlementStillRestoresAccess() async {
        let defaultsKey = "batalPaidUnlocks"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService(entitlements: [StoreProductID.legacyCatalogFullUnlock])
        )
        await viewModel.load()

        XCTAssertTrue(viewModel.isFullCatalogUnlocked())
        XCTAssertTrue(viewModel.parts.allSatisfy { viewModel.isUnlocked($0) })
    }

    @MainActor
    func testFitmentSearchRanksExactPartNumberBeforeTextMatches() async {
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )

        await viewModel.load()
        let matches = viewModel.fitmentMatches(for: "21082-4W000")

        XCTAssertEqual(matches.first?.partNumber, "21082-4W000")
    }

    @MainActor
    func testCompactAlternatePartNumberSearchIgnoresMismatchedCategoryFilter() async {
        let viewModel = CatalogViewModel(
            repository: AlternatePartNumberRepository(),
            store: TestPurchaseService()
        )

        await viewModel.load()
        viewModel.selectedCategory = .engine
        viewModel.searchText = "081210401F"

        XCTAssertEqual(viewModel.filteredParts.map(\.partNumber), ["23378-M4901"])
    }

    @MainActor
    func testCloseCompactPartNumberSearchSuggestsNearestCatalogRecord() async {
        let viewModel = CatalogViewModel(
            repository: AlternatePartNumberRepository(),
            store: TestPurchaseService()
        )

        await viewModel.load()
        viewModel.searchText = "081208301F"

        XCTAssertEqual(viewModel.filteredParts.map(\.partNumber), ["23378-M4901"])
        XCTAssertTrue(viewModel.fitmentSummary(for: "081208301F").contains("23••••01"))
    }

    @MainActor
    func testAssistantContextMasksLockedPartNumbersAndOmitsVIN() async throws {
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService(),
            aiService: FakeAIAssistantService()
        )
        await viewModel.load()
        viewModel.searchText = "21082-4W000"
        viewModel.vehicleProfile.vin = "JN8AZ2NF0E9555555"
        viewModel.maintenanceItems = [
            MaintenanceItem(title: "Oil service", odometer: "120000", notes: "Customer token=secret")
        ]

        let request = viewModel.assistantContextRequest(message: "هل تناسب؟")
        let encoded = try String(data: JSONEncoder().encode(request), encoding: .utf8) ?? ""

        XCTAssertFalse(encoded.contains("JN8AZ2NF0E9555555"))
        XCTAssertFalse(encoded.contains("\"partNumber\":\"21082-4W000\""))
        XCTAssertTrue(encoded.contains("21••••00"))
        XCTAssertEqual(request.parts.first?.unlocked, false)
    }

    @MainActor
    func testAssistantAppendsResponseAndSuggestions() async {
        let service = FakeAIAssistantService(answer: "راجع أقرب نتيجة.")
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService(),
            aiService: service
        )
        await viewModel.load()

        await viewModel.askAssistant("وش أقرب قطعة؟")

        XCTAssertEqual(viewModel.aiMessages.count, 2)
        XCTAssertEqual(viewModel.aiMessages.last?.role, .assistant)
        XCTAssertTrue(viewModel.aiMessages.last?.text.contains("راجع أقرب نتيجة.") ?? false)
        XCTAssertEqual(viewModel.aiSuggestions.map(\.id), ["review-top-result"])
        XCTAssertNil(viewModel.aiErrorMessage)
    }

    @MainActor
    func testAssistantRejectsEmptyQuestion() async {
        let viewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService(),
            aiService: FakeAIAssistantService()
        )

        viewModel.aiQuestion = "   "
        await viewModel.askAssistant()

        XCTAssertTrue(viewModel.aiMessages.isEmpty)
        XCTAssertNotNil(viewModel.aiErrorMessage)
    }

    func testCatalogArchiveIndexAndManagedAssetDeliveryAreComplete() throws {
        let search = try loadJSONObject(named: "catalog_search_index", subdirectory: "search")
        let entries = try XCTUnwrap(search["entries"] as? [[String: Any]])
        let catalogEntries = entries.filter { entry in
            (entry["type"] as? String) == "catalog_pdf"
        }

        let manifest = try loadJSONObject(named: "patrol_full_catalog_files", subdirectory: "data")
        let files = try XCTUnwrap(manifest["files"] as? [[String: Any]])
        let bundledFiles = files.filter { item in
            (item["bundled"] as? Bool) == true && ((item["app_path"] as? String)?.hasSuffix(".pdf") == true)
        }
        let delivery = try loadJSONObject(named: "catalog_asset_delivery", subdirectory: "data")
        let deliveryDocuments = try XCTUnwrap(delivery["documents"] as? [[String: Any]])
        let deliveryPacks = try XCTUnwrap(delivery["packs"] as? [[String: Any]])

        XCTAssertEqual(files.count, 640)
        XCTAssertEqual(catalogEntries.count, bundledFiles.count)
        XCTAssertEqual(catalogEntries.count, 640)
        XCTAssertEqual(catalogEntries.filter { ($0["model"] as? String) == "Y60" }.count, 297)
        XCTAssertEqual(catalogEntries.filter { ($0["model"] as? String) == "Y61" }.count, 143)
        XCTAssertEqual(catalogEntries.filter { ($0["model"] as? String) == "Y62" }.count, 140)
        XCTAssertEqual(files.filter { ($0["generation"] as? String) == "Y60" }.count, 297)
        XCTAssertEqual(files.filter { ($0["generation"] as? String) == "Y61" }.count, 143)
        XCTAssertEqual(files.filter { ($0["generation"] as? String) == "Y62" }.count, 140)
        XCTAssertEqual(delivery["schemaVersion"] as? Int, 1)
        XCTAssertEqual(delivery["delivery"] as? String, "apple_hosted_background_assets")
        XCTAssertEqual(delivery["minimumManagedOS"] as? String, "iOS 26.0")
        XCTAssertEqual(delivery["totalFiles"] as? Int, 640)
        XCTAssertEqual(delivery["packCount"] as? Int, deliveryPacks.count)
        XCTAssertEqual(deliveryPacks.count, 40)
        XCTAssertLessThanOrEqual(deliveryPacks.count, 200)
        XCTAssertEqual(deliveryDocuments.count, 640)

        var uniquePaths = Set<String>()
        var sourceByPath: [String: [String: Any]] = [:]
        for item in bundledFiles {
            let archivePath = try XCTUnwrap(item["app_path"] as? String)
            let sha256 = try XCTUnwrap(item["sha256"] as? String)
            let byteCount = (item["bundled_bytes"] as? Int) ?? (item["size_bytes"] as? Int) ?? 0

            XCTAssertTrue(uniquePaths.insert(archivePath).inserted, "Duplicate catalog path: \(archivePath)")
            XCTAssertNotNil(sha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression))
            XCTAssertGreaterThan(byteCount, 0)
            sourceByPath[archivePath] = item
        }

        var deliveredPaths = Set<String>()
        var deliveredBytes: Int64 = 0
        let packIDs = Set(deliveryPacks.compactMap { $0["id"] as? String })
        XCTAssertEqual(packIDs.count, deliveryPacks.count)
        for document in deliveryDocuments {
            let assetPath = try XCTUnwrap(document["assetPath"] as? String)
            let assetPackID = try XCTUnwrap(document["assetPackID"] as? String)
            let sha256 = try XCTUnwrap(document["sha256"] as? String)
            let sizeBytes = try XCTUnwrap((document["sizeBytes"] as? NSNumber)?.int64Value)
            let source = try XCTUnwrap(sourceByPath[assetPath], "Missing source record for \(assetPath)")

            XCTAssertTrue(deliveredPaths.insert(assetPath).inserted, "Duplicate delivered path: \(assetPath)")
            XCTAssertTrue(assetPath.hasPrefix("catalog/patrol_full_unique/"))
            XCTAssertFalse(assetPath.split(separator: "/").contains(".."))
            XCTAssertTrue(packIDs.contains(assetPackID))
            XCTAssertEqual(sha256, source["sha256"] as? String)
            XCTAssertEqual(
                sizeBytes,
                ((source["bundled_bytes"] as? NSNumber) ?? (source["size_bytes"] as? NSNumber))?.int64Value
            )
            deliveredBytes += sizeBytes
        }
        XCTAssertEqual(deliveredPaths, uniquePaths)
        XCTAssertEqual(deliveredBytes, (delivery["totalBytes"] as? NSNumber)?.int64Value)

        let copiedPDFCount = catalogEntries.reduce(into: 0) { count, entry in
            guard
                let sourcePath = entry["sourcePdfPath"] as? String,
                let resourceURL = bundle.resourceURL
            else { return }
            let catalogURL = resourceURL.appendingPathComponent(sourcePath)
            if FileManager.default.fileExists(atPath: catalogURL.path) {
                count += 1
            }
        }
        XCTAssertEqual(
            copiedPDFCount,
            0,
            "Catalog PDFs must be delivered as Apple-hosted asset packs, not copied into the IPA."
        )

        for entry in catalogEntries.prefix(3) {
            let sourcePath = try XCTUnwrap(entry["sourcePdfPath"] as? String)
            XCTAssertTrue(sourcePath.hasPrefix("catalog/patrol_full_unique/"))
        }

        let status = try XCTUnwrap(manifest["catalog_bundle_status"] as? [String: Any])
        XCTAssertEqual(status["bundled_files"] as? Int, bundledFiles.count)
        XCTAssertEqual(status["missing_files"] as? Int, 0)
    }

    func testManagedCatalogServiceLoadsEveryIndexedDocument() async throws {
        let service = CatalogAssetService(resourceURL: bundle.resourceURL, localArchiveRoot: nil)

        let documents = try await service.loadDocuments()

        XCTAssertEqual(documents.count, 640)
        XCTAssertEqual(documents.filter { $0.generation == "Y60" }.count, 297)
        XCTAssertEqual(documents.filter { $0.generation == "Y61" }.count, 143)
        XCTAssertEqual(documents.filter { $0.generation == "Y62" }.count, 140)
        XCTAssertEqual(Set(documents.map(\.assetPackID)).count, 40)
    }

    func testManagedCatalogServiceVerifiesLocalPDFChecksum() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("BatalCatalogAssetTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let relativePath = "catalog/patrol_full_unique/Y60/1992/test.pdf"
        let fileURL = root.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let validData = Data("verified catalog payload".utf8)
        try validData.write(to: fileURL)
        let checksum = SHA256.hash(data: validData).map { String(format: "%02x", $0) }.joined()
        let document = CatalogDocument(
            id: "checksum-test",
            fileName: "test.pdf",
            generation: "Y60",
            years: ["1992"],
            engines: ["TB42"],
            modelCodes: ["Y60"],
            markets: [],
            sourceKind: "test",
            pageCount: 1,
            sizeBytes: Int64(validData.count),
            sha256: checksum,
            assetPackID: "batal.catalog.y60.001",
            assetPath: relativePath,
            sourceRelativePath: "test.pdf"
        )
        let validService = CatalogAssetService(resourceURL: nil, localArchiveRoot: root)

        let resolvedURL = try await validService.localURL(for: document)
        XCTAssertEqual(resolvedURL, fileURL)

        try Data(repeating: 0x41, count: validData.count).write(to: fileURL)
        let invalidService = CatalogAssetService(resourceURL: nil, localArchiveRoot: root)
        do {
            _ = try await invalidService.localURL(for: document)
            XCTFail("A modified PDF must not pass integrity verification.")
        } catch CatalogAssetError.invalidChecksum {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    @MainActor
    func testSmartPartIndicatorsAreActionableAndExplained() throws {
        let viewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService()
        )
        let part = try JSONDecoder().decode(Part.self, from: Data("""
        {
          "part_number": "96935-TRIM",
          "name_ar": "ديكور القير العنابي",
          "name_en": "Burgundy Gear Shift Console Finisher",
          "confidence": 70,
          "source_count": 2,
          "audit_status": "مدقق جزئيًا",
          "category": "interior",
          "model": "Y60",
          "years": ["1992"],
          "engines": ["TB42"],
          "evidence": [
            {
              "source_id": "01_combined_catalog_1988_1997",
              "year": "1992",
              "reference": "969A",
              "context": "Y60 console trim"
            }
          ]
        }
        """.utf8))

        let indicators = viewModel.smartIndicators(for: part)

        XCTAssertEqual(indicators.map(\.kind), SmartPartIndicatorKind.allCases)
        XCTAssertEqual(indicators.count, 4)
        for indicator in indicators {
            XCTAssertFalse(indicator.value.isEmpty)
            XCTAssertFalse(indicator.summary.isEmpty)
            XCTAssertFalse(indicator.details.isEmpty)
        }
        XCTAssertEqual(indicators.first { $0.kind == .confidence }?.value, "70%")
        XCTAssertEqual(indicators.first { $0.kind == .priceScore }?.value, "بيانات غير كافية")
    }

    private func loadJSONObject(named name: String, subdirectory: String) throws -> [String: Any] {
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory))
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }
}

private struct StaticCatalogRepository: CatalogRepository {
    func loadCatalog() async throws -> CatalogPayload {
        CatalogPayload(
            generatedAt: nil,
            appName: "بطل الدروب",
            model: "Y60",
            sourceCount: 0,
            recordCount: 0,
            partCount: 0,
            sources: [],
            parts: []
        )
    }

    func loadStores() async throws -> [VerifiedStore] {
        []
    }
}

private struct RankedCatalogRepository: CatalogRepository {
    func loadCatalog() async throws -> CatalogPayload {
        let parts = try [
            Self.part("""
            {
              "part_number": "99999-TEST",
              "name_en": "Text match 21082-4W000",
              "confidence": 100,
              "category": "general",
              "model": "Y61",
              "years": ["2005"],
              "engines": ["TB45"]
            }
            """),
            Self.part("""
            {
              "part_number": "21082-4W000",
              "name_en": "Exact part",
              "confidence": 70,
              "category": "cooling",
              "model": "Y60",
              "years": ["1997"],
              "engines": ["TB48"]
            }
            """)
        ]

        return CatalogPayload(
            generatedAt: nil,
            appName: "بطل الدروب",
            model: "Y60",
            sourceCount: 0,
            recordCount: 2,
            partCount: 2,
            sources: [],
            parts: parts
        )
    }

    func loadStores() async throws -> [VerifiedStore] {
        []
    }

    private static func part(_ json: String) throws -> Part {
        try JSONDecoder().decode(Part.self, from: Data(json.utf8))
    }
}

private struct InteriorTrimCatalogRepository: CatalogRepository {
    func loadCatalog() async throws -> CatalogPayload {
        let parts = try [
            Self.part("""
            {
              "part_number": "01225-00371",
              "name_ar": "صامولة",
              "name_en": "Grommet-Screw",
              "confidence": 98,
              "category": "body",
              "model": "Y60",
              "years": ["1988", "1989", "1990", "1991", "1992", "1993"],
              "engines": ["TB42"],
              "evidence": [
                {
                  "source_id": "01_combined_catalog_1988_1997",
                  "year": "1992",
                  "reference": "680A",
                  "context": "Y60 | لوحة العدادات، بطانة وغطاء مجموعة العدادات | Grommet-Screw | صامولة | gear trim nearby"
                }
              ]
            }
            """),
            Self.part("""
            {
              "part_number": "96935-TRIM",
              "name_ar": "ديكور القير العنابي",
              "name_en": "Burgundy Gear Shift Console Finisher",
              "confidence": 70,
              "category": "body",
              "model": "Y60",
              "years": ["1992"],
              "engines": ["TB42"],
              "evidence": [
                {
                  "source_id": "01_combined_catalog_1988_1997",
                  "year": "1992",
                  "reference": "969A",
                  "context": "Y60 | Console box and shift lever finisher | ديكور القير | burgundy interior trim | cover shift selector"
                }
              ]
            }
            """)
        ]

        return CatalogPayload(
            generatedAt: nil,
            appName: "بطل الدروب",
            model: "Y60",
            sourceCount: 1,
            recordCount: 2,
            partCount: 2,
            sources: [],
            parts: parts
        )
    }

    func loadStores() async throws -> [VerifiedStore] {
        []
    }

    private static func part(_ json: String) throws -> Part {
        try JSONDecoder().decode(Part.self, from: Data(json.utf8))
    }
}

private struct AlternatePartNumberRepository: CatalogRepository {
    func loadCatalog() async throws -> CatalogPayload {
        let part = try JSONDecoder().decode(Part.self, from: Data("""
        {
          "part_number": "23378-M4901",
          "name_en": "Holder Assy-Brush",
          "category": "general",
          "part_numbers": ["23378-M4901", "08121-0401F"],
          "primary_oem_number": "23378-M4901"
        }
        """.utf8))

        return CatalogPayload(
            generatedAt: nil,
            appName: "بطل الدروب",
            model: "Y60",
            sourceCount: 0,
            recordCount: 1,
            partCount: 1,
            sources: [],
            parts: [part]
        )
    }

    func loadStores() async throws -> [VerifiedStore] {
        []
    }
}

private actor RetryStoreDirectoryRepository: CatalogRepository {
    private var attempts = 0

    func loadCatalog() async throws -> CatalogPayload {
        try await StaticCatalogRepository().loadCatalog()
    }

    func loadStores() async throws -> [VerifiedStore] {
        attempts += 1
        if attempts == 1 { throw TestFailure.storeDirectoryUnavailable }
        return [
            VerifiedStore(
                id: "verified-store",
                nameAr: "متجر موثق",
                nameEn: "Verified Store",
                category: "global",
                website: "https://example.com",
                searchURLTemplate: "https://example.com/search?q={part_number}"
            )
        ]
    }

    func storeLoadAttempts() -> Int {
        attempts
    }
}

private struct TestPurchaseService: PurchaseService {
    var entitlements = Set<String>()

    func availableProductIDs(for productIDs: [String]) async throws -> Set<String> {
        Set(productIDs)
    }

    func currentEntitledProductIDs() async -> Set<String> {
        entitlements
    }

    func entitlementUpdates() -> AsyncStream<Set<String>> {
        AsyncStream { continuation in continuation.finish() }
    }

    func purchase(productID _: String) async throws -> PurchaseOutcome {
        .success
    }

    func restorePurchasedProductIDs() async throws -> Set<String> {
        entitlements
    }

    func presentOfferCodeRedemption() async throws {}
}

private final class ProductRefreshPurchaseService: PurchaseService, @unchecked Sendable {
    private var availabilityResponses: [Set<String>]
    private var lookupCount = 0
    private var purchasedIDs: [String] = []

    init(availabilityResponses: [Set<String>]) {
        self.availabilityResponses = availabilityResponses
    }

    func availableProductIDs(for productIDs: [String]) async throws -> Set<String> {
        lookupCount += 1
        guard !availabilityResponses.isEmpty else { return Set(productIDs) }
        return availabilityResponses.removeFirst()
    }

    func currentEntitledProductIDs() async -> Set<String> {
        []
    }

    func entitlementUpdates() -> AsyncStream<Set<String>> {
        AsyncStream { continuation in continuation.finish() }
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        purchasedIDs.append(productID)
        return .success
    }

    func restorePurchasedProductIDs() async throws -> Set<String> {
        []
    }

    func presentOfferCodeRedemption() async throws {}

    func availableProductLookupCount() -> Int {
        lookupCount
    }

    func purchasedProductIDs() -> [String] {
        purchasedIDs
    }
}

private final class FixedOutcomePurchaseService: PurchaseService, @unchecked Sendable {
    private let outcome: PurchaseOutcome
    private var purchasedIDs: [String] = []

    init(outcome: PurchaseOutcome) {
        self.outcome = outcome
    }

    func availableProductIDs(for productIDs: [String]) async throws -> Set<String> {
        Set(productIDs)
    }

    func currentEntitledProductIDs() async -> Set<String> {
        []
    }

    func entitlementUpdates() -> AsyncStream<Set<String>> {
        AsyncStream { continuation in continuation.finish() }
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        purchasedIDs.append(productID)
        return outcome
    }

    func restorePurchasedProductIDs() async throws -> Set<String> {
        []
    }

    func presentOfferCodeRedemption() async throws {}

    func purchasedProductIDs() -> [String] {
        purchasedIDs
    }
}

private final class OfferCodeTrackingPurchaseService: PurchaseService, @unchecked Sendable {
    private let entitlementsAfterRedemption: Set<String>
    private var presentationCount = 0
    private var hasPresentedRedemption = false

    init(entitlementsAfterRedemption: Set<String>) {
        self.entitlementsAfterRedemption = entitlementsAfterRedemption
    }

    func availableProductIDs(for productIDs: [String]) async throws -> Set<String> {
        Set(productIDs)
    }

    func currentEntitledProductIDs() async -> Set<String> {
        hasPresentedRedemption ? entitlementsAfterRedemption : []
    }

    func entitlementUpdates() -> AsyncStream<Set<String>> {
        AsyncStream { continuation in continuation.finish() }
    }

    func purchase(productID _: String) async throws -> PurchaseOutcome {
        .success
    }

    func restorePurchasedProductIDs() async throws -> Set<String> {
        await currentEntitledProductIDs()
    }

    func presentOfferCodeRedemption() async throws {
        presentationCount += 1
        hasPresentedRedemption = true
    }

    func redemptionPresentationCount() -> Int {
        presentationCount
    }
}

private struct FakeAIAssistantService: AIAssistantServicing {
    var answer = "AI answer"
    var isRemoteAIConfigured: Bool {
        true
    }

    func answer(_: AIAssistantRequest) async throws -> AIAssistantResponse {
        AIAssistantResponse(
            answer: answer,
            suggestions: [
                AISuggestion(id: "review-top-result", title: "افتح أقرب نتيجة", reason: "أفضل مرشح من البحث.")
            ],
            generatedByAI: true,
            privacyNote: "اختبار"
        )
    }
}

private enum TestFailure: Error {
    case storeDirectoryUnavailable
}
