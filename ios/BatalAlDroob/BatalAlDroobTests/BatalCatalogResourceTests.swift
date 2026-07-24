@testable import BatalAlDroob
import XCTest

final class BatalCatalogResourceTests: XCTestCase {
    private var bundle: Bundle {
        Bundle(for: Self.self)
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

    @MainActor
    func testSavedPartRequestIsTrimmedBeforeStorage() {
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
        let request = SavedPartRequest(
            generation: "   ",
            year: " 1997 ",
            vin: " wgy60348567 ",
            partNumber: " 21082-4w000 ",
            partName: " Water outlet "
        )

        XCTAssertTrue(viewModel.saveRequestPlan(plan, request: request))
        let saved = try? XCTUnwrap(viewModel.savedRequests.first)
        XCTAssertEqual(saved?.generation, "Y60")
        XCTAssertEqual(saved?.year, "1997")
        XCTAssertEqual(saved?.vin, "WGY60348567")
        XCTAssertEqual(saved?.partNumber, "21082-4W000")
        XCTAssertEqual(saved?.partName, "Water outlet")
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
    func testCatalogUnlockUsesPermanentProductIdentifier() {
        let viewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService()
        )

        XCTAssertEqual(viewModel.purchaseProductIDs, ["batal.catalog.permanent.unlock"])
        XCTAssertEqual(StoreProductID.catalogPermanentUnlock, "batal.catalog.permanent.unlock")
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
    func testDescriptionSearchAcceptsDirectPartNumber() async {
        let viewModel = CatalogViewModel(
            repository: RankedCatalogRepository(),
            store: TestPurchaseService()
        )

        await viewModel.load()
        XCTAssertTrue(viewModel.applyDescriptionSearch("21082-4W000"))
        XCTAssertEqual(viewModel.selectedPart?.partNumber, "21082-4W000")
    }

    @MainActor
    func testBlankDescriptionSearchShowsUserVisibleError() {
        let viewModel = CatalogViewModel(
            repository: StaticCatalogRepository(),
            store: TestPurchaseService()
        )

        XCTAssertFalse(viewModel.applyDescriptionSearch("   "))
        XCTAssertNotNil(viewModel.errorMessage)
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
              "category": "general"
            }
            """),
            Self.part("""
            {
              "part_number": "21082-4W000",
              "name_en": "Exact part",
              "confidence": 70,
              "category": "cooling"
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
          "evidence": []
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
}

private enum TestFailure: Error {
    case storeDirectoryUnavailable
}
