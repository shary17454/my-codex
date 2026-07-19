import XCTest
@testable import BatalAlDroob

final class BatalCatalogResourceTests: XCTestCase {
    private var bundle: Bundle { Bundle(for: Self.self) }

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
    }

    func testBundledSupportDataExists() throws {
        XCTAssertNotNil(bundle.url(forResource: "part_fitment_index", withExtension: "json", subdirectory: "data"))
        XCTAssertNotNil(bundle.url(forResource: "patrol_catalog_manifest", withExtension: "json", subdirectory: "data"))
        XCTAssertNotNil(bundle.url(forResource: "patrol_catalog_database", withExtension: "json", subdirectory: "data"))
        XCTAssertNotNil(bundle.url(forResource: "part_request_business_model", withExtension: "json", subdirectory: "data"))
    }

    func testPartNumberCandidatesRecognizePrintedOEMFormats() {
        let candidates = partNumberCandidates(in: "NISSAN 21082 – 4W000 / REF A123456789")

        XCTAssertTrue(candidates.contains("21082-4W000"))
        XCTAssertTrue(candidates.contains("A123456789"))
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

    func testExternalStoreLinksRequireHTTPHost() throws {
        XCTAssertTrue(isAllowedExternalURL(try XCTUnwrap(URL(string: "https://example.com/parts?q=21082-4W000"))))
        XCTAssertFalse(isAllowedExternalURL(try XCTUnwrap(URL(string: "javascript:alert(1)"))))
        XCTAssertFalse(isAllowedExternalURL(try XCTUnwrap(URL(string: "https:///missing-host"))))
    }

    func testWeatherConditionIsLocalized() {
        let weather = OpenMeteoWeather.Current(temperature2m: 31, weatherCode: 3)

        XCTAssertEqual(weather.condition(language: .arabic), "غائم")
        XCTAssertEqual(weather.condition(language: .english), "Cloudy")
    }

    private func loadJSONObject(named name: String, subdirectory: String) throws -> [String: Any] {
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory))
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }
}
