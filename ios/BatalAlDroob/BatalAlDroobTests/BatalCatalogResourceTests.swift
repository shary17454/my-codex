@testable import BatalAlDroob
import XCTest

final class BatalCatalogResourceTests: XCTestCase {
    private var bundle: Bundle {
        Bundle(for: Self.self)
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

            XCTAssertGreaterThan(imageData.count, 100_000, "\(imageName) should be a real optimized photo, not a placeholder.")
            XCTAssertLessThan(imageData.count, 350_000, "\(imageName) should stay compressed enough for the app bundle.")
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

    @MainActor
    func testNaturalArabicSteeringArmSearchFindsCatalogParts() async throws {
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
    func testDialectPartSearchFindsBundledCatalogResults() async throws {
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
    func testPurchaseActionStaysEnabledWhenProductsNeedRefresh() async throws {
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
        XCTAssertFalse(viewModel.isFullCatalogUnlocked(), "Local customer email must not bypass StoreKit catalog access.")
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
        XCTAssertEqual(viewModel.customerProfile.accessMode, .guest)
        XCTAssertEqual(viewModel.customerProfile.email, "")
        XCTAssertFalse(viewModel.customerProfile.hasCompletedSignInChoice)
    }

    @MainActor
    func testContinueAsGuestClearsLocalCustomerEmail() {
        let defaultsKey = "batalCustomerProfile"
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: defaultsKey) }

        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )

        XCTAssertTrue(viewModel.saveLocalCustomer(name: "Owner", email: "owner@example.com"))
        viewModel.continueAsGuest()

        XCTAssertEqual(viewModel.customerProfile.accessMode, .guest)
        XCTAssertEqual(viewModel.customerProfile.displayName, "")
        XCTAssertEqual(viewModel.customerProfile.email, "")
        XCTAssertTrue(viewModel.customerProfile.hasCompletedSignInChoice)
    }

    @MainActor
    func testLegacyFullCatalogEntitlementStillRestoresAccess() async throws {
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
        let encoded = String(data: try JSONEncoder().encode(request), encoding: .utf8) ?? ""

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
    var isRemoteAIConfigured: Bool { true }

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
