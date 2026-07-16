import XCTest

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

    private func loadJSONObject(named name: String, subdirectory: String) throws -> [String: Any] {
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory))
        let data = try Data(contentsOf: url)
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }
}
